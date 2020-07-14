// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show ErrorEncoding;
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/micro/analysis_context.dart';
import 'package:analyzer/src/dart/micro/cider_byte_store.dart';
import 'package:analyzer/src/dart/micro/library_analyzer.dart';
import 'package:analyzer/src/dart/micro/library_graph.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/link.dart' as link2;
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

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

  _LibraryContextReset _libraryContextReset;

  /// This field gets value only during testing.
  FileResolverTestView testView;

  FileSystemState fsState;

  MicroContextObjects contextObjects;

  _LibraryContext libraryContext;

  FileResolver(
    PerformanceLog logger,
    ResourceProvider resourceProvider,
    @deprecated ByteStore byteStore,
    SourceFactory sourceFactory,
    String Function(String path) getFileDigest,
    void Function(List<String> paths) prefetchFiles, {
    @required Workspace workspace,
    Duration libraryContextResetTimeout = const Duration(seconds: 60),
  }) : this.from(
          logger: logger,
          resourceProvider: resourceProvider,
          sourceFactory: sourceFactory,
          getFileDigest: getFileDigest,
          prefetchFiles: prefetchFiles,
          workspace: workspace,
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
    Duration libraryContextResetTimeout = const Duration(seconds: 60),
  })  : this.logger = logger,
        this.sourceFactory = sourceFactory,
        this.resourceProvider = resourceProvider,
        this.getFileDigest = getFileDigest,
        this.prefetchFiles = prefetchFiles,
        this.workspace = workspace {
    byteStore ??= CiderMemoryByteStore();
    this.byteStore = byteStore;
    _libraryContextReset = _LibraryContextReset(
      fileResolver: this,
      resetTimeout: libraryContextResetTimeout,
    );
  }

  FeatureSet get defaultFeatureSet => FeatureSet.fromEnableFlags([]);

  /// Update the resolver to reflect the fact that the file with the given
  /// [path] was changed. We need to make sure that when this file, of any file
  /// that directly or indirectly referenced it, is resolved, we used the new
  /// state of the file.
  void changeFile(String path) {
    if (fsState == null) {
      return;
    }

    // Remove this file and all files that transitively depend on it.
    var removedFiles = <FileState>[];
    fsState.changeFile(path, removedFiles);

    // Remove libraries represented by removed files.
    // If we need these libraries later, we will relink and reattach them.
    if (libraryContext != null) {
      libraryContext.elementFactory.removeLibraries(
        removedFiles.map((e) => e.uriStr).toList(),
      );
    }
  }

  void dispose() {
    _libraryContextReset.dispose();
  }

  ErrorsResult getErrors({
    @required String path,
    OperationPerformanceImpl performance,
  }) {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    return _withLibraryContextReset(() {
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
        var bytes = byteStore.get(errorsKey, errorsSignature);
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
          byteStore.put(errorsKey, errorsSignature, bytes);
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

  ResolvedUnitResult resolve({
    int completionOffset,
    @required String path,
    OperationPerformanceImpl performance,
  }) {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    return _withLibraryContextReset(() {
      return logger.run('Resolve $path', () {
        var fileContext = getFileContext(
          path: path,
          performance: performance,
        );
        var file = fileContext.file;
        var libraryFile = file.partOfLibrary ?? file;

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
            (String path) => resourceProvider.getFile(path).readAsStringSync(),
          );

          results = performance.run('analyze', (performance) {
            return libraryAnalyzer.analyzeSync(
              completionPath: completionOffset != null ? path : null,
              completionOffset: completionOffset,
              performance: performance,
            );
          });
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
    });
  }

  @deprecated
  ResolvedUnitResult resolve2({
    int completionOffset,
    @required String path,
    OperationPerformanceImpl performance,
  }) {
    return resolve(
      completionOffset: completionOffset,
      path: path,
      performance: performance,
    );
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
        packages: Packages.empty,
        packageDefaultFeatureSet: analysisOptions.contextFeatures,
        nonPackageDefaultFeatureSet: analysisOptions.nonPackageFeatureSet,
      );

      fsState = FileSystemState(
        resourceProvider,
        byteStore,
        sourceFactory,
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

    var optionsFile = performance.run('findOptionsFile', (_) {
      var folder = resourceProvider.getFile(path).parent;
      return _findOptionsFile(folder);
    });

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
          var separator = resourceProvider.pathContext.separator;
          if (path
              .contains('${separator}third_party${separator}dart$separator')) {
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

  void _throwIfNotAbsoluteNormalizedPath(String path) {
    var pathContext = resourceProvider.pathContext;
    if (pathContext.normalize(path) != path) {
      throw ArgumentError(
        'Only normalized paths are supported: $path',
      );
    }
  }

  /// Run the [operation] that uses the library context, by locking it first,
  /// so that it is not reset while the operating is still running, and
  /// unlocking after the operation is done, so that the library context
  /// will be reset after some timeout.
  T _withLibraryContextReset<T>(T Function() operation) {
    _libraryContextReset.lock();
    try {
      return operation();
    } finally {
      _libraryContextReset.unlock();
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
    // TODO(scheglov) remove it?
    _createElementFactory();
  }

  /// Load data required to access elements of the given [targetLibrary].
  void load2({
    @required FileState targetLibrary,
    @required OperationPerformanceImpl performance,
  }) {
    var inputBundles = <LinkedNodeBundle>[];

    var librariesLinked = 0;
    var librariesLinkedTimer = Stopwatch();
    var inputsTimer = Stopwatch();

    void loadBundle(LibraryCycle cycle) {
      if (!loadedBundles.add(cycle)) return;

      performance.getDataInt('cycleCount').increment();
      performance.getDataInt('libraryCount').add(cycle.libraries.length);

      cycle.directDependencies.forEach(loadBundle);

      var key = cycle.cyclePathsHash;
      var bytes = byteStore.get(key, cycle.signature);

      if (bytes == null) {
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

            var content = '';
            try {
              var resource = resourceProvider.getFile(file.path);
              content = resource.readAsStringSync();
            } catch (_) {}

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

        var linkResult = link2.link(elementFactory, inputLibraries);
        librariesLinked += cycle.libraries.length;

        bytes = serializeBundle(cycle.signature, linkResult).toBuffer();

        byteStore.put(key, cycle.signature, bytes);
        performance.getDataInt('bytesPut').add(bytes.length);

        librariesLinkedTimer.stop();
      } else {
        performance.getDataInt('bytesGet').add(bytes.length);
        performance.getDataInt('libraryLoadCount').add(cycle.libraries.length);
      }

      // We are about to load dart:core, but if we have just linked it, the
      // linker might have set the type provider. So, clear it, and recreate
      // the element factory - it is empty anyway.
      if (!elementFactory.hasDartCore) {
        contextObjects.analysisContext.clearTypeProvider();
        _createElementFactory();
      }
      var cBundle = CiderLinkedLibraryCycle.fromBuffer(bytes);
      inputBundles.add(cBundle.bundle);
      elementFactory.addBundle(
        LinkedBundleContext(elementFactory, cBundle.bundle),
      );

      // Set informative data.
      for (var libraryFile in cycle.libraries) {
        for (var unitFile in libraryFile.libraryFiles) {
          elementFactory.setInformativeData(
            libraryFile.uriStr,
            unitFile.uriStr,
            unitFile.unlinked2.informativeData,
          );
        }
      }
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

    // There might be a rare (and wrong) situation, when the external summaries
    // already include the [targetLibrary]. When this happens, [loadBundle]
    // exists without doing any work. But the type provider must be created.
    _createElementFactoryTypeProvider();
  }

  void _createElementFactory() {
    elementFactory = LinkedElementFactory(
      contextObjects.analysisContext,
      contextObjects.analysisSession,
      Reference.root(),
    );
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

  static CiderLinkedLibraryCycleBuilder serializeBundle(
      List<int> signature, link2.LinkResult linkResult) {
    return CiderLinkedLibraryCycleBuilder(
      signature: signature,
      bundle: linkResult.bundle,
    );
  }
}

/// The helper to reset the library context will be reset after the specified
/// interval of inactivity. Keeping library context with loaded elements
/// significantly improves performance of resolution, because we don't have
/// to resynthesize elements, build export scopes for libraries, etc.
/// However keeping elements that we don't need anymore, or when the user
/// does not work with files, is wasteful.
class _LibraryContextReset {
  final FileResolver fileResolver;
  final Duration resetTimeout;

  /// The lock level, incremented by [lock], and decremented by [unlock].
  /// The timeout timer is started when the level reaches zero.
  int _lockLevel = 0;
  Timer _timer;

  _LibraryContextReset({
    @required this.fileResolver,
    @required this.resetTimeout,
  });

  void dispose() {
    _stop();
  }

  /// Stop the timeout timer, and increment the lock level. The library context
  /// will be not reset until [unlock] will bring the lock level back to zero.
  void lock() {
    _stop();
    _lockLevel++;
  }

  /// Unlock the timer, the library context will be reset after the timeout.
  void unlock() {
    assert(_lockLevel > 0);
    _lockLevel--;

    if (_lockLevel == 0) {
      _stop();
      if (resetTimeout != null) {
        _timer = Timer(resetTimeout, () {
          _timer = null;
          if (fileResolver.libraryContext != null) {
            fileResolver.contextObjects = null;
            fileResolver.libraryContext = null;
          }
        });
      }
    }
  }

  void _stop() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }
}
