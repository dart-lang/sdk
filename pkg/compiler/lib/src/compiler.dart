// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.compiler_base;

import 'dart:async' show Future;

import '../compiler_new.dart' as api;
import 'backend_strategy.dart';
import 'closure.dart' as closureMapping show ClosureTask;
import 'common/names.dart' show Selectors;
import 'common/names.dart' show Uris;
import 'common/resolution.dart'
    show
        ParsingContext,
        Resolution,
        ResolutionWorkItem,
        ResolutionImpact,
        Target;
import 'common/tasks.dart' show CompilerTask, GenericTask, Measurer;
import 'common/work.dart' show WorkItem;
import 'common.dart';
import 'compile_time_constants.dart';
import 'constants/values.dart';
import 'common_elements.dart' show CommonElements, ElementEnvironment;
import 'deferred_load.dart' show DeferredLoadTask;
import 'diagnostics/code_location.dart';
import 'diagnostics/diagnostic_listener.dart' show DiagnosticReporter;
import 'diagnostics/invariant.dart' show REPORT_EXCESS_RESOLUTION;
import 'diagnostics/messages.dart' show Message, MessageTemplate;
import 'dump_info.dart' show DumpInfoTask;
import 'elements/elements.dart';
import 'elements/entities.dart';
import 'elements/resolution_types.dart' show ResolutionDartType, Types;
import 'elements/types.dart' show DartTypes;
import 'enqueue.dart' show Enqueuer, EnqueueTask, ResolutionEnqueuer;
import 'environment.dart';
import 'frontend_strategy.dart';
import 'id_generator.dart';
import 'io/source_information.dart' show SourceInformation;
import 'io/source_file.dart' show Binary;
import 'js_backend/backend.dart' show JavaScriptBackend;
import 'js_backend/element_strategy.dart' show ElementBackendStrategy;
import 'kernel/kernel_strategy.dart';
import 'library_loader.dart'
    show
        ElementScanner,
        LibraryLoader,
        LibraryLoaderTask,
        LoadedLibraries,
        ScriptLoader;
import 'mirrors_used.dart' show MirrorUsageAnalyzerTask;
import 'null_compiler_output.dart' show NullCompilerOutput, NullSink;
import 'options.dart' show CompilerOptions, DiagnosticOptions;
import 'parser/diet_parser_task.dart' show DietParserTask;
import 'parser/parser_task.dart' show ParserTask;
import 'patch_parser.dart' show PatchParserTask;
import 'resolution/resolution.dart' show ResolverTask;
import 'resolution/resolution_strategy.dart';
import 'resolved_uri_translator.dart';
import 'scanner/scanner_task.dart' show ScannerTask;
import 'script.dart' show Script;
import 'serialization/task.dart' show SerializationTask;
import 'ssa/nodes.dart' show HInstruction;
import 'package:front_end/src/fasta/scanner.dart' show StringToken, Token;
import 'tokens/token_map.dart' show TokenMap;
import 'tree/tree.dart' show Node, TypeAnnotation;
import 'typechecker.dart' show TypeCheckerTask;
import 'types/types.dart' show GlobalTypeInferenceTask;
import 'universe/selector.dart' show Selector;
import 'universe/world_builder.dart'
    show ResolutionWorldBuilder, CodegenWorldBuilder;
import 'universe/use.dart' show StaticUse, TypeUse;
import 'universe/world_impact.dart'
    show ImpactStrategy, WorldImpact, WorldImpactBuilderImpl;
import 'util/util.dart' show Link;
import 'world.dart' show ClosedWorld, ClosedWorldRefiner;

typedef CompilerDiagnosticReporter MakeReporterFunction(
    Compiler compiler, CompilerOptions options);

abstract class Compiler {
  Measurer get measurer;

  final IdGenerator idGenerator = new IdGenerator();
  DartTypes types;
  FrontEndStrategy frontEndStrategy;
  BackendStrategy backendStrategy;
  CommonElements _commonElements;
  ElementEnvironment _elementEnvironment;
  CompilerDiagnosticReporter _reporter;
  CompilerResolution _resolution;
  ParsingContext _parsingContext;

  ImpactStrategy impactStrategy = const ImpactStrategy();

  /**
   * Map from token to the first preceding comment token.
   */
  final TokenMap commentMap = new TokenMap();

  /// Options provided from command-line arguments.
  final CompilerOptions options;

  /**
   * If true, stop compilation after type inference is complete. Used for
   * debugging and testing purposes only.
   */
  bool stopAfterTypeInference = false;

  /// Output provider from user of Compiler API.
  api.CompilerOutput userOutputProvider;

  List<Uri> librariesToAnalyzeWhenRun;

  ResolvedUriTranslator get resolvedUriTranslator;

  LibraryEntity mainApp;
  FunctionEntity mainFunction;

  DiagnosticReporter get reporter => _reporter;
  ElementEnvironment get elementEnvironment => _elementEnvironment;
  CommonElements get commonElements => _commonElements;
  Resolution get resolution => _resolution;
  ParsingContext get parsingContext => _parsingContext;

  // TODO(zarah): Remove this map and incorporate compile-time errors
  // in the model.
  /// Tracks elements with compile-time errors.
  final Map<Entity, List<DiagnosticMessage>> elementsWithCompileTimeErrors =
      new Map<Entity, List<DiagnosticMessage>>();

  final Environment environment;
  // TODO(sigmund): delete once we migrate the rest of the compiler to use
  // `environment` directly.
  @deprecated
  fromEnvironment(String name) => environment.valueOf(name);

  Entity get currentElement => _reporter.currentElement;

  List<CompilerTask> tasks;
  ScannerTask scanner;
  DietParserTask dietParser;
  ParserTask parser;
  PatchParserTask patchParser;
  LibraryLoaderTask libraryLoader;
  SerializationTask serialization;
  ResolverTask resolver;
  closureMapping.ClosureTask closureToClassMapper;
  TypeCheckerTask checker;
  GlobalTypeInferenceTask globalInference;
  JavaScriptBackend backend;
  CodegenWorldBuilder _codegenWorldBuilder;

  GenericTask selfTask;

  /// The constant environment for the frontend interpretation of compile-time
  /// constants.
  ConstantEnvironment constants;

  EnqueueTask enqueuer;
  DeferredLoadTask deferredLoadTask;
  MirrorUsageAnalyzerTask mirrorUsageAnalyzerTask;
  DumpInfoTask dumpInfoTask;

  bool get hasCrashed => _reporter.hasCrashed;

  Stopwatch progress;

  bool get shouldPrintProgress {
    return options.verbose && progress.elapsedMilliseconds > 500;
  }

  static const int PHASE_SCANNING = 0;
  static const int PHASE_RESOLVING = 1;
  static const int PHASE_DONE_RESOLVING = 2;
  static const int PHASE_COMPILING = 3;
  int phase;

  bool compilationFailed = false;

  Compiler(
      {CompilerOptions options,
      api.CompilerOutput outputProvider,
      this.environment: const _EmptyEnvironment(),
      MakeReporterFunction makeReporter})
      : this.options = options,
        this.userOutputProvider = outputProvider == null
            ? const NullCompilerOutput()
            : outputProvider {
    if (makeReporter != null) {
      _reporter = makeReporter(this, options);
    } else {
      _reporter = new CompilerDiagnosticReporter(this, options);
    }
    frontEndStrategy = options.loadFromDill
        ? new KernelFrontEndStrategy(reporter, environment)
        : new ResolutionFrontEndStrategy(this);
    backendStrategy = options.loadFromDill
        ? new KernelBackendStrategy(this)
        : new ElementBackendStrategy(this);
    _resolution = createResolution();
    _elementEnvironment = frontEndStrategy.elementEnvironment;
    _commonElements = new CommonElements(_elementEnvironment);
    types = new Types(_resolution);

    if (options.verbose) {
      progress = new Stopwatch()..start();
    }

    backend = createBackend();
    enqueuer = backend.makeEnqueuer();

    tasks = [
      dietParser = new DietParserTask(idGenerator, backend, reporter, measurer),
      scanner = createScannerTask(),
      serialization = new SerializationTask(this),
      patchParser = new PatchParserTask(this),
      libraryLoader = frontEndStrategy.createLibraryLoader(
          resolvedUriTranslator,
          options.compileOnly
              ? new _NoScriptLoader(this)
              : new _ScriptLoader(this),
          new _ElementScanner(scanner),
          serialization,
          resolvePatchUri,
          patchParser,
          environment,
          reporter,
          measurer),
      parser = new ParserTask(this),
      resolver = createResolverTask(),
      closureToClassMapper = new closureMapping.ClosureTask(this),
      checker = new TypeCheckerTask(this),
      globalInference = new GlobalTypeInferenceTask(this),
      constants = backend.constantCompilerTask,
      deferredLoadTask = new DeferredLoadTask(this),
      mirrorUsageAnalyzerTask = new MirrorUsageAnalyzerTask(this),
      // [enqueuer] is created earlier because it contains the resolution world
      // objects needed by other tasks.
      enqueuer,
      dumpInfoTask = new DumpInfoTask(this),
      selfTask = new GenericTask('self', measurer),
    ];
    if (options.resolveOnly) {
      serialization.supportSerialization = true;
    }

    _parsingContext =
        new ParsingContext(reporter, parser, scanner, patchParser, backend);

    tasks.addAll(backend.tasks);
  }

  /// Creates the backend.
  ///
  /// Override this to mock the backend for testing.
  JavaScriptBackend createBackend() {
    return new JavaScriptBackend(this,
        generateSourceMap: options.generateSourceMap,
        useStartupEmitter: options.useStartupEmitter,
        useMultiSourceInfo: options.useMultiSourceInfo,
        useNewSourceInfo: options.useNewSourceInfo);
  }

  /// Creates the scanner task.
  ///
  /// Override this to mock the scanner for testing.
  ScannerTask createScannerTask() =>
      new ScannerTask(dietParser, reporter, measurer,
          preserveComments: options.preserveComments, commentMap: commentMap);

  /// Creates the resolution object.
  ///
  /// Override this to mock resolution for testing.
  Resolution createResolution() => new CompilerResolution(this);

  /// Creates the resolver task.
  ///
  /// Override this to mock the resolver for testing.
  ResolverTask createResolverTask() {
    return new ResolverTask(resolution, backend.constantCompilerTask, measurer);
  }

  ResolutionWorldBuilder get resolutionWorldBuilder =>
      enqueuer.resolution.worldBuilder;
  CodegenWorldBuilder get codegenWorldBuilder {
    assert(invariant(NO_LOCATION_SPANNABLE, _codegenWorldBuilder != null,
        message: "CodegenWorldBuilder has not been created yet."));
    return _codegenWorldBuilder;
  }

  bool get analyzeAll => options.analyzeAll || compileAll;

  bool get compileAll => false;

  bool get disableTypeInference =>
      options.disableTypeInference || compilationFailed;

  // Compiles the dart script at [uri].
  //
  // The resulting future will complete with true if the compilation
  // succeeded.
  Future<bool> run(Uri uri) => selfTask.measureSubtask("Compiler.run", () {
        measurer.startWallClock();

        return new Future.sync(() => runInternal(uri))
            .catchError((error) => _reporter.onError(uri, error))
            .whenComplete(() {
          measurer.stopWallClock();
        }).then((_) {
          return !compilationFailed;
        });
      });

  /// Compute the set of distinct import chains to the library at [uri] within
  /// [loadedLibraries].
  ///
  /// The chains are strings of the form
  ///
  ///       <main-uri> => <intermediate-uri1> => <intermediate-uri2> => <uri>
  ///
  Set<String> computeImportChainsFor(LoadedLibraries loadedLibraries, Uri uri) {
    // TODO(johnniwinther): Move computation of dependencies to the library
    // loader.
    Set<String> importChains = new Set<String>();
    // The maximum number of full imports chains to process.
    final int chainLimit = 10000;
    // The maximum number of imports chains to show.
    final int compactChainLimit = options.verbose ? 20 : 10;
    int chainCount = 0;
    loadedLibraries.forEachImportChain(uri,
        callback: (Link<Uri> importChainReversed) {
      Link<CodeLocation> compactImportChain = const Link<CodeLocation>();
      CodeLocation currentCodeLocation =
          new UriLocation(importChainReversed.head);
      compactImportChain = compactImportChain.prepend(currentCodeLocation);
      for (Link<Uri> link = importChainReversed.tail;
          !link.isEmpty;
          link = link.tail) {
        Uri uri = link.head;
        if (!currentCodeLocation.inSameLocation(uri)) {
          currentCodeLocation =
              options.verbose ? new UriLocation(uri) : new CodeLocation(uri);
          compactImportChain = compactImportChain.prepend(currentCodeLocation);
        }
      }
      String importChain = compactImportChain.map((CodeLocation codeLocation) {
        return codeLocation.relativize(
            (loadedLibraries.rootLibrary as LibraryElement).canonicalUri);
      }).join(' => ');

      if (!importChains.contains(importChain)) {
        if (importChains.length > compactChainLimit) {
          importChains.add('...');
          return false;
        } else {
          importChains.add(importChain);
        }
      }

      chainCount++;
      if (chainCount > chainLimit) {
        // Assume there are more import chains.
        importChains.add('...');
        return false;
      }
      return true;
    });
    return importChains;
  }

  /// This method is called when all new libraries loaded through
  /// [LibraryLoader.loadLibrary] has been loaded and their imports/exports
  /// have been computed.
  ///
  /// [loadedLibraries] contains the newly loaded libraries.
  ///
  /// The method returns a [Future] allowing for the loading of additional
  /// libraries.
  LoadedLibraries processLoadedLibraries(LoadedLibraries loadedLibraries) {
    loadedLibraries.forEachLibrary((LibraryEntity library) {
      backend.setAnnotations(library);
    });

    // TODO(efortuna, sigmund): These validation steps should be done in the
    // front end for the Kernel path since Kernel doesn't have the notion of
    // imports (everything has already been resolved). (See
    // https://github.com/dart-lang/sdk/issues/29368)
    if (!options.useKernel && !options.loadFromDill) {
      for (Uri uri in resolvedUriTranslator.disallowedLibraryUris) {
        if (loadedLibraries.containsLibrary(uri)) {
          Set<String> importChains =
              computeImportChainsFor(loadedLibraries, uri);
          reporter.reportInfo(
              NO_LOCATION_SPANNABLE, MessageKind.DISALLOWED_LIBRARY_IMPORT, {
            'uri': uri,
            'importChain': importChains
                .join(MessageTemplate.DISALLOWED_LIBRARY_IMPORT_PADDING)
          });
        }
      }

      if (loadedLibraries.containsLibrary(Uris.dart_core)) {
        bool importsMirrorsLibrary =
            loadedLibraries.containsLibrary(Uris.dart_mirrors);
        if (importsMirrorsLibrary && !backend.supportsReflection) {
          Set<String> importChains =
              computeImportChainsFor(loadedLibraries, Uris.dart_mirrors);
          reporter.reportErrorMessage(NO_LOCATION_SPANNABLE,
              MessageKind.MIRRORS_LIBRARY_NOT_SUPPORT_BY_BACKEND, {
            'importChain': importChains
                .join(MessageTemplate.MIRRORS_NOT_SUPPORTED_BY_BACKEND_PADDING)
          });
        } else if (importsMirrorsLibrary &&
            !options.enableExperimentalMirrors) {
          Set<String> importChains =
              computeImportChainsFor(loadedLibraries, Uris.dart_mirrors);
          reporter.reportWarningMessage(
              NO_LOCATION_SPANNABLE, MessageKind.IMPORT_EXPERIMENTAL_MIRRORS, {
            'importChain': importChains
                .join(MessageTemplate.IMPORT_EXPERIMENTAL_MIRRORS_PADDING)
          });
        }
      }
    }
    backend.onLibrariesLoaded(loadedLibraries);
    return loadedLibraries;
  }

  /**
   * Get an [Uri] pointing to a patch for the dart: library with
   * the given path. Returns null if there is no patch.
   */
  Uri resolvePatchUri(String dartLibraryPath);

  Future runInternal(Uri uri) async {
    // TODO(ahe): This prevents memory leaks when invoking the compiler
    // multiple times. Implement a better mechanism where we can store
    // such caches in the compiler and get access to them through a
    // suitably maintained static reference to the current compiler.
    StringToken.canonicalizer.clear();
    Selector.canonicalizedValues.clear();

    // The selector objects held in static fields must remain canonical.
    for (Selector selector in Selectors.ALL) {
      Selector.canonicalizedValues
          .putIfAbsent(selector.hashCode, () => <Selector>[])
          .add(selector);
    }

    assert(uri != null || options.analyzeOnly);
    // As far as I can tell, this branch is only used by test code.
    if (librariesToAnalyzeWhenRun != null) {
      await Future.forEach(librariesToAnalyzeWhenRun, (libraryUri) async {
        reporter.log('Analyzing $libraryUri (${options.buildId})');
        LoadedLibraries loadedLibraries =
            await libraryLoader.loadLibrary(libraryUri);
        processLoadedLibraries(loadedLibraries);
      });
    }
    if (uri != null) {
      if (options.analyzeOnly) {
        reporter.log('Analyzing $uri (${options.buildId})');
      } else {
        reporter.log('Compiling $uri (${options.buildId})');
      }
      LoadedLibraries libraries = await libraryLoader.loadLibrary(uri);
      processLoadedLibraries(libraries);
      mainApp = libraries.rootLibrary;
    }
    compileLoadedLibraries(mainApp);
  }

  /// Analyze all members of the library in [libraryUri].
  ///
  /// If [skipLibraryWithPartOfTag] is `true`, member analysis is skipped if the
  /// library has a `part of` tag, assuming it is a part and not a library.
  ///
  /// This operation assumes an unclosed resolution queue and is only supported
  /// when the '--analyze-main' option is used.
  Future<LibraryElement> analyzeUri(Uri libraryUri,
      {bool skipLibraryWithPartOfTag: true}) async {
    assert(options.analyzeMain);
    reporter.log('Analyzing $libraryUri (${options.buildId})');
    LoadedLibraries loadedLibraries = await libraryLoader
        .loadLibrary(libraryUri, skipFileWithPartOfTag: true);
    if (loadedLibraries == null) return null;
    processLoadedLibraries(loadedLibraries);
    LibraryElement library = loadedLibraries.rootLibrary;
    ResolutionEnqueuer resolutionEnqueuer = startResolution();
    resolutionEnqueuer.applyImpact(computeImpactForLibrary(library));
    emptyQueue(resolutionEnqueuer, onProgress: showResolutionProgress);
    resolutionEnqueuer.logSummary(reporter.log);
    return library;
  }

  /// Starts the resolution phase, creating the [ResolutionEnqueuer] if not
  /// already created.
  ///
  /// During normal compilation resolution only started once, but through
  /// [analyzeUri] resolution is started repeatedly.
  ResolutionEnqueuer startResolution() {
    ResolutionEnqueuer resolutionEnqueuer;
    if (enqueuer.hasResolution) {
      resolutionEnqueuer = enqueuer.resolution;
    } else {
      resolutionEnqueuer = enqueuer.createResolutionEnqueuer();
      backend.onResolutionStart(resolutionEnqueuer);
    }
    resolutionEnqueuer.addDeferredActions(libraryLoader.pullDeferredActions());
    return resolutionEnqueuer;
  }

  /// Performs the compilation when all libraries have been loaded.
  void compileLoadedLibraries(LibraryEntity rootLibrary) =>
      selfTask.measureSubtask("Compiler.compileLoadedLibraries", () {
        ResolutionEnqueuer resolutionEnqueuer = startResolution();
        WorldImpactBuilderImpl mainImpact = new WorldImpactBuilderImpl();
        mainFunction = frontEndStrategy.computeMain(rootLibrary, mainImpact);

        if (!options.loadFromDill) {
          // TODO(johnniwinther): Support mirrors usages analysis from dill.
          mirrorUsageAnalyzerTask.analyzeUsage(rootLibrary);
        }

        // In order to see if a library is deferred, we must compute the
        // compile-time constants that are metadata.  This means adding
        // something to the resolution queue.  So we cannot wait with
        // this until after the resolution queue is processed.
        deferredLoadTask.beforeResolution(this);
        impactStrategy = backend.createImpactStrategy(
            supportDeferredLoad: deferredLoadTask.isProgramSplit,
            supportDumpInfo: options.dumpInfo,
            supportSerialization: serialization.supportSerialization);

        phase = PHASE_RESOLVING;
        resolutionEnqueuer.applyImpact(mainImpact);
        if (options.resolveOnly) {
          libraryLoader.libraries.where((LibraryEntity library) {
            return !serialization.isDeserialized(library);
          }).forEach((LibraryEntity library) {
            reporter.log('Enqueuing ${library.canonicalUri}');
            resolutionEnqueuer.applyImpact(computeImpactForLibrary(library));
          });
        } else if (analyzeAll) {
          libraryLoader.libraries.forEach((LibraryEntity library) {
            reporter.log('Enqueuing ${library.canonicalUri}');
            resolutionEnqueuer.applyImpact(computeImpactForLibrary(library));
          });
        } else if (options.analyzeMain) {
          if (rootLibrary != null) {
            resolutionEnqueuer
                .applyImpact(computeImpactForLibrary(rootLibrary));
          }
          if (librariesToAnalyzeWhenRun != null) {
            for (Uri libraryUri in librariesToAnalyzeWhenRun) {
              resolutionEnqueuer.applyImpact(computeImpactForLibrary(
                  libraryLoader.lookupLibrary(libraryUri)));
            }
          }
        }
        if (commonElements.mirrorsLibrary != null && !options.loadFromDill) {
          // TODO(johnniwinther): Support mirrors from dill.
          resolveLibraryMetadata();
        }
        reporter.log('Resolving...');

        processQueue(resolutionEnqueuer, mainFunction, libraryLoader.libraries,
            onProgress: showResolutionProgress);
        backend.onResolutionEnd();
        resolutionEnqueuer.logSummary(reporter.log);

        _reporter.reportSuppressedMessagesSummary();

        if (compilationFailed) {
          if (!options.generateCodeWithCompileTimeErrors) return;
          if (mainFunction == null) return;
          if (!backend
              .enableCodegenWithErrorsIfSupported(NO_LOCATION_SPANNABLE)) {
            return;
          }
        }

        if (options.resolveOnly && !compilationFailed) {
          reporter.log('Serializing to ${options.resolutionOutput}');
          serialization.serializeToSink(
              userOutputProvider.createOutputSink(
                  '', 'data', api.OutputType.serializationData),
              libraryLoader.libraries.where((LibraryEntity library) {
            return !serialization.isDeserialized(library);
          }));
        }
        if (options.analyzeOnly) return;
        assert(mainFunction != null);

        ClosedWorldRefiner closedWorldRefiner = closeResolution();
        ClosedWorld closedWorld = closedWorldRefiner.closedWorld;

        reporter.log('Inferring types...');
        globalInference.runGlobalTypeInference(
            mainFunction, closedWorld, closedWorldRefiner);

        if (stopAfterTypeInference) return;

        backend.onTypeInferenceComplete(globalInference.results);

        reporter.log('Compiling...');
        phase = PHASE_COMPILING;

        Enqueuer codegenEnqueuer = enqueuer.createCodegenEnqueuer(closedWorld);
        _codegenWorldBuilder = codegenEnqueuer.worldBuilder;
        codegenEnqueuer.applyImpact(
            backend.onCodegenStart(closedWorld, _codegenWorldBuilder));
        if (compileAll) {
          libraryLoader.libraries.forEach((LibraryEntity library) {
            codegenEnqueuer.applyImpact(computeImpactForLibrary(library));
          });
        }
        processQueue(codegenEnqueuer, mainFunction, libraryLoader.libraries,
            onProgress: showCodegenProgress);
        codegenEnqueuer.logSummary(reporter.log);

        int programSize = backend.assembleProgram(closedWorld);

        if (options.dumpInfo) {
          dumpInfoTask.reportSize(programSize);
          dumpInfoTask.dumpInfo(closedWorld);
        }

        backend.onCodegenEnd();

        checkQueues(resolutionEnqueuer, codegenEnqueuer);
      });

  /// Perform the steps needed to fully end the resolution phase.
  ClosedWorldRefiner closeResolution() {
    phase = PHASE_DONE_RESOLVING;

    ClosedWorld closedWorld = resolutionWorldBuilder.closeWorld();
    ClosedWorldRefiner closedWorldRefiner =
        backendStrategy.createClosedWorldRefiner(closedWorld);
    // Compute whole-program-knowledge that the backend needs. (This might
    // require the information computed in [world.closeWorld].)
    backend.onResolutionClosedWorld(closedWorld, closedWorldRefiner);

    deferredLoadTask.onResolutionComplete(mainFunction, closedWorld);

    // TODO(johnniwinther): Move this after rti computation but before
    // reflection members computation, and (re-)close the world afterwards.
    backendStrategy.convertClosures(closedWorldRefiner);
    return closedWorldRefiner;
  }

  /// Compute the [WorldImpact] for accessing all elements in [library].
  WorldImpact computeImpactForLibrary(LibraryElement library) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();

    void registerStaticUse(Element element) {
      impactBuilder.registerStaticUse(new StaticUse.directUse(element));
    }

    void registerElement(Element element) {
      if (element.isClass) {
        ClassElement cls = element;
        cls.ensureResolved(resolution);
        cls.forEachLocalMember(registerStaticUse);
        impactBuilder.registerTypeUse(new TypeUse.instantiation(cls.rawType));
      } else if (element.isTypedef) {
        TypedefElement typdef = element;
        typdef.ensureResolved(resolution);
      } else {
        registerStaticUse(element);
      }
    }

    library.implementation.forEachLocalMember(registerElement);

    library.imports.forEach((ImportElement import) {
      if (import.isDeferred) {
        // `import.prefix` and `loadLibrary` may be `null` when the deferred
        // import has compile-time errors.
        GetterElement loadLibrary = import.prefix?.loadLibrary;
        if (loadLibrary != null) {
          registerStaticUse(loadLibrary);
        }
      }
      if (serialization.supportSerialization) {
        for (MetadataAnnotation metadata in import.metadata) {
          metadata.ensureResolved(resolution);
        }
      }
    });
    if (serialization.supportSerialization) {
      library.exports.forEach((ExportElement export) {
        for (MetadataAnnotation metadata in export.metadata) {
          metadata.ensureResolved(resolution);
        }
      });
      library.compilationUnits.forEach((CompilationUnitElement unit) {
        for (MetadataAnnotation metadata in unit.metadata) {
          metadata.ensureResolved(resolution);
        }
      });
    }
    return impactBuilder;
  }

  // Resolves metadata on library elements.  This is necessary in order to
  // resolve metadata classes referenced only from metadata on library tags.
  // TODO(ahe): Figure out how to do this lazily.
  void resolveLibraryMetadata() {
    assert(commonElements.mirrorsLibrary != null);
    for (LibraryElement library in libraryLoader.libraries) {
      if (library.metadata != null) {
        for (MetadataAnnotation metadata in library.metadata) {
          metadata.ensureResolved(resolution);
        }
      }
    }
  }

  /**
   * Empty the [enqueuer] queue.
   */
  void emptyQueue(Enqueuer enqueuer, {void onProgress(Enqueuer enqueuer)}) {
    selfTask.measureSubtask("Compiler.emptyQueue", () {
      enqueuer.forEach((WorkItem work) {
        if (onProgress != null) {
          onProgress(enqueuer);
        }
        reporter.withCurrentElement(
            work.element,
            () => selfTask.measureSubtask("world.applyImpact", () {
                  enqueuer.applyImpact(
                      selfTask.measureSubtask("work.run", () => work.run()),
                      impactSource: work.element);
                }));
      });
    });
  }

  void processQueue(Enqueuer enqueuer, FunctionEntity mainMethod,
      Iterable<LibraryEntity> libraries,
      {void onProgress(Enqueuer enqueuer)}) {
    selfTask.measureSubtask("Compiler.processQueue", () {
      enqueuer.open(impactStrategy, mainMethod, libraries);
      if (options.verbose) {
        progress.reset();
      }
      emptyQueue(enqueuer, onProgress: onProgress);
      enqueuer.queueIsClosed = true;
      enqueuer.close();
      // Notify the impact strategy impacts are no longer needed for this
      // enqueuer.
      impactStrategy.onImpactUsed(enqueuer.impactUse);
      assert(compilationFailed ||
          enqueuer.checkNoEnqueuedInvokedInstanceMethods(elementEnvironment));
    });
  }

  /**
   * Perform various checks of the queues. This includes checking that
   * the queues are empty (nothing was added after we stopped
   * processing the queues). Also compute the number of methods that
   * were resolved, but not compiled (aka excess resolution).
   */
  checkQueues(Enqueuer resolutionEnqueuer, Enqueuer codegenEnqueuer) {
    for (Enqueuer enqueuer in [resolutionEnqueuer, codegenEnqueuer]) {
      enqueuer.checkQueueIsEmpty();
    }
    if (!REPORT_EXCESS_RESOLUTION) return;
    var resolved = new Set.from(resolutionEnqueuer.processedEntities);
    for (MemberEntity e in codegenEnqueuer.processedEntities) {
      resolved.remove(e);
    }
    for (MemberEntity e in new Set.from(resolved)) {
      if (e.isField) {
        resolved.remove(e);
      }
      if (e.isConstructor && (e as ConstructorEntity).isGenerativeConstructor) {
        resolved.remove(e);
      }
      if (backend.isTargetSpecificLibrary(e.library)) {
        resolved.remove(e);
      }
    }
    reporter.log('Excess resolution work: ${resolved.length}.');
    for (MemberEntity e in resolved) {
      reporter.reportWarningMessage(e, MessageKind.GENERIC,
          {'text': 'Warning: $e resolved but not compiled.'});
    }
  }

  void showResolutionProgress(Enqueuer enqueuer) {
    if (shouldPrintProgress) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      assert(phase == PHASE_RESOLVING);
      reporter.log('Resolved ${enqueuer.processedEntities.length} '
          'elements.');
      progress.reset();
    }
  }

  void showCodegenProgress(Enqueuer enqueuer) {
    if (shouldPrintProgress) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      reporter.log('Compiled ${enqueuer.processedEntities.length} methods.');
      progress.reset();
    }
  }

  void reportDiagnostic(DiagnosticMessage message,
      List<DiagnosticMessage> infos, api.Diagnostic kind);

  void reportCrashInUserCode(String message, exception, stackTrace) {
    reporter.onCrashInUserCode(message, exception, stackTrace);
  }

  /// Messages for which compile-time errors are reported but compilation
  /// continues regardless.
  static const List<MessageKind> BENIGN_ERRORS = const <MessageKind>[
    MessageKind.INVALID_METADATA,
    MessageKind.INVALID_METADATA_GENERIC,
  ];

  bool markCompilationAsFailed(DiagnosticMessage message, api.Diagnostic kind) {
    if (options.testMode) {
      // When in test mode, i.e. on the build-bot, we always stop compilation.
      return true;
    }
    if (reporter.options.fatalWarnings) {
      return true;
    }
    return !BENIGN_ERRORS.contains(message.message.kind);
  }

  void fatalDiagnosticReported(DiagnosticMessage message,
      List<DiagnosticMessage> infos, api.Diagnostic kind) {
    if (markCompilationAsFailed(message, kind)) {
      compilationFailed = true;
    }
    registerCompileTimeError(currentElement, message);
  }

  /**
   * Reads the script specified by the [readableUri].
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Future<Script> readScript(Uri readableUri, [Spannable node]) {
    throw new SpannableAssertionFailure(
        node, 'Compiler.readScript not implemented.');
  }

  Future<Binary> readBinary(Uri readableUri, [Spannable node]) {
    throw new SpannableAssertionFailure(
        node, 'Compiler.readBinary not implemented.');
  }

  Element lookupElementIn(ScopeContainerElement container, String name) {
    Element element = container.localLookup(name);
    if (element == null) {
      throw 'Could not find $name in $container';
    }
    return element;
  }

  bool get isMockCompilation => false;

  /// Helper for determining whether the current element is declared within
  /// 'user code'.
  ///
  /// See [inUserCode] for what defines 'user code'.
  bool currentlyInUserCode() {
    return inUserCode(currentElement);
  }

  /// Helper for determining whether [element] is declared within 'user code'.
  ///
  /// What constitutes 'user code' is defined by the URI(s) provided by the
  /// entry point(s) of compilation or analysis:
  ///
  /// If an entrypoint URI uses the 'package' scheme then every library from
  /// that same package is considered to be in user code. For instance, if
  /// an entry point URI is 'package:foo/bar.dart' then every library whose
  /// canonical URI starts with 'package:foo/' is in user code.
  ///
  /// If an entrypoint URI uses another scheme than 'package' then every library
  /// with that scheme is in user code. For instance, an entry point URI is
  /// 'file:///foo.dart' then every library whose canonical URI scheme is
  /// 'file' is in user code.
  ///
  /// If [assumeInUserCode] is `true`, [element] is assumed to be in user code
  /// if no entrypoints have been set.
  bool inUserCode(Element element, {bool assumeInUserCode: false}) {
    if (element == null) return false;
    Iterable<CodeLocation> userCodeLocations =
        computeUserCodeLocations(assumeInUserCode: assumeInUserCode);
    Uri libraryUri = element.library.canonicalUri;
    return userCodeLocations.any(
        (CodeLocation codeLocation) => codeLocation.inSameLocation(libraryUri));
  }

  Iterable<CodeLocation> computeUserCodeLocations(
      {bool assumeInUserCode: false}) {
    List<CodeLocation> userCodeLocations = <CodeLocation>[];
    if (mainApp != null) {
      userCodeLocations.add(new CodeLocation(mainApp.canonicalUri));
    }
    if (librariesToAnalyzeWhenRun != null) {
      userCodeLocations.addAll(
          librariesToAnalyzeWhenRun.map((Uri uri) => new CodeLocation(uri)));
    }
    if (userCodeLocations.isEmpty && assumeInUserCode) {
      // Assume in user code since [mainApp] has not been set yet.
      userCodeLocations.add(const AnyLocation());
    }
    return userCodeLocations;
  }

  /// Return a canonical URI for the source of [element].
  ///
  /// For a package library with canonical URI 'package:foo/bar/baz.dart' the
  /// return URI is 'package:foo'. For non-package libraries the returned URI is
  /// the canonical URI of the library itself.
  Uri getCanonicalUri(Element element) {
    if (element == null) return null;
    Uri libraryUri = element.library.canonicalUri;
    if (libraryUri.scheme == 'package') {
      int slashPos = libraryUri.path.indexOf('/');
      if (slashPos != -1) {
        String packageName = libraryUri.path.substring(0, slashPos);
        return new Uri(scheme: 'package', path: packageName);
      }
    }
    return libraryUri;
  }

  /// Returns [true] if a compile-time error has been reported for element.
  bool elementHasCompileTimeError(Entity element) {
    return elementsWithCompileTimeErrors.containsKey(element);
  }

  /// Associate [element] with a compile-time error [message].
  void registerCompileTimeError(Entity element, DiagnosticMessage message) {
    // The information is only needed if [generateCodeWithCompileTimeErrors].
    if (options.generateCodeWithCompileTimeErrors) {
      if (element == null) {
        // Record as global error.
        // TODO(zarah): Extend element model to represent compile-time
        // errors instead of using a map.
        element = mainFunction;
      }
      elementsWithCompileTimeErrors
          .putIfAbsent(element, () => <DiagnosticMessage>[])
          .add(message);
    }
  }

  api.OutputSink outputProvider(
      String name, String extension, api.OutputType type) {
    if (compilationFailed) {
      if (!options.generateCodeWithCompileTimeErrors || options.testMode) {
        // Disable output in test mode: The build bot currently uses the time
        // stamp of the generated file to determine whether the output is
        // up-to-date.
        return NullSink.outputProvider(name, extension, type);
      }
    }
    return userOutputProvider.createOutputSink(name, extension, type);
  }
}

/// Information about suppressed warnings and hints for a given library.
class SuppressionInfo {
  int warnings = 0;
  int hints = 0;
}

class CompilerDiagnosticReporter extends DiagnosticReporter {
  final Compiler compiler;
  final DiagnosticOptions options;

  Entity _currentElement;
  bool hasCrashed = false;

  /// `true` if the last diagnostic was filtered, in which case the
  /// accompanying info message should be filtered as well.
  bool lastDiagnosticWasFiltered = false;

  /// Map containing information about the warnings and hints that have been
  /// suppressed for each library.
  Map<Uri, SuppressionInfo> suppressedWarnings = <Uri, SuppressionInfo>{};

  CompilerDiagnosticReporter(this.compiler, this.options);

  Entity get currentElement => _currentElement;

  DiagnosticMessage createMessage(Spannable spannable, MessageKind messageKind,
      [Map arguments = const {}]) {
    SourceSpan span = spanFromSpannable(spannable);
    MessageTemplate template = MessageTemplate.TEMPLATES[messageKind];
    Message message = template.message(arguments, options.terseDiagnostics);
    return new DiagnosticMessage(span, spannable, message);
  }

  void reportError(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reportDiagnosticInternal(message, infos, api.Diagnostic.ERROR);
  }

  void reportWarning(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reportDiagnosticInternal(message, infos, api.Diagnostic.WARNING);
  }

  void reportHint(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reportDiagnosticInternal(message, infos, api.Diagnostic.HINT);
  }

  @deprecated
  void reportInfo(Spannable node, MessageKind messageKind,
      [Map arguments = const {}]) {
    reportDiagnosticInternal(createMessage(node, messageKind, arguments),
        const <DiagnosticMessage>[], api.Diagnostic.INFO);
  }

  void reportDiagnosticInternal(DiagnosticMessage message,
      List<DiagnosticMessage> infos, api.Diagnostic kind) {
    if (!options.showAllPackageWarnings &&
        message.spannable != NO_LOCATION_SPANNABLE) {
      switch (kind) {
        case api.Diagnostic.WARNING:
        case api.Diagnostic.HINT:
          Element element = elementFromSpannable(message.spannable);
          if (!compiler.inUserCode(element, assumeInUserCode: true)) {
            Uri uri = compiler.getCanonicalUri(element);
            if (options.showPackageWarningsFor(uri)) {
              reportDiagnostic(message, infos, kind);
              return;
            }
            SuppressionInfo info = suppressedWarnings.putIfAbsent(
                uri, () => new SuppressionInfo());
            if (kind == api.Diagnostic.WARNING) {
              info.warnings++;
            } else {
              info.hints++;
            }
            lastDiagnosticWasFiltered = true;
            return;
          }
          break;
        case api.Diagnostic.INFO:
          if (lastDiagnosticWasFiltered) {
            return;
          }
          break;
      }
    }
    lastDiagnosticWasFiltered = false;
    reportDiagnostic(message, infos, kind);
  }

  void reportDiagnostic(DiagnosticMessage message,
      List<DiagnosticMessage> infos, api.Diagnostic kind) {
    compiler.reportDiagnostic(message, infos, kind);
    if (kind == api.Diagnostic.ERROR ||
        kind == api.Diagnostic.CRASH ||
        (options.fatalWarnings && kind == api.Diagnostic.WARNING)) {
      Entity errorElement;
      if (message.spannable is Entity) {
        errorElement = message.spannable;
      } else {
        errorElement = currentElement;
      }
      compiler.registerCompileTimeError(errorElement, message);
      compiler.fatalDiagnosticReported(message, infos, kind);
    }
  }

  @override
  bool get hasReportedError => compiler.compilationFailed;

  /**
   * Perform an operation, [f], returning the return value from [f].  If an
   * error occurs then report it as having occurred during compilation of
   * [element].  Can be nested.
   */
  withCurrentElement(Entity element, f()) {
    Entity old = currentElement;
    _currentElement = element;
    try {
      return f();
    } on SpannableAssertionFailure catch (ex) {
      if (!hasCrashed) {
        reportAssertionFailure(ex);
        pleaseReportCrash();
      }
      hasCrashed = true;
      rethrow;
    } on StackOverflowError {
      // We cannot report anything useful in this case, because we
      // do not have enough stack space.
      rethrow;
    } catch (ex) {
      if (hasCrashed) rethrow;
      try {
        unhandledExceptionOnElement(element);
      } catch (doubleFault) {
        // Ignoring exceptions in exception handling.
      }
      rethrow;
    } finally {
      _currentElement = old;
    }
  }

  void reportAssertionFailure(SpannableAssertionFailure ex) {
    String message =
        (ex.message != null) ? tryToString(ex.message) : tryToString(ex);
    reportDiagnosticInternal(
        createMessage(ex.node, MessageKind.GENERIC, {'text': message}),
        const <DiagnosticMessage>[],
        api.Diagnostic.CRASH);
  }

  /// Using [frontEndStrategy] to compute a [SourceSpan] from spannable using
  /// the [currentElement] as context.
  SourceSpan _spanFromStrategy(Spannable spannable) {
    SourceSpan span =
        compiler.frontEndStrategy.spanFromSpannable(spannable, currentElement);
    if (span != null) return span;
    throw 'No error location.';
  }

  SourceSpan spanFromSpannable(Spannable spannable) {
    if (spannable == CURRENT_ELEMENT_SPANNABLE) {
      spannable = currentElement;
    } else if (spannable == NO_LOCATION_SPANNABLE) {
      if (currentElement == null) return null;
      spannable = currentElement;
    }
    if (spannable is SourceSpan) {
      return spannable;
    } else if (spannable is HInstruction) {
      Entity element = spannable.sourceElement;
      if (element == null) element = currentElement;
      SourceInformation position = spannable.sourceInformation;
      if (position != null) return position.sourceSpan;
      return _spanFromStrategy(element);
    } else if (spannable is Local) {
      Local local = spannable;
      return _spanFromStrategy(local.executableContext);
    } else {
      return _spanFromStrategy(spannable);
    }
  }

  // TODO(johnniwinther): Move this to the parser listeners.
  @override
  SourceSpan spanFromToken(Token token) {
    if (compiler.frontEndStrategy is ResolutionFrontEndStrategy) {
      ResolutionFrontEndStrategy strategy = compiler.frontEndStrategy;
      return strategy.spanFromToken(currentElement, token);
    }
    throw 'No error location.';
  }

  Element _elementFromHInstruction(HInstruction instruction) {
    return instruction.sourceElement is Element
        ? instruction.sourceElement
        : null;
  }

  internalError(Spannable spannable, reason) {
    String message = tryToString(reason);
    reportDiagnosticInternal(
        createMessage(spannable, MessageKind.GENERIC, {'text': message}),
        const <DiagnosticMessage>[],
        api.Diagnostic.CRASH);
    throw 'Internal Error: $message';
  }

  void unhandledExceptionOnElement(Entity element) {
    if (hasCrashed) return;
    hasCrashed = true;
    reportDiagnostic(createMessage(element, MessageKind.COMPILER_CRASHED),
        const <DiagnosticMessage>[], api.Diagnostic.CRASH);
    pleaseReportCrash();
  }

  void pleaseReportCrash() {
    print(MessageTemplate.TEMPLATES[MessageKind.PLEASE_REPORT_THE_CRASH]
        .message({'buildId': compiler.options.buildId}));
  }

  /// Finds the approximate [Element] for [node]. [currentElement] is used as
  /// the default value.
  Element elementFromSpannable(Spannable node) {
    Element element;
    if (node is Element) {
      element = node;
    } else if (node is HInstruction) {
      element = _elementFromHInstruction(node);
    } else if (node is MetadataAnnotation) {
      element = node.annotatedElement;
    }
    return element != null ? element : currentElement;
  }

  void log(message) {
    Message msg = MessageTemplate.TEMPLATES[MessageKind.GENERIC]
        .message({'text': '$message'});
    reportDiagnostic(new DiagnosticMessage(null, null, msg),
        const <DiagnosticMessage>[], api.Diagnostic.VERBOSE_INFO);
  }

  String tryToString(object) {
    try {
      return object.toString();
    } catch (_) {
      return '<exception in toString()>';
    }
  }

  onError(Uri uri, error) {
    try {
      if (!hasCrashed) {
        hasCrashed = true;
        if (error is SpannableAssertionFailure) {
          reportAssertionFailure(error);
        } else {
          reportDiagnostic(
              createMessage(
                  new SourceSpan(uri, 0, 0), MessageKind.COMPILER_CRASHED),
              const <DiagnosticMessage>[],
              api.Diagnostic.CRASH);
        }
        pleaseReportCrash();
      }
    } catch (doubleFault) {
      // Ignoring exceptions in exception handling.
    }
    throw error;
  }

  @override
  void onCrashInUserCode(String message, exception, stackTrace) {
    hasCrashed = true;
    print('$message: ${tryToString(exception)}');
    print(tryToString(stackTrace));
  }

  void reportSuppressedMessagesSummary() {
    if (!options.showAllPackageWarnings && !options.suppressWarnings) {
      suppressedWarnings.forEach((Uri uri, SuppressionInfo info) {
        MessageKind kind = MessageKind.HIDDEN_WARNINGS_HINTS;
        if (info.warnings == 0) {
          kind = MessageKind.HIDDEN_HINTS;
        } else if (info.hints == 0) {
          kind = MessageKind.HIDDEN_WARNINGS;
        }
        MessageTemplate template = MessageTemplate.TEMPLATES[kind];
        Message message = template.message(
            {'warnings': info.warnings, 'hints': info.hints, 'uri': uri},
            options.terseDiagnostics);
        reportDiagnostic(new DiagnosticMessage(null, null, message),
            const <DiagnosticMessage>[], api.Diagnostic.HINT);
      });
    }
  }
}

// TODO(johnniwinther): Move [ResolverTask] here.
class CompilerResolution implements Resolution {
  final Compiler _compiler;
  final Map<Element, ResolutionImpact> _resolutionImpactCache =
      <Element, ResolutionImpact>{};
  final Map<Element, WorldImpact> _worldImpactCache = <Element, WorldImpact>{};
  bool retainCachesForTesting = false;

  CompilerResolution(this._compiler);

  @override
  DiagnosticReporter get reporter => _compiler.reporter;

  @override
  ParsingContext get parsingContext => _compiler.parsingContext;

  @override
  CommonElements get commonElements => _compiler.commonElements;

  @override
  Types get types => _compiler.types;

  @override
  Target get target => _compiler.backend.target;

  @override
  ResolverTask get resolver => _compiler.resolver;

  @override
  ResolutionEnqueuer get enqueuer => _compiler.enqueuer.resolution;

  @override
  CompilerOptions get options => _compiler.options;

  @override
  IdGenerator get idGenerator => _compiler.idGenerator;

  @override
  ConstantEnvironment get constants => _compiler.constants;

  @override
  MirrorUsageAnalyzerTask get mirrorUsageAnalyzerTask =>
      _compiler.mirrorUsageAnalyzerTask;

  LibraryElement get coreLibrary => _compiler._commonElements.coreLibrary;

  @override
  bool get wasProxyConstantComputedTestingOnly => _proxyConstant != null;

  @override
  void registerClass(ClassElement cls) {
    enqueuer.worldBuilder.registerClass(cls);
  }

  @override
  void resolveClass(ClassElement cls) {
    _compiler.resolver.resolveClass(cls);
  }

  @override
  void resolveTypedef(TypedefElement typdef) {
    _compiler.resolver.resolve(typdef);
  }

  @override
  void resolveMetadataAnnotation(MetadataAnnotation metadataAnnotation) {
    _compiler.resolver.resolveMetadataAnnotation(metadataAnnotation);
  }

  @override
  FunctionSignature resolveSignature(FunctionElement function) {
    return _compiler.resolver.resolveSignature(function);
  }

  @override
  ResolutionDartType resolveTypeAnnotation(
      Element element, TypeAnnotation node) {
    return _compiler.resolver.resolveTypeAnnotation(element, node);
  }

  @override
  void ensureResolved(Element element) {
    if (_compiler.serialization.isDeserialized(element)) {
      return;
    }
    computeWorldImpact(element);
  }

  @override
  void ensureClassMembers(ClassElement element) {
    if (!_compiler.serialization.isDeserialized(element)) {
      _compiler.resolver.checkClass(element);
    }
  }

  @override
  void registerCompileTimeError(Element element, DiagnosticMessage message) =>
      _compiler.registerCompileTimeError(element, message);

  @override
  bool hasResolvedAst(ExecutableElement element) {
    assert(invariant(element, element.isDeclaration,
        message: "Element $element must be the declaration."));
    if (_compiler.serialization.isDeserialized(element)) {
      return _compiler.serialization.hasResolvedAst(element);
    }
    return hasBeenResolved(element.memberContext.declaration) &&
        element.hasResolvedAst;
  }

  @override
  ResolvedAst getResolvedAst(ExecutableElement element) {
    assert(invariant(element, element.isDeclaration,
        message: "Element $element must be the declaration."));
    assert(invariant(element, hasResolvedAst(element),
        message: "ResolvedAst not available for $element."));
    if (_compiler.serialization.isDeserialized(element)) {
      return _compiler.serialization.getResolvedAst(element);
    }
    return element.resolvedAst;
  }

  @override
  ResolvedAst computeResolvedAst(Element element) {
    ensureResolved(element);
    return getResolvedAst(element);
  }

  @override
  bool hasResolutionImpact(Element element) {
    assert(invariant(element, element.isDeclaration,
        message: "Element $element must be the declaration."));
    if (_compiler.serialization.isDeserialized(element)) {
      return _compiler.serialization.hasResolutionImpact(element);
    }
    return _resolutionImpactCache.containsKey(element);
  }

  @override
  ResolutionImpact getResolutionImpact(Element element) {
    assert(invariant(element, element.isDeclaration,
        message: "Element $element must be the declaration."));
    ResolutionImpact resolutionImpact;
    if (_compiler.serialization.isDeserialized(element)) {
      resolutionImpact = _compiler.serialization.getResolutionImpact(element);
    } else {
      resolutionImpact = _resolutionImpactCache[element];
    }
    assert(invariant(element, resolutionImpact != null,
        message: "ResolutionImpact not available for $element."));
    return resolutionImpact;
  }

  @override
  WorldImpact getWorldImpact(Element element) {
    assert(invariant(element, element.isDeclaration,
        message: "Element $element must be the declaration."));
    WorldImpact worldImpact = _worldImpactCache[element];
    assert(invariant(element, worldImpact != null,
        message: "WorldImpact not computed for $element."));
    return worldImpact;
  }

  @override
  WorldImpact computeWorldImpact(Element element) {
    return _compiler.selfTask.measureSubtask("Resolution.computeWorldImpact",
        () {
      assert(invariant(
          element,
          element.impliesType ||
              element.isField ||
              element.isFunction ||
              element.isConstructor ||
              element.isGetter ||
              element.isSetter,
          message: 'Unexpected element kind: ${element.kind}'));
      assert(invariant(element, element is AnalyzableElement,
          message: 'Element $element is not analyzable.'));
      assert(invariant(element, element.isDeclaration,
          message: "Element $element must be the declaration."));
      return _worldImpactCache.putIfAbsent(element, () {
        assert(_compiler.parser != null);
        Node tree = _compiler.parser.parse(element);
        assert(invariant(element, !element.isSynthesized || tree == null));
        ResolutionImpact resolutionImpact = _compiler.resolver.resolve(element);

        if (_compiler.serialization.supportSerialization ||
            retainCachesForTesting) {
          // [ResolutionImpact] is currently only used by serialization. The
          // enqueuer uses the [WorldImpact] which is always cached.
          // TODO(johnniwinther): Align these use cases better; maybe only
          // cache [ResolutionImpact] and let the enqueuer transform it into
          // a [WorldImpact].
          _resolutionImpactCache[element] = resolutionImpact;
        }
        if (tree != null && !_compiler.options.analyzeSignaturesOnly) {
          // TODO(het): don't do this if suppressWarnings is on, currently we
          // have to do it because the typechecker also sets types
          // Only analyze nodes with a corresponding [TreeElements].
          _compiler.checker.check(element);
        }
        return transformResolutionImpact(element, resolutionImpact);
      });
    });
  }

  @override
  WorldImpact transformResolutionImpact(
      Element element, ResolutionImpact resolutionImpact) {
    WorldImpact worldImpact = _compiler.backend.impactTransformer
        .transformResolutionImpact(resolutionImpact);
    _worldImpactCache[element] = worldImpact;
    return worldImpact;
  }

  @override
  void uncacheWorldImpact(Element element) {
    assert(invariant(element, element.isDeclaration,
        message: "Element $element must be the declaration."));
    if (retainCachesForTesting) return;
    if (_compiler.serialization.isDeserialized(element)) return;
    assert(invariant(element, _worldImpactCache[element] != null,
        message: "WorldImpact not computed for $element."));
    _worldImpactCache[element] = const WorldImpact();
    _resolutionImpactCache.remove(element);
  }

  @override
  void emptyCache() {
    if (retainCachesForTesting) return;
    for (Element element in _worldImpactCache.keys) {
      _worldImpactCache[element] = const WorldImpact();
    }
    _resolutionImpactCache.clear();
  }

  @override
  bool hasBeenResolved(Element element) {
    return _worldImpactCache.containsKey(element);
  }

  @override
  ResolutionWorkItem createWorkItem(MemberElement element) {
    if (_compiler.serialization.isDeserialized(element)) {
      return _compiler.serialization.createResolutionWorkItem(element);
    } else {
      return new ResolutionWorkItem(this, element);
    }
  }

  ConstantValue _proxyConstant;

  @override
  bool isProxyConstant(ConstantValue value) {
    FieldElement field = coreLibrary.find('proxy');
    if (field == null) return false;
    if (!hasBeenResolved(field)) return false;
    if (_proxyConstant == null) {
      _proxyConstant = constants
          .getConstantValue(resolver.constantCompiler.compileConstant(field));
    }
    return _proxyConstant == value;
  }
}

class _ScriptLoader implements ScriptLoader {
  Compiler compiler;
  _ScriptLoader(this.compiler);

  Future<Script> readScript(Uri uri, [Spannable spannable]) =>
      compiler.readScript(uri, spannable);

  Future<Binary> readBinary(Uri uri, [Spannable spannable]) =>
      compiler.readBinary(uri, spannable);
}

/// [ScriptLoader] used to ensure that scripts are not loaded accidentally
/// through the [LibraryLoader] when `CompilerOptions.compileOnly` is `true`.
class _NoScriptLoader implements ScriptLoader {
  Compiler compiler;
  _NoScriptLoader(this.compiler);

  Future<Script> readScript(Uri uri, [Spannable spannable]) {
    throw compiler.reporter
        .internalError(spannable, "Script loading of '$uri' is not enabled.");
  }

  Future<Binary> readBinary(Uri uri, [Spannable spannable]) {
    throw compiler.reporter
        .internalError(spannable, "Script loading of '$uri' is not enabled.");
  }
}

class _ElementScanner implements ElementScanner {
  ScannerTask scanner;
  _ElementScanner(this.scanner);
  void scanLibrary(LibraryElement library) => scanner.scanLibrary(library);
  void scanUnit(CompilationUnitElement unit) => scanner.scan(unit);
}

class _EmptyEnvironment implements Environment {
  const _EmptyEnvironment();

  String valueOf(String key) => null;
}
