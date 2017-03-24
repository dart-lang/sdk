// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.compiler_base;

import 'dart:async' show EventSink, Future;

import '../compiler_new.dart' as api;
import 'closure.dart' as closureMapping show ClosureTask;
import 'common/names.dart' show Selectors;
import 'common/names.dart' show Identifiers, Uris;
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
import 'common_elements.dart'
    show CommonElements, CommonElementsMixin, ElementEnvironment;
import 'deferred_load.dart' show DeferredLoadTask;
import 'diagnostics/code_location.dart';
import 'diagnostics/diagnostic_listener.dart' show DiagnosticReporter;
import 'diagnostics/invariant.dart' show REPORT_EXCESS_RESOLUTION;
import 'diagnostics/messages.dart' show Message, MessageTemplate;
import 'dump_info.dart' show DumpInfoTask;
import 'elements/elements.dart';
import 'elements/entities.dart';
import 'elements/modelx.dart' show ErroneousElementX;
import 'elements/resolution_types.dart'
    show
        ResolutionDartType,
        ResolutionDynamicType,
        ResolutionInterfaceType,
        Types;
import 'enqueue.dart'
    show DeferredAction, Enqueuer, EnqueueTask, ResolutionEnqueuer;
import 'environment.dart';
import 'id_generator.dart';
import 'io/source_information.dart' show SourceInformation;
import 'js_backend/backend.dart' show JavaScriptBackend;
import 'library_loader.dart'
    show
        ElementScanner,
        LibraryLoader,
        LibraryLoaderTask,
        LoadedLibraries,
        LibraryProvider,
        ScriptLoader;
import 'mirrors_used.dart' show MirrorUsageAnalyzerTask;
import 'null_compiler_output.dart' show NullCompilerOutput, NullSink;
import 'options.dart' show CompilerOptions, DiagnosticOptions;
import 'parser/diet_parser_task.dart' show DietParserTask;
import 'parser/parser_task.dart' show ParserTask;
import 'patch_parser.dart' show PatchParserTask;
import 'resolution/resolution.dart' show ResolverTask;
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
import 'universe/call_structure.dart' show CallStructure;
import 'universe/selector.dart' show Selector;
import 'universe/world_builder.dart'
    show ResolutionWorldBuilder, CodegenWorldBuilder;
import 'universe/use.dart' show StaticUse, TypeUse;
import 'universe/world_impact.dart'
    show ImpactStrategy, WorldImpact, WorldImpactBuilderImpl;
import 'util/util.dart' show Link;
import 'world.dart' show ClosedWorld, ClosedWorldRefiner, ClosedWorldImpl;

typedef CompilerDiagnosticReporter MakeReporterFunction(
    Compiler compiler, CompilerOptions options);

abstract class Compiler {
  Measurer get measurer;

  final IdGenerator idGenerator = new IdGenerator();
  Types types;
  _CompilerCommonElements _commonElements;
  _CompilerElementEnvironment _elementEnvironment;
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

  LibraryElement mainApp;
  MethodElement mainFunction;

  DiagnosticReporter get reporter => _reporter;
  ElementEnvironment get elementEnvironment => _elementEnvironment;
  CommonElements get commonElements => _commonElements;
  Resolution get resolution => _resolution;
  ParsingContext get parsingContext => _parsingContext;

  // TODO(zarah): Remove this map and incorporate compile-time errors
  // in the model.
  /// Tracks elements with compile-time errors.
  final Map<Element, List<DiagnosticMessage>> elementsWithCompileTimeErrors =
      new Map<Element, List<DiagnosticMessage>>();

  final Environment environment;
  // TODO(sigmund): delete once we migrate the rest of the compiler to use
  // `environment` directly.
  @deprecated
  fromEnvironment(String name) => environment.valueOf(name);

  Element get currentElement => _reporter.currentElement;

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
    _resolution = createResolution();
    _elementEnvironment = new _CompilerElementEnvironment(this);
    _commonElements =
        new _CompilerCommonElements(_elementEnvironment, _resolution, reporter);
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
      libraryLoader = new LibraryLoaderTask(
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
        useNewSourceInfo: options.useNewSourceInfo,
        useKernel: options.useKernel);
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

  // TODO(het): remove this from here. Either inline at all use sites or add it
  // to Reporter.
  void unimplemented(Spannable spannable, String methodName) {
    reporter.internalError(spannable, "$methodName not implemented.");
  }

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
        return codeLocation
            .relativize(loadedLibraries.rootLibrary.canonicalUri);
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
    loadedLibraries.forEachLibrary((LibraryElement library) {
      _commonElements.registerCommonLibraries(library);
      backend.setAnnotations(library);
    });

    for (Uri uri in resolvedUriTranslator.disallowedLibraryUris) {
      if (loadedLibraries.containsLibrary(uri)) {
        Set<String> importChains = computeImportChainsFor(loadedLibraries, uri);
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
      } else if (importsMirrorsLibrary && !options.enableExperimentalMirrors) {
        Set<String> importChains =
            computeImportChainsFor(loadedLibraries, Uris.dart_mirrors);
        reporter.reportWarningMessage(
            NO_LOCATION_SPANNABLE, MessageKind.IMPORT_EXPERIMENTAL_MIRRORS, {
          'importChain': importChains
              .join(MessageTemplate.IMPORT_EXPERIMENTAL_MIRRORS_PADDING)
        });
      }
    }
    backend.onLibrariesLoaded(loadedLibraries);
    return loadedLibraries;
  }

  // TODO(johnniwinther): Move this to [PatchParser] when it is moved to the
  // [JavaScriptBackend]. Currently needed for testing.
  String get patchVersion => backend.patchVersion;

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
    compileLoadedLibraries();
  }

  WorldImpact computeMain() {
    if (mainApp == null) return const WorldImpact();

    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    Element main = mainApp.findExported(Identifiers.main);
    ErroneousElement errorElement = null;
    if (main == null) {
      if (options.analyzeOnly) {
        if (!analyzeAll) {
          errorElement = new ErroneousElementX(MessageKind.CONSIDER_ANALYZE_ALL,
              {'main': Identifiers.main}, Identifiers.main, mainApp);
        }
      } else {
        // Compilation requires a main method.
        errorElement = new ErroneousElementX(MessageKind.MISSING_MAIN,
            {'main': Identifiers.main}, Identifiers.main, mainApp);
      }
      mainFunction = backend.helperForMissingMain();
    } else if (main.isError && main.isSynthesized) {
      if (main is ErroneousElement) {
        errorElement = main;
      } else {
        reporter.internalError(main, 'Problem with ${Identifiers.main}.');
      }
      mainFunction = backend.helperForBadMain();
    } else if (!main.isFunction) {
      errorElement = new ErroneousElementX(MessageKind.MAIN_NOT_A_FUNCTION,
          {'main': Identifiers.main}, Identifiers.main, main);
      mainFunction = backend.helperForBadMain();
    } else {
      mainFunction = main;
      mainFunction.computeType(resolution);
      FunctionSignature parameters = mainFunction.functionSignature;
      if (parameters.requiredParameterCount > 2) {
        int index = 0;
        parameters.orderedForEachParameter((Element parameter) {
          if (index++ < 2) return;
          errorElement = new ErroneousElementX(
              MessageKind.MAIN_WITH_EXTRA_PARAMETER,
              {'main': Identifiers.main},
              Identifiers.main,
              parameter);
          // Don't warn about main not being used:
          impactBuilder.registerStaticUse(
              new StaticUse.staticInvoke(mainFunction, CallStructure.NO_ARGS));

          mainFunction = backend.helperForMainArity();
        });
      }
    }
    if (mainFunction == null) {
      if (errorElement == null && !options.analyzeOnly && !analyzeAll) {
        reporter.internalError(mainApp, "Problem with '${Identifiers.main}'.");
      } else {
        mainFunction = errorElement;
      }
    }
    if (errorElement != null &&
        errorElement.isSynthesized &&
        !mainApp.isSynthesized) {
      reporter.reportWarningMessage(errorElement, errorElement.messageKind,
          errorElement.messageArguments);
    }
    return impactBuilder;
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
  void compileLoadedLibraries() =>
      selfTask.measureSubtask("Compiler.compileLoadedLibraries", () {
        ResolutionEnqueuer resolutionEnqueuer = startResolution();
        WorldImpact mainImpact = computeMain();

        mirrorUsageAnalyzerTask.analyzeUsage(mainApp);

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
          libraryLoader.libraries.where((LibraryElement library) {
            return !serialization.isDeserialized(library);
          }).forEach((LibraryElement library) {
            reporter.log('Enqueuing ${library.canonicalUri}');
            resolutionEnqueuer.applyImpact(computeImpactForLibrary(library));
          });
        } else if (analyzeAll) {
          libraryLoader.libraries.forEach((LibraryElement library) {
            reporter.log('Enqueuing ${library.canonicalUri}');
            resolutionEnqueuer.applyImpact(computeImpactForLibrary(library));
          });
        } else if (options.analyzeMain) {
          if (mainApp != null) {
            resolutionEnqueuer.applyImpact(computeImpactForLibrary(mainApp));
          }
          if (librariesToAnalyzeWhenRun != null) {
            for (Uri libraryUri in librariesToAnalyzeWhenRun) {
              resolutionEnqueuer.applyImpact(computeImpactForLibrary(
                  libraryLoader.lookupLibrary(libraryUri)));
            }
          }
        }
        if (deferredLoadTask.isProgramSplit) {
          resolutionEnqueuer
              .applyImpact(backend.computeDeferredLoadingImpact());
        }
        resolveLibraryMetadata();
        reporter.log('Resolving...');
        MethodElement mainMethod;
        if (mainFunction != null && !mainFunction.isMalformed) {
          mainFunction.computeType(resolution);
          mainMethod = mainFunction;
        }

        processQueue(resolutionEnqueuer, mainMethod, libraryLoader.libraries,
            onProgress: showResolutionProgress);
        resolutionEnqueuer.logSummary(reporter.log);

        _reporter.reportSuppressedMessagesSummary();

        if (compilationFailed) {
          if (!options.generateCodeWithCompileTimeErrors) return;
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
              libraryLoader.libraries.where((LibraryElement library) {
            return !serialization.isDeserialized(library);
          }));
        }
        if (options.analyzeOnly) {
          if (!analyzeAll && !compilationFailed) {
            // No point in reporting unused code when [analyzeAll] is true: all
            // code is artificially used.
            // If compilation failed, it is possible that the error prevents the
            // compiler from analyzing all the code.
            // TODO(johnniwinther): Reenable this when the reporting is more
            // precise.
            //reportUnusedCode();
          }
          return;
        }
        assert(mainFunction != null);

        ClosedWorldRefiner closedWorldRefiner = closeResolution();
        ClosedWorld closedWorld = closedWorldRefiner.closedWorld;

        reporter.log('Inferring types...');
        globalInference.runGlobalTypeInference(
            mainFunction, closedWorld, closedWorldRefiner);

        if (stopAfterTypeInference) return;

        backend.onTypeInferenceComplete();

        reporter.log('Compiling...');
        phase = PHASE_COMPILING;

        Enqueuer codegenEnqueuer = enqueuer.createCodegenEnqueuer(closedWorld);
        _codegenWorldBuilder = codegenEnqueuer.worldBuilder;
        codegenEnqueuer.applyImpact(
            backend.onCodegenStart(closedWorld, _codegenWorldBuilder));
        if (compileAll) {
          libraryLoader.libraries.forEach((LibraryElement library) {
            codegenEnqueuer.applyImpact(computeImpactForLibrary(library));
          });
        }
        processQueue(codegenEnqueuer, mainMethod, libraryLoader.libraries,
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

    ClosedWorldImpl world = resolutionWorldBuilder.closeWorld(reporter);
    // Compute whole-program-knowledge that the backend needs. (This might
    // require the information computed in [world.closeWorld].)
    backend.onResolutionComplete(world, world);

    deferredLoadTask.onResolutionComplete(mainFunction);

    // TODO(johnniwinther): Move this after rti computation but before
    // reflection members computation, and (re-)close the world afterwards.
    closureToClassMapper.createClosureClasses(world);
    return world;
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

  void processQueue(Enqueuer enqueuer, MethodElement mainMethod,
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
      backend.onQueueClosed();
      assert(compilationFailed ||
          enqueuer.checkNoEnqueuedInvokedInstanceMethods());
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
    for (Element e in codegenEnqueuer.processedEntities) {
      resolved.remove(e);
    }
    for (Element e in new Set.from(resolved)) {
      if (e.isClass ||
          e.isField ||
          e.isTypeVariable ||
          e.isTypedef ||
          identical(e.kind, ElementKind.ABSTRACT_FIELD)) {
        resolved.remove(e);
      }
      if (identical(e.kind, ElementKind.GENERATIVE_CONSTRUCTOR)) {
        resolved.remove(e);
      }
      if (backend.isTargetSpecificLibrary(e.library)) {
        resolved.remove(e);
      }
    }
    reporter.log('Excess resolution work: ${resolved.length}.');
    for (Element e in resolved) {
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
    unimplemented(node, 'Compiler.readScript');
    return null;
  }

  Element lookupElementIn(ScopeContainerElement container, String name) {
    Element element = container.localLookup(name);
    if (element == null) {
      throw 'Could not find $name in $container';
    }
    return element;
  }

  bool get isMockCompilation => false;

  void reportUnusedCode() {
    void checkLive(member) {
      if (member.isMalformed) return;
      if (member.isFunction) {
        if (!resolutionWorldBuilder.isMemberUsed(member)) {
          reporter.reportHintMessage(
              member, MessageKind.UNUSED_METHOD, {'name': member.name});
        }
      } else if (member.isClass) {
        if (!member.isResolved) {
          reporter.reportHintMessage(
              member, MessageKind.UNUSED_CLASS, {'name': member.name});
        } else {
          member.forEachLocalMember(checkLive);
        }
      } else if (member.isTypedef) {
        if (!member.isResolved) {
          reporter.reportHintMessage(
              member, MessageKind.UNUSED_TYPEDEF, {'name': member.name});
        }
      }
    }

    libraryLoader.libraries.forEach((LibraryElement library) {
      // TODO(ahe): Implement better heuristics to discover entry points of
      // packages and use that to discover unused implementation details in
      // packages.
      if (library.isPlatformLibrary || library.isPackageLibrary) return;
      library.compilationUnits.forEach((unit) {
        unit.forEachLocalMember(checkLive);
      });
    });
  }

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
  bool elementHasCompileTimeError(Element element) {
    return elementsWithCompileTimeErrors.containsKey(element);
  }

  /// Associate [element] with a compile-time error [message].
  void registerCompileTimeError(Element element, DiagnosticMessage message) {
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

class _CompilerCommonElements extends CommonElementsMixin {
  final Resolution resolution;
  final DiagnosticReporter reporter;

  final ElementEnvironment environment;

  LibraryElement coreLibrary;
  LibraryElement asyncLibrary;
  LibraryElement mirrorsLibrary;
  LibraryElement typedDataLibrary;

  _CompilerCommonElements(this.environment, this.resolution, this.reporter);

  @override
  ResolutionDynamicType get dynamicType => const ResolutionDynamicType();

  void registerCommonLibraries(LibraryElement library) {
    Uri uri = library.canonicalUri;
    if (uri == Uris.dart_core) {
      coreLibrary = library;
    } else if (uri == Uris.dart_async) {
      asyncLibrary = library;
    } else if (uri == Uris.dart__native_typed_data) {
      typedDataLibrary = library;
    } else if (uri == Uris.dart_mirrors) {
      mirrorsLibrary = library;
    }
  }

  @override
  MemberElement findLibraryMember(LibraryElement library, String name,
      {bool setter: false, bool required: true}) {
    Element member = _findLibraryMember(library, name, required: required);
    if (member != null && member.isAbstractField) {
      AbstractFieldElement abstractField = member;
      if (setter) {
        member = abstractField.setter;
      } else {
        member = abstractField.getter;
      }
      if (member == null && required) {
        reporter.internalError(
            library,
            "The library '${library.canonicalUri}' does not contain required "
            "${setter ? 'setter' : 'getter'}: '$name'.");
      }
    }
    return member;
  }

  @override
  MemberElement findClassMember(ClassElement cls, String name,
      {bool setter: false, bool required: true}) {
    cls.ensureResolved(resolution);
    Element member = cls.lookupLocalMember(name);
    if (member != null && member.isAbstractField) {
      AbstractFieldElement abstractField = member;
      if (setter) {
        member = abstractField.setter;
      } else {
        member = abstractField.getter;
      }
    }
    if (member == null && required) {
      reporter.internalError(
          cls,
          "The class '${cls}' in '${cls.library.canonicalUri}' does not "
          "contain required member: '$name'.");
    }
    return member;
  }

  @override
  ConstructorElement findConstructor(ClassElement cls, String name,
      {bool required: true}) {
    cls.ensureResolved(resolution);
    ConstructorElement constructor = cls.lookupConstructor(name);
    if (constructor == null && required) {
      reporter.internalError(
          cls,
          "The class '${cls}' in '${cls.library.canonicalUri}' does not "
          "contain required constructor: '$name'.");
    }
    return constructor;
  }

  @override
  ClassElement findClass(LibraryElement library, String name,
      {bool required: true}) {
    return _findLibraryMember(library, name, required: required);
  }

  Element _findLibraryMember(LibraryElement library, String name,
      {bool required: true}) {
    // If the script of the library is synthesized, the library does not exist
    // and we do not try to load the helpers.
    //
    // This could for example happen if dart:async is disabled, then loading it
    // should not try to find the given element.
    if (library == null || library.isSynthesized) return null;

    Element element = library.find(name);
    if (element == null && required) {
      reporter.internalError(
          library,
          "The library '${library.canonicalUri}' does not contain required "
          "element: '$name'.");
    }
    return element;
  }
}

class CompilerDiagnosticReporter extends DiagnosticReporter {
  final Compiler compiler;
  final DiagnosticOptions options;

  Element _currentElement;
  bool hasCrashed = false;

  /// `true` if the last diagnostic was filtered, in which case the
  /// accompanying info message should be filtered as well.
  bool lastDiagnosticWasFiltered = false;

  /// Map containing information about the warnings and hints that have been
  /// suppressed for each library.
  Map<Uri, SuppressionInfo> suppressedWarnings = <Uri, SuppressionInfo>{};

  CompilerDiagnosticReporter(this.compiler, this.options);

  Element get currentElement => _currentElement;

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
      Element errorElement;
      if (message.spannable is Element) {
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
  withCurrentElement(Element element, f()) {
    Element old = currentElement;
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

  @override
  SourceSpan spanFromToken(Token token) => spanFromTokens(token, token);

  SourceSpan spanFromTokens(Token begin, Token end, [Uri uri]) {
    if (begin == null || end == null) {
      // TODO(ahe): We can almost always do better. Often it is only
      // end that is null. Otherwise, we probably know the current
      // URI.
      throw 'Cannot find tokens to produce error message.';
    }
    if (uri == null && currentElement != null) {
      uri = currentElement.compilationUnit.script.resourceUri;
      assert(invariant(currentElement, () {
        bool sameToken(Token token, Token sought) {
          if (token == sought) return true;
          if (token.stringValue == '>>') {
            // `>>` is converted to `>` in the parser when needed.
            return sought.stringValue == '>' &&
                token.charOffset <= sought.charOffset &&
                sought.charOffset < token.charEnd;
          }
          return false;
        }

        /// Check that [begin] and [end] can be found between [from] and [to].
        validateToken(Token from, Token to) {
          if (from == null || to == null) return true;
          bool foundBegin = false;
          bool foundEnd = false;
          Token token = from;
          while (true) {
            if (sameToken(token, begin)) {
              foundBegin = true;
            }
            if (sameToken(token, end)) {
              foundEnd = true;
            }
            if (foundBegin && foundEnd) {
              return true;
            }
            if (token == to || token == token.next || token.next == null) {
              break;
            }
            token = token.next;
          }

          // Create a good message for when the tokens were not found.
          StringBuffer sb = new StringBuffer();
          sb.write('Invalid current element: $currentElement. ');
          sb.write('Looking for ');
          sb.write('[${begin} (${begin.hashCode}),');
          sb.write('${end} (${end.hashCode})] in');

          token = from;
          while (true) {
            sb.write('\n ${token} (${token.hashCode})');
            if (token == to || token == token.next || token.next == null) {
              break;
            }
            token = token.next;
          }
          return sb.toString();
        }

        if (currentElement.enclosingClass != null &&
            currentElement.enclosingClass.isEnumClass) {
          // Enums ASTs are synthesized (and give messed up messages).
          return true;
        }

        if (currentElement is AstElement) {
          AstElement astElement = currentElement;
          if (astElement.hasNode) {
            Token from = astElement.node.getBeginToken();
            Token to = astElement.node.getEndToken();
            if (astElement.metadata.isNotEmpty) {
              if (!astElement.metadata.first.hasNode) {
                // We might try to report an error while parsing the metadata
                // itself.
                return true;
              }
              from = astElement.metadata.first.node.getBeginToken();
            }
            return validateToken(from, to);
          }
        }
        return true;
      }, message: "Invalid current element: $currentElement [$begin,$end]."));
    }
    return new SourceSpan.fromTokens(uri, begin, end);
  }

  SourceSpan spanFromNode(Node node) {
    return spanFromTokens(node.getBeginToken(), node.getPrefixEndToken());
  }

  SourceSpan spanFromElement(Element element) {
    if (element != null && element.sourcePosition != null) {
      return element.sourcePosition;
    }
    while (element != null && element.isSynthesized) {
      element = element.enclosingElement;
    }
    if (element != null &&
        element.sourcePosition == null &&
        !element.isLibrary &&
        !element.isCompilationUnit) {
      // Sometimes, the backend fakes up elements that have no
      // position. So we use the enclosing element instead. It is
      // not a good error location, but cancel really is "internal
      // error" or "not implemented yet", so the vicinity is good
      // enough for now.
      element = element.enclosingElement;
      // TODO(ahe): I plan to overhaul this infrastructure anyways.
    }
    if (element == null) {
      element = currentElement;
    }
    if (element == null) {
      return null;
    }

    if (element.sourcePosition != null) {
      return element.sourcePosition;
    }
    Token position = element.position;
    Uri uri = element.compilationUnit.script.resourceUri;
    return (position == null)
        ? new SourceSpan(uri, 0, 0)
        : spanFromTokens(position, position, uri);
  }

  SourceSpan spanFromHInstruction(HInstruction instruction) {
    Element element = _elementFromHInstruction(instruction);
    if (element == null) element = currentElement;
    SourceInformation position = instruction.sourceInformation;
    if (position == null) return spanFromElement(element);
    return position.sourceSpan;
  }

  SourceSpan spanFromSpannable(Spannable node) {
    if (node == CURRENT_ELEMENT_SPANNABLE) {
      node = currentElement;
    } else if (node == NO_LOCATION_SPANNABLE) {
      if (currentElement == null) return null;
      node = currentElement;
    }
    if (node is SourceSpan) {
      return node;
    } else if (node is Node) {
      return spanFromNode(node);
    } else if (node is HInstruction) {
      return spanFromHInstruction(node);
    } else if (node is Element) {
      return spanFromElement(node);
    } else if (node is MetadataAnnotation) {
      return node.sourcePosition;
    } else if (node is Local) {
      Local local = node;
      return spanFromElement(local.executableContext);
    } else if (node is Entity) {
      return spanFromElement(currentElement);
    } else {
      throw 'No error location.';
    }
  }

  Element _elementFromHInstruction(HInstruction instruction) {
    return instruction.sourceElement is Element
        ? instruction.sourceElement
        : null;
  }

  internalError(Spannable node, reason) {
    String message = tryToString(reason);
    reportDiagnosticInternal(
        createMessage(node, MessageKind.GENERIC, {'text': message}),
        const <DiagnosticMessage>[],
        api.Diagnostic.CRASH);
    throw 'Internal Error: $message';
  }

  void unhandledExceptionOnElement(Element element) {
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
        .transformResolutionImpact(enqueuer, resolutionImpact);
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
}

/// [ScriptLoader] used to ensure that scripts are not loaded accidentally
/// through the [LibraryLoader] when `CompilerOptions.compileOnly` is `true`.
class _NoScriptLoader implements ScriptLoader {
  Compiler compiler;
  _NoScriptLoader(this.compiler);

  Future<Script> readScript(Uri uri, [Spannable spannable]) {
    compiler.reporter
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

/// An element environment base on a [Compiler].
class _CompilerElementEnvironment implements ElementEnvironment {
  final Compiler _compiler;

  _CompilerElementEnvironment(this._compiler);

  LibraryProvider get _libraryProvider => _compiler.libraryLoader;
  Resolution get _resolution => _compiler.resolution;

  @override
  LibraryEntity get mainLibrary => _compiler.mainApp;

  @override
  FunctionEntity get mainFunction => _compiler.mainFunction;

  @override
  ResolutionInterfaceType getThisType(ClassElement cls) {
    cls.ensureResolved(_resolution);
    return cls.thisType;
  }

  @override
  ResolutionInterfaceType getRawType(ClassElement cls) {
    cls.ensureResolved(_resolution);
    return cls.rawType;
  }

  @override
  ResolutionInterfaceType createInterfaceType(
      ClassElement cls, List<ResolutionDartType> typeArguments) {
    cls.ensureResolved(_resolution);
    return cls.thisType.createInstantiation(typeArguments);
  }

  @override
  MemberElement lookupClassMember(ClassElement cls, String name,
      {bool setter: false, bool required: false}) {
    cls.ensureResolved(_resolution);
    Element member = cls.implementation.lookupLocalMember(name);
    if (member != null && member.isAbstractField) {
      AbstractFieldElement abstractField = member;
      if (setter) {
        member = abstractField.setter;
      } else {
        member = abstractField.getter;
      }
      if (member == null && required) {
        throw new SpannableAssertionFailure(
            cls,
            "The class '${cls.name}' does not contain required "
            "${setter ? 'setter' : 'getter'}: '$name'.");
      }
    }
    if (member == null && required) {
      throw new SpannableAssertionFailure(
          cls,
          "The class '${cls.name}' does not "
          "contain required member: '$name'.");
    }
    return member?.declaration;
  }

  @override
  ConstructorElement lookupConstructor(ClassElement cls, String name,
      {bool required: false}) {
    cls.ensureResolved(_resolution);
    ConstructorElement constructor = cls.implementation.lookupConstructor(name);
    if (constructor == null && required) {
      throw new SpannableAssertionFailure(
          cls,
          "The class '${cls.name}' does not contain "
          "required constructor: '$name'.");
    }
    return constructor?.declaration;
  }

  @override
  MemberElement lookupLibraryMember(LibraryElement library, String name,
      {bool setter: false, bool required: false}) {
    Element member = library.implementation.findLocal(name);
    if (member != null && member.isAbstractField) {
      AbstractFieldElement abstractField = member;
      if (setter) {
        member = abstractField.setter;
      } else {
        member = abstractField.getter;
      }
      if (member == null && required) {
        throw new SpannableAssertionFailure(
            library,
            "The library '${library.canonicalUri}' does not contain required "
            "${setter ? 'setter' : 'getter'}: '$name'.");
      }
    }
    if (member == null && required) {
      throw new SpannableAssertionFailure(
          member,
          "The library '${library.libraryName}' does not "
          "contain required member: '$name'.");
    }
    return member?.declaration;
  }

  @override
  ClassElement lookupClass(LibraryElement library, String name,
      {bool required: false}) {
    ClassElement cls = library.implementation.findLocal(name);
    if (cls == null && required) {
      throw new SpannableAssertionFailure(
          cls,
          "The library '${library.libraryName}' does not "
          "contain required class: '$name'.");
    }
    return cls?.declaration;
  }

  @override
  LibraryElement lookupLibrary(Uri uri, {bool required: false}) {
    LibraryElement library = _libraryProvider.lookupLibrary(uri);
    if (library != null && library.isSynthesized) {
      return null;
    }
    if (library == null && required) {
      throw new SpannableAssertionFailure(
          library, "The library '${uri}' was not found.");
    }
    return library;
  }
}
