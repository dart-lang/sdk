// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.compiler_base;

import 'dart:async' show Future;

import 'package:front_end/src/api_unstable/dart2js.dart'
    show clearStringTokenCanonicalizer;
import 'package:kernel/ast.dart' as ir;

import '../compiler_new.dart' as api;
import 'backend_strategy.dart';
import 'common/codegen.dart';
import 'common/names.dart' show Selectors, Uris;
import 'common/tasks.dart' show CompilerTask, GenericTask, Measurer;
import 'common/work.dart' show WorkItem;
import 'common.dart';
import 'common_elements.dart' show ElementEnvironment;
import 'deferred_load.dart' show DeferredLoadTask, OutputUnitData;
import 'diagnostics/code_location.dart';
import 'diagnostics/diagnostic_listener.dart' show DiagnosticReporter;
import 'diagnostics/messages.dart' show Message, MessageTemplate;
import 'dump_info.dart' show DumpInfoTask;
import 'elements/entities.dart';
import 'enqueue.dart' show Enqueuer, EnqueueTask, ResolutionEnqueuer;
import 'environment.dart';
import 'frontend_strategy.dart';
import 'inferrer/abstract_value_domain.dart' show AbstractValueStrategy;
import 'inferrer/trivial.dart' show TrivialAbstractValueStrategy;
import 'inferrer/powersets/wrapped.dart' show WrappedAbstractValueStrategy;
import 'inferrer/powersets/powersets.dart' show PowersetStrategy;
import 'inferrer/typemasks/masks.dart' show TypeMaskStrategy;
import 'inferrer/types.dart'
    show GlobalTypeInferenceResults, GlobalTypeInferenceTask;
import 'io/source_information.dart' show SourceInformation;
import 'js_backend/backend.dart' show CodegenInputs, JavaScriptImpactStrategy;
import 'js_backend/inferred_data.dart';
import 'js_model/js_strategy.dart';
import 'js_model/js_world.dart';
import 'kernel/kernel_strategy.dart';
import 'kernel/loader.dart' show KernelLoaderTask, KernelResult;
import 'null_compiler_output.dart' show NullCompilerOutput;
import 'options.dart' show CompilerOptions;
import 'serialization/task.dart';
import 'serialization/strategies.dart';
import 'ssa/nodes.dart' show HInstruction;
import 'universe/selector.dart' show Selector;
import 'universe/codegen_world_builder.dart';
import 'universe/resolution_world_builder.dart';
import 'universe/world_impact.dart'
    show ImpactStrategy, WorldImpact, WorldImpactBuilderImpl;
import 'world.dart' show JClosedWorld, KClosedWorld;

typedef CompilerDiagnosticReporter MakeReporterFunction(
    Compiler compiler, CompilerOptions options);

abstract class Compiler {
  Measurer get measurer;

  api.CompilerInput get provider;

  FrontendStrategy frontendStrategy;
  BackendStrategy backendStrategy;
  CompilerDiagnosticReporter _reporter;
  Map<Entity, WorldImpact> _impactCache;
  ImpactCacheDeleter _impactCacheDeleter;

  ImpactStrategy impactStrategy = const ImpactStrategy();

  /// Options provided from command-line arguments.
  final CompilerOptions options;

  // These internal flags are used to stop compilation after a specific phase.
  // Used only for debugging and testing purposes only.
  bool stopAfterClosedWorld = false;
  bool stopAfterTypeInference = false;

  /// Output provider from user of Compiler API.
  api.CompilerOutput _outputProvider;

  api.CompilerOutput get outputProvider => _outputProvider;

  List<CodeLocation> _userCodeLocations = <CodeLocation>[];

  JClosedWorld backendClosedWorldForTesting;

  DiagnosticReporter get reporter => _reporter;
  Map<Entity, WorldImpact> get impactCache => _impactCache;
  ImpactCacheDeleter get impactCacheDeleter => _impactCacheDeleter;

  final Environment environment;
  // TODO(sigmund): delete once we migrate the rest of the compiler to use
  // `environment` directly.
  @deprecated
  fromEnvironment(String name) => environment.valueOf(name);

  Entity get currentElement => _reporter.currentElement;

  List<CompilerTask> tasks;
  KernelLoaderTask kernelLoader;
  GlobalTypeInferenceTask globalInference;
  CodegenWorldBuilder _codegenWorldBuilder;

  AbstractValueStrategy abstractValueStrategy;

  GenericTask selfTask;

  EnqueueTask enqueuer;
  DeferredLoadTask deferredLoadTask;
  DumpInfoTask dumpInfoTask;
  SerializationTask serializationTask;

  bool get hasCrashed => _reporter.hasCrashed;

  Progress progress = const Progress();

  static const int PHASE_SCANNING = 0;
  static const int PHASE_RESOLVING = 1;
  static const int PHASE_DONE_RESOLVING = 2;
  static const int PHASE_COMPILING = 3;
  int phase;

  bool compilationFailed = false;

  // Callback function used for testing resolution enqueuing.
  void Function() onResolutionQueueEmptyForTesting;

  // Callback function used for testing codegen enqueuing.
  void Function() onCodegenQueueEmptyForTesting;

  Compiler(
      {CompilerOptions options,
      api.CompilerOutput outputProvider,
      this.environment: const _EmptyEnvironment(),
      MakeReporterFunction makeReporter})
      : this.options = options {
    options.deriveOptions();
    options.validate();

    abstractValueStrategy = options.useTrivialAbstractValueDomain
        ? const TrivialAbstractValueStrategy()
        : const TypeMaskStrategy();
    if (options.experimentalWrapped || options.testMode) {
      abstractValueStrategy =
          WrappedAbstractValueStrategy(abstractValueStrategy);
    } else if (options.experimentalPowersets) {
      abstractValueStrategy = PowersetStrategy(abstractValueStrategy);
    }

    CompilerTask kernelFrontEndTask;
    selfTask = new GenericTask('self', measurer);
    _outputProvider = new _CompilerOutput(this, outputProvider);
    if (makeReporter != null) {
      _reporter = makeReporter(this, options);
    } else {
      _reporter = new CompilerDiagnosticReporter(this);
    }
    kernelFrontEndTask = new GenericTask('Front end', measurer);
    frontendStrategy = new KernelFrontendStrategy(
        kernelFrontEndTask, options, reporter, environment);
    backendStrategy = createBackendStrategy();
    _impactCache = <Entity, WorldImpact>{};
    _impactCacheDeleter = new _MapImpactCacheDeleter(_impactCache);

    if (options.showInternalProgress) {
      progress = new InteractiveProgress();
    }

    enqueuer = new EnqueueTask(this);

    tasks = [
      kernelLoader = new KernelLoaderTask(
          options, provider, _outputProvider, reporter, measurer),
      kernelFrontEndTask,
      globalInference = new GlobalTypeInferenceTask(this),
      deferredLoadTask = frontendStrategy.createDeferredLoadTask(this),
      // [enqueuer] is created earlier because it contains the resolution world
      // objects needed by other tasks.
      enqueuer,
      dumpInfoTask = new DumpInfoTask(this),
      selfTask,
      serializationTask = new SerializationTask(
          options, reporter, provider, outputProvider, measurer),
    ];

    tasks.addAll(backendStrategy.tasks);
  }

  /// Creates the backend strategy.
  ///
  /// Override this to mock the backend strategy for testing.
  BackendStrategy createBackendStrategy() {
    return new JsBackendStrategy(this);
  }

  ResolutionWorldBuilder resolutionWorldBuilderForTesting;

  KClosedWorld get frontendClosedWorldForTesting =>
      resolutionWorldBuilderForTesting.closedWorldForTesting;

  CodegenWorldBuilder get codegenWorldBuilder {
    assert(
        _codegenWorldBuilder != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "CodegenWorldBuilder has not been created yet."));
    return _codegenWorldBuilder;
  }

  CodegenWorld codegenWorldForTesting;

  bool get disableTypeInference =>
      options.disableTypeInference || compilationFailed;

  // Compiles the dart script at [uri].
  //
  // The resulting future will complete with true if the compilation
  // succeeded.
  Future<bool> run(Uri uri) => selfTask.measureSubtask("run", () {
        measurer.startWallClock();

        return new Future.sync(() => runInternal(uri))
            .catchError((error, StackTrace stackTrace) =>
                _reporter.onError(uri, error, stackTrace))
            .whenComplete(() {
          measurer.stopWallClock();
        }).then((_) {
          return !compilationFailed;
        });
      });

  bool get onlyPerformGlobalTypeInference {
    return options.readClosedWorldUri != null &&
        options.readDataUri == null &&
        options.readCodegenUri == null;
  }

  Future runInternal(Uri uri) async {
    clearState();
    assert(uri != null);
    reporter.log('Compiling $uri (${options.buildId})');

    if (onlyPerformGlobalTypeInference) {
      ir.Component component =
          await serializationTask.deserializeComponentAndUpdateOptions();
      JsClosedWorld closedWorld =
          await serializationTask.deserializeClosedWorld(
              environment, abstractValueStrategy, component);
      GlobalTypeInferenceResults globalTypeInferenceResults =
          performGlobalTypeInference(closedWorld);
      if (options.writeDataUri != null) {
        serializationTask
            .serializeGlobalTypeInference(globalTypeInferenceResults);
        return;
      }
      await generateJavaScriptCode(globalTypeInferenceResults);
    } else if (options.readDataUri != null) {
      GlobalTypeInferenceResults globalTypeInferenceResults;
      if (options.readClosedWorldUri != null) {
        ir.Component component =
            await serializationTask.deserializeComponentAndUpdateOptions();
        JsClosedWorld closedWorld =
            await serializationTask.deserializeClosedWorld(
                environment, abstractValueStrategy, component);
        globalTypeInferenceResults =
            await serializationTask.deserializeGlobalAnalysis(
                environment, abstractValueStrategy, component, closedWorld);
      } else {
        globalTypeInferenceResults = await serializationTask
            .deserializeGlobalTypeInference(environment, abstractValueStrategy);
      }
      if (options.debugGlobalInference) {
        performGlobalTypeInference(globalTypeInferenceResults.closedWorld);
        return;
      }
      await generateJavaScriptCode(globalTypeInferenceResults);
    } else {
      KernelResult result = await kernelLoader.load(uri);
      reporter.log("Kernel load complete");
      if (result == null) return;
      if (compilationFailed) {
        return;
      }
      if (options.cfeOnly) return;

      frontendStrategy.registerLoadedLibraries(result);

      // TODO(efortuna, sigmund): These validation steps should be done in the
      // front end for the Kernel path since Kernel doesn't have the notion of
      // imports (everything has already been resolved). (See
      // https://github.com/dart-lang/sdk/issues/29368)
      if (result.libraries.contains(Uris.dart_mirrors)) {
        reporter.reportWarningMessage(NO_LOCATION_SPANNABLE,
            MessageKind.MIRRORS_LIBRARY_NOT_SUPPORT_WITH_CFE);
      }

      await compileFromKernel(result.rootLibraryUri, result.libraries);
    }
  }

  void generateJavaScriptCode(
      GlobalTypeInferenceResults globalTypeInferenceResults) async {
    JClosedWorld closedWorld = globalTypeInferenceResults.closedWorld;
    backendStrategy.registerJClosedWorld(closedWorld);
    phase = PHASE_COMPILING;
    CodegenInputs codegenInputs =
        backendStrategy.onCodegenStart(globalTypeInferenceResults);

    if (options.readCodegenUri != null) {
      CodegenResults codegenResults =
          await serializationTask.deserializeCodegen(
              backendStrategy, globalTypeInferenceResults, codegenInputs);
      reporter.log('Compiling methods');
      runCodegenEnqueuer(codegenResults);
    } else {
      reporter.log('Compiling methods');
      CodegenResults codegenResults = new OnDemandCodegenResults(
          globalTypeInferenceResults,
          codegenInputs,
          backendStrategy.functionCompiler);
      if (options.writeCodegenUri != null) {
        serializationTask.serializeCodegen(backendStrategy, codegenResults);
      } else {
        runCodegenEnqueuer(codegenResults);
      }
    }
  }

  /// Clear the internal compiler state to prevent memory leaks when invoking
  /// the compiler multiple times (e.g. in batch mode).
  // TODO(ahe): implement a better mechanism where we can store
  // such caches in the compiler and get access to them through a
  // suitably maintained static reference to the current compiler.
  void clearState() {
    clearStringTokenCanonicalizer();
    Selector.canonicalizedValues.clear();

    // The selector objects held in static fields must remain canonical.
    for (Selector selector in Selectors.ALL) {
      Selector.canonicalizedValues
          .putIfAbsent(selector.hashCode, () => <Selector>[])
          .add(selector);
    }
  }

  JClosedWorld computeClosedWorld(Uri rootLibraryUri, Iterable<Uri> libraries) {
    ResolutionEnqueuer resolutionEnqueuer = enqueuer.createResolutionEnqueuer();
    if (retainDataForTesting) {
      resolutionWorldBuilderForTesting = resolutionEnqueuer.worldBuilder;
    }
    frontendStrategy.onResolutionStart();
    for (LibraryEntity library
        in frontendStrategy.elementEnvironment.libraries) {
      frontendStrategy.elementEnvironment.forEachClass(library,
          (ClassEntity cls) {
        // Register all classes eagerly to optimize closed world computation in
        // `ClassWorldBuilder.isInheritedInSubtypeOf`.
        resolutionEnqueuer.worldBuilder.registerClass(cls);
      });
    }
    WorldImpactBuilderImpl mainImpact = new WorldImpactBuilderImpl();
    FunctionEntity mainFunction = frontendStrategy.computeMain(mainImpact);

    // In order to see if a library is deferred, we must compute the
    // compile-time constants that are metadata.  This means adding
    // something to the resolution queue.  So we cannot wait with
    // this until after the resolution queue is processed.
    deferredLoadTask.beforeResolution(rootLibraryUri, libraries);

    impactStrategy = new JavaScriptImpactStrategy(
        impactCacheDeleter, dumpInfoTask,
        supportDeferredLoad: deferredLoadTask.isProgramSplit,
        supportDumpInfo: options.dumpInfo);

    phase = PHASE_RESOLVING;
    resolutionEnqueuer.applyImpact(mainImpact);
    if (options.showInternalProgress) reporter.log('Computing closed world');

    processQueue(
        frontendStrategy.elementEnvironment, resolutionEnqueuer, mainFunction,
        onProgress: showResolutionProgress);
    frontendStrategy.onResolutionEnd();
    resolutionEnqueuer.logSummary(reporter.log);

    _reporter.reportSuppressedMessagesSummary();

    if (compilationFailed) {
      return null;
    }

    assert(mainFunction != null);
    checkQueue(resolutionEnqueuer);

    JClosedWorld closedWorld =
        closeResolution(mainFunction, resolutionEnqueuer.worldBuilder);
    return closedWorld;
  }

  GlobalTypeInferenceResults performGlobalTypeInference(
      JClosedWorld closedWorld) {
    FunctionEntity mainFunction = closedWorld.elementEnvironment.mainFunction;
    reporter.log('Performing global type inference');
    InferredDataBuilder inferredDataBuilder =
        new InferredDataBuilderImpl(closedWorld.annotationsData);
    return globalInference.runGlobalTypeInference(
        mainFunction, closedWorld, inferredDataBuilder);
  }

  void runCodegenEnqueuer(CodegenResults codegenResults) {
    GlobalTypeInferenceResults globalInferenceResults =
        codegenResults.globalTypeInferenceResults;
    JClosedWorld closedWorld = globalInferenceResults.closedWorld;
    CodegenInputs codegenInputs = codegenResults.codegenInputs;
    Enqueuer codegenEnqueuer = enqueuer.createCodegenEnqueuer(
        closedWorld, globalInferenceResults, codegenInputs, codegenResults);
    _codegenWorldBuilder = codegenEnqueuer.worldBuilder;

    FunctionEntity mainFunction = closedWorld.elementEnvironment.mainFunction;
    processQueue(closedWorld.elementEnvironment, codegenEnqueuer, mainFunction,
        onProgress: showCodegenProgress);
    codegenEnqueuer.logSummary(reporter.log);
    CodegenWorld codegenWorld = codegenWorldBuilder.close();
    if (retainDataForTesting) {
      codegenWorldForTesting = codegenWorld;
    }
    reporter.log('Emitting JavaScript');
    int programSize = backendStrategy.assembleProgram(closedWorld,
        globalInferenceResults.inferredData, codegenInputs, codegenWorld);

    if (options.dumpInfo) {
      dumpInfoTask.reportSize(programSize);
      dumpInfoTask.dumpInfo(closedWorld, globalInferenceResults);
    }

    backendStrategy.onCodegenEnd(codegenInputs);

    checkQueue(codegenEnqueuer);
  }

  GlobalTypeInferenceResults globalTypeInferenceResultsTestMode(
      GlobalTypeInferenceResults results) {
    SerializationStrategy strategy = const BytesInMemorySerializationStrategy();
    List<int> irData = strategy.unpackAndSerializeComponent(results);
    List worldData = strategy.serializeGlobalTypeInferenceResults(results);
    return strategy.deserializeGlobalTypeInferenceResults(
        options,
        reporter,
        environment,
        abstractValueStrategy,
        strategy.deserializeComponent(irData),
        worldData);
  }

  void compileFromKernel(Uri rootLibraryUri, Iterable<Uri> libraries) {
    _userCodeLocations.add(new CodeLocation(rootLibraryUri));
    selfTask.measureSubtask("compileFromKernel", () {
      JsClosedWorld closedWorld = selfTask.measureSubtask("computeClosedWorld",
          () => computeClosedWorld(rootLibraryUri, libraries));
      if (closedWorld == null) return;

      if (retainDataForTesting) {
        backendClosedWorldForTesting = closedWorld;
      }

      if (options.writeClosedWorldUri != null) {
        serializationTask.serializeComponent(
            closedWorld.elementMap.programEnv.mainComponent);
        serializationTask.serializeClosedWorld(closedWorld);
        return;
      }
      if (stopAfterClosedWorld) return;
      GlobalTypeInferenceResults globalInferenceResults =
          performGlobalTypeInference(closedWorld);
      if (options.writeDataUri != null) {
        serializationTask.serializeGlobalTypeInference(globalInferenceResults);
        return;
      }
      if (options.testMode) {
        globalInferenceResults =
            globalTypeInferenceResultsTestMode(globalInferenceResults);
      }
      if (stopAfterTypeInference) return;
      generateJavaScriptCode(globalInferenceResults);
    });
  }

  /// Perform the steps needed to fully end the resolution phase.
  JClosedWorld closeResolution(FunctionEntity mainFunction,
      ResolutionWorldBuilder resolutionWorldBuilder) {
    phase = PHASE_DONE_RESOLVING;

    KClosedWorld kClosedWorld = resolutionWorldBuilder.closeWorld(reporter);
    OutputUnitData result = deferredLoadTask.run(mainFunction, kClosedWorld);
    JClosedWorld jClosedWorld =
        backendStrategy.createJClosedWorld(kClosedWorld, result);
    return jClosedWorld;
  }

  /// Empty the [enqueuer] queue.
  void emptyQueue(Enqueuer enqueuer, {void onProgress(Enqueuer enqueuer)}) {
    selfTask.measureSubtask("emptyQueue", () {
      enqueuer.forEach((WorkItem work) {
        if (onProgress != null) {
          onProgress(enqueuer);
        }
        reporter.withCurrentElement(
            work.element,
            () => selfTask.measureSubtask("applyImpact", () {
                  enqueuer.applyImpact(
                      selfTask.measureSubtask("work.run", () => work.run()),
                      impactSource: work.element);
                }));
      });
    });
  }

  void processQueue(ElementEnvironment elementEnvironment, Enqueuer enqueuer,
      FunctionEntity mainMethod,
      {void onProgress(Enqueuer enqueuer)}) {
    selfTask.measureSubtask("processQueue", () {
      enqueuer.open(
          impactStrategy,
          mainMethod,
          elementEnvironment.libraries
              .map((LibraryEntity library) => library.canonicalUri));
      progress.startPhase();
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

  /// Perform various checks of the queue. This includes checking that the
  /// queues are empty (nothing was added after we stopped processing the
  /// queues).
  checkQueue(Enqueuer enqueuer) {
    enqueuer.checkQueueIsEmpty();
  }

  void showResolutionProgress(Enqueuer enqueuer) {
    assert(phase == PHASE_RESOLVING, 'Unexpected phase: $phase');
    progress.showProgress(
        'Resolved ', enqueuer.processedEntities.length, ' elements.');
  }

  void showCodegenProgress(Enqueuer enqueuer) {
    progress.showProgress(
        'Compiled ', enqueuer.processedEntities.length, ' methods.');
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
  bool inUserCode(Entity element, {bool assumeInUserCode: false}) {
    if (element == null) return assumeInUserCode;
    Uri libraryUri = _uriFromElement(element);
    if (libraryUri == null) return false;
    if (_userCodeLocations.isEmpty && assumeInUserCode) return true;
    return _userCodeLocations.any(
        (CodeLocation codeLocation) => codeLocation.inSameLocation(libraryUri));
  }

  /// Return a canonical URI for the source of [element].
  ///
  /// For a package library with canonical URI 'package:foo/bar/baz.dart' the
  /// return URI is 'package:foo'. For non-package libraries the returned URI is
  /// the canonical URI of the library itself.
  Uri getCanonicalUri(Entity element) {
    Uri libraryUri = _uriFromElement(element);
    if (libraryUri == null) return null;
    if (libraryUri.scheme == 'package') {
      int slashPos = libraryUri.path.indexOf('/');
      if (slashPos != -1) {
        String packageName = libraryUri.path.substring(0, slashPos);
        return new Uri(scheme: 'package', path: packageName);
      }
    }
    return libraryUri;
  }

  Uri _uriFromElement(Entity element) {
    if (element is LibraryEntity) {
      return element.canonicalUri;
    } else if (element is ClassEntity) {
      return element.library.canonicalUri;
    } else if (element is MemberEntity) {
      return element.library.canonicalUri;
    }
    return null;
  }
}

class _CompilerOutput implements api.CompilerOutput {
  final Compiler _compiler;
  final api.CompilerOutput _userOutput;

  _CompilerOutput(this._compiler, api.CompilerOutput output)
      : this._userOutput = output ?? const NullCompilerOutput();

  @override
  api.OutputSink createOutputSink(
      String name, String extension, api.OutputType type) {
    if (_compiler.compilationFailed) {
      // Ensure that we don't emit output when the compilation has failed.
      return const NullCompilerOutput().createOutputSink(name, extension, type);
    }
    return _userOutput.createOutputSink(name, extension, type);
  }

  @override
  api.BinaryOutputSink createBinarySink(Uri uri) {
    return _userOutput.createBinarySink(uri);
  }
}

/// Information about suppressed warnings and hints for a given library.
class SuppressionInfo {
  int warnings = 0;
  int hints = 0;
}

class CompilerDiagnosticReporter extends DiagnosticReporter {
  final Compiler compiler;
  @override
  CompilerOptions get options => compiler.options;

  Entity _currentElement;
  bool hasCrashed = false;

  /// `true` if the last diagnostic was filtered, in which case the
  /// accompanying info message should be filtered as well.
  bool lastDiagnosticWasFiltered = false;

  /// Map containing information about the warnings and hints that have been
  /// suppressed for each library.
  Map<Uri, SuppressionInfo> suppressedWarnings = <Uri, SuppressionInfo>{};

  CompilerDiagnosticReporter(this.compiler);

  Entity get currentElement => _currentElement;

  @override
  DiagnosticMessage createMessage(Spannable spannable, MessageKind messageKind,
      [Map<String, String> arguments = const {}]) {
    SourceSpan span = spanFromSpannable(spannable);
    MessageTemplate template = MessageTemplate.TEMPLATES[messageKind];
    Message message = template.message(arguments, options);
    return new DiagnosticMessage(span, spannable, message);
  }

  @override
  void reportError(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reportDiagnosticInternal(message, infos, api.Diagnostic.ERROR);
  }

  @override
  void reportWarning(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reportDiagnosticInternal(message, infos, api.Diagnostic.WARNING);
  }

  @override
  void reportHint(DiagnosticMessage message,
      [List<DiagnosticMessage> infos = const <DiagnosticMessage>[]]) {
    reportDiagnosticInternal(message, infos, api.Diagnostic.HINT);
  }

  @deprecated
  @override
  void reportInfo(Spannable node, MessageKind messageKind,
      [Map<String, String> arguments = const {}]) {
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
          Entity element = elementFromSpannable(message.spannable);
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
      compiler.fatalDiagnosticReported(message, infos, kind);
    }
  }

  @override
  bool get hasReportedError => compiler.compilationFailed;

  /// Perform an operation, [f], returning the return value from [f].  If an
  /// error occurs then report it as having occurred during compilation of
  /// [element].  Can be nested.
  @override
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

  /// Using [frontendStrategy] to compute a [SourceSpan] from spannable using
  /// the [currentElement] as context.
  SourceSpan _spanFromStrategy(Spannable spannable) {
    SourceSpan span;
    if (compiler.phase == Compiler.PHASE_COMPILING) {
      span =
          compiler.backendStrategy.spanFromSpannable(spannable, currentElement);
    } else {
      span = compiler.frontendStrategy
          .spanFromSpannable(spannable, currentElement);
    }
    if (span != null) return span;
    throw 'No error location.';
  }

  @override
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
    } else {
      return _spanFromStrategy(spannable);
    }
  }

  @override
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
        .message({'buildId': compiler.options.buildId}, options));
  }

  /// Finds the approximate [Element] for [node]. [currentElement] is used as
  /// the default value.
  Entity elementFromSpannable(Spannable node) {
    Entity element;
    if (node is Entity) {
      element = node;
    } else if (node is HInstruction) {
      element = node.sourceElement;
    }
    return element != null ? element : currentElement;
  }

  @override
  void log(message) {
    Message msg = MessageTemplate.TEMPLATES[MessageKind.GENERIC]
        .message({'text': '$message'}, options);
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

  onError(Uri uri, error, StackTrace stackTrace) {
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
    return new Future.error(error, stackTrace);
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
        Message message = template.message({
          'warnings': info.warnings.toString(),
          'hints': info.hints.toString(),
          'uri': uri.toString(),
        }, options);
        reportDiagnostic(new DiagnosticMessage(null, null, message),
            const <DiagnosticMessage>[], api.Diagnostic.HINT);
      });
    }
  }
}

class _MapImpactCacheDeleter implements ImpactCacheDeleter {
  final Map<Entity, WorldImpact> _impactCache;
  _MapImpactCacheDeleter(this._impactCache);

  @override
  void uncacheWorldImpact(Entity element) {
    if (retainDataForTesting) return;
    _impactCache.remove(element);
  }

  @override
  void emptyCache() {
    if (retainDataForTesting) return;
    _impactCache.clear();
  }
}

class _EmptyEnvironment implements Environment {
  const _EmptyEnvironment();

  @override
  String valueOf(String key) => null;

  @override
  Map<String, String> toMap() => const {};
}

/// Interface for showing progress during compilation.
class Progress {
  const Progress();

  /// Starts a new phase for which to show progress.
  void startPhase() {}

  /// Shows progress of the current phase if needed. The shown message is
  /// computed as '$prefix$count$suffix'.
  void showProgress(String prefix, int count, String suffix) {}
}

/// Progress implementations that prints progress to the [DiagnosticReporter]
/// with 500ms intervals.
class ProgressImpl implements Progress {
  final DiagnosticReporter _reporter;
  final Stopwatch _stopwatch = new Stopwatch()..start();

  ProgressImpl(this._reporter);

  @override
  void showProgress(String prefix, int count, String suffix) {
    if (_stopwatch.elapsedMilliseconds > 500) {
      _reporter.log('$prefix$count$suffix');
      _stopwatch.reset();
    }
  }

  @override
  void startPhase() {
    _stopwatch.reset();
  }
}

/// Progress implementations that prints progress to the [DiagnosticReporter]
/// with 500ms intervals using escape sequences to keep the progress data on a
/// single line.
class InteractiveProgress implements Progress {
  final Stopwatch _stopwatchPhase = new Stopwatch()..start();
  final Stopwatch _stopwatchInterval = new Stopwatch()..start();
  @override
  void startPhase() {
    print('');
    _stopwatchPhase.reset();
    _stopwatchInterval.reset();
  }

  @override
  void showProgress(String prefix, int count, String suffix) {
    if (_stopwatchInterval.elapsedMilliseconds > 500) {
      var time = _stopwatchPhase.elapsedMilliseconds / 1000;
      var rate = count / _stopwatchPhase.elapsedMilliseconds;
      var s = new StringBuffer('\x1b[1A\x1b[K') // go up and clear the line.
        ..write('\x1b[48;5;40m\x1b[30m==>\x1b[0m $prefix')
        ..write(count)
        ..write('$suffix Elapsed time: ')
        ..write(time.toStringAsFixed(2))
        ..write(' s. Rate: ')
        ..write(rate.toStringAsFixed(2))
        ..write(' units/ms');
      print('$s');
      _stopwatchInterval.reset();
    }
  }
}
