// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/defined_names.dart';
import 'package:analyzer/src/dart/analysis/referenced_names.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/name_filter.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/base/api_signature.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:front_end/src/fasta/scanner/token.dart';
import 'package:meta/meta.dart';

/**
 * The type of the function that is notified about an error during parsing.
 */
typedef void FileParseExceptionHandler(
    FileState file, exception, StackTrace stackTrace);

/**
 * [FileContentOverlay] is used to temporary override content of files.
 */
class FileContentOverlay {
  final _map = <String, String>{};

  /**
   * Return the paths currently being overridden.
   */
  Iterable<String> get paths => _map.keys;

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
   * The absolute file URI of the file.
   */
  final Uri fileUri;

  /**
   * The [Source] of the file with the [uri].
   */
  final Source source;

  /**
   * Return `true` if this file is a stub created for a file in the provided
   * external summary store. The values of most properties are not the same
   * as they would be if the file were actually read from the file system.
   * The value of the property [uri] is correct.
   */
  final bool isInExternalSummaries;

  bool _exists;
  String _content;
  String _contentHash;
  LineInfo _lineInfo;
  Set<String> _definedTopLevelNames;
  Set<String> _definedClassMemberNames;
  Set<String> _referencedNames;
  Set<String> _subtypedNames;
  String _unlinkedKey;
  UnlinkedUnit _unlinked;
  List<int> _apiSignature;

  List<FileState> _importedFiles;
  List<FileState> _exportedFiles;
  List<FileState> _partedFiles;
  List<NameFilter> _exportFilters;

  Set<FileState> _directReferencedFiles = new Set<FileState>();
  Set<FileState> _transitiveFiles;
  String _transitiveSignature;

  Map<String, TopLevelDeclaration> _topLevelDeclarations;
  Map<String, TopLevelDeclaration> _exportedTopLevelDeclarations;

  /**
   * The flag that shows whether the file has an error or warning that
   * might be fixed by a change to another file.
   */
  bool hasErrorOrWarning = false;

  FileState._(this._fsState, this.path, this.uri, this.fileUri, this.source)
      : isInExternalSummaries = false;

  FileState._external(this._fsState, this.uri)
      : isInExternalSummaries = true,
        path = null,
        fileUri = null,
        source = null {
    _apiSignature = new Uint8List(16);
  }

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
   * The class member names defined by the file.
   */
  Set<String> get definedClassMemberNames => _definedClassMemberNames;

  /**
   * The top-level names defined by the file.
   */
  Set<String> get definedTopLevelNames => _definedTopLevelNames;

  /**
   * Return the set of all directly referenced files - imported, exported or
   * parted.
   */
  Set<FileState> get directReferencedFiles => _directReferencedFiles;

  /**
   * Return `true` if the file exists.
   */
  bool get exists => _exists;

  /**
   * The list of files this file exports.
   */
  List<FileState> get exportedFiles => _exportedFiles;

  /**
   * Return [TopLevelDeclaration]s exported from the this library file. The
   * keys to the map are names of declarations.
   */
  Map<String, TopLevelDeclaration> get exportedTopLevelDeclarations {
    if (_exportedTopLevelDeclarations == null) {
      _exportedTopLevelDeclarations = <String, TopLevelDeclaration>{};

      Set<FileState> seenLibraries = new Set<FileState>();

      /**
       * Compute [TopLevelDeclaration]s exported from the [library].
       */
      Map<String, TopLevelDeclaration> computeExported(FileState library) {
        var declarations = <String, TopLevelDeclaration>{};
        if (seenLibraries.add(library)) {
          // Append the exported declarations.
          for (int i = 0; i < library._exportedFiles.length; i++) {
            Map<String, TopLevelDeclaration> exported =
                computeExported(library._exportedFiles[i]);
            for (TopLevelDeclaration t in exported.values) {
              if (library._exportFilters[i].accepts(t.name)) {
                declarations[t.name] = t;
              }
            }
          }

          // Append the library declarations.
          declarations.addAll(library.topLevelDeclarations);
          for (FileState part in library.partedFiles) {
            declarations.addAll(part.topLevelDeclarations);
          }

          // We're done with this library.
          seenLibraries.remove(library);
        }

        return declarations;
      }

      _exportedTopLevelDeclarations = computeExported(this);
    }
    return _exportedTopLevelDeclarations;
  }

  @override
  int get hashCode => uri.hashCode;

  /**
   * The list of files this file imports.
   */
  List<FileState> get importedFiles => _importedFiles;

  /**
   * Return `true` if the file does not have a `library` directive, and has a
   * `part of` directive, so is probably a part.
   */
  bool get isPart => _unlinked.libraryNameOffset == 0 && _unlinked.isPartOf;

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
   * The names which are used in `extends`, `with` or `implements` clauses in
   * the file. Import prefixes and type arguments are not included.
   */
  Set<String> get subtypedNames => _subtypedNames;

  @visibleForTesting
  FileStateTestView get test => new FileStateTestView(this);

  /**
   * Return public top-level declarations declared in the file. The keys to the
   * map are names of declarations.
   */
  Map<String, TopLevelDeclaration> get topLevelDeclarations {
    if (_topLevelDeclarations == null) {
      _topLevelDeclarations = <String, TopLevelDeclaration>{};

      void addDeclaration(TopLevelDeclarationKind kind, String name) {
        if (!name.startsWith('_')) {
          _topLevelDeclarations[name] = new TopLevelDeclaration(kind, name);
        }
      }

      // Add types.
      for (UnlinkedClass type in unlinked.classes) {
        addDeclaration(TopLevelDeclarationKind.type, type.name);
      }
      for (UnlinkedEnum type in unlinked.enums) {
        addDeclaration(TopLevelDeclarationKind.type, type.name);
      }
      for (UnlinkedTypedef type in unlinked.typedefs) {
        addDeclaration(TopLevelDeclarationKind.type, type.name);
      }
      // Add functions and variables.
      Set<String> addedVariableNames = new Set<String>();
      for (UnlinkedExecutable executable in unlinked.executables) {
        String name = executable.name;
        if (executable.kind == UnlinkedExecutableKind.functionOrMethod) {
          addDeclaration(TopLevelDeclarationKind.function, name);
        } else if (executable.kind == UnlinkedExecutableKind.getter ||
            executable.kind == UnlinkedExecutableKind.setter) {
          if (executable.kind == UnlinkedExecutableKind.setter) {
            name = name.substring(0, name.length - 1);
          }
          if (addedVariableNames.add(name)) {
            addDeclaration(TopLevelDeclarationKind.variable, name);
          }
        }
      }
      for (UnlinkedVariable variable in unlinked.variables) {
        String name = variable.name;
        if (addedVariableNames.add(name)) {
          addDeclaration(TopLevelDeclarationKind.variable, name);
        }
      }
    }
    return _topLevelDeclarations;
  }

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
   *
   * If an exception happens during parsing, an empty unit is returned.
   */
  CompilationUnit parse(AnalysisErrorListener errorListener) {
    try {
      return PerformanceStatistics.parse.makeCurrentWhile(() {
        return _parse(errorListener);
      });
    } catch (exception, stackTrace) {
      if (_fsState.parseExceptionHandler != null) {
        _fsState.parseExceptionHandler(this, exception, stackTrace);
      }
      return _createEmptyCompilationUnit();
    }
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
      _exists = true;
    } catch (_) {
      _content = '';
      _exists = false;
    }

    // Compute the content hash.
    List<int> contentBytes = UTF8.encode(_content);
    {
      List<int> hashBytes = md5.convert(contentBytes).bytes;
      _contentHash = hex.encode(hashBytes);
    }

    // Prepare the unlinked bundle key.
    {
      ApiSignature signature = new ApiSignature();
      signature.addUint32List(_fsState._salt);
      signature.addInt(contentBytes.length);
      signature.addString(_contentHash);
      _unlinkedKey = '${signature.toHex()}.unlinked';
    }

    // Prepare bytes of the unlinked bundle - existing or new.
    List<int> bytes;
    {
      bytes = _fsState._byteStore.get(_unlinkedKey);
      if (bytes == null || bytes.isEmpty) {
        CompilationUnit unit = parse(AnalysisErrorListener.NULL_LISTENER);
        _fsState._logger.run('Create unlinked for $path', () {
          UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
          DefinedNames definedNames = computeDefinedNames(unit);
          List<String> referencedNames = computeReferencedNames(unit).toList();
          List<String> subtypedNames = computeSubtypedNames(unit).toList();
          bytes = new AnalysisDriverUnlinkedUnitBuilder(
                  unit: unlinkedUnit,
                  definedTopLevelNames: definedNames.topLevelNames.toList(),
                  definedClassMemberNames:
                      definedNames.classMemberNames.toList(),
                  referencedNames: referencedNames,
                  subtypedNames: subtypedNames)
              .toBuffer();
          _fsState._byteStore.put(_unlinkedKey, bytes);
        });
      }
    }

    // Read the unlinked bundle.
    var driverUnlinkedUnit = new AnalysisDriverUnlinkedUnit.fromBuffer(bytes);
    _definedTopLevelNames = driverUnlinkedUnit.definedTopLevelNames.toSet();
    _definedClassMemberNames =
        driverUnlinkedUnit.definedClassMemberNames.toSet();
    _referencedNames = driverUnlinkedUnit.referencedNames.toSet();
    _subtypedNames = driverUnlinkedUnit.subtypedNames.toSet();
    _unlinked = driverUnlinkedUnit.unit;
    _lineInfo = new LineInfo(_unlinked.lineStarts);
    _topLevelDeclarations = null;

    // Prepare API signature.
    List<int> newApiSignature = new Uint8List.fromList(_unlinked.apiSignature);
    bool apiSignatureChanged = _apiSignature != null &&
        !_equalByteLists(_apiSignature, newApiSignature);
    _apiSignature = newApiSignature;

    // The API signature changed.
    //   Flush transitive signatures of affected files.
    //   Flush exported top-level declarations of all files.
    if (apiSignatureChanged) {
      for (FileState file in _fsState._uriToFile.values) {
        if (file._transitiveFiles != null &&
            file._transitiveFiles.contains(this)) {
          file._transitiveSignature = null;
        }
        file._exportedTopLevelDeclarations = null;
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
    _exportFilters = <NameFilter>[];
    for (UnlinkedImport import in _unlinked.imports) {
      String uri = import.isImplicit ? 'dart:core' : import.uri;
      FileState file = _fileForRelativeUri(uri);
      _importedFiles.add(file);
    }
    for (UnlinkedExportPublic export in _unlinked.publicNamespace.exports) {
      String uri = export.uri;
      FileState file = _fileForRelativeUri(uri);
      _exportedFiles.add(file);
      _exportFilters
          .add(new NameFilter.forUnlinkedCombinators(export.combinators));
    }
    for (String uri in _unlinked.publicNamespace.parts) {
      FileState file = _fileForRelativeUri(uri);
      _partedFiles.add(file);
      // TODO(scheglov) Sort for stable results?
      _fsState._partToLibraries
          .putIfAbsent(file, () => <FileState>[])
          .add(this);
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

  CompilationUnit _createEmptyCompilationUnit() {
    var token = new Token.eof(0);
    return astFactory.compilationUnit(token, null, [], [], token)
      ..lineInfo = new LineInfo(const <int>[0]);
  }

  /**
   * Return the [FileState] for the given [relativeUri], maybe "unresolved"
   * file if the URI cannot be parsed, cannot correspond any file, etc.
   */
  FileState _fileForRelativeUri(String relativeUri) {
    if (relativeUri.isEmpty) {
      return _fsState.unresolvedFile;
    }

    Uri absoluteUri;
    try {
      absoluteUri = resolveRelativeUri(uri, Uri.parse(relativeUri));
    } on FormatException {
      return _fsState.unresolvedFile;
    }

    return _fsState.getFileForUri(absoluteUri);
  }

  CompilationUnit _parse(AnalysisErrorListener errorListener) {
    if (source == null) {
      return _createEmptyCompilationUnit();
    }

    AnalysisOptions analysisOptions = _fsState._analysisOptions;
    CharSequenceReader reader = new CharSequenceReader(content);
    Scanner scanner = new Scanner(source, reader, errorListener);
    scanner.scanGenericMethodComments = analysisOptions.strongMode;
    Token token = PerformanceStatistics.scan.makeCurrentWhile(() {
      return scanner.tokenize();
    });
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);

    bool useFasta = analysisOptions.useFastaParser;
    Parser parser = new Parser(source, errorListener, useFasta: useFasta);
    parser.enableOptionalNewAndConst = analysisOptions.previewDart2;
    parser.parseGenericMethodComments = analysisOptions.strongMode;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;

    // StringToken uses a static instance of StringCanonicalizer, so we need
    // to clear it explicitly once we are done using it for this file.
    StringToken.canonicalizer.clear();

    return unit;
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
}

@visibleForTesting
class FileStateTestView {
  final FileState file;

  FileStateTestView(this.file);

  String get unlinkedKey => file._unlinkedKey;
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

  /**
   * The optional store with externally provided unlinked and corresponding
   * linked summaries. These summaries are always added to the store for any
   * file analysis.
   *
   * While walking the file graph, when we reach a file that exists in the
   * external store, we add a stub [FileState], but don't attempt to read its
   * content, or its unlinked unit, or imported libraries, etc.
   */
  final SummaryDataStore externalSummaries;

  /**
   * The optional handler for scanning and parsing exceptions.
   *
   * We hope that these exceptions never happen, but we might need to get
   * additional information if there are exception when we are replacing
   * Analyzer's scanner and parser with implementations from FrontEnd.
   */
  final FileParseExceptionHandler parseExceptionHandler;

  /**
   * Mapping from a URI to the corresponding [FileState].
   */
  final Map<Uri, FileState> _uriToFile = {};

  /**
   * All known file paths.
   */
  final Set<String> knownFilePaths = new Set<String>();

  /**
   * Mapping from a path to the flag whether there is a URI for the path.
   */
  final Map<String, bool> _hasUriForPath = {};

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

  /**
   * The [FileState] instance that correspond to an unresolved URI.
   */
  FileState _unresolvedFile;

  FileSystemStateTestView _testView;

  FileSystemState(
      this._logger,
      this._byteStore,
      this._contentOverlay,
      this._resourceProvider,
      this._sourceFactory,
      this._analysisOptions,
      this._salt,
      {this.externalSummaries,
      this.parseExceptionHandler}) {
    _testView = new FileSystemStateTestView(this);
  }

  /**
   * Return the known files.
   */
  List<FileState> get knownFiles =>
      _pathToFiles.values.map((files) => files.first).toList();

  @visibleForTesting
  FileSystemStateTestView get test => _testView;

  /**
   * Return the [FileState] instance that correspond to an unresolved URI.
   */
  FileState get unresolvedFile {
    if (_unresolvedFile == null) {
      _unresolvedFile = new FileState._(this, null, null, null, null);
      _unresolvedFile.refresh();
    }
    return _unresolvedFile;
  }

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
      Uri fileUri = _resourceProvider.pathContext.toUri(path);
      FileSource uriSource = new FileSource(resource, uri);
      file = new FileState._(this, path, uri, fileUri, uriSource);
      _uriToFile[uri] = file;
      _addFileWithPath(path, file);
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
      // If the external store has this URI, create a stub file for it.
      // We are given all required unlinked and linked summaries for it.
      if (externalSummaries != null) {
        String uriStr = uri.toString();
        if (externalSummaries.hasLinkedLibrary(uriStr)) {
          file = new FileState._external(this, uri);
          _uriToFile[uri] = file;
          return file;
        }
      }

      Source uriSource = _sourceFactory.resolveUri(null, uri.toString());

      // If the URI cannot be resolved, for example because the factory
      // does not understand the scheme, return the unresolved file instance.
      if (uriSource == null) {
        _uriToFile[uri] = unresolvedFile;
        return unresolvedFile;
      }

      String path = uriSource.fullName;
      File resource = _resourceProvider.getFile(path);
      Uri fileUri = _resourceProvider.pathContext.toUri(path);
      FileSource source = new FileSource(resource, uri);
      file = new FileState._(this, path, uri, fileUri, source);
      _uriToFile[uri] = file;
      _addFileWithPath(path, file);
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

  /**
   * Return `true` if there is a URI that can be resolved to the [path].
   *
   * When a file exists, but for the URI that corresponds to the file is
   * resolved to another file, e.g. a generated one in Bazel, Gn, etc, we
   * cannot analyze the original file.
   */
  bool hasUri(String path) {
    bool flag = _hasUriForPath[path];
    if (flag == null) {
      File resource = _resourceProvider.getFile(path);
      Source fileSource = resource.createSource();
      Uri uri = _sourceFactory.restoreUri(fileSource);
      Source uriSource = _sourceFactory.forUri2(uri);
      flag = uriSource.fullName == path;
      _hasUriForPath[path] = flag;
    }
    return flag;
  }

  /**
   * Remove the file with the given [path].
   */
  void removeFile(String path) {
    _uriToFile.clear();
    knownFilePaths.clear();
    _pathToFiles.clear();
    _pathToCanonicalFile.clear();
    _partToLibraries.clear();
  }

  void _addFileWithPath(String path, FileState file) {
    var files = _pathToFiles[path];
    if (files == null) {
      knownFilePaths.add(path);
      files = <FileState>[];
      _pathToFiles[path] = files;
    }
    files.add(file);
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
