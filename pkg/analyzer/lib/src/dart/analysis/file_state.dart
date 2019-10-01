// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/defined_names.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/referenced_names.dart';
import 'package:analyzer/src/dart/analysis/unlinked_api_signature.dart';
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
import 'package:analyzer/src/summary/name_filter.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:front_end/src/fasta/scanner/token.dart';
import 'package:meta/meta.dart';

var counterFileStateRefresh = 0;
var counterUnlinkedLinkedBytes = 0;
var timerFileStateRefresh = Stopwatch();

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
  Set<String> _definedClassMemberNames;
  Set<String> _definedTopLevelNames;
  Set<String> _referencedNames;
  String _unlinkedKey;
  AnalysisDriverUnlinkedUnit _driverUnlinkedUnit;
  UnlinkedUnit _unlinked;
  List<int> _apiSignature;

  UnlinkedUnit2 _unlinked2;

  List<FileState> _importedFiles;
  List<FileState> _exportedFiles;
  List<FileState> _partedFiles;
  List<FileState> _libraryFiles;
  List<NameFilter> _exportFilters;

  Set<FileState> _directReferencedFiles;
  Set<FileState> _directReferencedLibraries;

  LibraryCycle _libraryCycle;
  String _transitiveSignature;
  String _transitiveSignatureLinked;

  /**
   * The flag that shows whether the file has an error or warning that
   * might be fixed by a change to another file.
   */
  bool hasErrorOrWarning = false;

  FileState._(this._fsState, this.path, this.uri, this.source)
      : isInExternalSummaries = false;

  FileState._external(this._fsState, this.uri)
      : isInExternalSummaries = true,
        path = null,
        source = null,
        _exists = true {
    _apiSignature = new Uint8List(16);
    _libraryCycle = new LibraryCycle.external();
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
  Set<String> get definedClassMemberNames {
    return _definedClassMemberNames ??=
        _driverUnlinkedUnit.definedClassMemberNames.toSet();
  }

  /**
   * The top-level names defined by the file.
   */
  Set<String> get definedTopLevelNames {
    return _definedTopLevelNames ??=
        _driverUnlinkedUnit.definedTopLevelNames.toSet();
  }

  /**
   * Return the set of all directly referenced files - imported, exported or
   * parted.
   */
  Set<FileState> get directReferencedFiles => _directReferencedFiles;

  /**
   * Return the set of all directly referenced libraries - imported or exported.
   */
  Set<FileState> get directReferencedLibraries => _directReferencedLibraries;

  /**
   * Return `true` if the file exists.
   */
  bool get exists => _exists;

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

  LibraryCycle get internal_libraryCycle => _libraryCycle;

  /**
   * Return `true` if the file is a stub created for a library in the provided
   * external summary store.
   */
  bool get isExternalLibrary {
    return _fsState.externalSummaries != null &&
        _fsState.externalSummaries.hasLinkedLibrary(uriStr);
  }

  /**
   * Return `true` if the file does not have a `library` directive, and has a
   * `part of` directive, so is probably a part.
   */
  bool get isPart {
    if (_fsState.externalSummaries != null &&
        _fsState.externalSummaries.hasUnlinkedUnit(uriStr)) {
      return _fsState.externalSummaries.isPartUnit(uriStr);
    }
    if (_unlinked2 != null) {
      return !_unlinked2.hasLibraryDirective && _unlinked2.hasPartOfDirective;
    }
    return _unlinked.libraryNameOffset == 0 && _unlinked.isPartOf;
  }

  /**
   * Return `true` if the file is the "unresolved" file, which does not have
   * neither a valid URI, nor a path.
   */
  bool get isUnresolved => uri == null;

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

  /// Return the [LibraryCycle] this file belongs to, even if it consists of
  /// just this file.  If the library cycle is not known yet, compute it.
  LibraryCycle get libraryCycle {
    if (isPart) {
      var library = this.library;
      if (library != null) {
        return library.libraryCycle;
      }
    }

    if (_libraryCycle == null) {
      computeLibraryCycle(_fsState._linkedSalt, this);
    }

    return _libraryCycle;
  }

  /**
   * The list of files files that this library consists of, i.e. this library
   * file itself and its [partedFiles].
   */
  List<FileState> get libraryFiles => _libraryFiles;

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
  Set<String> get referencedNames {
    return _referencedNames ??= _driverUnlinkedUnit.referencedNames.toSet();
  }

  @visibleForTesting
  FileStateTestView get test => new FileStateTestView(this);

  /**
   * Return the set of transitive files - the file itself and all of the
   * directly or indirectly referenced files.
   */
  Set<FileState> get transitiveFiles {
    var transitiveFiles = new Set<FileState>();

    void appendReferenced(FileState file) {
      if (transitiveFiles.add(file)) {
        file._directReferencedFiles?.forEach(appendReferenced);
      }
    }

    appendReferenced(this);
    return transitiveFiles;
  }

  /**
   * Return the signature of the file, based on API signatures of the
   * transitive closure of imported / exported files.
   */
  String get transitiveSignature {
    this.libraryCycle; // sets _transitiveSignature
    return _transitiveSignature;
  }

  /**
   * The value `transitiveSignature.linked` is used often, so we cache it.
   */
  String get transitiveSignatureLinked {
    return _transitiveSignatureLinked ??= '$transitiveSignature.linked';
  }

  /**
   * The [UnlinkedUnit] of the file.
   */
  UnlinkedUnit get unlinked => _unlinked;

  /**
   * The [UnlinkedUnit2] of the file.
   */
  UnlinkedUnit2 get unlinked2 => _unlinked2;

  /**
   * Return the [uri] string.
   */
  String get uriStr => uri.toString();

  @override
  bool operator ==(Object other) {
    return other is FileState && other.uri == uri;
  }

  void internal_setLibraryCycle(LibraryCycle cycle, String signature) {
    if (cycle == null) {
      _libraryCycle = null;
      _transitiveSignature = null;
      _transitiveSignatureLinked = null;
    } else {
      _libraryCycle = cycle;
      _transitiveSignature = signature;
    }
  }

  /**
   * Return a new parsed unresolved [CompilationUnit].
   *
   * If an exception happens during parsing, an empty unit is returned.
   */
  CompilationUnit parse([AnalysisErrorListener errorListener]) {
    errorListener ??= AnalysisErrorListener.NULL_LISTENER;
    try {
      return PerformanceStatistics.parse.makeCurrentWhile(() {
        return _parse(errorListener);
      });
    } catch (_) {
      AnalysisOptionsImpl analysisOptions = _fsState._analysisOptions;
      return _createEmptyCompilationUnit(analysisOptions.contextFeatures);
    }
  }

  /**
   * Read the file content and ensure that all of the file properties are
   * consistent with the read content, including API signature.
   *
   * If [allowCached] is `true`, don't read the content of the file if it
   * is already cached (in another [FileSystemState], because otherwise we
   * would not create this new instance of [FileState] and refresh it).
   *
   * Return `true` if the API signature changed since the last refresh.
   */
  bool refresh({bool allowCached: false}) {
    counterFileStateRefresh++;

    var timerWasRunning = timerFileStateRefresh.isRunning;
    if (!timerWasRunning) {
      timerFileStateRefresh.start();
    }

    _invalidateCurrentUnresolvedData();

    {
      var rawFileState = _fsState._fileContentCache.get(path, allowCached);
      _content = rawFileState.content;
      _exists = rawFileState.exists;
      _contentHash = rawFileState.contentHash;
    }

    // Prepare the unlinked bundle key.
    List<int> contentSignature;
    {
      var signature = new ApiSignature();
      signature.addUint32List(_fsState._unlinkedSalt);
      signature.addString(_contentHash);
      signature.addBool(_exists);
      contentSignature = signature.toByteList();
      _unlinkedKey = '${hex.encode(contentSignature)}.unlinked2';
    }

    // Prepare bytes of the unlinked bundle - existing or new.
    List<int> bytes;
    {
      bytes = _fsState._byteStore.get(_unlinkedKey);
      if (bytes == null || bytes.isEmpty) {
        CompilationUnit unit = parse();
        _fsState._logger.run('Create unlinked for $path', () {
          var unlinkedUnit = serializeAstUnlinked2(unit);
          var definedNames = computeDefinedNames(unit);
          var referencedNames = computeReferencedNames(unit).toList();
          var subtypedNames = computeSubtypedNames(unit).toList();
          bytes = new AnalysisDriverUnlinkedUnitBuilder(
            unit2: unlinkedUnit,
            definedTopLevelNames: definedNames.topLevelNames.toList(),
            definedClassMemberNames: definedNames.classMemberNames.toList(),
            referencedNames: referencedNames,
            subtypedNames: subtypedNames,
          ).toBuffer();
          _fsState._byteStore.put(_unlinkedKey, bytes);
        });
      }
    }

    // Read the unlinked bundle.
    _driverUnlinkedUnit = new AnalysisDriverUnlinkedUnit.fromBuffer(bytes);
    _unlinked2 = _driverUnlinkedUnit.unit2;
    _lineInfo = new LineInfo(_unlinked2.lineStarts);

    // Prepare API signature.
    var newApiSignature = new Uint8List.fromList(_unlinked2.apiSignature);
    bool apiSignatureChanged = _apiSignature != null &&
        !_equalByteLists(_apiSignature, newApiSignature);
    _apiSignature = newApiSignature;

    // The API signature changed.
    //   Flush affected library cycles.
    //   Flush exported top-level declarations of all files.
    if (apiSignatureChanged) {
      _libraryCycle?.invalidate();

      // If this is a part, invalidate the libraries.
      var libraries = _fsState._partToLibraries[this];
      if (libraries != null) {
        for (var library in libraries) {
          library.libraryCycle?.invalidate();
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
    _exportFilters = <NameFilter>[];
    for (var uri in _unlinked2.imports) {
      var file = _fileForRelativeUri(uri);
      _importedFiles.add(file);
    }
    for (var uri in _unlinked2.exports) {
      var file = _fileForRelativeUri(uri);
      _exportedFiles.add(file);
      // TODO(scheglov) implement
      _exportFilters.add(NameFilter.identity);
    }
    for (var uri in _unlinked2.parts) {
      var file = _fileForRelativeUri(uri);
      _partedFiles.add(file);
      _fsState._partToLibraries
          .putIfAbsent(file, () => <FileState>[])
          .add(this);
    }
    _libraryFiles = [this]..addAll(_partedFiles);

    // Compute referenced files.
    _directReferencedFiles = new Set<FileState>()
      ..addAll(_importedFiles)
      ..addAll(_exportedFiles)
      ..addAll(_partedFiles);
    _directReferencedLibraries = Set<FileState>()
      ..addAll(_importedFiles)
      ..addAll(_exportedFiles);

    // Update mapping from subtyped names to files.
    for (var name in _driverUnlinkedUnit.subtypedNames) {
      var files = _fsState._subtypedNameToFiles[name];
      if (files == null) {
        files = new Set<FileState>();
        _fsState._subtypedNameToFiles[name] = files;
      }
      files.add(this);
    }

    if (!timerWasRunning) {
      timerFileStateRefresh.stop();
    }

    // Return whether the API signature changed.
    return apiSignatureChanged;
  }

  @override
  String toString() => path ?? '<unresolved>';

  CompilationUnit _createEmptyCompilationUnit(FeatureSet featureSet) {
    var token = new Token.eof(0);
    return astFactory.compilationUnit(
        beginToken: token, endToken: token, featureSet: featureSet)
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

  /**
   * Invalidate any data that depends on the current unlinked data of the file,
   * because [refresh] is going to recompute the unlinked data.
   */
  void _invalidateCurrentUnresolvedData() {
    // Invalidate unlinked information.
    _definedTopLevelNames = null;
    _definedClassMemberNames = null;
    _referencedNames = null;

    if (_driverUnlinkedUnit != null) {
      for (var name in _driverUnlinkedUnit.subtypedNames) {
        var files = _fsState._subtypedNameToFiles[name];
        files?.remove(this);
      }
    }
  }

  CompilationUnit _parse(AnalysisErrorListener errorListener) {
    AnalysisOptionsImpl analysisOptions = _fsState._analysisOptions;
    FeatureSet featureSet = analysisOptions.contextFeatures;
    if (source == null) {
      return _createEmptyCompilationUnit(featureSet);
    }

    CharSequenceReader reader = new CharSequenceReader(content);
    Scanner scanner = new Scanner(source, reader, errorListener)
      ..configureFeatures(featureSet);
    Token token = PerformanceStatistics.scan.makeCurrentWhile(() {
      return scanner.tokenize(reportScannerErrors: false);
    });
    LineInfo lineInfo = new LineInfo(scanner.lineStarts);

    bool useFasta = analysisOptions.useFastaParser;
    // Pass the feature set from the scanner to the parser
    // because the scanner may have detected a language version comment
    // and downgraded the feature set it holds.
    Parser parser = new Parser(source, errorListener,
        featureSet: scanner.featureSet, useFasta: useFasta);
    parser.enableOptionalNewAndConst = true;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;

    // StringToken uses a static instance of StringCanonicalizer, so we need
    // to clear it explicitly once we are done using it for this file.
    StringToken.canonicalizer.clear();

    return unit;
  }

  static UnlinkedUnit2Builder serializeAstUnlinked2(CompilationUnit unit) {
    var exports = <String>[];
    var imports = <String>[];
    var parts = <String>[];
    var hasDartCoreImport = false;
    var hasLibraryDirective = false;
    var hasPartOfDirective = false;
    for (var directive in unit.directives) {
      if (directive is ExportDirective) {
        var uriStr = directive.uri.stringValue;
        exports.add(uriStr ?? '');
      } else if (directive is ImportDirective) {
        var uriStr = directive.uri.stringValue;
        imports.add(uriStr ?? '');
        if (uriStr == 'dart:core') {
          hasDartCoreImport = true;
        }
      } else if (directive is LibraryDirective) {
        hasLibraryDirective = true;
      } else if (directive is PartDirective) {
        var uriStr = directive.uri.stringValue;
        parts.add(uriStr ?? '');
      } else if (directive is PartOfDirective) {
        hasPartOfDirective = true;
      }
    }
    if (!hasDartCoreImport) {
      imports.add('dart:core');
    }
    var informativeData = createInformativeData(unit);
    return UnlinkedUnit2Builder(
      apiSignature: computeUnlinkedApiSignature(unit),
      exports: exports,
      imports: imports,
      parts: parts,
      hasLibraryDirective: hasLibraryDirective,
      hasPartOfDirective: hasPartOfDirective,
      lineStarts: unit.lineInfo.lineStarts,
      informativeData: informativeData,
    );
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
  final String contextName;
  final ByteStore _byteStore;
  final FileContentOverlay _contentOverlay;
  final SourceFactory _sourceFactory;
  final AnalysisOptions _analysisOptions;
  final Uint32List _unlinkedSalt;
  final Uint32List _linkedSalt;

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
   * Mapping from a URI to the corresponding [FileState].
   */
  final Map<Uri, FileState> _uriToFile = {};

  /**
   * All known file paths.
   */
  final Set<String> knownFilePaths = new Set<String>();

  /**
   * All known files.
   */
  final List<FileState> knownFiles = [];

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
   * The map of subtyped names to files where these names are subtyped.
   */
  final Map<String, Set<FileState>> _subtypedNameToFiles = {};

  /**
   * The value of this field is incremented when the set of files is updated.
   */
  int fileStamp = 0;

  /**
   * The [FileState] instance that correspond to an unresolved URI.
   */
  FileState _unresolvedFile;

  /**
   * The cache of content of files, possibly shared with other file system
   * states with the same resource provider and the content overlay.
   */
  _FileContentCache _fileContentCache;

  FileSystemStateTestView _testView;

  FileSystemState(
    this._logger,
    this._byteStore,
    this._contentOverlay,
    this._resourceProvider,
    this.contextName,
    this._sourceFactory,
    this._analysisOptions,
    this._unlinkedSalt,
    this._linkedSalt, {
    this.externalSummaries,
  }) {
    _fileContentCache = _FileContentCache.getInstance(
      _resourceProvider,
      _contentOverlay,
    );
    _testView = new FileSystemStateTestView(this);
  }

  @visibleForTesting
  FileSystemStateTestView get test => _testView;

  /**
   * Return the [FileState] instance that correspond to an unresolved URI.
   */
  FileState get unresolvedFile {
    if (_unresolvedFile == null) {
      _unresolvedFile = new FileState._(this, null, null, null);
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
      FileSource uriSource = new FileSource(resource, uri);
      file = new FileState._(this, path, uri, uriSource);
      _uriToFile[uri] = file;
      _addFileWithPath(path, file);
      _pathToCanonicalFile[path] = file;
      file.refresh(allowCached: true);
    }
    return file;
  }

  /**
   * Return the [FileState] for the given absolute [uri]. May return the
   * "unresolved" file if the [uri] is invalid, e.g. a `package:` URI without
   * a package name. The returned file has the last known state since if was
   * last refreshed.
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
      FileSource source = new FileSource(resource, uri);
      file = new FileState._(this, path, uri, source);
      _uriToFile[uri] = file;
      _addFileWithPath(path, file);
      file.refresh(allowCached: true);
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
   * Return files where the given [name] is subtyped, i.e. used in `extends`,
   * `with` or `implements` clauses.
   */
  Set<FileState> getFilesSubtypingName(String name) {
    return _subtypedNameToFiles[name];
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
      flag = uriSource?.fullName == path;
      _hasUriForPath[path] = flag;
    }
    return flag;
  }

  /**
   * The file with the given [path] might have changed, so ensure that it is
   * read the next time it is refreshed.
   */
  void markFileForReading(String path) {
    _fileContentCache.remove(path);
  }

  /**
   * Remove the file with the given [path].
   */
  void removeFile(String path) {
    markFileForReading(path);
    _clearFiles();
  }

  /**
   * Reset URI resolution, and forget all files. So, the next time any file is
   * requested, it will be read, and its whole (potentially different) graph
   * will be built.
   */
  void resetUriResolution() {
    _sourceFactory.clearCache();
    _fileContentCache.clear();
    _clearFiles();
  }

  void _addFileWithPath(String path, FileState file) {
    var files = _pathToFiles[path];
    if (files == null) {
      knownFilePaths.add(path);
      knownFiles.add(file);
      files = <FileState>[];
      _pathToFiles[path] = files;
      fileStamp++;
    }
    files.add(file);
  }

  /// Clear all [FileState] data - all maps from path or URI, etc.
  void _clearFiles() {
    _uriToFile.clear();
    knownFilePaths.clear();
    knownFiles.clear();
    _pathToFiles.clear();
    _pathToCanonicalFile.clear();
    _partToLibraries.clear();
    _subtypedNameToFiles.clear();
  }
}

@visibleForTesting
class FileSystemStateTestView {
  final FileSystemState state;

  FileSystemStateTestView(this.state);

  Set<FileState> get filesWithoutLibraryCycle {
    return state._uriToFile.values
        .where((f) => f._libraryCycle == null)
        .toSet();
  }
}

/**
 * Information about the content of a file.
 */
class _FileContent {
  final String path;
  final bool exists;
  final String content;
  final String contentHash;

  _FileContent(this.path, this.exists, this.content, this.contentHash);
}

/**
 * The cache of information about content of files.
 */
class _FileContentCache {
  /**
   * Weak map of cache instances.
   *
   * Outer key is a [FileContentOverlay].
   * Inner key is a [ResourceProvider].
   */
  static final _instances = new Expando<Expando<_FileContentCache>>();

  /**
   * Weak map of cache instances.
   *
   * Key is a [ResourceProvider].
   */
  static final _instances2 = new Expando<_FileContentCache>();

  final ResourceProvider _resourceProvider;
  final FileContentOverlay _contentOverlay;
  final Map<String, _FileContent> _pathToFile = {};

  _FileContentCache(this._resourceProvider, this._contentOverlay);

  void clear() {
    _pathToFile.clear();
  }

  /**
   * Return the content of the file with the given [path].
   *
   * If [allowCached] is `true`, and the file is in the cache, return the
   * cached data. Otherwise read the file, compute and cache the data.
   */
  _FileContent get(String path, bool allowCached) {
    var file = allowCached ? _pathToFile[path] : null;
    if (file == null) {
      String content;
      bool exists;
      try {
        if (_contentOverlay != null) {
          content = _contentOverlay[path];
        }
        content ??= _resourceProvider.getFile(path).readAsStringSync();
        exists = true;
      } catch (_) {
        content = '';
        exists = false;
      }

      List<int> contentBytes = utf8.encode(content);

      List<int> contentHashBytes = md5.convert(contentBytes).bytes;
      String contentHash = hex.encode(contentHashBytes);

      file = new _FileContent(path, exists, content, contentHash);
      _pathToFile[path] = file;
    }
    return file;
  }

  /**
   * Remove the file with the given [path] from the cache.
   */
  void remove(String path) {
    _pathToFile.remove(path);
  }

  static _FileContentCache getInstance(
      ResourceProvider resourceProvider, FileContentOverlay contentOverlay) {
    Expando<_FileContentCache> providerToInstance;
    if (contentOverlay != null) {
      providerToInstance = _instances[contentOverlay];
      if (providerToInstance == null) {
        providerToInstance = new Expando<_FileContentCache>();
        _instances[contentOverlay] = providerToInstance;
      }
    } else {
      providerToInstance = _instances2;
    }

    var instance = providerToInstance[resourceProvider];
    if (instance == null) {
      instance = new _FileContentCache(resourceProvider, contentOverlay);
      providerToInstance[resourceProvider] = instance;
    }
    return instance;
  }
}
