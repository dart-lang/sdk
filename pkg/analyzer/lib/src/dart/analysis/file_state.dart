// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/defined_names.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/referenced_names.dart';
import 'package:analyzer/src/dart/analysis/unlinked_api_signature.dart';
import 'package:analyzer/src/dart/analysis/unlinked_data.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart' show SourceFactory;
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

/// Information about a directive that "includes" a file - `import`, `export`,
/// or `part`. But not `part of` or `library augment` - these are modelled as
/// kinds.
sealed class DirectiveState {
  final FileKind container;

  DirectiveState({
    required this.container,
  });

  void dispose() {}
}

/// Meaning of a URI referenced in a directive.
sealed class DirectiveUri {
  const DirectiveUri();

  Source? get source => null;
}

class DirectiveUris {
  final DirectiveUri primary;
  final List<DirectiveUri> configurations;
  final DirectiveUri selected;

  DirectiveUris({
    required this.primary,
    required this.configurations,
    required this.selected,
  });
}

/// [DirectiveUriWithUri] with URI that resolves to a [FileState].
final class DirectiveUriWithFile extends DirectiveUriWithSource {
  final FileState file;

  DirectiveUriWithFile({
    required super.relativeUriStr,
    required super.relativeUri,
    required this.file,
  });

  @override
  FileSource get source => file.source;

  @override
  String toString() => '$file';
}

/// [DirectiveUriWithSource] with a [InSummarySource].
final class DirectiveUriWithInSummarySource extends DirectiveUriWithSource {
  @override
  final InSummarySource source;

  DirectiveUriWithInSummarySource({
    required super.relativeUriStr,
    required super.relativeUri,
    required this.source,
  });

  @override
  String toString() => '$source';
}

/// [DirectiveUri] for which we can't get its relative URI string.
final class DirectiveUriWithoutString extends DirectiveUri {
  const DirectiveUriWithoutString();
}

/// [DirectiveUriWithUri] that can be resolved into a [Source].
sealed class DirectiveUriWithSource extends DirectiveUriWithUri {
  DirectiveUriWithSource({
    required super.relativeUriStr,
    required super.relativeUri,
  });

  @override
  Source get source;

  @override
  String toString() => '$source';
}

/// [DirectiveUri] for which we can get its relative URI string.
final class DirectiveUriWithString extends DirectiveUri {
  final String relativeUriStr;

  DirectiveUriWithString({
    required this.relativeUriStr,
  });

  @override
  String toString() => relativeUriStr;
}

/// [DirectiveUriWithString] that can be parsed into a relative URI.
final class DirectiveUriWithUri extends DirectiveUriWithString {
  final Uri relativeUri;

  DirectiveUriWithUri({
    required super.relativeUriStr,
    required this.relativeUri,
  });

  @override
  String toString() => '$relativeUri';
}

abstract class FileContent {
  String get content;

  String get contentHash;

  bool get exists;
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

abstract class FileContentStrategy {
  FileContent get(String path);
}

abstract class FileKind {
  final FileState file;
  List<LibraryExportState>? _libraryExports;
  List<LibraryImportState>? _libraryImports;
  List<PartIncludeState>? _partIncludes;
  List<LibraryImportState>? _docImports;

  FileKind({
    required this.file,
  }) {
    disposeLibraryCycle();
  }

  /// When [library] returns `null`, this getter is used to look at this
  /// file itself as a library.
  LibraryFileKind get asLibrary {
    return LibraryFileKind(
      file: file,
      name: null,
      recoveredFrom: this,
    );
  }

  /// The import states of each `@docImport` on the library directive.
  List<LibraryImportState> get docImports {
    if (_docImports case var existing?) {
      return existing;
    }

    return _docImports =
        _unlinkedDocImports.map(_buildLibraryImportState).toFixedList();
  }

  /// Returns the library in which this file should be analyzed.
  LibraryFileKind? get library;

  List<LibraryExportState> get libraryExports {
    return _libraryExports ??=
        file.unlinked2.exports.map<LibraryExportState>((unlinked) {
      var uris = file._buildConfigurableDirectiveUris(unlinked);
      var selectedUri = uris.selected;
      switch (selectedUri) {
        case DirectiveUriWithFile():
          return LibraryExportWithFile(
            container: this,
            unlinked: unlinked,
            selectedUri: selectedUri,
            uris: uris,
          );
        case DirectiveUriWithInSummarySource():
          return LibraryExportWithInSummarySource(
            container: this,
            unlinked: unlinked,
            selectedUri: selectedUri,
            uris: uris,
          );
        case DirectiveUriWithUri():
          return LibraryExportWithUri(
            container: this,
            unlinked: unlinked,
            selectedUri: selectedUri,
            uris: uris,
          );
        case DirectiveUriWithString():
          return LibraryExportWithUriStr(
            container: this,
            unlinked: unlinked,
            selectedUri: selectedUri,
            uris: uris,
          );
        case DirectiveUriWithoutString():
          return LibraryExportState(
            container: this,
            unlinked: unlinked,
            selectedUri: selectedUri,
            uris: uris,
          );
      }
    }).toFixedList();
  }

  List<LibraryImportState> get libraryImports {
    if (_libraryImports case var existing?) {
      return existing;
    }

    var unlinked = file.unlinked2;
    var result = <LibraryImportState>[
      ...unlinked.imports.map(_buildLibraryImportState),
    ];

    if (this is LibraryFileKind) {
      if (!unlinked.isDartCore && !unlinked.hasDartCoreImport) {
        result.add(
          _buildLibraryImportState(
            UnlinkedLibraryImportDirective(
              combinators: const [],
              configurations: const [],
              importKeywordOffset: -1,
              isDocImport: false,
              isSyntheticDartCore: true,
              prefix: null,
              uri: 'dart:core',
            ),
          ),
        );
      }
    }

    return _libraryImports = result;
  }

  List<PartIncludeState> get partIncludes {
    return _partIncludes ??=
        file.unlinked2.parts.map<PartIncludeState>((unlinked) {
      var uris = file._buildConfigurableDirectiveUris(unlinked);
      var selectedUri = uris.selected;
      switch (selectedUri) {
        case DirectiveUriWithFile():
          return PartIncludeWithFile(
            container: this,
            unlinked: unlinked,
            selectedUri: selectedUri,
            uris: uris,
          );
        case DirectiveUriWithUri():
          return PartIncludeWithUri(
            container: this,
            unlinked: unlinked,
            selectedUri: selectedUri,
            uris: uris,
          );
        case DirectiveUriWithString():
          return PartIncludeWithUriStr(
            container: this,
            unlinked: unlinked,
            selectedUri: selectedUri,
            uris: uris,
          );
        case DirectiveUriWithoutString():
          return PartIncludeState(
            container: this,
            unlinked: unlinked,
            selectedUri: selectedUri,
            uris: uris,
          );
      }
    }).toFixedList();
  }

  List<UnlinkedLibraryImportDirective> get _unlinkedDocImports;

  /// Collect files that are transitively referenced by this file.
  @mustCallSuper
  void collectTransitive(Set<FileState> files) {
    if (files.add(file)) {
      for (var directive in libraryExports) {
        if (directive is LibraryExportWithFile) {
          directive.exportedLibrary?.collectTransitive(files);
        }
      }
      for (var directive in libraryImports) {
        if (directive is LibraryImportWithFile) {
          directive.importedLibrary?.collectTransitive(files);
        }
      }
      for (var directive in partIncludes) {
        if (directive is PartIncludeWithFile) {
          directive.includedPart?.collectTransitive(files);
        }
      }
    }
  }

  /// Directives are usually pulled lazily (so that we can parse a file
  /// without pulling all its transitive references), but when we output
  /// textual dumps we want to check that we reference only objects that
  /// are available. So, we need to discover all referenced files before
  /// we register available objects.
  void discoverReferencedFiles() {
    libraryExports;
    libraryImports;
    partIncludes;
    docImports;
  }

  @mustCallSuper
  void dispose() {
    disposeLibraryCycle();

    _libraryExports?.disposeAll();
    _libraryImports?.disposeAll();
    _partIncludes?.disposeAll();
    _docImports?.disposeAll();
  }

  /// Dispose the containing [LibraryFileKind] cycle.
  void disposeLibraryCycle() {
    // Macro generated files never add new dependencies.
    // So, there is no reason to dispose.
    if (file.isMacroPart) {
      return;
    }

    for (var reference in file.referencingFiles) {
      reference.kind.disposeLibraryCycle();
    }
  }

  bool hasPart(PartFileKind partKind) {
    for (var directive in partIncludes) {
      if (directive is PartIncludeWithFile) {
        if (directive.includedFile == partKind.file) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns `true` if [file] is imported as a library.
  bool importsFile(FileState file) {
    return libraryImports
        .whereType<LibraryImportWithFile>()
        .any((import) => import.importedFile == file);
  }

  /// Creates a [LibraryImportState] with the given unlinked [directive].
  LibraryImportState _buildLibraryImportState(
    UnlinkedLibraryImportDirective directive,
  ) {
    var uris = file._buildConfigurableDirectiveUris(directive);
    var selectedUri = uris.selected;
    switch (selectedUri) {
      case DirectiveUriWithFile():
        return LibraryImportWithFile(
          container: this,
          unlinked: directive,
          selectedUri: selectedUri,
          uris: uris,
        );
      case DirectiveUriWithInSummarySource():
        return LibraryImportWithInSummarySource(
          container: this,
          unlinked: directive,
          selectedUri: selectedUri,
          uris: uris,
        );
      case DirectiveUriWithUri():
        return LibraryImportWithUri(
          container: this,
          unlinked: directive,
          selectedUri: selectedUri,
          uris: uris,
        );
      case DirectiveUriWithString():
        return LibraryImportWithUriStr(
          container: this,
          unlinked: directive,
          selectedUri: selectedUri,
          uris: uris,
        );
      case DirectiveUriWithoutString():
        return LibraryImportState(
          container: this,
          unlinked: directive,
          selectedUri: selectedUri,
          uris: uris,
        );
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

  /// The [AnalysisOptions] associated with this file.
  final AnalysisOptionsImpl analysisOptions;

  /// The absolute path of the file.
  final String path;

  /// The absolute URI of the file.
  final Uri uri;

  /// Properties of the [uri].
  final FileUriProperties uriProperties;

  /// The [FileSource] of the file with the [uri].
  final FileSource source;

  /// The [WorkspacePackage] that contains this file.
  ///
  /// It might be `null` if the file is outside of the workspace.
  final WorkspacePackage? workspacePackage;

  /// The [FeatureSet] for this file.
  ///
  /// Usually it is the feature set of the latest language version, plus
  /// possibly additional enabled experiments (from the analysis options file,
  /// or from SDK allowed experiments).
  ///
  /// This feature set is then restricted, with the [packageLanguageVersion],
  /// or with a `@dart` language override token in the file header.
  final FeatureSet featureSet;

  /// The language version for the package that contains this file.
  final Version packageLanguageVersion;

  FileContent? _fileContent;
  LineInfo? _lineInfo;
  Uint8List? _unlinkedSignature;
  String? _unlinkedKey;
  AnalysisDriverUnlinkedUnit? _driverUnlinkedUnit;
  Uint8List? _apiSignature;

  UnlinkedUnit? _unlinked2;

  FileKind? _kind;

  bool isMacroPart = false;

  /// Files that reference this file.
  final Set<FileState> referencingFiles = {};

  /// The flag that shows whether the file has an error or warning that
  /// might be fixed by a change to another file.
  bool hasErrorOrWarning = false;

  /// Set to `true` if this file contains code that might be executed by
  /// a macro - declares a macro class itself, or is directly or indirectly
  /// imported into a library that declares one.
  bool mightBeExecutedByMacroClass = false;

  FileState._(
    this._fsState,
    this.path,
    this.uri,
    this.source,
    this.workspacePackage,
    this.featureSet,
    this.packageLanguageVersion,
    this.analysisOptions,
  ) : uriProperties = FileUriProperties(uri);

  /// The unlinked API signature of the file.
  Uint8List get apiSignature => _apiSignature!;

  /// The content of the file.
  String get content => _fileContent!.content;

  /// The MD5 hash of the [content].
  String get contentHash => _fileContent!.contentHash;

  /// The class member names defined by the file.
  Set<String> get definedClassMemberNames {
    return _driverUnlinkedUnit!.definedClassMemberNames;
  }

  /// The top-level names defined by the file.
  Set<String> get definedTopLevelNames {
    return _driverUnlinkedUnit!.definedTopLevelNames;
  }

  /// Return `true` if the file exists.
  bool get exists => _fileContent!.exists;

  @override
  int get hashCode => uri.hashCode;

  FileKind get kind => _kind!;

  /// Return information about line in the file.
  LineInfo get lineInfo => _lineInfo!;

  /// The external names referenced by the file.
  Set<String> get referencedNames {
    return _driverUnlinkedUnit!.referencedNames;
  }

  File get resource {
    return _fsState.resourceProvider.getFile(path);
  }

  @visibleForTesting
  FileStateTestView get test => FileStateTestView(this);

  /// The [UnlinkedUnit] of the file.
  UnlinkedUnit get unlinked2 => _unlinked2!;

  String get unlinkedKey => _unlinkedKey!;

  /// The MD5 signature based on the content, feature sets, language version.
  Uint8List get unlinkedSignature => _unlinkedSignature!;

  /// Return the [uri] string.
  String get uriStr => uri.toString();

  @override
  bool operator ==(Object other) {
    return other is FileState && other.uri == uri;
  }

  /// Returns either new, or cached parsed result for this file.
  ParsedFileState getParsed({
    required OperationPerformanceImpl performance,
  }) {
    var result = _fsState.parsedFileStateCache.get(this);
    if (result != null) {
      return result;
    }

    var errorListener = RecordingErrorListener();
    var unit = parseCode(
      code: content,
      errorListener: errorListener,
      performance: performance,
    );

    result = ParsedFileState(
      code: content,
      unit: unit,
      errors: errorListener.errors,
    );
    _fsState.parsedFileStateCache.put(this, result);

    return result;
  }

  /// Return a new parsed unresolved [CompilationUnit].
  CompilationUnitImpl parse({
    AnalysisErrorListener? errorListener,
    required OperationPerformanceImpl performance,
  }) {
    errorListener ??= AnalysisErrorListener.NULL_LISTENER;
    try {
      return parseCode(
        code: content,
        errorListener: errorListener,
        performance: performance,
      );
    } catch (exception, stackTrace) {
      throw CaughtExceptionWithFiles(
        exception,
        stackTrace,
        {path: content},
      );
    }
  }

  /// Parses given [code] with the same features as this file.
  CompilationUnitImpl parseCode({
    required String code,
    required AnalysisErrorListener errorListener,
    required OperationPerformanceImpl performance,
  }) {
    return performance.run('parseCode', (performance) {
      performance.getDataInt('length').add(code.length);

      CharSequenceReader reader = CharSequenceReader(code);
      Scanner scanner = Scanner(source, reader, errorListener)
        ..configureFeatures(
          featureSetForOverriding: featureSet,
          featureSet: featureSet.restrictToVersion(
            packageLanguageVersion,
          ),
        );
      Token token = scanner.tokenize(reportScannerErrors: false);
      LineInfo lineInfo = LineInfo(scanner.lineStarts);

      Parser parser = Parser(
        source,
        errorListener,
        featureSet: scanner.featureSet,
        lineInfo: lineInfo,
      );

      var unit = parser.parseCompilationUnit(token);
      unit.languageVersion = LibraryLanguageVersion(
        package: packageLanguageVersion,
        override: scanner.overrideVersion,
      );

      // Ensure the string canonicalization cache size is reasonable.
      pruneStringCanonicalizationCache();

      return unit;
    });
  }

  /// Read the file content and ensure that all of the file properties are
  /// consistent with the read content, including API signature.
  ///
  /// Return how the file changed since the last refresh.
  FileStateRefreshResult refresh({
    OperationPerformanceImpl? performance,
  }) {
    performance ??= OperationPerformanceImpl('<root>');
    _invalidateCurrentUnresolvedData();

    FileContent rawFileState;
    if (_fsState._macroFileContent case var macroFileContent?) {
      _fsState._macroFileContent = null;
      rawFileState = macroFileContent;
      isMacroPart = true;
    } else {
      rawFileState = _fsState.fileContentStrategy.get(path);
    }

    var contentChanged = _fileContent?.contentHash != rawFileState.contentHash;
    _fileContent = rawFileState;
    _fsState.parsedFileStateCache.remove(this);

    // Prepare the unlinked bundle key.
    var previousUnlinkedKey = _unlinkedKey;
    {
      var signature = ApiSignature();
      signature.addUint32List(_fsState._saltForUnlinked);
      signature.addFeatureSet(featureSet);
      signature.addLanguageVersion(packageLanguageVersion);
      signature.addString(contentHash);
      signature.addBool(exists);
      _unlinkedSignature = signature.toByteList();
      var signatureHex = hex.encode(_unlinkedSignature!);
      // TODO(scheglov): Use the path as the key, and store the signature.
      _unlinkedKey = '$signatureHex.unlinked2';
    }

    // Prepare the unlinked unit.
    performance.run('getUnlinkedUnit', (performance) {
      _driverUnlinkedUnit = _getUnlinkedUnit(
        previousUnlinkedKey,
        performance: performance,
      );
    });
    _unlinked2 = _driverUnlinkedUnit!.unit;
    _lineInfo = LineInfo(_unlinked2!.lineStarts);

    _prefetchDirectReferences();

    // Prepare API signature.
    var newApiSignature = _unlinked2!.apiSignature;
    bool apiSignatureChanged = _apiSignature != null &&
        !_equalByteLists(_apiSignature, newApiSignature);
    _apiSignature = newApiSignature;

    // Read parts eagerly to link parts to libraries.
    _updateKind();

    // Update mapping from subtyped names to files.
    for (var name in _driverUnlinkedUnit!.subtypedNames) {
      var files = _fsState._subtypedNameToFiles[name];
      if (files == null) {
        files = <FileState>{};
        _fsState._subtypedNameToFiles[name] = files;
      }
      files.add(this);
    }

    // Return how the file changed.
    if (apiSignatureChanged) {
      return FileStateRefreshResult.apiChanged;
    } else if (contentChanged) {
      return FileStateRefreshResult.contentChanged;
    } else {
      return FileStateRefreshResult.nothing;
    }
  }

  @override
  String toString() {
    return '$uri = $path';
  }

  // TODO(scheglov): move to _fsState?
  DirectiveUris _buildConfigurableDirectiveUris(
    UnlinkedConfigurableUriDirective directive,
  ) {
    var primaryUri = _buildDirectiveUri(directive.uri);

    DirectiveUri? selectedConfigurationUri;
    var configurationUris = directive.configurations.map((configuration) {
      var configurationUri = _buildDirectiveUri(configuration.uri);
      // Maybe select this URI.
      var name = configuration.name;
      var value = configuration.valueOrTrue;
      if (_fsState._declaredVariables.get(name) == value) {
        selectedConfigurationUri ??= configurationUri;
      }
      // Include it anyway.
      return configurationUri;
    }).toFixedList();

    return DirectiveUris(
      primary: primaryUri,
      configurations: configurationUris,
      selected: selectedConfigurationUri ?? primaryUri,
    );
  }

  DirectiveUri _buildDirectiveUri(String? relativeUriStr) {
    if (relativeUriStr == null) {
      return const DirectiveUriWithoutString();
    }

    var relativeUri = uriCache.tryParse(relativeUriStr);
    if (relativeUri == null) {
      return DirectiveUriWithString(
        relativeUriStr: relativeUriStr,
      );
    }

    var absoluteUri = uriCache.resolveRelative(uri, relativeUri);
    var uriResolution = _fsState.getFileForUri(absoluteUri);
    switch (uriResolution) {
      case null:
        return DirectiveUriWithUri(
          relativeUriStr: relativeUriStr,
          relativeUri: relativeUri,
        );
      case UriResolutionFile(:var file):
        return DirectiveUriWithFile(
          relativeUriStr: relativeUriStr,
          relativeUri: relativeUri,
          file: file,
        );
      case UriResolutionExternalLibrary(:var source):
        return DirectiveUriWithInSummarySource(
          relativeUriStr: relativeUriStr,
          relativeUri: relativeUri,
          source: source,
        );
    }
  }

  /// Return the [FileState] for the given [relativeUriStr], or `null` if the
  /// URI cannot be parsed, cannot correspond any file, etc.
  UriResolution? _fileForRelativeUri(String? relativeUriStr) {
    if (relativeUriStr == null) {
      return null;
    }

    Uri absoluteUri;
    try {
      var relativeUri = uriCache.parse(relativeUriStr);
      absoluteUri = uriCache.resolveRelative(uri, relativeUri);
    } on FormatException {
      return null;
    }

    return _fsState.getFileForUri(absoluteUri);
  }

  /// Return the unlinked unit, freshly deserialized from bytes,
  /// previously deserialized from bytes, or new.
  AnalysisDriverUnlinkedUnit _getUnlinkedUnit(
    String? previousUnlinkedKey, {
    required OperationPerformanceImpl performance,
  }) {
    if (previousUnlinkedKey != null) {
      if (previousUnlinkedKey != _unlinkedKey) {
        _fsState.unlinkedUnitStore.release(previousUnlinkedKey);
      } else {
        return _driverUnlinkedUnit!;
      }
    }

    var testData = _fsState.testData?.forFile(resource, uri);
    var fromStore = _fsState.unlinkedUnitStore.get(_unlinkedKey!);
    if (fromStore != null) {
      testData?.unlinkedKeyGet.add(unlinkedKey);
      return fromStore;
    }

    var bytes = _fsState._byteStore.get(_unlinkedKey!);
    if (bytes != null && bytes.isNotEmpty) {
      testData?.unlinkedKeyGet.add(unlinkedKey);
      var result = AnalysisDriverUnlinkedUnit.fromBytes(bytes);
      _fsState.unlinkedUnitStore.put(_unlinkedKey!, result);
      return result;
    }

    var unit = getParsed(
      performance: performance,
    ).unit;

    return performance.run('compute', (performance) {
      var unlinkedUnit = performance.run(
        'serializeAstUnlinked2',
        (performance) {
          return serializeAstUnlinked2(
            unit,
            exists: exists,
            isDartCore: uriStr == 'dart:core',
            performance: performance,
          );
        },
      );
      var definedNames = computeDefinedNames(unit);
      var referencedNames = computeReferencedNames(unit);
      var subtypedNames = computeSubtypedNames(unit);
      var driverUnlinkedUnit = AnalysisDriverUnlinkedUnit(
        definedTopLevelNames: definedNames.topLevelNames,
        definedClassMemberNames: definedNames.classMemberNames,
        referencedNames: referencedNames,
        subtypedNames: subtypedNames,
        unit: unlinkedUnit,
      );
      var bytes = driverUnlinkedUnit.toBytes();
      _fsState._byteStore.putGet(_unlinkedKey!, bytes);
      testData?.unlinkedKeyPut.add(unlinkedKey);
      _fsState.unlinkedUnitStore.put(_unlinkedKey!, driverUnlinkedUnit);
      return driverUnlinkedUnit;
    });
  }

  /// Invalidate any data that depends on the current unlinked data of the file,
  /// because [refresh] is going to recompute the unlinked data.
  void _invalidateCurrentUnresolvedData() {
    if (_driverUnlinkedUnit != null) {
      for (var name in _driverUnlinkedUnit!.subtypedNames) {
        var files = _fsState._subtypedNameToFiles[name];
        files?.remove(this);
      }
    }
  }

  // TODO(scheglov): write tests
  void _prefetchDirectReferences() {
    var prefetchFiles = _fsState.prefetchFiles;
    if (prefetchFiles == null) {
      return;
    }

    var paths = <String>{};

    void addRelativeUri(String? relativeUriStr) {
      if (relativeUriStr == null) {
        return;
      }
      Uri absoluteUri;
      try {
        var relativeUri = uriCache.parse(relativeUriStr);
        absoluteUri = uriCache.resolveRelative(uri, relativeUri);
      } on FormatException {
        return;
      }
      var path = _fsState._sourceFactory.forUri2(absoluteUri)?.fullName;
      if (path != null) {
        paths.add(path);
      }
    }

    for (var directive in unlinked2.imports) {
      addRelativeUri(directive.uri);
    }
    for (var directive in unlinked2.exports) {
      addRelativeUri(directive.uri);
    }
    for (var directive in unlinked2.parts) {
      addRelativeUri(directive.uri);
    }

    prefetchFiles(paths.toList());
  }

  void _updateKind() {
    _kind?.dispose();

    var libraryDirective = unlinked2.libraryDirective;
    var partOfNameDirective = unlinked2.partOfNameDirective;
    var partOfUriDirective = unlinked2.partOfUriDirective;
    if (libraryDirective != null) {
      _kind = LibraryFileKind(
        file: this,
        name: libraryDirective.name,
      );
    } else if (partOfNameDirective != null) {
      _kind = PartOfNameFileKind(
        file: this,
        unlinked: partOfNameDirective,
      );
    } else if (partOfUriDirective != null) {
      var uriStr = partOfUriDirective.uri;
      var uriResolution = _fileForRelativeUri(uriStr);
      switch (uriResolution) {
        case UriResolutionFile(:var file):
          _kind = PartOfUriKnownFileKind(
            file: this,
            unlinked: partOfUriDirective,
            uriFile: file,
          );
        default:
          _kind = PartOfUriUnknownFileKind(
            file: this,
            unlinked: partOfUriDirective,
          );
      }
    } else {
      _kind = LibraryFileKind(
        file: this,
        name: null,
      );
    }
  }

  static UnlinkedUnit serializeAstUnlinked2(
    CompilationUnit unit, {
    required bool exists,
    required bool isDartCore,
    required OperationPerformanceImpl performance,
  }) {
    List<UnlinkedLibraryImportDirective> buildDocImports(
      Directive directive,
    ) {
      var comment = directive.documentationComment;
      if (comment == null) {
        return const [];
      }

      return comment.docImports.map((docImport) {
        return _serializeImport(
          node: docImport.import,
          isDocImport: true,
        );
      }).toFixedList();
    }

    UnlinkedLibraryDirective? libraryDirective;
    UnlinkedPartOfNameDirective? partOfNameDirective;
    UnlinkedPartOfUriDirective? partOfUriDirective;
    var exports = <UnlinkedLibraryExportDirective>[];
    var imports = <UnlinkedLibraryImportDirective>[];
    var parts = <UnlinkedPartDirective>[];
    var macroClasses = <MacroClass>[];
    var hasDartCoreImport = false;
    for (var directive in unit.directives) {
      if (directive is ExportDirective) {
        var builder = _serializeExport(directive);
        exports.add(builder);
      } else if (directive is ImportDirectiveImpl) {
        var builder = _serializeImport(
          node: directive,
          isDocImport: false,
        );
        imports.add(builder);
        if (builder.uri == 'dart:core') {
          hasDartCoreImport = true;
        }
      } else if (directive is LibraryDirective) {
        libraryDirective = UnlinkedLibraryDirective(
          docImports: buildDocImports(directive),
          name: directive.name2?.name,
        );
      } else if (directive is PartDirective) {
        var unlinked = _serializePart(directive);
        parts.add(unlinked);
      } else if (directive is PartOfDirective) {
        var libraryName = directive.libraryName;
        var uri = directive.uri;
        if (libraryName != null) {
          partOfNameDirective ??= UnlinkedPartOfNameDirective(
            docImports: buildDocImports(directive),
            name: libraryName.name,
            nameRange: UnlinkedSourceRange(
              offset: libraryName.offset,
              length: libraryName.length,
            ),
          );
        } else if (uri != null) {
          partOfUriDirective ??= UnlinkedPartOfUriDirective(
            docImports: buildDocImports(directive),
            uri: uri.stringValue,
            uriRange: UnlinkedSourceRange(
              offset: uri.offset,
              length: uri.length,
            ),
          );
        }
      }
    }
    for (var declaration in unit.declarations) {
      if (declaration is ClassDeclarationImpl) {
        if (declaration.macroKeyword != null) {
          var constructors = declaration.members
              .whereType<ConstructorDeclaration>()
              .map((e) => e.name?.lexeme ?? '')
              .where((e) => !e.startsWith('_'))
              .toFixedList();
          if (constructors.isNotEmpty) {
            macroClasses.add(
              MacroClass(
                name: declaration.name.lexeme,
                constructors: constructors,
              ),
            );
          }
        }
      }
    }

    var topLevelDeclarations = <String>{};
    for (var declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        topLevelDeclarations.add(declaration.name.lexeme);
      } else if (declaration is EnumDeclaration) {
        topLevelDeclarations.add(declaration.name.lexeme);
      } else if (declaration is ExtensionDeclaration) {
        var name = declaration.name;
        if (name != null) {
          topLevelDeclarations.add(name.lexeme);
        }
      } else if (declaration is FunctionDeclaration) {
        topLevelDeclarations.add(declaration.name.lexeme);
      } else if (declaration is MixinDeclaration) {
        topLevelDeclarations.add(declaration.name.lexeme);
      } else if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          topLevelDeclarations.add(variable.name.lexeme);
        }
      }
    }

    var apiSignature = performance.run('apiSignature', (performance) {
      var signatureBuilder = ApiSignature();
      signatureBuilder.addBytes(computeUnlinkedApiSignature(unit));
      signatureBuilder.addBool(exists);
      return signatureBuilder.toByteList();
    });

    return UnlinkedUnit(
      apiSignature: apiSignature,
      exports: exports.toFixedList(),
      hasDartCoreImport: hasDartCoreImport,
      imports: imports.toFixedList(),
      informativeBytes: writeUnitInformative(unit),
      isDartCore: isDartCore,
      libraryDirective: libraryDirective,
      lineStarts: Uint32List.fromList(unit.lineInfo.lineStarts),
      macroClasses: macroClasses.toFixedList(),
      parts: parts.toFixedList(),
      partOfNameDirective: partOfNameDirective,
      partOfUriDirective: partOfUriDirective,
      topLevelDeclarations: topLevelDeclarations,
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

  static List<UnlinkedCombinator> _serializeCombinators(
    List<Combinator> combinators,
  ) {
    return combinators.map((combinator) {
      if (combinator is ShowCombinator) {
        return UnlinkedCombinator(
          keywordOffset: combinator.keyword.offset,
          endOffset: combinator.end,
          isShow: true,
          names: combinator.shownNames.map((e) => e.name).toFixedList(),
        );
      } else {
        combinator as HideCombinator;
        return UnlinkedCombinator(
          keywordOffset: combinator.keyword.offset,
          endOffset: combinator.end,
          isShow: false,
          names: combinator.hiddenNames.map((e) => e.name).toFixedList(),
        );
      }
    }).toFixedList();
  }

  static List<UnlinkedNamespaceDirectiveConfiguration> _serializeConfigurations(
    List<Configuration> configurations,
  ) {
    return configurations.map((configuration) {
      var name = configuration.name.components.join('.');
      var value = configuration.value?.stringValue ?? '';
      return UnlinkedNamespaceDirectiveConfiguration(
        name: name,
        value: value,
        uri: configuration.uri.stringValue,
      );
    }).toFixedList();
  }

  static UnlinkedLibraryExportDirective _serializeExport(ExportDirective node) {
    return UnlinkedLibraryExportDirective(
      combinators: _serializeCombinators(node.combinators),
      configurations: _serializeConfigurations(node.configurations),
      exportKeywordOffset: node.exportKeyword.offset,
      uri: node.uri.stringValue,
    );
  }

  static UnlinkedLibraryImportDirective _serializeImport({
    required ImportDirective node,
    required bool isDocImport,
  }) {
    UnlinkedLibraryImportPrefix? unlinkedPrefix;
    var prefix = node.prefix;
    if (prefix != null) {
      unlinkedPrefix = UnlinkedLibraryImportPrefix(
        deferredOffset: node.deferredKeyword?.offset,
        asOffset: node.asKeyword!.offset,
        name: prefix.name,
        nameOffset: prefix.offset,
      );
    }

    return UnlinkedLibraryImportDirective(
      combinators: _serializeCombinators(node.combinators),
      configurations: _serializeConfigurations(node.configurations),
      importKeywordOffset: node.importKeyword.offset,
      isDocImport: isDocImport,
      uri: node.uri.stringValue,
      prefix: unlinkedPrefix,
    );
  }

  static UnlinkedPartDirective _serializePart(PartDirective node) {
    return UnlinkedPartDirective(
      configurations: _serializeConfigurations(node.configurations),
      uri: node.uri.stringValue,
    );
  }
}

enum FileStateRefreshResult {
  /// No changes to the content, so no changes at all.
  nothing,

  /// The content changed, but the API of the file is the same.
  contentChanged,

  /// The content changed, and the API of the file is different.
  apiChanged,
}

@visibleForTesting
class FileStateTestView {
  final FileState file;

  FileStateTestView(this.file);

  String get unlinkedKey => file._unlinkedKey!;
}

/// Information about known file system state.
class FileSystemState {
  final ResourceProvider resourceProvider;
  final String contextName;
  final ByteStore _byteStore;
  final SourceFactory _sourceFactory;
  final Workspace? _workspace;
  final DeclaredVariables _declaredVariables;
  final Uint32List _saltForUnlinked;
  final Uint32List _saltForElements;

  final FeatureSetProvider featureSetProvider;

  /// Mapping from a URI to the corresponding [FileState].
  final Map<Uri, FileState> _uriToFile = {};

  /// All known file paths.
  final Set<String> knownFilePaths = <String>{};

  /// All known files.
  final Set<FileState> knownFiles = {};

  /// Mapping from a path to the flag whether there is a URI for the path.
  final Map<String, bool> _hasUriForPath = {};

  /// Mapping from a path to the corresponding [FileState].
  final Map<String, FileState> _pathToFile = {};

  /// Mapping from a library name to the [LibraryFileKind] that have it.
  final _LibraryNameToFiles _libraryNameToFiles = _LibraryNameToFiles();

  /// The map of subtyped names to files where these names are subtyped.
  final Map<String, Set<FileState>> _subtypedNameToFiles = {};

  /// The value of this field is incremented when the set of files is updated.
  int fileStamp = 0;

  final FileContentStrategy fileContentStrategy;
  final UnlinkedUnitStore unlinkedUnitStore;

  /// A function that fetches the given list of files. This function can be used
  /// to batch file reads in systems where file fetches are expensive.
  final void Function(List<String> paths)? prefetchFiles;

  /// A function that returns true if the given file path is likely to be that
  /// of a file that is generated.
  final bool Function(String path) isGenerated;

  /// The function that is invoked when a new file is created.
  final void Function(FileState file) onNewFile;

  late final FileSystemStateTestView _testView;

  final FileSystemTestData? testData;

  /// We set a value for this field when we are about to refresh the current
  /// macro [FileState]. During the refresh, this will is reset back to `null`.
  FileContent? _macroFileContent;

  /// Used for looking up options to associate with created file states.
  final AnalysisOptionsMap _analysisOptionsMap;

  /// The default performance for [_newFile].
  ///
  /// [_newFile] does expensive work, so it is important to see which
  /// operations it does, and how long they take. But it can be reached
  /// through getters, which we would like to keep getters. So, instead we
  /// store here the instance to attach [_newFile] operations.
  OperationPerformanceImpl? newFileOperationPerformance;

  /// We cache results of parsing [FileState]s because they might be useful
  /// in the process of a single analysis operation. But after that, even
  /// if these results are still valid, they are often never used again. So,
  /// currently we clear the cache after each operation.
  ParsedFileStateCache parsedFileStateCache = ParsedFileStateCache();

  FileSystemState(
    this._byteStore,
    this.resourceProvider,
    this.contextName,
    this._sourceFactory,
    this._workspace,
    this._declaredVariables,
    this._saltForUnlinked,
    this._saltForElements,
    this.featureSetProvider,
    AnalysisOptionsMap analysisOptionsMap, {
    required this.fileContentStrategy,
    required this.unlinkedUnitStore,
    required this.prefetchFiles,
    required this.isGenerated,
    required this.onNewFile,
    required this.testData,
  }) : _analysisOptionsMap = analysisOptionsMap {
    _testView = FileSystemStateTestView(this);
  }

  path.Context get pathContext => resourceProvider.pathContext;

  @visibleForTesting
  FileSystemStateTestView get test => _testView;

  /// Update the state to reflect the fact that the file with the given [path]
  /// was changed. Specifically this means that we evict this file and every
  /// file that referenced it.
  void changeFile(String path, Set<FileState> removedFiles) {
    var file = _pathToFile.remove(path);
    if (file == null) {
      return;
    }

    if (!removedFiles.add(file)) {
      return;
    }

    _uriToFile.remove(file.uri);
    knownFiles.remove(file);

    // The removed file does not reference other files anymore.
    file._kind?.dispose();

    // Release this unlinked data.
    unlinkedUnitStore.release(file.unlinkedKey);

    // Recursively remove files that reference the removed file.
    for (var reference in file.referencingFiles.toList()) {
      changeFile(reference.path, removedFiles);
    }
  }

  /// Collected files that transitively reference a file with the [path].
  /// These files are potentially affected by the change.
  void collectAffected(String path, Set<FileState> affected) {
    collectAffected(FileState file) {
      if (affected.add(file)) {
        for (var other in file.referencingFiles) {
          collectAffected(other);
        }
      }
    }

    var file = _pathToFile[path];
    if (file != null) {
      collectAffected(file);
    }
  }

  /// When printing the state for testing, we want to see all files.
  @visibleForTesting
  void discoverReferencedFiles() {
    while (true) {
      var fileCount = _pathToFile.length;
      for (var file in _pathToFile.values.toList()) {
        file.kind.discoverReferencedFiles();
      }
      if (_pathToFile.length == fileCount) {
        break;
      }
    }
  }

  /// Notifies this object that it is about to be discarded.
  ///
  /// Returns the keys of the artifacts that are no longer used.
  Set<String> dispose() {
    var result = <String>{};
    for (var file in _pathToFile.values) {
      result.add(file._unlinkedKey!);
    }
    _pathToFile.clear();
    _uriToFile.clear();
    knownFiles.clear();
    return result;
  }

  FileState? getExisting(File file) {
    return _pathToFile[file.path];
  }

  FileState? getExistingFromPath(String path) {
    return _pathToFile[path];
  }

  FileState? getExistingFromUri(Uri uri) {
    return _uriToFile[uri];
  }

  /// Return the [FileState] for the given absolute [path]. The returned file
  /// has the last known state since if was last refreshed.
  FileState getFileForPath(String path) {
    var file = _pathToFile[path];
    if (file == null) {
      File resource = resourceProvider.getFile(path);
      Uri uri = _sourceFactory.pathToUri(path)!;
      file = _newFile(resource, path, uri);
    }
    return file;
  }

  /// The given [uri] must be absolute.
  ///
  /// If [uri] corresponds to a library from the summary store, return a
  /// [UriResolutionExternalLibrary].
  ///
  /// Otherwise the [uri] is resolved to a file, and the corresponding
  /// [FileState] is returned. Might be `null` if the [uri] cannot be resolved
  /// to a file, for example because it is invalid (e.g. a `package:` URI
  /// without a package name), or we don't know this package. The returned
  /// file has the last known state since if was last refreshed.
  UriResolution? getFileForUri(
    Uri uri, {
    OperationPerformanceImpl? performance,
  }) {
    var uriSource = _sourceFactory.forUri2(uri);

    // If the external store has this URI, create a stub file for it.
    // We are given all required unlinked and linked summaries for it.
    if (uriSource is InSummarySource) {
      return UriResolutionExternalLibrary(uriSource);
    }

    FileState? file = _uriToFile[uri];
    if (file == null) {
      // If the URI cannot be resolved, for example because the factory
      // does not understand the scheme, return the unresolved file instance.
      if (uriSource == null) {
        return null;
      }

      String path = uriSource.fullName;

      // Check if already resolved to this path via different URI.
      // That different URI must be the canonical one.
      file = _pathToFile[path];
      if (file != null) {
        return UriResolutionFile(file);
      }

      File resource = resourceProvider.getFile(path);

      var rewrittenUri = rewriteToCanonicalUri(_sourceFactory, uri);
      if (rewrittenUri == null) {
        return null;
      }

      file = _newFile(
        resource,
        path,
        rewrittenUri,
        performance: performance,
      );
    }
    return UriResolutionFile(file);
  }

  /// Returns a list of files whose contents contains the given string.
  /// Generated files are not included in the search.
  List<String> getFilesContaining(String value) {
    var result = <String>[];
    _pathToFile.forEach((path, file) {
      // TODO(scheglov): tests for excluding generated
      if (!isGenerated(path)) {
        if (file.content.contains(value)) {
          result.add(path);
        }
      }
    });
    return result;
  }

  /// Return files where the given [name] is subtyped, i.e. used in `extends`,
  /// `with` or `implements` clauses.
  Set<FileState>? getFilesSubtypingName(String name) {
    return _subtypedNameToFiles[name];
  }

  /// Return files that have a top-level declaration with the [name].
  List<FileState> getFilesWithTopLevelDeclarations(String name) {
    var result = <FileState>[];
    for (var file in _pathToFile.values) {
      if (file.unlinked2.topLevelDeclarations.contains(name)) {
        result.add(file);
      }
    }
    return result;
  }

  /// Return `true` if there is a URI that can be resolved to the [path].
  ///
  /// When a file exists, but for the URI that corresponds to the file is
  /// resolved to another file, e.g. a generated one in Blaze, Gn, etc, we
  /// cannot analyze the original file.
  bool hasUri(String path) {
    bool? flag = _hasUriForPath[path];
    if (flag == null) {
      Uri uri = _sourceFactory.pathToUri(path)!;
      Source? uriSource = _sourceFactory.forUri2(uri);
      flag = uriSource?.fullName == path;
      _hasUriForPath[path] = flag;
    }
    return flag;
  }

  /// Remove the file with the given [path].
  void removeFile(String path) {
    _clearFiles();
  }

  /// Computes the set of [FileState]'s used/not used to analyze the given
  /// [paths]. Removes the [FileState]'s of the files not used for analysis from
  /// the cache. Returns the set of unused [FileState]'s.
  Set<FileState> removeUnusedFiles(List<String> paths) {
    var referenced = <FileState>{};
    for (var path in paths) {
      var library = _pathToFile[path]?.kind.library;
      library?.collectTransitive(referenced);
    }

    var removed = <FileState>{};
    for (var file in _pathToFile.values.toList()) {
      if (!referenced.contains(file)) {
        changeFile(file.path, removed);
      }
    }

    return removed;
  }

  /// Clear all [FileState] data - all maps from path or URI, etc.
  void _clearFiles() {
    _uriToFile.clear();
    knownFilePaths.clear();
    knownFiles.clear();
    _hasUriForPath.clear();
    _pathToFile.clear();
    _subtypedNameToFiles.clear();
    _libraryNameToFiles.clear();
    // TODO(jensj): If we use finalizers we shouldn't clear.
    unlinkedUnitStore.clear();
  }

  AnalysisOptionsImpl _getAnalysisOptions(File file) =>
      _analysisOptionsMap.getOptions(file);

  FeatureSet _getFeatureSet(
    String path,
    Uri uri,
    WorkspacePackage? workspacePackage,
    AnalysisOptionsImpl analysisOptions,
  ) {
    var workspacePackageExperiments = workspacePackage?.enabledExperiments;
    if (workspacePackageExperiments != null) {
      return featureSetProvider.featureSetForExperiments(
        workspacePackageExperiments,
      );
    }

    return featureSetProvider.getFeatureSet(path, uri,
        contextFeatures: analysisOptions.contextFeatures,
        nonPackageFeatureSet: analysisOptions.nonPackageFeatureSet);
  }

  Version _getLanguageVersion(
    String path,
    Uri uri,
    WorkspacePackage? workspacePackage,
    AnalysisOptionsImpl analysisOptions,
  ) {
    var workspaceLanguageVersion = workspacePackage?.languageVersion;
    if (workspaceLanguageVersion != null) {
      return workspaceLanguageVersion;
    }

    return featureSetProvider.getLanguageVersion(path, uri,
        nonPackageLanguageVersion: analysisOptions.nonPackageLanguageVersion);
  }

  FileState _newFile(
    File resource,
    String path,
    Uri uri, {
    OperationPerformanceImpl? performance,
  }) {
    FileSource uriSource = FileSource(resource, uri);
    WorkspacePackage? workspacePackage = _workspace?.findPackageFor(path);
    AnalysisOptionsImpl analysisOptions = _getAnalysisOptions(resource);
    FeatureSet featureSet =
        _getFeatureSet(path, uri, workspacePackage, analysisOptions);
    Version packageLanguageVersion =
        _getLanguageVersion(path, uri, workspacePackage, analysisOptions);
    var file = FileState._(this, path, uri, uriSource, workspacePackage,
        featureSet, packageLanguageVersion, analysisOptions);
    _pathToFile[path] = file;
    _uriToFile[uri] = file;
    knownFilePaths.add(path);
    knownFiles.add(file);
    fileStamp++;

    performance ??= newFileOperationPerformance;
    performance ??= OperationPerformanceImpl('<root>');
    performance.run('fileState.refresh', (performance) {
      file.refresh(
        performance: performance,
      );
    });

    onNewFile(file);
    return file;
  }
}

@visibleForTesting
class FileSystemStateTestView {
  final FileSystemState state;

  FileSystemStateTestView(this.state);

  Map<Uri, FileState> get uriToFile => state._uriToFile;
}

class FileSystemTestData {
  final Map<File, FileTestData> files = {};

  FileTestData forFile(File file, Uri uri) {
    return files[file] ??= FileTestData._(file, uri);
  }
}

class FileTestData {
  final File file;
  final Uri uri;

  /// We add the key every time we get unlinked data from the byte store.
  final List<String> unlinkedKeyGet = [];

  /// We add the key every time we put unlinked data into the byte store.
  final List<String> unlinkedKeyPut = [];

  FileTestData._(this.file, this.uri);

  @override
  int get hashCode => file.hashCode;

  @override
  bool operator ==(Object other) {
    return other is FileTestData && other.file == file && other.uri == uri;
  }
}

/// Precomputed properties of a file URI, used because [Uri] is relatively
/// expensive to work with, if we do this thousand times.
class FileUriProperties {
  static const int _isDart = 1 << 0;
  static const int _isDartInternal = 1 << 1;
  static const int _isSrc = 1 << 2;

  final int _flags;
  final String? packageName;

  factory FileUriProperties(Uri uri) {
    if (uri.isScheme('dart')) {
      var dartName = uri.pathSegments.firstOrNull;
      return FileUriProperties._dart(
        isInternal: dartName != null && dartName.startsWith('_'),
      );
    } else if (uri.isScheme('package')) {
      var segments = uri.pathSegments;
      if (segments.length >= 2) {
        return FileUriProperties._package(
          packageName: segments[0],
          isSrc: segments[1] == 'src',
        );
      }
    }
    return const FileUriProperties._unknown();
  }

  const FileUriProperties._dart({
    required bool isInternal,
  })  : _flags = _isDart | (isInternal ? _isDartInternal : 0),
        packageName = null;

  FileUriProperties._package({
    required this.packageName,
    required bool isSrc,
  }) : _flags = isSrc ? _isSrc : 0;

  const FileUriProperties._unknown()
      : _flags = 0,
        packageName = null;

  bool get isDart => (_flags & _isDart) != 0;

  bool get isDartInternal => (_flags & _isDartInternal) != 0;

  bool get isSrc => (_flags & _isSrc) != 0;
}

/// Information about a single `export` directive.
final class LibraryExportState<U extends DirectiveUri> extends DirectiveState {
  final UnlinkedLibraryExportDirective unlinked;
  final U selectedUri;
  final DirectiveUris uris;

  LibraryExportState({
    required super.container,
    required this.unlinked,
    required this.selectedUri,
    required this.uris,
  });

  /// If [exportedSource] corresponds to a library, returns it.
  Source? get exportedLibrarySource => null;

  /// Returns a [Source] that is referenced by this directive. If there are
  /// configurations, selects the one which satisfies the conditions.
  ///
  /// Returns `null` if the selected URI is not valid, or cannot be resolved
  /// into a [Source].
  Source? get exportedSource => null;
}

/// [LibraryExportWithUri] that has a valid URI that references a file.
final class LibraryExportWithFile
    extends LibraryExportWithUri<DirectiveUriWithFile> {
  LibraryExportWithFile({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  }) {
    exportedFile.referencingFiles.add(container.file);
  }

  FileState get exportedFile => selectedUri.file;

  /// Returns [exportedFile] if it is a library.
  LibraryFileKind? get exportedLibrary {
    var kind = exportedFile.kind;
    if (kind is LibraryFileKind) {
      return kind;
    }
    return null;
  }

  @override
  FileSource? get exportedLibrarySource {
    if (exportedFile.kind is LibraryFileKind) {
      return exportedSource;
    }
    return null;
  }

  @override
  FileSource get exportedSource => exportedFile.source;

  @override
  void dispose() {
    exportedFile.referencingFiles.remove(container.file);
  }
}

/// [LibraryExportWithUri] with a URI that resolves to [InSummarySource].
final class LibraryExportWithInSummarySource
    extends LibraryExportWithUri<DirectiveUriWithInSummarySource> {
  LibraryExportWithInSummarySource({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });

  @override
  InSummarySource? get exportedLibrarySource {
    if (exportedSource.kind == InSummarySourceKind.library) {
      return exportedSource;
    } else {
      return null;
    }
  }

  @override
  InSummarySource get exportedSource => selectedUri.source;
}

/// [LibraryExportState] that has a valid URI.
final class LibraryExportWithUri<U extends DirectiveUriWithUri>
    extends LibraryExportWithUriStr<U> {
  LibraryExportWithUri({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });
}

/// [LibraryExportState] that has a relative URI string.
final class LibraryExportWithUriStr<U extends DirectiveUriWithString>
    extends LibraryExportState<U> {
  LibraryExportWithUriStr({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });
}

class LibraryFileKind extends LibraryOrAugmentationFileKind {
  /// The name of the library from the `library` directive.
  /// Or `null` if no `library` directive.
  final String? name;

  /// The [FileKind] that created this object in [FileKind.asLibrary].
  final FileKind? recoveredFrom;

  /// The synthetic part includes added to [partIncludes] for the macro
  /// application results of this library. It is filled only if the library
  /// uses any macros.
  List<PartIncludeWithFile> _macroPartIncludes = const [];

  /// The cache for [apiSignature].
  Uint8List? _apiSignature;

  LibraryCycle? _libraryCycle;

  LibraryFileKind({
    required super.file,
    required this.name,
    this.recoveredFrom,
  }) {
    file._fsState._libraryNameToFiles.add(this);
  }

  /// The unlinked API signature of all library files.
  Uint8List get apiSignature {
    if (_apiSignature case var apiSignature?) {
      return apiSignature;
    }

    var builder = ApiSignature();

    var sortedFiles = files.sortedBy((file) => file.path);
    for (var file in sortedFiles) {
      builder.addBytes(file.apiSignature);
    }

    return _apiSignature = builder.toByteList();
  }

  /// The list of files that this library consists of:
  /// - the library file itself;
  /// - the part files, in the depth-first pre-order order.
  List<FileKind> get fileKinds {
    var result = <FileKind>[];

    void visitParts(FileKind kind) {
      result.add(kind);
      for (var directive in kind.partIncludes) {
        if (directive is PartIncludeWithFile) {
          var includedPart = directive.includedPart;
          if (includedPart != null) {
            visitParts(includedPart);
          }
        }
      }
    }

    visitParts(this);
    return result;
  }

  /// The files extracted from [fileKinds].
  List<FileState> get files {
    return fileKinds.map((kind) => kind.file).toList();
  }

  LibraryCycle? get internal_libraryCycle => _libraryCycle;

  @override
  LibraryFileKind get library => this;

  /// Return the [LibraryCycle] this file belongs to, even if it consists of
  /// just this file.  If the library cycle is not known yet, compute it.
  LibraryCycle get libraryCycle {
    if (_libraryCycle == null) {
      computeLibraryCycle(file._fsState._saltForElements, this);
    }

    return _libraryCycle!;
  }

  @override
  List<UnlinkedLibraryImportDirective> get _unlinkedDocImports {
    return file.unlinked2.libraryDirective?.docImports ?? const [];
  }

  /// [partialIndex] is provided while we run phases of macros, and accumulate
  /// results in separate augmentation libraries with names `foo.macroX.dart`.
  /// For the merged augmentation we pass `null` here, so a single
  /// `foo.macro.dart` is created.
  PartIncludeWithFile addMacroPart(
    String code, {
    required int? partialIndex,
    required OperationPerformanceImpl performance,
  }) {
    var pathContext = file._fsState.pathContext;
    var libraryFileName = pathContext.basename(file.path);

    String macroFileName = pathContext.setExtension(
      libraryFileName,
      '.macro${partialIndex != null ? '$partialIndex' : ''}.dart',
    );

    var macroRelativeUri = uriCache.parse(macroFileName);
    var macroUri = uriCache.resolveRelative(file.uri, macroRelativeUri);

    var contentBytes = utf8.encoder.convert(code);
    var hashBytes = md5.convert(contentBytes).bytes;
    var hashStr = hex.encode(hashBytes);
    var fileContent = StoredFileContent(
      content: code,
      contentHash: hashStr,
      exists: true,
    );

    // This content will be consumed by the next `refresh()`.
    // This might happen during `getFileForUri()` below.
    // Or this happens during the explicit `refresh()`, more below.
    file._fsState._macroFileContent = fileContent;

    var macroFileResolution = performance.run(
      'getFileForUri',
      (performance) {
        return file._fsState.getFileForUri(
          macroUri,
          performance: performance,
        );
      },
    );
    macroFileResolution as UriResolutionFile;
    var macroFile = macroFileResolution.file;

    // If the file existed, and has different content, force `refresh()`.
    // This will ensure that the file has the required content.
    if (macroFile.content != fileContent.content) {
      macroFile.refresh();
    }

    // We are done with the file, stop forcing its content.
    file._fsState._macroFileContent = null;

    var partUri = DirectiveUriWithFile(
      relativeUriStr: macroFileName,
      relativeUri: macroRelativeUri,
      file: macroFile,
    );

    var partInclude = PartIncludeWithFile(
      container: this,
      unlinked: UnlinkedPartDirective(
        configurations: [],
        uri: macroFileName,
      ),
      selectedUri: partUri,
      uris: DirectiveUris(
        primary: partUri,
        configurations: [],
        selected: partUri,
      ),
    );
    _macroPartIncludes = [..._macroPartIncludes, partInclude].toFixedList();

    // We cannot add, because the list is not growable.
    _partIncludes = [...partIncludes, partInclude].toFixedList();

    return partInclude;
  }

  @override
  void dispose() {
    file._fsState._libraryNameToFiles.remove(this);
    super.dispose();
  }

  @override
  void disposeLibraryCycle() {
    _libraryCycle?.dispose();
    _libraryCycle = null;
  }

  /// When the library cycle that contains this library is disposed, the
  /// macros might potentially generate different code, or no code at all. So,
  /// we discard the existing macro augmentation library, it will be rebuilt
  /// during linking.
  void disposeMacroAugmentations({
    required bool disposeFiles,
  }) {
    for (var macroInclude in _macroPartIncludes) {
      _partIncludes = partIncludes.withoutLast.toFixedList();
      if (disposeFiles) {
        _disposeMacroFile(macroInclude.includedFile);
      }
    }
    _macroPartIncludes = const [];
  }

  void internal_setLibraryCycle(LibraryCycle? cycle) {
    _libraryCycle = cycle;
    // Keep the merged augmentation file, as we do for normal files.
    disposeMacroAugmentations(disposeFiles: false);
  }

  void removeLastMacroPartInclude() {
    _macroPartIncludes = _macroPartIncludes.withoutLast.toFixedList();
    _partIncludes = partIncludes.withoutLast.toFixedList();
  }

  @override
  String toString() {
    return 'LibraryFileKind($file)';
  }

  void _disposeMacroFile(FileState macroFile) {
    macroFile.kind.dispose();
    file._fsState._pathToFile.remove(macroFile.path);
    file._fsState._uriToFile.remove(macroFile.uri);
    file._fsState.knownFiles.remove(macroFile);
  }
}

/// Information about a single `import` directive.
final class LibraryImportState<U extends DirectiveUri> extends DirectiveState {
  final UnlinkedLibraryImportDirective unlinked;
  final U selectedUri;
  final DirectiveUris uris;

  LibraryImportState({
    required super.container,
    required this.unlinked,
    required this.selectedUri,
    required this.uris,
  });

  /// If [importedSource] corresponds to a library, returns it.
  Source? get importedLibrarySource => null;

  /// Returns a [Source] that is referenced by this directive. If there are
  /// configurations, selects the one which satisfies the conditions.
  ///
  /// Returns `null` if the selected URI is not valid, or cannot be resolved
  /// into a [Source].
  Source? get importedSource => null;

  bool get isDocImport => unlinked.isDocImport;

  bool get isSyntheticDartCore => unlinked.isSyntheticDartCore;
}

/// [LibraryImportWithUri] that has a valid URI that references a file.
final class LibraryImportWithFile
    extends LibraryImportWithUri<DirectiveUriWithFile> {
  LibraryImportWithFile({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  }) {
    importedFile.referencingFiles.add(container.file);
  }

  FileState get importedFile => selectedUri.file;

  /// Returns [importedFile] if it is a library.
  LibraryFileKind? get importedLibrary {
    var kind = importedFile.kind;
    if (kind is LibraryFileKind) {
      return kind;
    }
    return null;
  }

  @override
  FileSource? get importedLibrarySource {
    if (importedFile.kind is LibraryFileKind) {
      return importedSource;
    }
    return null;
  }

  @override
  FileSource get importedSource => importedFile.source;

  @override
  void dispose() {
    importedFile.referencingFiles.remove(container.file);
  }
}

/// [LibraryImportWithUri] with a URI that resolves to [InSummarySource].
final class LibraryImportWithInSummarySource
    extends LibraryImportWithUri<DirectiveUriWithInSummarySource> {
  LibraryImportWithInSummarySource({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });

  @override
  InSummarySource? get importedLibrarySource {
    if (importedSource.kind == InSummarySourceKind.library) {
      return importedSource;
    } else {
      return null;
    }
  }

  @override
  InSummarySource get importedSource => selectedUri.source;
}

/// [LibraryImportState] that has a valid URI.
final class LibraryImportWithUri<U extends DirectiveUriWithUri>
    extends LibraryImportWithUriStr<U> {
  LibraryImportWithUri({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });
}

/// [LibraryImportState] that has a relative URI string.
final class LibraryImportWithUriStr<U extends DirectiveUriWithString>
    extends LibraryImportState<U> {
  LibraryImportWithUriStr({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });
}

abstract class LibraryOrAugmentationFileKind extends FileKind {
  LibraryOrAugmentationFileKind({
    required super.file,
  });
}

class ParsedFileState {
  final String code;
  final CompilationUnitImpl unit;
  final List<AnalysisError> errors;

  ParsedFileState({
    required this.code,
    required this.unit,
    required this.errors,
  });
}

class ParsedFileStateCache {
  final Map<FileState, ParsedFileState> _map = Map.identity();

  void clear() {
    _map.clear();
  }

  ParsedFileState? get(FileState file) {
    return _map[file];
  }

  void put(FileState file, ParsedFileState result) {
    _map[file] = result;
  }

  void remove(FileState file) {
    _map.remove(file);
  }
}

/// The file has `part of` directive.
sealed class PartFileKind extends FileKind {
  PartFileKind({
    required super.file,
  });

  /// Returns `true` if the `part of` directive confirms the [container].
  bool isPartOf(FileKind container);
}

/// Information about a single `part` directive.
final class PartIncludeState<U extends DirectiveUri> extends DirectiveState {
  final UnlinkedPartDirective unlinked;
  final U selectedUri;
  final DirectiveUris uris;

  PartIncludeState({
    required super.container,
    required this.unlinked,
    required this.selectedUri,
    required this.uris,
  });
}

/// [PartIncludeWithUri] that has a valid URI that references a file.
final class PartIncludeWithFile
    extends PartIncludeWithUri<DirectiveUriWithFile> {
  PartIncludeWithFile({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  }) {
    includedFile.referencingFiles.add(container.file);
  }

  FileState get includedFile => selectedUri.file;

  /// If [includedFile] is a [PartFileKind], and it confirms that it
  /// is a part of the [container], returns the [includedFile].
  PartFileKind? get includedPart {
    var kind = includedFile.kind;
    if (kind is PartFileKind && kind.isPartOf(container)) {
      return kind;
    }
    return null;
  }

  @override
  void dispose() {
    includedFile.referencingFiles.remove(container.file);
  }
}

/// [PartIncludeState] that has a valid URI.
final class PartIncludeWithUri<U extends DirectiveUriWithUri>
    extends PartIncludeWithUriStr<U> {
  PartIncludeWithUri({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });
}

/// [PartIncludeState] that has a relative URI string.
final class PartIncludeWithUriStr<U extends DirectiveUriWithString>
    extends PartIncludeState<U> {
  PartIncludeWithUriStr({
    required super.container,
    required super.unlinked,
    required super.selectedUri,
    required super.uris,
  });
}

/// The file has `part of name` directive.
class PartOfNameFileKind extends PartFileKind {
  final UnlinkedPartOfNameDirective unlinked;

  PartOfNameFileKind({
    required super.file,
    required this.unlinked,
  });

  /// Libraries with the same name as in [unlinked].
  List<LibraryFileKind> get libraries {
    var files = file._fsState._libraryNameToFiles;
    return files[unlinked.name] ?? [];
  }

  /// If there are libraries that include this file as a part, return the
  /// first one as if sorted by path.
  @override
  LibraryFileKind? get library {
    discoverLibraries();

    LibraryFileKind? result;
    for (var library in libraries) {
      if (library.hasPart(this)) {
        if (result == null) {
          result = library;
        } else if (library.file.path.compareTo(result.file.path) < 0) {
          result = library;
        }
      }
    }
    return result;
  }

  @override
  List<UnlinkedLibraryImportDirective> get _unlinkedDocImports {
    return unlinked.docImports;
  }

  @visibleForTesting
  void discoverLibraries() {
    if (libraries.isEmpty) {
      var resourceProvider = file._fsState.resourceProvider;
      var pathContext = resourceProvider.pathContext;

      var siblings = <Resource>[];
      try {
        siblings = file.resource.parent.getChildren();
      } catch (_) {}

      for (var sibling in siblings) {
        if (file_paths.isDart(pathContext, sibling.path)) {
          file._fsState.getFileForPath(sibling.path);
        }
      }
    }
  }

  @override
  bool isPartOf(FileKind container) {
    return container is LibraryFileKind && unlinked.name == container.name;
  }
}

/// The file has `part of URI` directive.
abstract class PartOfUriFileKind extends PartFileKind {
  final UnlinkedPartOfUriDirective unlinked;

  PartOfUriFileKind({
    required super.file,
    required this.unlinked,
  });

  @override
  List<UnlinkedLibraryImportDirective> get _unlinkedDocImports {
    return unlinked.docImports;
  }
}

/// The file has `part of URI` directive, and the URI can be resolved.
class PartOfUriKnownFileKind extends PartOfUriFileKind {
  final FileState uriFile;

  PartOfUriKnownFileKind({
    required super.file,
    required super.unlinked,
    required this.uriFile,
  });

  /// If the [uriFile] has `part` with this file, returns [uriFile].
  /// Otherwise, this file is not a valid part, returns `null`.
  FileKind? get includingContainer {
    var uriKind = uriFile.kind;
    if (uriKind.hasPart(this)) {
      return uriKind;
    }
    return null;
  }

  @override
  LibraryFileKind? get library {
    var visited = Set<FileKind>.identity();
    var current = includingContainer;
    while (current != null && visited.add(current)) {
      switch (current) {
        case LibraryFileKind():
          return current;
        case PartOfUriKnownFileKind():
          current = current.includingContainer;
        default:
          return null;
      }
    }
    return null;
  }

  @override
  bool isPartOf(FileKind container) {
    return uriFile == container.file;
  }
}

/// The file has `part of URI` directive, and the URI cannot be resolved.
class PartOfUriUnknownFileKind extends PartOfUriFileKind {
  PartOfUriUnknownFileKind({
    required super.file,
    required super.unlinked,
  });

  @override
  LibraryFileKind? get library => null;

  @override
  bool isPartOf(FileKind container) => false;
}

class StoredFileContent implements FileContent {
  @override
  final String content;

  @override
  final String contentHash;

  @override
  final bool exists;

  StoredFileContent({
    required this.content,
    required this.contentHash,
    required this.exists,
  });
}

class StoredFileContentStrategy implements FileContentStrategy {
  final FileContentCache _fileContentCache;

  StoredFileContentStrategy(this._fileContentCache);

  @override
  FileContent get(String path) {
    var fileContent = _fileContentCache.get(path);
    return StoredFileContent(
      content: fileContent.content,
      contentHash: fileContent.contentHash,
      exists: fileContent.exists,
    );
  }

  /// The file with the given [path] might have changed, so ensure that it is
  /// read the next time it is refreshed.
  void markFileForReading(String path) {
    _fileContentCache.invalidate(path);
  }
}

sealed class UriResolution {}

final class UriResolutionExternalLibrary extends UriResolution {
  final InSummarySource source;

  UriResolutionExternalLibrary(this.source);
}

final class UriResolutionFile extends UriResolution {
  final FileState file;

  UriResolutionFile(this.file);
}

class _LibraryNameToFiles {
  final Map<String, List<LibraryFileKind>> _map = {};

  List<LibraryFileKind>? operator [](String name) {
    return _map[name];
  }

  /// If [kind] is a named library, register it.
  void add(LibraryFileKind kind) {
    var name = kind.name;
    if (name != null) {
      var libraries = _map[name] ??= [];
      libraries.add(kind);
    }
  }

  void clear() {
    _map.clear();
  }

  /// If [kind] is a named library, unregister it.
  void remove(LibraryFileKind kind) {
    var name = kind.name;
    if (name != null) {
      var libraries = _map[name];
      if (libraries != null) {
        libraries.remove(kind);
        if (libraries.isEmpty) {
          _map.remove(name);
        }
      }
    }
  }
}

extension on List<DirectiveState> {
  void disposeAll() {
    for (var directive in this) {
      directive.dispose();
    }
  }
}

extension IterableOrFileStateExtension on Iterable<FileState> {
  List<File> get resources {
    return map((file) => file.resource).toList();
  }
}
