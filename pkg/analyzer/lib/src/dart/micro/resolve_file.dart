// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/micro/analysis_context.dart';
import 'package:analyzer/src/dart/micro/library_analyzer.dart';
import 'package:analyzer/src/dart/micro/library_graph.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/link.dart' as link2;
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';

/*
 * Resolves a single file.
 */
class FileResolver {
  final PerformanceLog logger;
  final ResourceProvider resourceProvider;
  final MemoryByteStore byteStore;
  final SourceFactory sourceFactory;

  /*
   * A function that returns the digest for a file as a String. The function
   * returns a non null value, can return an empty string if file does
   * not exist/has no contents.
   */
  final String Function(String path) getFileDigest;

  Workspace workspace;

  MicroAnalysisContextImpl analysisContext;

  FileResolver(this.logger, this.resourceProvider, this.byteStore,
      this.sourceFactory, this.getFileDigest,
      {Workspace workspace})
      : this.workspace = workspace;

  FeatureSet get defaultFeatureSet => FeatureSet.fromEnableFlags([]);

  ResolvedUnitResult resolve(String path) {
    _throwIfNotAbsoluteNormalizedPath(path);

    return logger.run('Resolve $path', () {
      logger.run('Create AnalysisContext', () {
        var contextLocator = ContextLocator(
          resourceProvider: this.resourceProvider,
        );

        var roots = contextLocator.locateRoots(
          includedPaths: [path],
          excludedPaths: [],
        );
        if (roots.length != 1) {
          throw StateError('Exactly one root expected: $roots');
        }
        var root = roots[0];

        var analysisOptions = AnalysisOptionsImpl();
        var declaredVariables = DeclaredVariables();

        analysisContext = MicroAnalysisContextImpl(
          this,
          root,
          analysisOptions,
          declaredVariables,
          sourceFactory,
          resourceProvider,
          workspace: workspace,
        );
      });

      return _resolve(path);
    });
  }

  ResolvedUnitResultImpl _resolve(String path) {
    var options = analysisContext.analysisOptions;
    var featureSetProvider = FeatureSetProvider.build(
      resourceProvider: resourceProvider,
      packages: Packages.empty,
      packageDefaultFeatureSet: analysisContext.analysisOptions.contextFeatures,
      nonPackageDefaultFeatureSet:
          (options as AnalysisOptionsImpl).nonPackageFeatureSet,
    );

    var fsState = FileSystemState(
      logger,
      resourceProvider,
      byteStore,
      analysisContext.sourceFactory,
      analysisContext.analysisOptions,
      Uint32List(0), // linkedSalt
      featureSetProvider,
      getFileDigest,
    );

    FileState file;
    logger.run('Get file $path', () {
      file = fsState.getFileForPath(path);
    });

    var errorListener = RecordingErrorListener();
    var content = resourceProvider.getFile(path).readAsStringSync();
    var unit = file.parse(errorListener, content);

    _LibraryContext libraryContext = _LibraryContext(
      logger,
      resourceProvider,
      byteStore,
      analysisContext.currentSession,
      analysisContext.analysisOptions,
      analysisContext.sourceFactory,
      analysisContext.declaredVariables,
    );
    libraryContext.load2(file);

    Map<FileState, UnitAnalysisResult> results;
    logger.run('Compute analysis results', () {
      var libraryAnalyzer = LibraryAnalyzer(
        analysisContext.analysisOptions,
        analysisContext.declaredVariables,
        analysisContext.sourceFactory,
        (_) => true, // _isLibraryUri
        libraryContext.analysisContext,
        libraryContext.elementFactory,
        libraryContext.inheritanceManager,
        file,
        resourceProvider,
        (String path) => resourceProvider.getFile(path).readAsStringSync(),
      );

      results = libraryAnalyzer.analyzeSync();
    });
    UnitAnalysisResult fileResult = results[file];

    return ResolvedUnitResultImpl(
      analysisContext.currentSession,
      path,
      file.uri,
      file.exists,
      content,
      unit.lineInfo,
      false, // isPart
      fileResult.unit,
      fileResult.errors,
    );
  }

  void _throwIfNotAbsoluteNormalizedPath(String path) {
    var pathContext = resourceProvider.pathContext;
    if (pathContext.normalize(path) != path) {
      throw ArgumentError(
        'Only normalized paths are supported: $path',
      );
    }
  }
}

class _LibraryContext {
  final PerformanceLog logger;
  final ResourceProvider resourceProvider;
  final MemoryByteStore byteStore;
  final AnalysisSession analysisSession;

  AnalysisContextImpl analysisContext;
  LinkedElementFactory elementFactory;
  InheritanceManager3 inheritanceManager;

  Set<LibraryCycle> loadedBundles = Set.identity();

  _LibraryContext(
    this.logger,
    this.resourceProvider,
    this.byteStore,
    this.analysisSession,
    AnalysisOptionsImpl analysisOptions,
    SourceFactory sourceFactory,
    DeclaredVariables declaredVariables,
  ) {
    var synchronousSession =
        SynchronousSession(analysisOptions, declaredVariables);
    analysisContext = AnalysisContextImpl(
      synchronousSession,
      sourceFactory,
    );

    _createElementFactory();
  }

  /// Load data required to access elements of the given [targetLibrary].
  void load2(FileState targetLibrary) {
    var inputBundles = <LinkedNodeBundle>[];

    var numCycles = 0;
    var librariesTotal = 0;
    var librariesLoaded = 0;
    var librariesLinked = 0;
    var librariesLinkedTimer = Stopwatch();
    var inputsTimer = Stopwatch();
    var bytesGet = 0;
    var bytesPut = 0;

    void loadBundle(LibraryCycle cycle) {
      if (!loadedBundles.add(cycle)) return;

      numCycles++;
      librariesTotal += cycle.libraries.length;

      cycle.directDependencies.forEach(loadBundle);

      var key = cycle.cyclePathsHash;
      var bytes = byteStore.get(key);

      // check to see if any of the sources have changed
      if (bytes != null) {
        var hash = CiderLinkedLibraryCycle.fromBuffer(bytes).signature;
        if (!const ListEquality().equals(hash, cycle.signature)) {
          bytes = null;
        }
      }

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
              content = resourceProvider.getFile(file.path).readAsStringSync();
            } catch (_) {}
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

        byteStore.put(key, bytes);
        bytesPut += bytes.length;

        librariesLinkedTimer.stop();
      } else {
        // TODO(scheglov) Take / clear parsed units in files.
        bytesGet += bytes.length;
        librariesLoaded += cycle.libraries.length;
      }

      // We are about to load dart:core, but if we have just linked it, the
      // linker might have set the type provider. So, clear it, and recreate
      // the element factory - it is empty anyway.
      if (!elementFactory.hasDartCore) {
        analysisContext.clearTypeProvider();
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
        '[numCycles: $numCycles]'
        '[librariesTotal: $librariesTotal]'
        '[librariesLoaded: $librariesLoaded]'
        '[inputsTimer: ${inputsTimer.elapsedMilliseconds} ms]'
        '[librariesLinked: $librariesLinked]'
        '[librariesLinkedTimer: ${librariesLinkedTimer.elapsedMilliseconds} ms]'
        '[bytesGet: $bytesGet][bytesPut: $bytesPut]',
      );
    });

    // There might be a rare (and wrong) situation, when the external summaries
    // already include the [targetLibrary]. When this happens, [loadBundle]
    // exists without doing any work. But the type provider must be created.
    _createElementFactoryTypeProvider();
    inheritanceManager = InheritanceManager3();
  }

  static CiderLinkedLibraryCycleBuilder serializeBundle(
      List<int> signature, link2.LinkResult linkResult) {
    return CiderLinkedLibraryCycleBuilder(
      signature: signature,
      bundle: linkResult.bundle,
    );
  }

  void _createElementFactory() {
    elementFactory = LinkedElementFactory(
      analysisContext,
      analysisSession,
      Reference.root(),
    );
  }

  /// Ensure that type provider is created.
  void _createElementFactoryTypeProvider() {
    if (analysisContext.typeProviderNonNullableByDefault == null) {
      var dartCore = elementFactory.libraryOfUri('dart:core');
      var dartAsync = elementFactory.libraryOfUri('dart:async');
      elementFactory.createTypeProviders(dartCore, dartAsync);
    }
  }
}
