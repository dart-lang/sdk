// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart'
    show StringToken;
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/defined_names.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/referenced_names.dart';
import 'package:analyzer/src/dart/analysis/unlinked_api_signature.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/util/either.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

var counterFileStateRefresh = 0;
var counterUnlinkedBytes = 0;
var counterUnlinkedLinkedBytes = 0;
var timerFileStateRefresh = Stopwatch();

/// A library from [SummaryDataStore].
class ExternalLibrary {
  final Uri uri;

  ExternalLibrary(this.uri);
}

/// [FileContentOverlay] is used to temporary override content of files.
class FileContentOverlay {
  final _map = <String, String>{};

  /// Return the paths currently being overridden.
  Iterable<String> get paths => _map.keys;

  /// Return the content of the file with the given [path], or `null` the
  /// overlay does not override the content of the file.
  ///
  /// The [path] must be absolute and normalized.
  String? operator [](String path) => _map[path];

  /// Return the new [content] of the file with the given [path].
  ///
  /// The [path] must be absolute and normalized.
  void operator []=(String path, String? content) {
    if (content == null) {
      _map.remove(path);
    } else {
      _map[path] = content;
    }
  }
}

/// Information about a file being analyzed, explicitly or implicitly.
///
/// It provides a consistent view on its properties.
///
/// The properties are not guaranteed to represent the most recent state
/// of the file system. To update the file to the most recent state, [refresh]
/// should be called.
class FileState {
  final FileSystemState _fsState;

  /// The absolute path of the file.
  final String path;

  /// The absolute URI of the file.
  final Uri uri;

  /// The [Source] of the file with the [uri].
  final Source source;

  /// The [WorkspacePackage] that contains this file.
  ///
  /// It might be `null` if the file is outside of the workspace.
  final WorkspacePackage? workspacePackage;

  /// The [FeatureSet] for all files in the analysis context.
  ///
  /// Usually it is the feature set of the latest language version, plus
  /// possibly additional enabled experiments (from the analysis options file,
  /// or from SDK allowed experiments).
  ///
  /// This feature set is then restricted, with the [packageLanguageVersion],
  /// or with a `@dart` language override token in the file header.
  final FeatureSet _contextFeatureSet;

  /// The language version for the package that contains this file.
  final Version packageLanguageVersion;

  bool? _exists;
  String? _content;
  String? _contentHash;
  LineInfo? _lineInfo;
  Set<String>? _definedClassMemberNames;
  Set<String>? _definedTopLevelNames;
  Set<String>? _referencedNames;
  List<int>? _unlinkedSignature;
  String? _unlinkedKey;
  String? _informativeKey;
  AnalysisDriverUnlinkedUnit? _driverUnlinkedUnit;
  List<int>? _apiSignature;

  UnlinkedUnit2? _unlinked2;

  List<FileState?>? _importedFiles;
  List<FileState?>? _exportedFiles;
  List<FileState?>? _partedFiles;
  List<FileState>? _libraryFiles;

  Set<FileState>? _directReferencedFiles;
  Set<FileState>? _directReferencedLibraries;

  LibraryCycle? _libraryCycle;
  String? _transitiveSignature;
  String? _transitiveSignatureLinked;

  /// The flag that shows whether the file has an error or warning that
  /// might be fixed by a change to another file.
  bool hasErrorOrWarning = false;

  FileState._(
    this._fsState,
    this.path,
    this.uri,
    this.source,
    this.workspacePackage,
    this._contextFeatureSet,
    this.packageLanguageVersion,
  );

  /// The unlinked API signature of the file.
  List<int> get apiSignature => _apiSignature!;

  /// The content of the file.
  String get content => _content!;

  /// The MD5 hash of the [content].
  String get contentHash => _contentHash!;

  /// The class member names defined by the file.
  Set<String> get definedClassMemberNames {
    return _definedClassMemberNames ??=
        _driverUnlinkedUnit!.definedClassMemberNames.toSet();
  }

  /// The top-level names defined by the file.
  Set<String> get definedTopLevelNames {
    return _definedTopLevelNames ??=
        _driverUnlinkedUnit!.definedTopLevelNames.toSet();
  }

  /// Return the set of all directly referenced files - imported, exported or
  /// parted.
  Set<FileState> get directReferencedFiles {
    return _directReferencedFiles ??= <FileState>{
      ...importedFiles.whereNotNull(),
      ...exportedFiles.whereNotNull(),
      ...partedFiles.whereNotNull(),
    };
  }

  /// Return the set of all directly referenced libraries - imported or
  /// exported.
  Set<FileState> get directReferencedLibraries {
    return _directReferencedLibraries ??= <FileState>{
      ...importedFiles.whereNotNull(),
      ...exportedFiles.whereNotNull(),
    };
  }

  /// Return `true` if the file exists.
  bool get exists => _exists!;

  /// The list of files this file exports.
  List<FileState?> get exportedFiles {
    if (_exportedFiles == null) {
      _exportedFiles = <FileState?>[];
      for (var directive in _unlinked2!.exports) {
        var uri = _selectRelativeUri(directive);
        _fileForRelativeUri(uri).map(
          (file) {
            _exportedFiles!.add(file);
          },
          (_) {},
        );
      }
    }
    return _exportedFiles!;
  }

  @override
  int get hashCode => uri.hashCode;

  /// The list of files this file imports.
  List<FileState?> get importedFiles {
    if (_importedFiles == null) {
      _importedFiles = <FileState?>[];
      for (var directive in _unlinked2!.imports) {
        var uri = _selectRelativeUri(directive);
        _fileForRelativeUri(uri).map(
          (file) {
            _importedFiles!.add(file);
          },
          (_) {},
        );
      }
    }
    return _importedFiles!;
  }

  LibraryCycle? get internal_libraryCycle => _libraryCycle;

  /// Return `true` if the file is a stub created for a library in the provided
  /// external summary store.
  bool get isExternalLibrary {
    return _fsState.externalSummaries != null &&
        _fsState.externalSummaries!.hasLinkedLibrary(uriStr);
  }

  /// Return `true` if the file does not have a `library` directive, and has a
  /// `part of` directive, so is probably a part.
  bool get isPart {
    if (_fsState.externalSummaries != null &&
        _fsState.externalSummaries!.hasUnlinkedUnit(uriStr)) {
      return _fsState.externalSummaries!.isPartUnit(uriStr);
    }
    return !_unlinked2!.hasLibraryDirective && _unlinked2!.hasPartOfDirective;
  }

  /// If the file [isPart], return a currently know library the file is a part
  /// of. Return `null` if a library is not known, for example because we have
  /// not processed a library file yet.
  FileState? get library {
    _fsState.readPartsForLibraries();
    List<FileState>? libraries = _fsState._partToLibraries[this];
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
      final library = this.library;
      if (library != null && !identical(library, this)) {
        return library.libraryCycle;
      }
    }

    if (_libraryCycle == null) {
      computeLibraryCycle(_fsState._saltForElements, this);
    }

    return _libraryCycle!;
  }

  /// The list of files files that this library consists of, i.e. this library
  /// file itself and its [partedFiles].
  List<FileState> get libraryFiles {
    return _libraryFiles ??= [
      this,
      ...partedFiles.whereNotNull(),
    ];
  }

  /// Return information about line in the file.
  LineInfo get lineInfo => _lineInfo!;

  /// The list of files this library file references as parts.
  List<FileState?> get partedFiles {
    if (_partedFiles == null) {
      _partedFiles = <FileState?>[];
      for (var uri in _unlinked2!.parts) {
        _fileForRelativeUri(uri).map(
          (file) {
            _partedFiles!.add(file);
            if (file != null) {
              _fsState._partToLibraries
                  .putIfAbsent(file, () => <FileState>[])
                  .add(this);
            }
          },
          (_) {},
        );
      }
    }
    return _partedFiles!;
  }

  /// The external names referenced by the file.
  Set<String> get referencedNames {
    return _referencedNames ??= _driverUnlinkedUnit!.referencedNames.toSet();
  }

  @visibleForTesting
  FileStateTestView get test => FileStateTestView(this);

  /// Return the set of transitive files - the file itself and all of the
  /// directly or indirectly referenced files.
  Set<FileState> get transitiveFiles {
    var transitiveFiles = <FileState>{};

    void appendReferenced(FileState file) {
      if (transitiveFiles.add(file)) {
        file.directReferencedFiles.forEach(appendReferenced);
      }
    }

    appendReferenced(this);
    return transitiveFiles;
  }

  /// Return the signature of the file, based on API signatures of the
  /// transitive closure of imported / exported files.
  String get transitiveSignature {
    libraryCycle; // sets _transitiveSignature
    _transitiveSignature ??= _invalidTransitiveSignature;
    return _transitiveSignature!;
  }

  /// The value `transitiveSignature.linked` is used often, so we cache it.
  String get transitiveSignatureLinked {
    return _transitiveSignatureLinked ??= '$transitiveSignature.linked';
  }

  /// The [UnlinkedUnit2] of the file.
  UnlinkedUnit2 get unlinked2 => _unlinked2!;

  /// The MD5 signature based on the content, feature sets, language version.
  List<int> get unlinkedSignature => _unlinkedSignature!;

  /// Return the [uri] string.
  String get uriStr => uri.toString();

  String get _invalidTransitiveSignature {
    return (ApiSignature()
          ..addString(path)
          ..addBytes(unlinkedSignature))
        .toHex();
  }

  @override
  bool operator ==(Object other) {
    return other is FileState && other.uri == uri;
  }

  Uint8List getInformativeBytes({CompilationUnit? unit}) {
    var bytes = _fsState._byteStore.get(_informativeKey!) as Uint8List?;
    if (bytes == null) {
      unit ??= parse();
      bytes = writeUnitInformative(unit);
      _fsState._byteStore.put(_informativeKey!, bytes);
    }
    return bytes;
  }

  void internal_setLibraryCycle(LibraryCycle? cycle, String? signature) {
    if (cycle == null) {
      _libraryCycle = null;
      _transitiveSignature = null;
      _transitiveSignatureLinked = null;
    } else {
      _libraryCycle = cycle;
      _transitiveSignature = signature;
    }
  }

  /// Return a new parsed unresolved [CompilationUnit].
  CompilationUnitImpl parse([AnalysisErrorListener? errorListener]) {
    errorListener ??= AnalysisErrorListener.NULL_LISTENER;
    try {
      return _parse(errorListener);
    } catch (exception, stackTrace) {
      throw CaughtExceptionWithFiles(
        exception,
        stackTrace,
        {path: content},
      );
    }
  }

  /// Read the file content and ensure that all of the file properties are
  /// consistent with the read content, including API signature.
  ///
  /// Return `true` if the API signature changed since the last refresh.
  bool refresh() {
    counterFileStateRefresh++;

    var timerWasRunning = timerFileStateRefresh.isRunning;
    if (!timerWasRunning) {
      timerFileStateRefresh.start();
    }

    _invalidateCurrentUnresolvedData();

    {
      var rawFileState = _fsState._fileContentCache.get(path);
      _content = rawFileState.content;
      _exists = rawFileState.exists;
      _contentHash = rawFileState.contentHash;
    }

    // Prepare the unlinked bundle key.
    {
      var signature = ApiSignature();
      signature.addUint32List(_fsState._saltForUnlinked);
      signature.addFeatureSet(_contextFeatureSet);
      signature.addLanguageVersion(packageLanguageVersion);
      signature.addString(_contentHash!);
      signature.addBool(_exists!);
      _unlinkedSignature = signature.toByteList();
      var signatureHex = hex.encode(_unlinkedSignature!);
      _unlinkedKey = '$signatureHex.unlinked2';
      // TODO(scheglov) Use the path as the key, and store the signature.
      _informativeKey = '$signatureHex.ast';
    }

    // Prepare bytes of the unlinked bundle - existing or new.
    var bytes = _getUnlinkedBytes();

    // Read the unlinked bundle.
    _driverUnlinkedUnit = AnalysisDriverUnlinkedUnit.fromBuffer(bytes);
    _unlinked2 = _driverUnlinkedUnit!.unit2;
    _lineInfo = LineInfo(_unlinked2!.lineStarts);

    // Prepare API signature.
    var newApiSignature = Uint8List.fromList(_unlinked2!.apiSignature);
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
          library.libraryCycle.invalidate();
        }
      }
    }

    // This file is potentially not a library for its previous parts anymore.
    if (_partedFiles != null) {
      for (var part in _partedFiles!) {
        _fsState._partToLibraries[part]?.remove(this);
      }
    }

    // Read imports/exports on demand.
    _importedFiles = null;
    _exportedFiles = null;
    _directReferencedFiles = null;
    _directReferencedLibraries = null;

    // Read parts on demand.
    _fsState._librariesWithoutPartsRead.add(this);
    _partedFiles = null;
    _libraryFiles = null;

    // Update mapping from subtyped names to files.
    for (var name in _driverUnlinkedUnit!.subtypedNames) {
      var files = _fsState._subtypedNameToFiles[name];
      if (files == null) {
        files = <FileState>{};
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
  String toString() {
    return '$uri = $path';
  }

  /// Return the [FileState] for the given [relativeUri], or `null` if the
  /// URI cannot be parsed, cannot correspond any file, etc.
  Either2<FileState?, ExternalLibrary> _fileForRelativeUri(
    String relativeUri,
  ) {
    if (relativeUri.isEmpty) {
      return Either2.t1(null);
    }

    Uri absoluteUri;
    try {
      absoluteUri = resolveRelativeUri(uri, Uri.parse(relativeUri));
    } on FormatException {
      return Either2.t1(null);
    }

    return _fsState.getFileForUri(absoluteUri);
  }

  /// Return the bytes of the unlinked summary - existing or new.
  List<int> _getUnlinkedBytes() {
    var bytes = _fsState._byteStore.get(_unlinkedKey!);
    if (bytes != null && bytes.isNotEmpty) {
      return bytes;
    }

    var unit = parse();
    return _fsState._logger.run('Create unlinked for $path', () {
      var unlinkedUnit = serializeAstUnlinked2(unit);
      var definedNames = computeDefinedNames(unit);
      var referencedNames = computeReferencedNames(unit).toList();
      var subtypedNames = computeSubtypedNames(unit).toList();
      var bytes = AnalysisDriverUnlinkedUnitBuilder(
        unit2: unlinkedUnit,
        definedTopLevelNames: definedNames.topLevelNames.toList(),
        definedClassMemberNames: definedNames.classMemberNames.toList(),
        referencedNames: referencedNames,
        subtypedNames: subtypedNames,
      ).toBuffer();
      _fsState._byteStore.put(_unlinkedKey!, bytes);
      counterUnlinkedBytes += bytes.length;
      counterUnlinkedLinkedBytes += bytes.length;
      return bytes;
    });
  }

  /// Invalidate any data that depends on the current unlinked data of the file,
  /// because [refresh] is going to recompute the unlinked data.
  void _invalidateCurrentUnresolvedData() {
    // Invalidate unlinked information.
    _definedTopLevelNames = null;
    _definedClassMemberNames = null;
    _referencedNames = null;

    if (_driverUnlinkedUnit != null) {
      for (var name in _driverUnlinkedUnit!.subtypedNames) {
        var files = _fsState._subtypedNameToFiles[name];
        files?.remove(this);
      }
    }
  }

  CompilationUnitImpl _parse(AnalysisErrorListener errorListener) {
    CharSequenceReader reader = CharSequenceReader(content);
    Scanner scanner = Scanner(source, reader, errorListener)
      ..configureFeatures(
        featureSetForOverriding: _contextFeatureSet,
        featureSet: _contextFeatureSet.restrictToVersion(
          packageLanguageVersion,
        ),
      );
    Token token = scanner.tokenize(reportScannerErrors: false);
    LineInfo lineInfo = LineInfo(scanner.lineStarts);

    Parser parser = Parser(
      source,
      errorListener,
      featureSet: scanner.featureSet,
    );
    parser.enableOptionalNewAndConst = true;

    var unit = parser.parseCompilationUnit(token);
    unit.lineInfo = lineInfo;
    unit.languageVersion = LibraryLanguageVersion(
      package: packageLanguageVersion,
      override: scanner.overrideVersion,
    );

    // StringToken uses a static instance of StringCanonicalizer, so we need
    // to clear it explicitly once we are done using it for this file.
    StringToken.canonicalizer.clear();

    return unit;
  }

  String _selectRelativeUri(UnlinkedNamespaceDirective directive) {
    for (var configuration in directive.configurations) {
      var name = configuration.name;
      var value = configuration.value;
      if (value.isEmpty) {
        value = 'true';
      }
      if (_fsState._declaredVariables.get(name) == value) {
        return configuration.uri;
      }
    }
    return directive.uri;
  }

  static UnlinkedUnit2Builder serializeAstUnlinked2(CompilationUnit unit) {
    var exports = <UnlinkedNamespaceDirectiveBuilder>[];
    var imports = <UnlinkedNamespaceDirectiveBuilder>[];
    var parts = <String>[];
    var hasDartCoreImport = false;
    var hasLibraryDirective = false;
    var hasPartOfDirective = false;
    for (var directive in unit.directives) {
      if (directive is ExportDirective) {
        var builder = _serializeNamespaceDirective(directive);
        exports.add(builder);
      } else if (directive is ImportDirective) {
        var builder = _serializeNamespaceDirective(directive);
        imports.add(builder);
        if (builder.uri == 'dart:core') {
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
      imports.add(
        UnlinkedNamespaceDirectiveBuilder(
          uri: 'dart:core',
        ),
      );
    }
    return UnlinkedUnit2Builder(
      apiSignature: computeUnlinkedApiSignature(unit),
      exports: exports,
      imports: imports,
      parts: parts,
      hasLibraryDirective: hasLibraryDirective,
      hasPartOfDirective: hasPartOfDirective,
      lineStarts: unit.lineInfo!.lineStarts,
    );
  }

  /// Return `true` if the given byte lists are equal.
  static bool _equalByteLists(List<int>? a, List<int>? b) {
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

  static UnlinkedNamespaceDirectiveBuilder _serializeNamespaceDirective(
      NamespaceDirective directive) {
    return UnlinkedNamespaceDirectiveBuilder(
      configurations: directive.configurations.map((configuration) {
        var name = configuration.name.components.join('.');
        var value = configuration.value?.stringValue ?? '';
        return UnlinkedNamespaceDirectiveConfigurationBuilder(
          name: name,
          value: value,
          uri: configuration.uri.stringValue ?? '',
        );
      }).toList(),
      uri: directive.uri.stringValue ?? '',
    );
  }
}

@visibleForTesting
class FileStateTestView {
  final FileState file;

  FileStateTestView(this.file);

  String get unlinkedKey => file._unlinkedKey!;
}

/// Information about known file system state.
class FileSystemState {
  final PerformanceLog _logger;
  final ResourceProvider _resourceProvider;
  final String contextName;
  final ByteStore _byteStore;
  final SourceFactory _sourceFactory;
  final Workspace? _workspace;
  final DeclaredVariables _declaredVariables;
  final Uint32List _saltForUnlinked;
  final Uint32List _saltForElements;

  final FeatureSetProvider featureSetProvider;

  /// The optional store with externally provided unlinked and corresponding
  /// linked summaries. These summaries are always added to the store for any
  /// file analysis.
  ///
  /// While walking the file graph, when we reach a file that exists in the
  /// external store, we add a stub [FileState], but don't attempt to read its
  /// content, or its unlinked unit, or imported libraries, etc.
  final SummaryDataStore? externalSummaries;

  /// Mapping from a URI to the corresponding [FileState].
  final Map<Uri, FileState> _uriToFile = {};

  /// All known file paths.
  final Set<String> knownFilePaths = <String>{};

  /// All known files.
  final List<FileState> knownFiles = [];

  /// Mapping from a path to the flag whether there is a URI for the path.
  final Map<String, bool> _hasUriForPath = {};

  /// Mapping from a path to the corresponding [FileState]s, canonical or not.
  final Map<String, List<FileState>> _pathToFiles = {};

  /// Mapping from a path to the corresponding canonical [FileState].
  final Map<String, FileState> _pathToCanonicalFile = {};

  /// We don't read parts until requested, but if we need to know the
  /// library for a file, we need to read parts of every file to know
  /// which libraries reference this part.
  final List<FileState> _librariesWithoutPartsRead = [];

  /// Mapping from a part to the libraries it is a part of.
  final Map<FileState, List<FileState>> _partToLibraries = {};

  /// The map of subtyped names to files where these names are subtyped.
  final Map<String, Set<FileState>> _subtypedNameToFiles = {};

  /// The value of this field is incremented when the set of files is updated.
  int fileStamp = 0;

  /// The cache of content of files, possibly shared with other file system
  /// states.
  final FileContentCache _fileContentCache;

  late final FileSystemStateTestView _testView;

  FileSystemState(
    this._logger,
    this._byteStore,
    this._resourceProvider,
    this.contextName,
    this._sourceFactory,
    this._workspace,
    @Deprecated('No longer used; will be removed')
        AnalysisOptions analysisOptions,
    this._declaredVariables,
    this._saltForUnlinked,
    this._saltForElements,
    this.featureSetProvider, {
    this.externalSummaries,
    required FileContentCache fileContentCache,
  }) : _fileContentCache = fileContentCache {
    _testView = FileSystemStateTestView(this);
  }

  @visibleForTesting
  FileSystemStateTestView get test => _testView;

  FeatureSet contextFeatureSet(
    String path,
    Uri uri,
    WorkspacePackage? workspacePackage,
  ) {
    var workspacePackageExperiments = workspacePackage?.enabledExperiments;
    if (workspacePackageExperiments != null) {
      return featureSetProvider.featureSetForExperiments(
        workspacePackageExperiments,
      );
    }

    return featureSetProvider.getFeatureSet(path, uri);
  }

  Version contextLanguageVersion(
    String path,
    Uri uri,
    WorkspacePackage? workspacePackage,
  ) {
    var workspaceLanguageVersion = workspacePackage?.languageVersion;
    if (workspaceLanguageVersion != null) {
      return workspaceLanguageVersion;
    }

    return featureSetProvider.getLanguageVersion(path, uri);
  }

  /// Return the canonical [FileState] for the given absolute [path]. The
  /// returned file has the last known state since if was last refreshed.
  ///
  /// Here "canonical" means that if the [path] is in a package `lib` then the
  /// returned file will have the `package:` style URI.
  FileState getFileForPath(String path) {
    FileState? file = _pathToCanonicalFile[path];
    if (file == null) {
      File resource = _resourceProvider.getFile(path);
      Source fileSource = resource.createSource();
      Uri? uri = _sourceFactory.restoreUri(fileSource);
      // Try to get the existing instance.
      file = _uriToFile[uri];
      // If we have a file, call it the canonical one and return it.
      if (file != null) {
        _pathToCanonicalFile[path] = file;
        return file;
      }
      // Create a new file.
      FileSource uriSource = FileSource(resource, uri!);
      WorkspacePackage? workspacePackage = _workspace?.findPackageFor(path);
      FeatureSet featureSet = contextFeatureSet(path, uri, workspacePackage);
      Version packageLanguageVersion =
          contextLanguageVersion(path, uri, workspacePackage);
      file = FileState._(this, path, uri, uriSource, workspacePackage,
          featureSet, packageLanguageVersion);
      _uriToFile[uri] = file;
      _addFileWithPath(path, file);
      _pathToCanonicalFile[path] = file;
      file.refresh();
    }
    return file;
  }

  /// The given [uri] must be absolute.
  ///
  /// If [uri] corresponds to a library from the summary store, return a
  /// [ExternalLibrary].
  ///
  /// Otherwise the [uri] is resolved to a file, and the corresponding
  /// [FileState] is returned. Might be `null` if the [uri] cannot be resolved
  /// to a file, for example because it is invalid (e.g. a `package:` URI
  /// without a package name), or we don't know this package. The returned
  /// file has the last known state since if was last refreshed.
  Either2<FileState?, ExternalLibrary> getFileForUri(Uri uri) {
    // If the external store has this URI, create a stub file for it.
    // We are given all required unlinked and linked summaries for it.
    if (externalSummaries != null) {
      String uriStr = uri.toString();
      if (externalSummaries!.hasLinkedLibrary(uriStr)) {
        return Either2.t2(ExternalLibrary(uri));
      }
    }

    FileState? file = _uriToFile[uri];
    if (file == null) {
      Source? uriSource = _sourceFactory.resolveUri(null, uri.toString());

      // If the URI cannot be resolved, for example because the factory
      // does not understand the scheme, return the unresolved file instance.
      if (uriSource == null) {
        return Either2.t1(null);
      }

      String path = uriSource.fullName;
      File resource = _resourceProvider.getFile(path);
      FileSource source = FileSource(resource, uri);
      WorkspacePackage? workspacePackage = _workspace?.findPackageFor(path);
      FeatureSet featureSet = contextFeatureSet(path, uri, workspacePackage);
      Version packageLanguageVersion =
          contextLanguageVersion(path, uri, workspacePackage);
      file = FileState._(this, path, uri, source, workspacePackage, featureSet,
          packageLanguageVersion);
      _uriToFile[uri] = file;
      _addFileWithPath(path, file);
      file.refresh();
    }
    return Either2.t1(file);
  }

  /// Return the list of all [FileState]s corresponding to the given [path]. The
  /// list has at least one item, and the first item is the canonical file.
  List<FileState> getFilesForPath(String path) {
    FileState canonicalFile = getFileForPath(path);
    List<FileState> allFiles = _pathToFiles[path]!.toList();
    if (allFiles.length == 1) {
      return allFiles;
    }
    return allFiles
      ..remove(canonicalFile)
      ..insert(0, canonicalFile);
  }

  /// Return files where the given [name] is subtyped, i.e. used in `extends`,
  /// `with` or `implements` clauses.
  Set<FileState>? getFilesSubtypingName(String name) {
    return _subtypedNameToFiles[name];
  }

  /// Return `true` if there is a URI that can be resolved to the [path].
  ///
  /// When a file exists, but for the URI that corresponds to the file is
  /// resolved to another file, e.g. a generated one in Bazel, Gn, etc, we
  /// cannot analyze the original file.
  bool hasUri(String path) {
    bool? flag = _hasUriForPath[path];
    if (flag == null) {
      File resource = _resourceProvider.getFile(path);
      Source fileSource = resource.createSource();
      Uri? uri = _sourceFactory.restoreUri(fileSource);
      Source? uriSource = _sourceFactory.forUri2(uri!);
      flag = uriSource?.fullName == path;
      _hasUriForPath[path] = flag;
    }
    return flag;
  }

  /// The file with the given [path] might have changed, so ensure that it is
  /// read the next time it is refreshed.
  void markFileForReading(String path) {
    _fileContentCache.invalidate(path);
  }

  void readPartsForLibraries() {
    // Make a copy, because reading new files will update it.
    var libraryToProcess = _librariesWithoutPartsRead.toList();

    // We will process these files, so clear it now.
    // It will be filled with new files during the loop below.
    _librariesWithoutPartsRead.clear();

    for (var library in libraryToProcess) {
      library.partedFiles;
    }
  }

  /// Remove the file with the given [path].
  void removeFile(String path) {
    markFileForReading(path);
    _clearFiles();
  }

  /// Reset URI resolution, and forget all files. So, the next time any file is
  /// requested, it will be read, and its whole (potentially different) graph
  /// will be built.
  void resetUriResolution() {
    _sourceFactory.clearCache();
    _fileContentCache.invalidateAll();
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
