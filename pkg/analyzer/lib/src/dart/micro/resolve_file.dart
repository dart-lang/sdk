// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/cache.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show ErrorEncoding;
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/micro/analysis_context.dart';
import 'package:analyzer/src/dart/micro/cider_byte_store.dart';
import 'package:analyzer/src/dart/micro/library_analyzer.dart';
import 'package:analyzer/src/dart/micro/library_graph.dart';
import 'package:analyzer/src/dart/micro/utils.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

class CiderSearchInfo {
  final CharacterLocation startPosition;
  final int length;
  final MatchKind kind;

  CiderSearchInfo(this.startPosition, this.length, this.kind);

  @override
  bool operator ==(Object other) =>
      other is CiderSearchInfo &&
      startPosition == other.startPosition &&
      length == other.length &&
      kind == other.kind;
}

class CiderSearchMatch {
  final String path;
  final List<CiderSearchInfo> references;

  CiderSearchMatch(this.path, this.references);

  @override
  bool operator ==(Object other) =>
      other is CiderSearchMatch &&
      path == other.path &&
      const ListEquality<CiderSearchInfo>()
          .equals(references, other.references);

  @override
  String toString() {
    return '($path, $references)';
  }
}

class FileContext {
  final AnalysisOptionsImpl analysisOptions;
  final FileState file;

  FileContext(this.analysisOptions, this.file);
}

class FileResolver {
  final PerformanceLog logger;
  final ResourceProvider resourceProvider;
  CiderByteStore byteStore;
  final SourceFactory sourceFactory;

  /// A function that returns the digest for a file as a String. The function
  /// returns a non null value, can return an empty string if file does
  /// not exist/has no contents.
  final String Function(String path) getFileDigest;

  /// A function that returns true if the given file path is likely to be that
  /// of a file that is generated.
  final bool Function(String path)? isGenerated;

  /// A function that fetches the given list of files. This function can be used
  /// to batch file reads in systems where file fetches are expensive.
  final void Function(List<String> paths)? prefetchFiles;

  final Workspace workspace;

  /// This field gets value only during testing.
  FileResolverTestView? testView;

  FileSystemState? fsState;

  MicroContextObjects? contextObjects;

  LibraryContext? libraryContext;

  /// List of keys for cache elements that are invalidated. Track elements that
  /// are invalidated during [changeFile]. Used in [releaseAndClearRemovedIds]
  /// to release the cache items and is then cleared.
  final Set<String> removedCacheKeys = {};

  /// The cache of file results, cleared on [changeFile].
  ///
  /// It is used to allow assists and fixes without resolving the same file
  /// multiple times, as we compute more than one assist, or fixes when there
  /// are more than one error on a line.
  @visibleForTesting
  final Map<String, ResolvedLibraryResult> cachedResults = {};

  /// The cache of error results.
  final Cache<String, Uint8List> _errorResultsCache =
      Cache(128 * 1024, (bytes) => bytes.length);

  FileResolver({
    required this.logger,
    required this.resourceProvider,
    required this.sourceFactory,
    required this.getFileDigest,
    required this.prefetchFiles,
    required this.workspace,
    this.isGenerated,
    required this.byteStore,
  });

  @Deprecated('Use the unnamed constructor instead')
  FileResolver.from({
    required this.logger,
    required this.resourceProvider,
    required this.sourceFactory,
    required this.getFileDigest,
    required this.prefetchFiles,
    required this.workspace,
    this.isGenerated,
    required this.byteStore,
  });

  /// Update the resolver to reflect the fact that the file with the given
  /// [path] was changed. We need to make sure that when this file, of any file
  /// that directly or indirectly referenced it, is resolved, we used the new
  /// state of the file. Updates [removedCacheIds] with the ids of the invalidated
  /// items, used in [releaseAndClearRemovedIds] to release the cache items.
  void changeFile(String path) {
    if (fsState == null) {
      return;
    }

    // Forget all results, anything is potentially affected.
    cachedResults.clear();

    // Remove this file and all files that transitively depend on it.
    var removedFiles = <FileState>[];
    fsState!.changeFile(path, removedFiles);

    // Schedule disposing references to cached unlinked data.
    for (var removedFile in removedFiles) {
      removedCacheKeys.add(removedFile.unlinkedKey);
    }

    // Remove libraries represented by removed files.
    // If we need these libraries later, we will relink and reattach them.
    if (libraryContext != null) {
      libraryContext!.remove(removedFiles, removedCacheKeys);
    }
  }

  /// Collects all the cached artifacts and add all the cache id's for the
  /// removed artifacts to [removedCacheKeys].
  @Deprecated('Use dispose() instead')
  void collectSharedDataIdentifiers() {
    removedCacheKeys.addAll(fsState!.dispose());
    removedCacheKeys.addAll(libraryContext!.dispose());
  }

  /// Notifies this object that it is about to be discarded, so it should
  /// release any shared data.
  void dispose() {
    removedCacheKeys.addAll(fsState!.dispose());
    removedCacheKeys.addAll(libraryContext!.dispose());
    releaseAndClearRemovedIds();
  }

  /// Looks for references to the given Element. All the files currently
  ///  cached by the resolver are searched, generated files are ignored.
  Future<List<CiderSearchMatch>> findReferences2(Element element,
      {OperationPerformanceImpl? performance}) async {
    return logger.runAsync('findReferences for ${element.name}', () async {
      var references = <CiderSearchMatch>[];

      Future<void> collectReferences2(
          String path, OperationPerformanceImpl performance) async {
        await performance.runAsync('collectReferences', (_) async {
          var resolved = await resolve2(path: path);
          var collector = ReferencesCollector(element);
          resolved.unit.accept(collector);
          var matches = collector.references;
          if (matches.isNotEmpty) {
            var lineInfo = resolved.unit.lineInfo;
            references.add(CiderSearchMatch(
                path,
                matches
                    .map((match) => CiderSearchInfo(
                        lineInfo.getLocation(match.offset),
                        match.length,
                        match.matchKind))
                    .toList()));
          }
        });
      }

      performance ??= OperationPerformanceImpl('<default>');
      // TODO(keertip): check if element is named constructor.
      if (element is LocalVariableElement ||
          (element is ParameterElement && !element.isNamed)) {
        await collectReferences2(element.source!.fullName, performance!);
      } else if (element is ImportElement) {
        return await _searchReferences_Import(element);
      } else {
        var result = performance!.run('getFilesContaining', (performance) {
          return fsState!.getFilesContaining(element.displayName);
        });
        for (var filePath in result) {
          await collectReferences2(filePath, performance!);
        }
      }
      return references;
    });
  }

  Future<ErrorsResult> getErrors2({
    required String path,
    OperationPerformanceImpl? performance,
  }) async {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    return logger.runAsync('Get errors for $path', () async {
      var fileContext = getFileContext(
        path: path,
        performance: performance!,
      );
      var file = fileContext.file;

      final errorsSignatureBuilder = ApiSignature();
      errorsSignatureBuilder.addBytes(file.libraryCycle.signature);
      errorsSignatureBuilder.addBytes(file.digest);
      final errorsKey = '${errorsSignatureBuilder.toHex()}.errors';

      final List<AnalysisError> errors;
      final bytes = _errorResultsCache.get(errorsKey);
      if (bytes != null) {
        var data = CiderUnitErrors.fromBuffer(bytes);
        errors = data.errors.map((error) {
          return ErrorEncoding.decode(file.source, error)!;
        }).toList();
      } else {
        var unitResult = await resolve2(
          path: path,
          performance: performance,
        );
        errors = unitResult.errors;

        _errorResultsCache.put(
          errorsKey,
          CiderUnitErrorsBuilder(
            errors: errors.map(ErrorEncoding.encode).toList(),
          ).toBuffer(),
        );
      }

      return ErrorsResultImpl(
        contextObjects!.analysisSession,
        path,
        file.uri,
        file.lineInfo,
        false, // isPart
        errors,
      );
    });
  }

  FileContext getFileContext({
    required String path,
    required OperationPerformanceImpl performance,
  }) {
    return performance.run('fileContext', (performance) {
      var analysisOptions = performance.run('analysisOptions', (performance) {
        return _getAnalysisOptions(
          path: path,
          performance: performance,
        );
      });

      performance.run('createContext', (_) {
        _createContext(path, analysisOptions);
      });

      var file = performance.run('fileForPath', (performance) {
        return fsState!.getFileForPath(
          path: path,
          performance: performance,
        );
      });

      return FileContext(analysisOptions, file);
    });
  }

  /// Return files that have a top-level declaration with the [name].
  List<FileState> getFilesWithTopLevelDeclarations(String name) {
    final fsState = this.fsState;
    if (fsState == null) {
      return const [];
    }
    return fsState.getFilesWithTopLevelDeclarations(name);
  }

  Future<LibraryElement> getLibraryByUri2({
    required String uriStr,
    OperationPerformanceImpl? performance,
  }) async {
    performance ??= OperationPerformanceImpl('<default>');

    var uri = Uri.parse(uriStr);
    var path = sourceFactory.forUri2(uri)?.fullName;

    if (path == null) {
      throw ArgumentError('$uri cannot be resolved to a file.');
    }

    var fileContext = getFileContext(
      path: path,
      performance: performance,
    );
    var file = fileContext.file;

    if (file.partOfLibrary != null) {
      throw ArgumentError('$uri is not a library.');
    }

    await performance.runAsync('libraryContext', (performance) async {
      await libraryContext!.load(
        targetLibrary: file,
        performance: performance,
      );
    });

    return libraryContext!.elementFactory.libraryOfUri2(uri);
  }

  String getLibraryLinkedSignature({
    required String path,
    required OperationPerformanceImpl performance,
  }) {
    _throwIfNotAbsoluteNormalizedPath(path);

    var file = fsState!.getFileForPath(
      path: path,
      performance: performance,
    );

    return file.libraryCycle.signatureStr;
  }

  /// Ensure that libraries necessary for resolving [path] are linked.
  ///
  /// Libraries are linked in library cycles, from the bottom to top, so that
  /// when we link a cycle, everything it transitively depends is ready. We
  /// load newly linked libraries from bytes, and when we link a new library
  /// cycle we partially resynthesize AST and elements from previously
  /// loaded libraries.
  ///
  /// But when we are done linking libraries, and want to resolve just the
  /// very top library that transitively depends on the whole dependency
  /// tree, this library will not reference as many elements in the
  /// dependencies as we needed for linking. Most probably it references
  /// elements from directly imported libraries, and a couple of layers below.
  /// So, keeping all previously resynthesized data is usually a waste.
  ///
  /// This method ensures that we discard the libraries context, with all its
  /// partially resynthesized data, and so prepare for loading linked summaries
  /// from bytes, which will be done by [getErrors2]. It is OK for it to
  /// spend some more time on this.
  Future<void> linkLibraries2({
    required String path,
  }) async {
    _throwIfNotAbsoluteNormalizedPath(path);

    var performance = OperationPerformanceImpl('<unused>');

    var fileContext = getFileContext(
      path: path,
      performance: performance,
    );
    var file = fileContext.file;
    var libraryFile = file.partOfLibrary ?? file;

    // Load the library, link if necessary.
    await libraryContext!.load(
      targetLibrary: libraryFile,
      performance: performance,
    );

    // Unload libraries, but don't release the linked data.
    // If we are the only consumer of it, we will lose it.
    final linkedKeysToRelease = libraryContext!.unloadAll();

    // Load the library again, the reference count is `>= 2`.
    await libraryContext!.load(
      targetLibrary: libraryFile,
      performance: performance,
    );

    // Release the linked data, the reference count is `>= 1`.
    byteStore.release2(linkedKeysToRelease);
  }

  /// Releases from the cache and clear [removedCacheKeys].
  void releaseAndClearRemovedIds() {
    byteStore.release2(removedCacheKeys);
    removedCacheKeys.clear();
  }

  /// Remove cached [FileState]'s that were not used in the current analysis
  /// session. The list of files analyzed is used to compute the set of unused
  /// [FileState]'s. Adds the cache id's for the removed [FileState]'s to
  /// [removedCacheIds].
  void removeFilesNotNecessaryForAnalysisOf(List<String> files) {
    var removedFiles = fsState!.removeUnusedFiles(files);
    for (var removedFile in removedFiles) {
      removedCacheKeys.add(removedFile.unlinkedKey);
    }
  }

  /// The [completionLine] and [completionColumn] are zero based.
  Future<ResolvedUnitResult> resolve2({
    int? completionLine,
    int? completionColumn,
    required String path,
    OperationPerformanceImpl? performance,
  }) async {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    return logger.runAsync('Resolve $path', () async {
      var fileContext = getFileContext(
        path: path,
        performance: performance!,
      );
      var file = fileContext.file;

      // If we have a `part of` directive, we want to analyze this library.
      // But the library must include the file, so have its element.
      var libraryFile = file;
      var partOfLibrary = file.partOfLibrary;
      if (partOfLibrary != null) {
        if (partOfLibrary.files().ofLibrary.contains(file)) {
          libraryFile = partOfLibrary;
        }
      }

      var libraryResult = await resolveLibrary2(
        completionLine: completionLine,
        completionColumn: completionColumn,
        path: libraryFile.path,
        completionPath: completionLine != null ? path : null,
        performance: performance,
      );
      return libraryResult.units.firstWhere(
        (unitResult) => unitResult.path == path,
      );
    });
  }

  /// The [completionLine] and [completionColumn] are zero based.
  Future<ResolvedLibraryResult> resolveLibrary2({
    int? completionLine,
    int? completionColumn,
    String? completionPath,
    required String path,
    OperationPerformanceImpl? performance,
  }) async {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    var cachedResult = cachedResults[path];
    if (cachedResult != null) {
      return cachedResult;
    }

    return logger.runAsync('Resolve $path', () async {
      var fileContext = getFileContext(
        path: path,
        performance: performance!,
      );
      var file = fileContext.file;

      // If we have a `part of` directive, we want to analyze this library.
      // But the library must include the file, so have its element.
      var libraryFile = file;
      var partOfLibrary = file.partOfLibrary;
      if (partOfLibrary != null) {
        if (partOfLibrary.files().ofLibrary.contains(file)) {
          libraryFile = partOfLibrary;
        }
      }

      int? completionOffset;
      if (completionLine != null && completionColumn != null) {
        var lineOffset = file.lineInfo.getOffsetOfLine(completionLine);
        completionOffset = lineOffset + completionColumn;
      }

      await performance.runAsync('libraryContext', (performance) async {
        await libraryContext!.load(
          targetLibrary: libraryFile,
          performance: performance,
        );
      });

      testView?.addResolvedLibrary(path);

      late Map<FileState, UnitAnalysisResult> results;

      logger.run('Compute analysis results', () {
        var libraryAnalyzer = LibraryAnalyzer(
          fileContext.analysisOptions,
          contextObjects!.declaredVariables,
          sourceFactory,
          (_) => true, // _isLibraryUri
          contextObjects!.analysisContext,
          libraryContext!.elementFactory,
          contextObjects!.inheritanceManager,
          libraryFile,
          (file) => file.getContent(),
        );

        try {
          results = performance!.run('analyze', (performance) {
            return libraryAnalyzer.analyze(
              completionPath: completionOffset != null ? completionPath : null,
              completionOffset: completionOffset,
              performance: performance,
            );
          });
        } catch (exception, stackTrace) {
          var fileContentMap = <String, String>{};
          for (var file in libraryFile.files().ofLibrary) {
            var path = file.path;
            fileContentMap[path] = _getFileContent(path);
          }
          throw CaughtExceptionWithFiles(
            exception,
            stackTrace,
            fileContentMap,
          );
        }
      });

      var resolvedUnits = results.values.map((fileResult) {
        var file = fileResult.file;
        return ResolvedUnitResultImpl(
          contextObjects!.analysisSession,
          file.path,
          file.uri,
          file.exists,
          file.getContent(),
          file.lineInfo,
          file.isPart,
          fileResult.unit,
          fileResult.errors,
        );
      }).toList();

      var libraryUnit = resolvedUnits.first;
      var result = ResolvedLibraryResultImpl(contextObjects!.analysisSession,
          libraryUnit.libraryElement, resolvedUnits);

      if (completionPath == null) {
        cachedResults[path] = result;
      }

      return result;
    });
  }

  /// Make sure that [fsState], [contextObjects], and [libraryContext] are
  /// created and configured with the given [fileAnalysisOptions].
  ///
  /// The [fsState] is not affected by [fileAnalysisOptions].
  ///
  /// The [fileAnalysisOptions] only affect reported diagnostics, but not
  /// elements and types. So, we really need to reconfigure only when we are
  /// going to resolve some files using these new options.
  ///
  /// Specifically, "implicit casts" and "strict inference" affect the type
  /// system. And there are lints that are enabled for one package, but not
  /// for another.
  void _createContext(String path, AnalysisOptionsImpl fileAnalysisOptions) {
    if (contextObjects != null) {
      contextObjects!.analysisOptions = fileAnalysisOptions;
      return;
    }

    var analysisOptions = AnalysisOptionsImpl()
      ..implicitCasts = fileAnalysisOptions.implicitCasts
      ..strictInference = fileAnalysisOptions.strictInference;

    if (fsState == null) {
      var featureSetProvider = FeatureSetProvider.build(
        sourceFactory: sourceFactory,
        resourceProvider: resourceProvider,
        packages: Packages.empty,
        packageDefaultFeatureSet: analysisOptions.contextFeatures,
        nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
        nonPackageDefaultFeatureSet: analysisOptions.nonPackageFeatureSet,
      );

      fsState = FileSystemState(
        resourceProvider,
        byteStore,
        sourceFactory,
        workspace,
        Uint32List(0), // linkedSalt
        featureSetProvider,
        getFileDigest,
        prefetchFiles,
        isGenerated,
      )..testData = testView?.fileSystemTestData;
    }

    if (contextObjects == null) {
      var rootFolder = resourceProvider.getFolder(workspace.root);
      var root = ContextRootImpl(resourceProvider, rootFolder, workspace);
      root.included.add(rootFolder);

      contextObjects = createMicroContextObjects(
        fileResolver: this,
        analysisOptions: analysisOptions,
        sourceFactory: sourceFactory,
        root: root,
        resourceProvider: resourceProvider,
      );

      libraryContext = LibraryContext(
        testView,
        logger,
        resourceProvider,
        byteStore,
        contextObjects!,
      );
    }
  }

  File? _findOptionsFile(Folder folder) {
    for (var current in folder.withAncestors) {
      var file = _getFile(current, file_paths.analysisOptionsYaml);
      if (file != null) {
        return file;
      }
    }
    return null;
  }

  /// Return the analysis options.
  ///
  /// If the [path] is not `null`, read it.
  ///
  /// If the [workspace] is a [WorkspaceWithDefaultAnalysisOptions], get the
  /// default options, if the file exists.
  ///
  /// Otherwise, return the default options.
  AnalysisOptionsImpl _getAnalysisOptions({
    required String path,
    required OperationPerformanceImpl performance,
  }) {
    YamlMap? optionMap;

    var separator = resourceProvider.pathContext.separator;
    var isThirdParty = path
            .contains('${separator}third_party${separator}dart$separator') ||
        path.contains('${separator}third_party${separator}dart_lang$separator');

    File? optionsFile;
    if (!isThirdParty) {
      optionsFile = performance.run('findOptionsFile', (_) {
        var folder = resourceProvider.getFile(path).parent;
        return _findOptionsFile(folder);
      });
    }

    if (optionsFile != null) {
      performance.run('getOptionsFromFile', (_) {
        try {
          var optionsProvider = AnalysisOptionsProvider(sourceFactory);
          optionMap = optionsProvider.getOptionsFromFile(optionsFile!);
        } catch (e) {
          // ignored
        }
      });
    } else {
      var source = performance.run('defaultOptions', (_) {
        if (workspace is WorkspaceWithDefaultAnalysisOptions) {
          if (isThirdParty) {
            return sourceFactory.forUri(
              WorkspaceWithDefaultAnalysisOptions.thirdPartyUri,
            );
          } else {
            return sourceFactory.forUri(
              WorkspaceWithDefaultAnalysisOptions.uri,
            );
          }
        }
        return null;
      });

      if (source != null && source.exists()) {
        performance.run('getOptionsFromFile', (_) {
          try {
            var optionsProvider = AnalysisOptionsProvider(sourceFactory);
            optionMap = optionsProvider.getOptionsFromSource(source);
          } catch (e) {
            // ignored
          }
        });
      }
    }

    var options = AnalysisOptionsImpl();

    if (optionMap != null) {
      performance.run('applyToAnalysisOptions', (_) {
        applyToAnalysisOptions(options, optionMap!);
      });
    }

    if (isThirdParty) {
      options.hint = false;
    }

    return options;
  }

  /// Return the file content, the empty string if any exception.
  String _getFileContent(String path) {
    try {
      return resourceProvider.getFile(path).readAsStringSync();
    } catch (_) {
      return '';
    }
  }

  Future<List<CiderSearchMatch>> _searchReferences_Import(
      ImportElement element) async {
    var results = <CiderSearchMatch>[];
    LibraryElement libraryElement = element.library;
    for (CompilationUnitElement unitElement in libraryElement.units) {
      String unitPath = unitElement.source.fullName;
      var unitResult = await resolve2(path: unitPath);
      var visitor = ImportElementReferencesVisitor(element, unitElement);
      unitResult.unit.accept(visitor);
      var lineInfo = unitResult.lineInfo;
      var infos = visitor.results
          .map((searchResult) => CiderSearchInfo(
              lineInfo.getLocation(searchResult.offset),
              searchResult.length,
              MatchKind.REFERENCE))
          .toList();
      results.add(CiderSearchMatch(unitPath, infos));
    }
    return results;
  }

  void _throwIfNotAbsoluteNormalizedPath(String path) {
    var pathContext = resourceProvider.pathContext;
    if (pathContext.normalize(path) != path) {
      throw ArgumentError(
        'Only normalized paths are supported: $path',
      );
    }
  }

  static File? _getFile(Folder directory, String name) {
    var file = directory.getChildAssumingFile(name);
    return file.exists ? file : null;
  }
}

class FileResolverTestView {
  final FileSystemTestData fileSystemTestData = FileSystemTestData();

  /// Keys: the sorted list of library files.
  final Map<List<File>, LibraryCycleTestData> libraryCycles = LinkedHashMap(
    hashCode: Object.hashAll,
    equals: const ListEquality<File>().equals,
  );

  /// The paths of libraries which were resolved.
  ///
  /// The library path is added every time when it is resolved.
  final List<String> resolvedLibraries = [];

  void addResolvedLibrary(String path) {
    resolvedLibraries.add(path);
  }

  LibraryCycleTestData forCycle(LibraryCycle cycle) {
    final files = cycle.libraries.map((e) => e.resource).toList();
    files.sortBy((file) => file.path);

    return libraryCycles[files] ??= LibraryCycleTestData();
  }
}

class LibraryContext {
  final FileResolverTestView? testData;
  final PerformanceLog logger;
  final ResourceProvider resourceProvider;
  final CiderByteStore byteStore;
  final MicroContextObjects contextObjects;

  Set<LibraryCycle> loadedBundles = Set.identity();

  LibraryContext(
    this.testData,
    this.logger,
    this.resourceProvider,
    this.byteStore,
    this.contextObjects,
  );

  LinkedElementFactory get elementFactory {
    return contextObjects.analysisSession.elementFactory;
  }

  /// Notifies this object that it is about to be discarded.
  ///
  /// Returns the keys of the artifacts that are no longer used.
  Set<String> dispose() {
    return unloadAll();
  }

  /// Load data required to access elements of the given [targetLibrary].
  Future<void> load({
    required FileState targetLibrary,
    required OperationPerformanceImpl performance,
  }) async {
    var librariesLinked = 0;
    var librariesLinkedTimer = Stopwatch();
    var inputsTimer = Stopwatch();

    Future<void> loadBundle(LibraryCycle cycle) async {
      if (!loadedBundles.add(cycle)) return;

      performance.getDataInt('cycleCount').increment();
      performance.getDataInt('libraryCount').add(cycle.libraries.length);

      for (var directDependency in cycle.directDependencies) {
        await loadBundle(directDependency);
      }

      var resolutionKey = '${cycle.signatureStr}.resolution';
      var resolutionBytes = byteStore.get2(resolutionKey);

      var unitsInformativeBytes = <Uri, Uint8List>{};
      for (var library in cycle.libraries) {
        for (var file in library.files().ofLibrary) {
          var informativeBytes = file.unlinkedUnit.informativeBytes;
          unitsInformativeBytes[file.uri] = informativeBytes;
        }
      }

      if (resolutionBytes == null) {
        librariesLinkedTimer.start();

        inputsTimer.start();
        var inputLibraries = <LinkInputLibrary>[];
        for (var libraryFile in cycle.libraries) {
          var librarySource = libraryFile.source;

          var inputUnits = <LinkInputUnit>[];
          var partIndex = -1;
          for (var file in libraryFile.files().ofLibrary) {
            var isSynthetic = !file.exists;

            var content = file.getContent();
            performance.getDataInt('parseCount').increment();
            performance.getDataInt('parseLength').add(content.length);

            var unit = file.parse(
              AnalysisErrorListener.NULL_LISTENER,
              content,
            );

            String? partUriStr;
            if (partIndex >= 0) {
              partUriStr = libraryFile.unlinkedUnit.parts[partIndex];
            }
            partIndex++;

            inputUnits.add(
              LinkInputUnit(
                // TODO(scheglov) bad, group part data
                partDirectiveIndex: partIndex - 1,
                partUriStr: partUriStr,
                source: file.source,
                isSynthetic: isSynthetic,
                unit: unit,
              ),
            );
          }

          inputLibraries.add(
            LinkInputLibrary(
              source: librarySource,
              units: inputUnits,
            ),
          );
        }
        inputsTimer.stop();

        var linkResult = await performance.runAsync(
          'link',
          (performance) async {
            return await link2(
              elementFactory: elementFactory,
              performance: performance,
              inputLibraries: inputLibraries,
            );
          },
        );

        librariesLinked += cycle.libraries.length;

        resolutionBytes = linkResult.resolutionBytes;
        resolutionBytes = byteStore.putGet2(resolutionKey, resolutionBytes);
        performance.getDataInt('bytesPut').add(resolutionBytes.length);
        testData?.forCycle(cycle).putKeys.add(resolutionKey);

        librariesLinkedTimer.stop();
      } else {
        testData?.forCycle(cycle).getKeys.add(resolutionKey);
        performance.getDataInt('bytesGet').add(resolutionBytes.length);
        performance.getDataInt('libraryLoadCount').add(cycle.libraries.length);
        elementFactory.addBundle(
          BundleReader(
            elementFactory: elementFactory,
            unitsInformativeBytes: unitsInformativeBytes,
            resolutionBytes: resolutionBytes,
          ),
        );
      }
      cycle.resolutionKey = resolutionKey;

      // We might have just linked dart:core, ensure the type provider.
      _createElementFactoryTypeProvider();
    }

    await logger.runAsync('Prepare linked bundles', () async {
      var libraryCycle = targetLibrary.libraryCycle;
      await loadBundle(libraryCycle);
      logger.writeln(
        '[inputsTimer: ${inputsTimer.elapsedMilliseconds} ms]'
        '[librariesLinked: $librariesLinked]'
        '[librariesLinkedTimer: ${librariesLinkedTimer.elapsedMilliseconds} ms]',
      );
    });
  }

  /// Remove libraries represented by the [removed] files.
  /// If we need these libraries later, we will relink and reattach them.
  void remove(List<FileState> removed, Set<String> removedKeys) {
    elementFactory.removeLibraries(
      removed.map((e) => e.uri).toSet(),
    );

    var removedSet = removed.toSet();

    void addIfNotNull(String? key) {
      if (key != null) {
        removedKeys.add(key);
      }
    }

    loadedBundles.removeWhere((cycle) {
      if (cycle.libraries.any(removedSet.contains)) {
        addIfNotNull(cycle.resolutionKey);
        return true;
      }
      return false;
    });
  }

  /// Unloads all loaded bundles.
  ///
  /// Returns the keys of the artifacts that are no longer used.
  Set<String> unloadAll() {
    final keySet = <String>{};
    final uriSet = <Uri>{};

    void addIfNotNull(String? key) {
      if (key != null) {
        keySet.add(key);
      }
    }

    for (var cycle in loadedBundles) {
      addIfNotNull(cycle.resolutionKey);
      uriSet.addAll(cycle.libraries.map((e) => e.uri));
    }

    elementFactory.removeLibraries(uriSet);
    loadedBundles.clear();

    return keySet;
  }

  /// Ensure that type provider is created.
  void _createElementFactoryTypeProvider() {
    var analysisContext = contextObjects.analysisContext;
    if (!analysisContext.hasTypeProvider) {
      elementFactory.createTypeProviders(
        elementFactory.dartCoreElement,
        elementFactory.dartAsyncElement,
      );
    }
  }
}

class LibraryCycleTestData {
  final List<String> getKeys = [];
  final List<String> putKeys = [];
}
