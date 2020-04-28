// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show ErrorEncoding;
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/micro/analysis_context.dart';
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
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';
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
  final MemoryByteStore byteStore;
  final SourceFactory sourceFactory;

  /*
   * A function that returns the digest for a file as a String. The function
   * returns a non null value, can return an empty string if file does
   * not exist/has no contents.
   */
  final String Function(String path) getFileDigest;

  /**
   * A function that fetches the given list of files. This function can be used
   * to batch file reads in systems where file fetches are expensive.
   */
  final void Function(List<String> paths) prefetchFiles;

  final Workspace workspace;

  /// If not `null`, the library context will be reset after the specified
  /// interval of inactivity. Keeping library context with loaded elements
  /// significantly improves performance of resolution, because we don't have
  /// to resynthesize elements, build export scopes for libraries, etc.
  /// However keeping elements that we don't need anymore, or when the user
  /// does not work with files, is wasteful.
  ///
  /// TODO(scheglov) use it
  final Duration libraryContextResetDuration;

  /// This field gets value only during testing.
  FileResolverTestView testView;

  MicroAnalysisContextImpl analysisContext;

  FileSystemState fsState;

  _LibraryContext libraryContext;

  FileResolver(
    this.logger,
    this.resourceProvider,
    this.byteStore,
    this.sourceFactory,
    this.getFileDigest,
    this.prefetchFiles, {
    @required Workspace workspace,
    this.libraryContextResetDuration,
  }) : this.workspace = workspace;

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

  ErrorsResult getErrors(String path) {
    _throwIfNotAbsoluteNormalizedPath(path);

    return logger.run('Get errors for $path', () {
      var fileContext = getFileContext(path, withLog: true);
      var file = fileContext.file;

      var errorsSignatureBuilder = ApiSignature();
      errorsSignatureBuilder.addBytes(file.libraryCycle.signature);
      errorsSignatureBuilder.addBytes(file.digest);
      var errorsSignature = errorsSignatureBuilder.toByteList();

      var errorsKey = file.path + '.errors';
      var bytes = byteStore.get(errorsKey);

      List<AnalysisError> errors;
      if (bytes != null) {
        var data = CiderUnitErrors.fromBuffer(bytes);
        if (const ListEquality().equals(data.signature, errorsSignature)) {
          errors = data.errors.map((error) {
            return ErrorEncoding.decode(file.source, error);
          }).toList();
        }
      }

      if (errors == null) {
        var unitResult = resolve(path);
        errors = unitResult.errors;

        bytes = CiderUnitErrorsBuilder(
          signature: errorsSignature,
          errors: errors.map((ErrorEncoding.encode)).toList(),
        ).toBuffer();
        byteStore.put(errorsKey, bytes);
      }

      return ErrorsResultImpl(
        libraryContext.analysisSession,
        path,
        file.uri,
        file.lineInfo,
        false, // isPart
        errors,
      );
    });
  }

  FileContext getFileContext(String path, {bool withLog = false}) {
    FileContext perform() {
      var analysisOptions = _getAnalysisOptions(path);

      _createContext(analysisOptions);

      var file = fsState.getFileForPath(path);
      return FileContext(analysisOptions, file);
    }

    if (withLog) {
      return logger.run('Get file $path', () {
        try {
          return getFileContext(path);
        } finally {
          fsState.logStatistics();
        }
      });
    } else {
      return perform();
    }
  }

  String getLibraryLinkedSignature(String path) {
    _throwIfNotAbsoluteNormalizedPath(path);

    var fileContext = getFileContext(path);
    var file = fileContext.file;
    return file.libraryCycle.signatureStr;
  }

  ResolvedUnitResult resolve(String path) {
    _throwIfNotAbsoluteNormalizedPath(path);

    return logger.run('Resolve $path', () {
      var fileContext = getFileContext(path, withLog: true);
      var file = fileContext.file;

      libraryContext.load2(file);

      testView?.addResolvedFile(path);

      var errorListener = RecordingErrorListener();
      var content = resourceProvider.getFile(path).readAsStringSync();
      var unit = file.parse(errorListener, content);

      Map<FileState, UnitAnalysisResult> results;
      logger.run('Compute analysis results', () {
        var libraryAnalyzer = LibraryAnalyzer(
          fileContext.analysisOptions,
          analysisContext.declaredVariables,
          sourceFactory,
          (_) => true,
          // _isLibraryUri
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
    });
  }

  /// Make sure that [analysisContext], [fsState] and [libraryContext] are
  /// compatible with the given [fileAnalysisOptions].
  ///
  /// Specifically we check that `implicit-casts` and `strict-inference`
  /// flags are the same, so the type systems would be the same.
  void _createContext(AnalysisOptionsImpl fileAnalysisOptions) {
    if (analysisContext != null) {
      var analysisOptions = analysisContext.analysisOptions;
      var analysisOptionsImpl = analysisOptions as AnalysisOptionsImpl;
      if (analysisOptionsImpl.implicitCasts !=
              fileAnalysisOptions.implicitCasts ||
          analysisOptionsImpl.strictInference !=
              fileAnalysisOptions.strictInference) {
        logger.writeln(
          'Reset the context, different type system affecting options.',
        );
        fsState = null; // TODO(scheglov) don't do this
        analysisContext = null;
        libraryContext = null;
      }
    }

    var analysisOptions = AnalysisOptionsImpl()
      ..implicitCasts = fileAnalysisOptions.implicitCasts
      ..strictInference = fileAnalysisOptions.strictInference;

    if (fsState == null) {
      var featureSetProvider = FeatureSetProvider.build(
        resourceProvider: resourceProvider,
        packages: Packages.empty,
        packageDefaultFeatureSet: analysisOptions.contextFeatures,
        nonPackageDefaultFeatureSet: analysisOptions.nonPackageFeatureSet,
      );

      fsState = FileSystemState(
        logger,
        resourceProvider,
        byteStore,
        sourceFactory,
        analysisOptions,
        Uint32List(0), // linkedSalt
        featureSetProvider,
        getFileDigest,
        prefetchFiles,
      );
    }

    if (analysisContext == null) {
      var rootFolder = resourceProvider.getFolder(workspace.root);
      var root = ContextRootImpl(
        resourceProvider,
        rootFolder,
      );

      root.included.add(rootFolder);

      analysisContext = MicroAnalysisContextImpl(
        this,
        root,
        analysisOptions,
        DeclaredVariables(),
        sourceFactory,
        resourceProvider,
        workspace: workspace,
      );
    }

    if (libraryContext == null) {
      libraryContext = _LibraryContext(
        logger,
        resourceProvider,
        byteStore,
        analysisContext.currentSession,
        analysisContext.analysisOptions,
        sourceFactory,
        analysisContext.declaredVariables,
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
  /// If the [optionsFile] is not `null`, read it.
  ///
  /// If the [workspace] is a [WorkspaceWithDefaultAnalysisOptions], get the
  /// default options, if the file exists.
  ///
  /// Otherwise, return the default options.
  AnalysisOptionsImpl _getAnalysisOptions(String path) {
    YamlMap optionMap;
    var folder = resourceProvider.getFile(path).parent;
    var optionsFile = _findOptionsFile(folder);
    if (optionsFile != null) {
      try {
        var optionsProvider = AnalysisOptionsProvider(sourceFactory);
        optionMap = optionsProvider.getOptionsFromFile(optionsFile);
      } catch (e) {
        // ignored
      }
    } else {
      Source source;
      if (workspace is WorkspaceWithDefaultAnalysisOptions) {
        source = sourceFactory.forUri(WorkspaceWithDefaultAnalysisOptions.uri);
      }

      if (source != null && source.exists()) {
        try {
          var optionsProvider = AnalysisOptionsProvider(sourceFactory);
          optionMap = optionsProvider.getOptionsFromSource(source);
        } catch (e) {
          // ignored
        }
      }
    }

    var options = AnalysisOptionsImpl();

    if (optionMap != null) {
      applyToAnalysisOptions(options, optionMap);
    }

    return options;
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

  static CiderLinkedLibraryCycleBuilder serializeBundle(
      List<int> signature, link2.LinkResult linkResult) {
    return CiderLinkedLibraryCycleBuilder(
      signature: signature,
      bundle: linkResult.bundle,
    );
  }
}
