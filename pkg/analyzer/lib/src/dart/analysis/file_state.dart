// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

/**
 * [FileContentOverlay] is used to temporary override content of files.
 */
class FileContentOverlay {
  final _map = <String, String>{};

  /**
   * Return the content of the file with the given [path], or `null` the
   * overlay does not override the content of the file.
   *
   * The [path] must be absolute and normalized.
   */
  String operator [](String path) => _map[path];

  /**
   * Return the new [content] of the file with the given [path].
   *
   * The [path] must be absolute and normalized.
   */
  void operator []=(String path, String content) {
    if (content == null) {
      _map.remove(path);
    } else {
      _map[path] = content;
    }
  }
}

/**
 * Information about a file being analyzed, explicitly or implicitly.
 *
 * It provides a consistent view on its properties.
 *
 * The properties are not guaranteed to represent the most recent state
 * of the file system. To update the file to the most recent state, [refresh]
 * should be called.
 */
class FileState {
  final FileSystemState _fsState;

  /**
   * The absolute path of the file.
   */
  final String path;

  /**
   * The [Source] for the file in the current [SourceFactory].
   */
  final Source source;

  String _content;
  String _contentHash;
  UnlinkedUnit _unlinked;
  List<int> _apiSignature;

  List<FileState> _importedFiles;
  List<FileState> _exportedFiles;
  List<FileState> _partedFiles;
  List<FileState> _dependencies;

  FileState(this._fsState, this.path, this.source);

  /**
   * The unlinked API signature of the file.
   */
  List<int> get apiSignature => _apiSignature;

  /**
   * The content of the file.
   */
  String get content => _content;

  /**
   * The MD5 hash of the [content].
   */
  String get contentHash => _contentHash;

  /**
   * Return the list of all direct dependencies.
   */
  List<FileState> get dependencies => _dependencies;

  /**
   * The list of files this file exports.
   */
  List<FileState> get exportedFiles => _exportedFiles;

  /**
   * The list of files this file imports.
   */
  List<FileState> get importedFiles => _importedFiles;

  /**
   * The list of files this library file references as parts.
   */
  List<FileState> get partedFiles => _partedFiles;

  /**
   * The [UnlinkedUnit] of the file.
   */
  UnlinkedUnit get unlinked => _unlinked;

  /**
   * The absolute URI of the file in the [SourceFactory].
   */
  Uri get uri => source.uri;

  /**
   * Read the file content and ensure that all of the file properties are
   * consistent with the read content, including API signature.
   *
   * Return `true` if the API signature changed since the last refresh.
   */
  bool refresh() {
    // Read the content.
    try {
      _content = _fsState._contentOverlay[path];
      _content ??= _fsState._resourceProvider.getFile(path).readAsStringSync();
    } catch (_) {
      _content = '';
      // TODO(scheglov) We fail to report URI_DOES_NOT_EXIST.
      // On one hand we need to provide an unlinked bundle to prevent
      // analysis context from reading the file (we want it to work
      // hermetically and handle one one file at a time). OTOH,
      // ResynthesizerResultProvider happily reports that any source in the
      // SummaryDataStore has MODIFICATION_TIME `0`. We need to return `-1`
      // for missing files. Maybe add this feature to SummaryDataStore?
    }
    // Compute the content hash.
    List<int> textBytes = UTF8.encode(content);
    List<int> hashBytes = md5.convert(textBytes).bytes;
    _contentHash = hex.encode(hashBytes);
    // Prepare bytes of the unlinked bundle - existing or new.
    List<int> bytes;
    {
      String key = '$contentHash.unlinked';
      bytes = _fsState._byteStore.get(key);
      if (bytes == null) {
        CompilationUnit unit =
            _parse(source, _content, _fsState._analysisOptions);
        _fsState._logger.run('Create unlinked for $path', () {
          UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
          bytes = unlinkedUnit.toBuffer();
          _fsState._byteStore.put(key, bytes);
        });
      }
    }
    // Read the unlinked bundle.
    _unlinked = new UnlinkedUnit.fromBuffer(bytes);
    List<int> newApiSignature = _unlinked.apiSignature;
    bool apiSignatureChanged = _apiSignature != null &&
        !_equalByteLists(_apiSignature, newApiSignature);
    _apiSignature = newApiSignature;
    // Build the graph.
    _importedFiles = <FileState>[];
    _exportedFiles = <FileState>[];
    _partedFiles = <FileState>[];
    for (UnlinkedImport import in _unlinked.imports) {
      if (!import.isImplicit) {
        String uri = import.uri;
        if (!_isDartUri(uri)) {
          FileState file = _fileForRelativeUri(uri);
          _importedFiles.add(file);
        }
      }
    }
    for (UnlinkedExportPublic export in _unlinked.publicNamespace.exports) {
      String uri = export.uri;
      if (!_isDartUri(uri)) {
        FileState file = _fileForRelativeUri(uri);
        _exportedFiles.add(file);
      }
    }
    for (String uri in _unlinked.publicNamespace.parts) {
      if (!_isDartUri(uri)) {
        FileState file = _fileForRelativeUri(uri);
        _partedFiles.add(file);
      }
    }
    // Compute direct dependencies.
    _dependencies = (new Set<FileState>()
          ..addAll(_importedFiles)
          ..addAll(_exportedFiles)
          ..addAll(_partedFiles))
        .toList();
    // Return whether the API signature changed.
    return apiSignatureChanged;
  }

  @override
  String toString() => path;

  /**
   * Return the [FileState] for the given [relativeUri].
   */
  FileState _fileForRelativeUri(String relativeUri) {
    Source uriSource = _fsState._sourceFactory.resolveUri(source, relativeUri);
    return _fsState.getFile(uriSource.fullName);
  }

  /**
   * Return `true` if the given byte lists are equal.
   */
  static bool _equalByteLists(List<int> a, List<int> b) {
    if (a == null) {
      return b == null;
    } else if (b == null) {
      return false;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  static bool _isDartUri(String uri) {
    return uri.startsWith('dart:');
  }

  /**
   * Return the parsed unresolved [CompilationUnit] for the given [content].
   */
  static CompilationUnit _parse(
      Source source, String content, AnalysisOptions analysisOptions) {
    AnalysisErrorListener errorListener = AnalysisErrorListener.NULL_LISTENER;

    CharSequenceReader reader = new CharSequenceReader(content);
    Scanner scanner = new Scanner(source, reader, errorListener);
    scanner.scanGenericMethodComments = analysisOptions.strongMode;
    Token token = scanner.tokenize();
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);

    Parser parser = new Parser(source, errorListener);
    parser.parseGenericMethodComments = analysisOptions.strongMode;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;
    return unit;
  }
}

/**
 * Information about known file system state.
 */
class FileSystemState {
  final PerformanceLog _logger;
  final ResourceProvider _resourceProvider;
  final ByteStore _byteStore;
  final FileContentOverlay _contentOverlay;
  final SourceFactory _sourceFactory;
  final AnalysisOptions _analysisOptions;

  final Map<String, FileState> _pathToFile = <String, FileState>{};

  FileSystemState(this._logger, this._byteStore, this._contentOverlay,
      this._resourceProvider, this._sourceFactory, this._analysisOptions);

  /**
   * Return the [FileState] for the give [path]. The returned file has the
   * last known state since if was last refreshed.
   */
  FileState getFile(String path) {
    FileState file = _pathToFile[path];
    if (file == null) {
      Source source = _sourceForPath(path);
      file = new FileState(this, path, source);
      _pathToFile[path] = file;
      file.refresh();
    }
    return file;
  }

  /**
   * Return the [Source] for the given [path] in [_sourceFactory].
   */
  Source _sourceForPath(String path) {
    Source fileSource = _resourceProvider.getFile(path).createSource();
    Uri uri = _sourceFactory.restoreUri(fileSource);
    return _resourceProvider.getFile(path).createSource(uri);
  }
}
