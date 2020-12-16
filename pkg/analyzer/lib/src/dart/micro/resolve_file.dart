// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/null_safety_understanding_flag.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show ErrorEncoding;
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/micro/analysis_context.dart';
import 'package:analyzer/src/dart/micro/cider_byte_store.dart';
import 'package:analyzer/src/dart/micro/library_analyzer.dart';
import 'package:analyzer/src/dart/micro/library_graph.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/link.dart' as link2;
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

const M = 1024 * 1024 /*1 MiB*/;
const memoryCacheSize = 200 * M;

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

  /*
   * A function that returns the digest for a file as a String. The function
   * returns a non null value, can return an empty string if file does
   * not exist/has no contents.
   */
  final String Function(String path) getFileDigest;

  /// A function that fetches the given list of files. This function can be used
  /// to batch file reads in systems where file fetches are expensive.
  final void Function(List<String> paths) prefetchFiles;

  final Workspace workspace;

  /// This field gets value only during testing.
  FileResolverTestView testView;

  FileSystemState fsState;

  MicroContextObjects contextObjects;

  _LibraryContext libraryContext;

  /// List of ids for cache elements that are invalidated. Track elements that
  /// are invalidated during [changeFile]. Used in [releaseAndClearRemovedIds]
  /// to release the cache items and is then cleared.
  final Set<int> removedCacheIds = {};

  FileResolver(
    PerformanceLog logger,
    ResourceProvider resourceProvider,
    @deprecated ByteStore byteStore,
    SourceFactory sourceFactory,
    String Function(String path) getFileDigest,
    void Function(List<String> paths) prefetchFiles, {
    @required Workspace workspace,
    @deprecated Duration libraryContextResetTimeout,
  }) : this.from(
          logger: logger,
          resourceProvider: resourceProvider,
          sourceFactory: sourceFactory,
          getFileDigest: getFileDigest,
          prefetchFiles: prefetchFiles,
          workspace: workspace,
          // ignore: deprecated_member_use_from_same_package
          libraryContextResetTimeout: libraryContextResetTimeout,
        );

  FileResolver.from({
    @required PerformanceLog logger,
    @required ResourceProvider resourceProvider,
    @required SourceFactory sourceFactory,
    @required String Function(String path) getFileDigest,
    @required void Function(List<String> paths) prefetchFiles,
    @required Workspace workspace,
    CiderByteStore byteStore,
    @deprecated Duration libraryContextResetTimeout,
  })  : logger = logger,
        sourceFactory = sourceFactory,
        resourceProvider = resourceProvider,
        getFileDigest = getFileDigest,
        prefetchFiles = prefetchFiles,
        workspace = workspace {
    byteStore ??= CiderCachedByteStore(memoryCacheSize);
    this.byteStore = byteStore;
  }

  /// Update the resolver to reflect the fact that the file with the given
  /// [path] was changed. We need to make sure that when this file, of any file
  /// that directly or indirectly referenced it, is resolved, we used the new
  /// state of the file. Updates [removedCacheIds] with the ids of the invalidated
  /// items, used in [releaseAndClearRemovedIds] to release the cache items.
  void changeFile(String path) {
    if (fsState == null) {
      return;
    }

    // Remove this file and all files that transitively depend on it.
    var removedFiles = <FileState>[];
    fsState.changeFile(path, removedFiles);

    // Schedule disposing references to cached unlinked data.
    for (var removedFile in removedFiles) {
      removedCacheIds.add(removedFile.id);
    }

    // Remove libraries represented by removed files.
    // If we need these libraries later, we will relink and reattach them.
    if (libraryContext != null) {
      libraryContext.remove(removedFiles, removedCacheIds);
    }
  }

  /// Collects all the cached artifacts and add all the cache id's for the
  /// removed artifacts to [removedCacheIds].
  void collectSharedDataIdentifiers() {
    removedCacheIds.addAll(fsState.collectSharedDataIdentifiers());
    removedCacheIds.addAll(libraryContext.collectSharedDataIdentifiers());
  }

  @deprecated
  void dispose() {}

  ErrorsResult getErrors({
    @required String path,
    OperationPerformanceImpl performance,
  }) {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    return logger.run('Get errors for $path', () {
      var fileContext = getFileContext(
        path: path,
        performance: performance,
      );
      var file = fileContext.file;

      var errorsSignatureBuilder = ApiSignature();
      errorsSignatureBuilder.addBytes(file.libraryCycle.signature);
      errorsSignatureBuilder.addBytes(file.digest);
      var errorsSignature = errorsSignatureBuilder.toByteList();

      var errorsKey = file.path + '.errors';
      var bytes = byteStore.get(errorsKey, errorsSignature)?.bytes;
      List<AnalysisError> errors;
      if (bytes != null) {
        var data = CiderUnitErrors.fromBuffer(bytes);
        errors = data.errors.map((error) {
          return ErrorEncoding.decode(file.source, error);
        }).toList();
      }

      if (errors == null) {
        var unitResult = resolve(
          path: path,
          performance: performance,
        );
        errors = unitResult.errors;

        bytes = CiderUnitErrorsBuilder(
          signature: errorsSignature,
          errors: errors.map(ErrorEncoding.encode).toList(),
        ).toBuffer();
        bytes = byteStore.putGet(errorsKey, errorsSignature, bytes).bytes;
      }

      return ErrorsResultImpl(
        contextObjects.analysisSession,
        path,
        file.uri,
        file.lineInfo,
        false, // isPart
        errors,
      );
    });
  }

  @deprecated
  ErrorsResult getErrors2({
    @required String path,
    OperationPerformanceImpl performance,
  }) {
    return getErrors(
      path: path,
      performance: performance,
    );
  }

  FileContext getFileContext({
    @required String path,
    @required OperationPerformanceImpl performance,
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
        return fsState.getFileForPath(
          path: path,
          performance: performance,
        );
      });

      return FileContext(analysisOptions, file);
    });
  }

  String getLibraryLinkedSignature({
    @required String path,
    @required OperationPerformanceImpl performance,
  }) {
    _throwIfNotAbsoluteNormalizedPath(path);

    var file = fsState.getFileForPath(
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
  /// from bytes, which will be done by [getErrors]. It is OK for it to
  /// spend some more time on this.
  void linkLibraries({
    @required String path,
  }) {
    _throwIfNotAbsoluteNormalizedPath(path);

    var performance = OperationPerformanceImpl('<unused>');

    var fileContext = getFileContext(
      path: path,
      performance: performance,
    );
    var file = fileContext.file;
    var libraryFile = file.partOfLibrary ?? file;

    libraryContext.load2(
      targetLibrary: libraryFile,
      performance: performance,
    );

    _resetContextObjects();
  }

  /// Update the cache with list of invalidated ids and clears [removedCacheIds].
  void releaseAndClearRemovedIds() {
    byteStore.release(removedCacheIds);
    removedCacheIds.clear();
  }

  /// Remove cached [FileState]'s that were not used in the current analysis
  /// session. The list of files analyzed is used to compute the set of unused
  /// [FileState]'s. Adds the cache id's for the removed [FileState]'s to
  /// [removedCacheIds].
  void removeFilesNotNecessaryForAnalysisOf(List<String> files) {
    var removedFiles = fsState.removeUnusedFiles(files);
    for (var removedFile in removedFiles) {
      removedCacheIds.add(removedFile.id);
    }
  }

  /// The [completionLine] and [completionColumn] are zero based.
  ResolvedUnitResult resolve({
    int completionLine,
    int completionColumn,
    @required String path,
    OperationPerformanceImpl performance,
  }) {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    return logger.run('Resolve $path', () {
      var fileContext = getFileContext(
        path: path,
        performance: performance,
      );
      var file = fileContext.file;
      var libraryFile = file.partOfLibrary ?? file;

      int completionOffset;
      if (completionLine != null && completionColumn != null) {
        var lineOffset = file.lineInfo.getOffsetOfLine(completionLine);
        completionOffset = lineOffset + completionColumn;
      }

      performance.run('libraryContext', (performance) {
        libraryContext.load2(
          targetLibrary: libraryFile,
          performance: performance,
        );
      });

      testView?.addResolvedFile(path);

      var content = _getFileContent(path);
      var errorListener = RecordingErrorListener();
      var unit = file.parse(errorListener, content);

      Map<FileState, UnitAnalysisResult> results;

      logger.run('Compute analysis results', () {
        var libraryAnalyzer = LibraryAnalyzer(
          fileContext.analysisOptions,
          contextObjects.declaredVariables,
          sourceFactory,
          (_) => true, // _isLibraryUri
          contextObjects.analysisContext,
          libraryContext.elementFactory,
          contextObjects.inheritanceManager,
          libraryFile,
          resourceProvider,
          (file) => file.getContentWithSameDigest(),
        );

        try {
          results = performance.run('analyze', (performance) {
            return NullSafetyUnderstandingFlag.enableNullSafetyTypes(() {
              return libraryAnalyzer.analyzeSync(
                completionPath: completionOffset != null ? path : null,
                completionOffset: completionOffset,
                performance: performance,
              );
            });
          });
        } catch (exception, stackTrace) {
          var fileContentMap = <String, String>{};
          for (var file in libraryFile.libraryFiles) {
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
      UnitAnalysisResult fileResult = results[file];

      return ResolvedUnitResultImpl(
        contextObjects.analysisSession,
        path,
        file.uri,
        file.exists,
        content,
        unit.lineInfo,
        false, // isPart
        fileResult.unit,
        fileResult.errors,
      );
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
      contextObjects.analysisOptions = fileAnalysisOptions;
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
        analysisOptions,
        Uint32List(0),
        // linkedSalt
        featureSetProvider,
        getFileDigest,
        prefetchFiles,
      );
    }

    if (contextObjects == null) {
      var rootFolder = resourceProvider.getFolder(workspace.root);
      var root = ContextRootImpl(resourceProvider, rootFolder);
      root.included.add(rootFolder);

      contextObjects = createMicroContextObjects(
        fileResolver: this,
        analysisOptions: analysisOptions,
        sourceFactory: sourceFactory,
        root: root,
        resourceProvider: resourceProvider,
        workspace: workspace,
      );

      libraryContext = _LibraryContext(
        logger,
        resourceProvider,
        byteStore,
        contextObjects,
      );
    }
  }

  File _findOptionsFile(Folder folder) {
    while (folder != null) {
      File packagesFile =
          _getFile(folder, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
      if (packagesFile != null) {
        return packagesFile;
      }
      folder = folder.parent;
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
    @required String path,
    @required OperationPerformanceImpl performance,
  }) {
    YamlMap optionMap;

    var separator = resourceProvider.pathContext.separator;
    var isThirdParty = path
            .contains('${separator}third_party${separator}dart$separator') ||
        path.contains('${separator}third_party${separator}dart_lang$separator');

    File optionsFile;
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
          optionMap = optionsProvider.getOptionsFromFile(optionsFile);
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
        applyToAnalysisOptions(options, optionMap);
      });
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

  void _resetContextObjects() {
    if (libraryContext != null) {
      contextObjects = null;
      libraryContext = null;
    }
  }

  void _throwIfNotAbsoluteNormalizedPath(String path) {
    var pathContext = resourceProvider.pathContext;
    if (pathContext.normalize(path) != path) {
      throw ArgumentError(
        'Only normalized paths are supported: $path',
      );
    }
  }

  static File _getFile(Folder directory, String name) {
    Resource resource = directory.getChild(name);
    if (resource is File && resource.exists) {
      return resource;
    }
    return null;
  }
}

class FileResolverTestView {
  /// The paths of files which were resolved.
  ///
  /// The file path is added every time when it is resolved.
  final List<String> resolvedFiles = [];

  void addResolvedFile(String path) {
    resolvedFiles.add(path);
  }
}

class _LibraryContext {
  final PerformanceLog logger;
  final ResourceProvider resourceProvider;
  final CiderByteStore byteStore;
  final MicroContextObjects contextObjects;

  LinkedElementFactory elementFactory;

  Set<LibraryCycle> loadedBundles = Set.identity();

  _LibraryContext(
    this.logger,
    this.resourceProvider,
    this.byteStore,
    this.contextObjects,
  ) {
    elementFactory = LinkedElementFactory(
      contextObjects.analysisContext,
      contextObjects.analysisSession,
      Reference.root(),
    );
  }

  /// Clears all the loaded libraries. Returns the cache ids for the removed
  /// artifacts.
  Set<int> collectSharedDataIdentifiers() {
    var idSet = <int>{};
    for (var cycle in loadedBundles) {
      idSet.add(cycle.astId);
      idSet.add(cycle.resolutionId);
    }
    loadedBundles.clear();
    return idSet;
  }

  /// Load data required to access elements of the given [targetLibrary].
  void load2({
    @required FileState targetLibrary,
    @required OperationPerformanceImpl performance,
  }) {
    var librariesLinked = 0;
    var librariesLinkedTimer = Stopwatch();
    var inputsTimer = Stopwatch();

    void loadBundle(LibraryCycle cycle) {
      if (!loadedBundles.add(cycle)) return;

      performance.getDataInt('cycleCount').increment();
      performance.getDataInt('libraryCount').add(cycle.libraries.length);

      cycle.directDependencies.forEach(loadBundle);

      var astKey = '${cycle.cyclePathsHash}.ast';
      var resolutionKey = '${cycle.cyclePathsHash}.resolution';
      var astData = byteStore.get(astKey, cycle.signature);
      var resolutionData = byteStore.get(resolutionKey, cycle.signature);
      var astBytes = astData?.bytes;
      var resolutionBytes = resolutionData?.bytes;

      if (astBytes == null || resolutionBytes == null) {
        librariesLinkedTimer.start();

        inputsTimer.start();
        var inputLibraries = <link2.LinkInputLibrary>[];
        for (var libraryFile in cycle.libraries) {
          var librarySource = libraryFile.source;
          if (librarySource == null) continue;

          var inputUnits = <link2.LinkInputUnit>[];
          var partIndex = -1;
          for (var file in libraryFile.libraryFiles) {
            var isSynthetic = !file.exists;

            var content = file.getContentWithSameDigest();
            performance.getDataInt('parseCount').increment();
            performance.getDataInt('parseLength').add(content.length);

            var unit = file.parse(
              AnalysisErrorListener.NULL_LISTENER,
              content,
            );

            String partUriStr;
            if (partIndex >= 0) {
              partUriStr = libraryFile.unlinked2.parts[partIndex];
            }
            partIndex++;

            inputUnits.add(
              link2.LinkInputUnit(
                partUriStr,
                file.source,
                isSynthetic,
                unit,
              ),
            );
          }

          inputLibraries.add(
            link2.LinkInputLibrary(librarySource, inputUnits),
          );
        }
        inputsTimer.stop();

        var linkResult = link2.link(elementFactory, inputLibraries, true);
        librariesLinked += cycle.libraries.length;

        astBytes = linkResult.astBytes;
        resolutionBytes = linkResult.resolutionBytes;

        astData = byteStore.putGet(astKey, cycle.signature, astBytes);
        astBytes = astData.bytes;
        performance.getDataInt('bytesPut').add(astBytes.length);

        resolutionData =
            byteStore.putGet(resolutionKey, cycle.signature, resolutionBytes);
        resolutionBytes = resolutionData.bytes;
        performance.getDataInt('bytesPut').add(resolutionBytes.length);

        librariesLinkedTimer.stop();
      } else {
        performance.getDataInt('bytesGet').add(astBytes.length);
        performance.getDataInt('bytesGet').add(resolutionBytes.length);
        performance.getDataInt('libraryLoadCount').add(cycle.libraries.length);
      }
      cycle.astId = astData.id;
      cycle.resolutionId = resolutionData.id;

      elementFactory.addBundle(
        BundleReader(
          elementFactory: elementFactory,
          astBytes: astBytes,
          resolutionBytes: resolutionBytes,
        ),
      );

      // We might have just linked dart:core, ensure the type provider.
      _createElementFactoryTypeProvider();
    }

    logger.run('Prepare linked bundles', () {
      var libraryCycle = targetLibrary.libraryCycle;
      loadBundle(libraryCycle);
      logger.writeln(
        '[inputsTimer: ${inputsTimer.elapsedMilliseconds} ms]'
        '[librariesLinked: $librariesLinked]'
        '[librariesLinkedTimer: ${librariesLinkedTimer.elapsedMilliseconds} ms]',
      );
    });
  }

  /// Remove libraries represented by the [removed] files.
  /// If we need these libraries later, we will relink and reattach them.
  void remove(List<FileState> removed, Set<int> removedIds) {
    elementFactory.removeLibraries(
      removed.map((e) => e.uriStr).toSet(),
    );

    var removedSet = removed.toSet();
    loadedBundles.removeWhere((cycle) {
      if (cycle.libraries.any(removedSet.contains)) {
        removedIds.add(cycle.astId);
        removedIds.add(cycle.resolutionId);
        return true;
      }
      return false;
    });
  }

  /// Ensure that type provider is created.
  void _createElementFactoryTypeProvider() {
    var analysisContext = contextObjects.analysisContext;
    if (analysisContext.typeProviderNonNullableByDefault == null) {
      var dartCore = elementFactory.libraryOfUri('dart:core');
      var dartAsync = elementFactory.libraryOfUri('dart:async');
      elementFactory.createTypeProviders(dartCore, dartAsync);
    }
  }
}
