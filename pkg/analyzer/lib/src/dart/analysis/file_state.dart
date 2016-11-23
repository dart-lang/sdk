// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/referenced_names.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

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
   * The absolute URI of the file.
   */
  final Uri uri;

  /**
   * The [Source] of the file with the [uri].
   */
  Source source;

  String _content;
  String _contentHash;
  LineInfo _lineInfo;
  Set<String> _referencedNames;
  UnlinkedUnit _unlinked;
  List<int> _apiSignature;

  List<FileState> _importedFiles;
  List<FileState> _exportedFiles;
  List<FileState> _partedFiles;
  Set<FileState> _directReferencedFiles = new Set<FileState>();
  Set<FileState> _transitiveFiles;
  String _transitiveSignature;

  FileState._(this._fsState, this.path, this.uri, this.source);

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
   * Return the set of all directly referenced files - imported, exported or
   * parted.
   */
  Set<FileState> get directReferencedFiles => _directReferencedFiles;

  /**
   * The list of files this file exports.
   */
  List<FileState> get exportedFiles => _exportedFiles;

  @override
  int get hashCode => uri.hashCode;

  /**
   * The list of files this file imports.
   */
  List<FileState> get importedFiles => _importedFiles;

  /**
   * Return `true` if the file has a `part of` directive, so is probably a part.
   */
  bool get isPart => _unlinked.isPartOf;

  /**
   * If the file [isPart], return a currently know library the file is a part
   * of. Return `null` if a library is not known, for example because we have
   * not processed a library file yet.
   */
  FileState get library {
    List<FileState> libraries = _fsState._partToLibraries[this];
    if (libraries == null || libraries.isEmpty) {
      return null;
    } else {
      return libraries.first;
    }
  }

  /**
   * Return information about line in the file.
   */
  LineInfo get lineInfo => _lineInfo;

  /**
   * The list of files this library file references as parts.
   */
  List<FileState> get partedFiles => _partedFiles;

  /**
   * The external names referenced by the file.
   */
  Set<String> get referencedNames => _referencedNames;

  /**
   * Return the set of transitive files - the file itself and all of the
   * directly or indirectly referenced files.
   */
  Set<FileState> get transitiveFiles {
    if (_transitiveFiles == null) {
      _transitiveFiles = new Set<FileState>();

      void appendReferenced(FileState file) {
        if (_transitiveFiles.add(file)) {
          file._directReferencedFiles.forEach(appendReferenced);
        }
      }

      appendReferenced(this);
    }
    return _transitiveFiles;
  }

  /**
   * Return the signature of the file, based on the [transitiveFiles].
   */
  String get transitiveSignature {
    if (_transitiveSignature == null) {
      ApiSignature signature = new ApiSignature();
      signature.addUint32List(_fsState._salt);
      signature.addString(_fsState._sdkApiSignature);
      signature.addInt(transitiveFiles.length);
      transitiveFiles
          .map((file) => file.apiSignature)
          .forEach(signature.addBytes);
      signature.addString(uri.toString());
      _transitiveSignature = signature.toHex();
    }
    return _transitiveSignature;
  }

  /**
   * The [UnlinkedUnit] of the file.
   */
  UnlinkedUnit get unlinked => _unlinked;

  /**
   * Return the [uri] string.
   */
  String get uriStr => uri.toString();

  @override
  bool operator ==(Object other) {
    return other is FileState && other.uri == uri;
  }

  /**
   * Return a new parsed unresolved [CompilationUnit].
   */
  CompilationUnit parse(AnalysisErrorListener errorListener) {
    AnalysisOptions analysisOptions = _fsState._analysisOptions;

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
    List<int> contentBytes = UTF8.encode(_content);
    {
      List<int> hashBytes = md5.convert(contentBytes).bytes;
      _contentHash = hex.encode(hashBytes);
    }

    // Prepare the unlinked bundle key.
    String unlinkedKey;
    {
      ApiSignature signature = new ApiSignature();
      signature.addUint32List(_fsState._salt);
      signature.addBytes(contentBytes);
      unlinkedKey = '${signature.toHex()}.unlinked';
    }

    // Prepare bytes of the unlinked bundle - existing or new.
    List<int> bytes;
    {
      bytes = _fsState._byteStore.get(unlinkedKey);
      if (bytes == null) {
        CompilationUnit unit = parse(AnalysisErrorListener.NULL_LISTENER);
        _fsState._logger.run('Create unlinked for $path', () {
          UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
          List<String> referencedNames = computeReferencedNames(unit).toList();
          bytes = new AnalysisDriverUnlinkedUnitBuilder(
                  unit: unlinkedUnit, referencedNames: referencedNames)
              .toBuffer();
          _fsState._byteStore.put(unlinkedKey, bytes);
        });
      }
    }

    // Read the unlinked bundle.
    var driverUnlinkedUnit = new AnalysisDriverUnlinkedUnit.fromBuffer(bytes);
    _referencedNames = new Set<String>.from(driverUnlinkedUnit.referencedNames);
    _unlinked = driverUnlinkedUnit.unit;
    _lineInfo = new LineInfo(_unlinked.lineStarts);
    List<int> newApiSignature = _unlinked.apiSignature;
    bool apiSignatureChanged = _apiSignature != null &&
        !_equalByteLists(_apiSignature, newApiSignature);
    _apiSignature = newApiSignature;

    // If the API signature changed, flush transitive signatures.
    if (apiSignatureChanged) {
      for (FileState file in _fsState._uriToFile.values) {
        if (file._transitiveFiles != null &&
            file._transitiveFiles.contains(this)) {
          file._transitiveSignature = null;
        }
      }
    }

    // This file is potentially not a library for its previous parts anymore.
    if (_partedFiles != null) {
      for (FileState part in _partedFiles) {
        _fsState._partToLibraries[part]?.remove(this);
      }
    }

    // Build the graph.
    _importedFiles = <FileState>[];
    _exportedFiles = <FileState>[];
    _partedFiles = <FileState>[];
    for (UnlinkedImport import in _unlinked.imports) {
      if (!import.isImplicit) {
        String uri = import.uri;
        if (!_isDartUri(uri)) {
          FileState file = _fileForRelativeUri(uri);
          if (file != null) {
            _importedFiles.add(file);
          }
        }
      }
    }
    for (UnlinkedExportPublic export in _unlinked.publicNamespace.exports) {
      String uri = export.uri;
      if (!_isDartUri(uri)) {
        FileState file = _fileForRelativeUri(uri);
        if (file != null) {
          _exportedFiles.add(file);
        }
      }
    }
    for (String uri in _unlinked.publicNamespace.parts) {
      if (!_isDartUri(uri)) {
        FileState file = _fileForRelativeUri(uri);
        if (file != null) {
          _partedFiles.add(file);
          // TODO(scheglov) Sort for stable results?
          _fsState._partToLibraries
              .putIfAbsent(file, () => <FileState>[])
              .add(this);
        }
      }
    }

    // Compute referenced files.
    Set<FileState> oldDirectReferencedFiles = _directReferencedFiles;
    _directReferencedFiles = new Set<FileState>()
      ..addAll(_importedFiles)
      ..addAll(_exportedFiles)
      ..addAll(_partedFiles);

    // If the set of directly referenced files of this file is changed,
    // then the transitive sets of files that include this file are also
    // changed. Reset these transitive sets.
    if (_directReferencedFiles.length != oldDirectReferencedFiles.length ||
        !_directReferencedFiles.containsAll(oldDirectReferencedFiles)) {
      for (FileState file in _fsState._uriToFile.values) {
        if (file._transitiveFiles != null &&
            file._transitiveFiles.contains(this)) {
          file._transitiveFiles = null;
        }
      }
    }

    // Return whether the API signature changed.
    return apiSignatureChanged;
  }

  @override
  String toString() => path;

  /**
   * Return the [FileState] for the given [relativeUri].
   */
  FileState _fileForRelativeUri(String relativeUri) {
    Uri absoluteUri = resolveRelativeUri(uri, FastUri.parse(relativeUri));
    return _fsState.getFileForUri(absoluteUri);
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
  final Uint32List _salt;
  final String _sdkApiSignature;

  /**
   * Mapping from a URI to the corresponding [FileState].
   */
  final Map<Uri, FileState> _uriToFile = {};

  /**
   * Mapping from a path to the corresponding [FileState]s, canonical or not.
   */
  final Map<String, List<FileState>> _pathToFiles = {};

  /**
   * Mapping from a path to the corresponding canonical [FileState].
   */
  final Map<String, FileState> _pathToCanonicalFile = {};

  /**
   * Mapping from a part to the libraries it is a part of.
   */
  final Map<FileState, List<FileState>> _partToLibraries = {};

  FileSystemStateTestView _testView;

  FileSystemState(
      this._logger,
      this._byteStore,
      this._contentOverlay,
      this._resourceProvider,
      this._sourceFactory,
      this._analysisOptions,
      this._salt,
      this._sdkApiSignature) {
    _testView = new FileSystemStateTestView(this);
  }

  /**
   * Return the set of known files.
   */
  Set<String> get knownFiles => _pathToFiles.keys.toSet();

  @visibleForTesting
  FileSystemStateTestView get test => _testView;

  /**
   * Return the canonical [FileState] for the given absolute [path]. The
   * returned file has the last known state since if was last refreshed.
   *
   * Here "canonical" means that if the [path] is in a package `lib` then the
   * returned file will have the `package:` style URI.
   */
  FileState getFileForPath(String path) {
    FileState file = _pathToCanonicalFile[path];
    if (file == null) {
      File resource = _resourceProvider.getFile(path);
      Source fileSource = resource.createSource();
      Uri uri = _sourceFactory.restoreUri(fileSource);
      // Try to get the existing instance.
      file = _uriToFile[uri];
      // If we have a file, call it the canonical one and return it.
      if (file != null) {
        _pathToCanonicalFile[path] = file;
        return file;
      }
      // Create a new file.
      FileSource uriSource = new FileSource(resource, uri);
      file = new FileState._(this, path, uri, uriSource);
      _uriToFile[uri] = file;
      _pathToFiles.putIfAbsent(path, () => <FileState>[]).add(file);
      _pathToCanonicalFile[path] = file;
      file.refresh();
    }
    return file;
  }

  /**
   * Return the [FileState] for the given absolute [uri]. May return `null` if
   * the [uri] is invalid, e.g. a `package:` URI without a package name. The
   * returned file has the last known state since if was last refreshed.
   */
  FileState getFileForUri(Uri uri) {
    FileState file = _uriToFile[uri];
    if (file == null) {
      Source uriSource = _sourceFactory.resolveUri(null, uri.toString());
      // If the URI is invalid, for example package:/test/d.dart (note the
      // leading '/'), then `null` is returned. We should ignore this URI.
      if (uriSource == null) {
        return null;
      }
      String path = uriSource.fullName;
      File resource = _resourceProvider.getFile(path);
      FileSource source = new FileSource(resource, uri);
      file = new FileState._(this, path, uri, source);
      _uriToFile[uri] = file;
      _pathToFiles.putIfAbsent(path, () => <FileState>[]).add(file);
      file.refresh();
    }
    return file;
  }

  /**
   * Return the list of all [FileState]s corresponding to the given [path]. The
   * list has at least one item, and the first item is the canonical file.
   */
  List<FileState> getFilesForPath(String path) {
    FileState canonicalFile = getFileForPath(path);
    List<FileState> allFiles = _pathToFiles[path].toList();
    if (allFiles.length == 1) {
      return allFiles;
    }
    return allFiles
      ..remove(canonicalFile)
      ..insert(0, canonicalFile);
  }
}

@visibleForTesting
class FileSystemStateTestView {
  final FileSystemState state;

  FileSystemStateTestView(this.state);

  Set<FileState> get filesWithoutTransitiveFiles {
    return state._uriToFile.values
        .where((f) => f._transitiveFiles == null)
        .toSet();
  }

  Set<FileState> get filesWithoutTransitiveSignature {
    return state._uriToFile.values
        .where((f) => f._transitiveSignature == null)
        .toSet();
  }
}
