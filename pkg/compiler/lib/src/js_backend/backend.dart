// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend;

import '../common.dart';
import '../common/backend_api.dart' show ImpactTransformer;
import '../common/codegen.dart' show CodegenResult;
import '../common/names.dart' show Uris;
import '../common/tasks.dart' show CompilerTask;
import '../common/work.dart';
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../compiler.dart' show Compiler;
import '../deferred_load.dart' show DeferredLoadTask;
import '../dump_info.dart' show DumpInfoTask;
import '../elements/entities.dart';
import '../enqueue.dart' show Enqueuer, EnqueueTask, ResolutionEnqueuer;
import '../frontend_strategy.dart';
import '../inferrer/types.dart';
import '../io/source_information.dart' show SourceInformationStrategy;
import '../js/js.dart' as jsAst;
import '../js_model/elements.dart';
import '../js_emitter/js_emitter.dart' show CodeEmitterTask, ModularEmitter;
import '../kernel/dart2js_target.dart';
import '../native/enqueue.dart';
import '../ssa/ssa.dart' show SsaFunctionCompiler;
import '../tracer.dart';
import '../universe/class_hierarchy.dart'
    show ClassHierarchyBuilder, ClassQueries;
import '../universe/codegen_world_builder.dart';
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart';
import '../universe/world_impact.dart'
    show ImpactStrategy, ImpactUseCase, WorldImpact, WorldImpactVisitor;
import '../util/util.dart';
import '../world.dart' show JClosedWorld;
import 'field_analysis.dart';
import 'annotations.dart';
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'checked_mode_helpers.dart';
import 'codegen_listener.dart';
import 'custom_elements_analysis.dart';
import 'enqueuer.dart';
import 'impact_transformer.dart';
import 'inferred_data.dart';
import 'interceptor_data.dart';
import 'namer.dart';
import 'native_data.dart';
import 'no_such_method_registry.dart';
import 'resolution_listener.dart';
import 'runtime_types.dart';

abstract class FunctionCompiler {
  void onCodegenStart(CodegenInputs codegen);

  /// Generates JavaScript code for [member].
  CodegenResult compile(
      MemberEntity member,
      CodegenInputs codegen,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults);

  Iterable get tasks;
}

/*
 * Invariants:
 *   canInline(function) implies canInline(function, insideLoop:true)
 *   !canInline(function, insideLoop: true) implies !canInline(function)
 */
class FunctionInlineCache {
  static const int _unknown = -1;
  static const int _mustNotInline = 0;
  // May-inline-in-loop means that the function may not be inlined outside loops
  // but may be inlined in a loop.
  static const int _mayInlineInLoopMustNotOutside = 1;
  // The function can be inlined in a loop, but not outside.
  static const int _canInlineInLoopMustNotOutside = 2;
  // May-inline means that we know that it can be inlined inside a loop, but
  // don't know about the general case yet.
  static const int _canInlineInLoopMayInlineOutside = 3;
  static const int _canInline = 4;

  final Map<FunctionEntity, int> _cachedDecisions =
      new Map<FunctionEntity, int>();

  final Set<FunctionEntity> _tryInlineFunctions = new Set<FunctionEntity>();

  FunctionInlineCache(AnnotationsData annotationsData) {
    annotationsData.forEachNoInline((FunctionEntity function) {
      markAsNonInlinable(function);
    });
    annotationsData.forEachTryInline((FunctionEntity function) {
      markAsTryInline(function);
    });
  }

  /// Checks that [method] is the canonical representative for this method.
  ///
  /// For a [MethodElement] this means it must be the declaration element.
  bool checkFunction(FunctionEntity method) {
    return '$method'.startsWith(jsElementPrefix);
  }

  /// Returns the current cache decision. This should only be used for testing.
  int getCurrentCacheDecisionForTesting(FunctionEntity element) {
    assert(checkFunction(element), failedAt(element));
    return _cachedDecisions[element];
  }

  // Returns `true`/`false` if we have a cached decision.
  // Returns `null` otherwise.
  bool canInline(FunctionEntity element, {bool insideLoop}) {
    assert(checkFunction(element), failedAt(element));
    int decision = _cachedDecisions[element];

    if (decision == null) {
      // TODO(sra): Have annotations for mustInline / noInline for constructor
      // bodies. (There used to be some logic here to have constructor bodies,
      // inherit the settings from annotations on the generative
      // constructor. This was conflated with the heuristic decisions, leading
      // to lack of inlining where it was beneficial.)
      decision = _unknown;
    }

    if (insideLoop) {
      switch (decision) {
        case _mustNotInline:
          return false;

        case _unknown:
        case _mayInlineInLoopMustNotOutside:
          // We know we can't inline outside a loop, but don't know for the
          // loop case. Return `null` to indicate that we don't know yet.
          return null;

        case _canInlineInLoopMustNotOutside:
        case _canInlineInLoopMayInlineOutside:
        case _canInline:
          return true;
      }
    } else {
      switch (decision) {
        case _mustNotInline:
        case _mayInlineInLoopMustNotOutside:
        case _canInlineInLoopMustNotOutside:
          return false;

        case _unknown:
        case _canInlineInLoopMayInlineOutside:
          // We know we can inline inside a loop, but don't know for the
          // non-loop case. Return `null` to indicate that we don't know yet.
          return null;

        case _canInline:
          return true;
      }
    }

    // Quiet static checker.
    return null;
  }

  void markAsInlinable(FunctionEntity element, {bool insideLoop}) {
    assert(checkFunction(element), failedAt(element));
    int oldDecision = _cachedDecisions[element];

    if (oldDecision == null) {
      oldDecision = _unknown;
    }

    if (insideLoop) {
      switch (oldDecision) {
        case _mustNotInline:
          throw failedAt(
              element,
              "Can't mark a function as non-inlinable and inlinable at the "
              "same time.");

        case _unknown:
          // We know that it can be inlined in a loop, but don't know about the
          // non-loop case yet.
          _cachedDecisions[element] = _canInlineInLoopMayInlineOutside;
          break;

        case _mayInlineInLoopMustNotOutside:
          _cachedDecisions[element] = _canInlineInLoopMustNotOutside;
          break;

        case _canInlineInLoopMustNotOutside:
        case _canInlineInLoopMayInlineOutside:
        case _canInline:
          // Do nothing.
          break;
      }
    } else {
      switch (oldDecision) {
        case _mustNotInline:
        case _mayInlineInLoopMustNotOutside:
        case _canInlineInLoopMustNotOutside:
          throw failedAt(
              element,
              "Can't mark a function as non-inlinable and inlinable at the "
              "same time.");

        case _unknown:
        case _canInlineInLoopMayInlineOutside:
          _cachedDecisions[element] = _canInline;
          break;

        case _canInline:
          // Do nothing.
          break;
      }
    }
  }

  void markAsNonInlinable(FunctionEntity element, {bool insideLoop: true}) {
    assert(checkFunction(element), failedAt(element));
    int oldDecision = _cachedDecisions[element];

    if (oldDecision == null) {
      oldDecision = _unknown;
    }

    if (insideLoop) {
      switch (oldDecision) {
        case _canInlineInLoopMustNotOutside:
        case _canInlineInLoopMayInlineOutside:
        case _canInline:
          throw failedAt(
              element,
              "Can't mark a function as non-inlinable and inlinable at the "
              "same time.");

        case _mayInlineInLoopMustNotOutside:
        case _unknown:
          _cachedDecisions[element] = _mustNotInline;
          break;

        case _mustNotInline:
          // Do nothing.
          break;
      }
    } else {
      switch (oldDecision) {
        case _canInline:
          throw failedAt(
              element,
              "Can't mark a function as non-inlinable and inlinable at the "
              "same time.");

        case _unknown:
          // We can't inline outside a loop, but we might still be allowed to do
          // so outside.
          _cachedDecisions[element] = _mayInlineInLoopMustNotOutside;
          break;

        case _canInlineInLoopMayInlineOutside:
          // We already knew that the function could be inlined inside a loop,
          // but didn't have information about the non-loop case. Now we know
          // that it can't be inlined outside a loop.
          _cachedDecisions[element] = _canInlineInLoopMustNotOutside;
          break;

        case _mayInlineInLoopMustNotOutside:
        case _canInlineInLoopMustNotOutside:
        case _mustNotInline:
          // Do nothing.
          break;
      }
    }
  }

  void markAsTryInline(FunctionEntity element) {
    assert(checkFunction(element), failedAt(element));
    _tryInlineFunctions.add(element);
  }

  bool markedAsTryInline(FunctionEntity element) {
    assert(checkFunction(element), failedAt(element));
    return _tryInlineFunctions.contains(element);
  }
}

enum SyntheticConstantKind {
  DUMMY_INTERCEPTOR,
  EMPTY_VALUE,
  TYPEVARIABLE_REFERENCE, // Reference to a type in reflection data.
  NAME
}

class JavaScriptBackend {
  static const String JS = 'JS';
  static const String JS_BUILTIN = 'JS_BUILTIN';
  static const String JS_EMBEDDED_GLOBAL = 'JS_EMBEDDED_GLOBAL';
  static const String JS_INTERCEPTOR_CONSTANT = 'JS_INTERCEPTOR_CONSTANT';
  static const String JS_STRING_CONCAT = 'JS_STRING_CONCAT';

  final Compiler compiler;

  FrontendStrategy get frontendStrategy => compiler.frontendStrategy;

  FunctionCompiler functionCompiler;

  CodeEmitterTask emitterTask;

  /// The generated code as a js AST for compiled methods.
  final Map<MemberEntity, jsAst.Expression> generatedCode =
      <MemberEntity, jsAst.Expression>{};

  Namer _namer;

  Namer get namerForTesting => _namer;

  /// Set of classes whose `operator ==` methods handle `null` themselves.
  final Set<ClassEntity> specialOperatorEqClasses = new Set<ClassEntity>();

  List<CompilerTask> get tasks {
    List<CompilerTask> result = functionCompiler.tasks;
    result.add(emitterTask);
    return result;
  }

  RuntimeTypesChecksBuilder _rtiChecksBuilder;

  RuntimeTypesEncoder _rtiEncoder;

  /// True if the html library has been loaded.
  bool htmlLibraryIsLoaded = false;

  /// Resolution support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsResolutionAnalysis _customElementsResolutionAnalysis;

  /// Codegen support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsCodegenAnalysis _customElementsCodegenAnalysis;

  KFieldAnalysis _fieldAnalysis;

  /// Support for classifying `noSuchMethod` implementations.
  NoSuchMethodRegistry noSuchMethodRegistry;

  /// Backend transformation methods for the world impacts.
  ImpactTransformer impactTransformer;

  CodegenImpactTransformer _codegenImpactTransformer;

  /// The strategy used for collecting and emitting source information.
  SourceInformationStrategy sourceInformationStrategy;

  NativeDataBuilderImpl _nativeDataBuilder;
  NativeDataBuilder get nativeDataBuilder => _nativeDataBuilder;
  BackendUsageBuilder _backendUsageBuilder;

  NativeResolutionEnqueuer _nativeResolutionEnqueuer;
  NativeCodegenEnqueuer _nativeCodegenEnqueuer;

  JavaScriptBackend(this.compiler,
      {bool generateSourceMap: true,
      bool useMultiSourceInfo: false,
      bool useNewSourceInfo: false})
      : this.sourceInformationStrategy =
            compiler.backendStrategy.sourceInformationStrategy {
    CommonElements commonElements = compiler.frontendStrategy.commonElements;
    _backendUsageBuilder =
        new BackendUsageBuilderImpl(compiler.frontendStrategy);
    emitterTask = new CodeEmitterTask(compiler, generateSourceMap);
    noSuchMethodRegistry = new NoSuchMethodRegistryImpl(
        commonElements, compiler.frontendStrategy.createNoSuchMethodResolver());
    functionCompiler = new SsaFunctionCompiler(
        compiler.options,
        compiler.reporter,
        compiler.backendStrategy,
        compiler.measurer,
        sourceInformationStrategy);
  }

  DiagnosticReporter get reporter => compiler.reporter;

  ImpactCacheDeleter get impactCacheDeleter => compiler.impactCacheDeleter;

  KFieldAnalysis get fieldAnalysisForTesting => _fieldAnalysis;

  /// Resolution support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsResolutionAnalysis get customElementsResolutionAnalysis {
    assert(
        _customElementsResolutionAnalysis != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "CustomElementsResolutionAnalysis has not been created yet."));
    return _customElementsResolutionAnalysis;
  }

  /// Codegen support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsCodegenAnalysis get customElementsCodegenAnalysis {
    assert(
        _customElementsCodegenAnalysis != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "CustomElementsCodegenAnalysis has not been created yet."));
    return _customElementsCodegenAnalysis;
  }

  RuntimeTypesChecksBuilder get rtiChecksBuilder {
    assert(
        _rtiChecksBuilder != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesChecksBuilder has not been created yet."));
    assert(
        !_rtiChecksBuilder.rtiChecksBuilderClosed,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesChecks has already been computed."));
    return _rtiChecksBuilder;
  }

  RuntimeTypesChecksBuilder get rtiChecksBuilderForTesting => _rtiChecksBuilder;

  RuntimeTypesEncoder get rtiEncoder {
    assert(
        _rtiEncoder != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesEncoder has not been created."));
    return _rtiEncoder;
  }

  Namer determineNamer(JClosedWorld closedWorld, RuntimeTypeTags rtiTags) {
    return compiler.options.enableMinification
        ? compiler.options.useFrequencyNamer
            ? new FrequencyBasedNamer(closedWorld, rtiTags)
            : new MinifyNamer(closedWorld, rtiTags)
        : new Namer(closedWorld, rtiTags);
  }

  void validateInterceptorImplementsAllObjectMethods(
      ClassEntity interceptorClass) {
    if (interceptorClass == null) return;
    ClassEntity objectClass = frontendStrategy.commonElements.objectClass;
    frontendStrategy.elementEnvironment.forEachClassMember(objectClass,
        (_, MemberEntity member) {
      MemberEntity interceptorMember = frontendStrategy.elementEnvironment
          .lookupLocalClassMember(interceptorClass, member.name);
      // Interceptors must override all Object methods due to calling convention
      // differences.
      assert(
          interceptorMember.enclosingClass == interceptorClass,
          failedAt(
              interceptorMember,
              "Member ${member.name} not overridden in ${interceptorClass}. "
              "Found $interceptorMember from "
              "${interceptorMember.enclosingClass}."));
    });
  }

  /// Called before processing of the resolution queue is started.
  void onResolutionStart() {
    // TODO(johnniwinther): Avoid the compiler.elementEnvironment.getThisType
    // calls. Currently needed to ensure resolution of the classes for various
    // queries in native behavior computation, inference and codegen.
    frontendStrategy.elementEnvironment
        .getThisType(frontendStrategy.commonElements.jsArrayClass);
    frontendStrategy.elementEnvironment
        .getThisType(frontendStrategy.commonElements.jsExtendableArrayClass);

    validateInterceptorImplementsAllObjectMethods(
        frontendStrategy.commonElements.jsInterceptorClass);
    // The null-interceptor must also implement *all* methods.
    validateInterceptorImplementsAllObjectMethods(
        frontendStrategy.commonElements.jsNullClass);
  }

  /// Called when the resolution queue has been closed.
  void onResolutionEnd() {
    frontendStrategy.annotationProcessor.processJsInteropAnnotations(
        frontendStrategy.nativeBasicData, nativeDataBuilder);
  }

  ResolutionEnqueuer createResolutionEnqueuer(
      CompilerTask task, Compiler compiler) {
    ElementEnvironment elementEnvironment =
        compiler.frontendStrategy.elementEnvironment;
    CommonElements commonElements = compiler.frontendStrategy.commonElements;
    NativeBasicData nativeBasicData = compiler.frontendStrategy.nativeBasicData;
    RuntimeTypesNeedBuilder rtiNeedBuilder =
        compiler.frontendStrategy.createRuntimeTypesNeedBuilder();
    BackendImpacts impacts = new BackendImpacts(commonElements);
    _nativeResolutionEnqueuer = new NativeResolutionEnqueuer(
        compiler.options,
        elementEnvironment,
        commonElements,
        compiler.frontendStrategy.dartTypes,
        compiler.frontendStrategy.createNativeClassFinder(nativeBasicData));
    _nativeDataBuilder = new NativeDataBuilderImpl(nativeBasicData);
    _customElementsResolutionAnalysis = new CustomElementsResolutionAnalysis(
        elementEnvironment,
        commonElements,
        nativeBasicData,
        _backendUsageBuilder);
    _fieldAnalysis = new KFieldAnalysis(compiler.frontendStrategy);
    ClassQueries classQueries = compiler.frontendStrategy.createClassQueries();
    ClassHierarchyBuilder classHierarchyBuilder =
        new ClassHierarchyBuilder(commonElements, classQueries);
    impactTransformer = new JavaScriptImpactTransformer(
        compiler.options,
        elementEnvironment,
        commonElements,
        impacts,
        nativeBasicData,
        _nativeResolutionEnqueuer,
        _backendUsageBuilder,
        customElementsResolutionAnalysis,
        rtiNeedBuilder,
        classHierarchyBuilder);
    InterceptorDataBuilder interceptorDataBuilder =
        new InterceptorDataBuilderImpl(
            nativeBasicData, elementEnvironment, commonElements);
    AnnotationsDataBuilder annotationsDataBuilder =
        new AnnotationsDataBuilder();
    return new ResolutionEnqueuer(
        task,
        compiler.options,
        compiler.reporter,
        new ResolutionEnqueuerListener(
            compiler.options,
            elementEnvironment,
            commonElements,
            impacts,
            nativeBasicData,
            interceptorDataBuilder,
            _backendUsageBuilder,
            noSuchMethodRegistry,
            customElementsResolutionAnalysis,
            _nativeResolutionEnqueuer,
            _fieldAnalysis,
            compiler.deferredLoadTask),
        compiler.frontendStrategy.createResolutionWorldBuilder(
            nativeBasicData,
            _nativeDataBuilder,
            interceptorDataBuilder,
            _backendUsageBuilder,
            rtiNeedBuilder,
            _fieldAnalysis,
            _nativeResolutionEnqueuer,
            noSuchMethodRegistry,
            annotationsDataBuilder,
            const StrongModeWorldStrategy(),
            classHierarchyBuilder,
            classQueries),
        compiler.frontendStrategy.createResolutionWorkItemBuilder(
            nativeBasicData,
            _nativeDataBuilder,
            annotationsDataBuilder,
            impactTransformer,
            compiler.impactCache,
            _fieldAnalysis));
  }

  /// Creates an [Enqueuer] for code generation specific to this backend.
  CodegenEnqueuer createCodegenEnqueuer(
      CompilerTask task,
      Compiler compiler,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults,
      CodegenInputs codegen) {
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    CommonElements commonElements = closedWorld.commonElements;
    BackendImpacts impacts = new BackendImpacts(commonElements);
    _customElementsCodegenAnalysis = new CustomElementsCodegenAnalysis(
        commonElements, elementEnvironment, closedWorld.nativeData);
    return new CodegenEnqueuer(
        task,
        compiler.options,
        compiler.backendStrategy.createCodegenWorldBuilder(
            closedWorld.nativeData,
            closedWorld,
            compiler.abstractValueStrategy.createSelectorStrategy()),
        compiler.backendStrategy.createCodegenWorkItemBuilder(
            closedWorld, globalInferenceResults, codegen),
        new CodegenEnqueuerListener(
            elementEnvironment,
            commonElements,
            impacts,
            closedWorld.backendUsage,
            closedWorld.rtiNeed,
            customElementsCodegenAnalysis,
            nativeCodegenEnqueuer));
  }

  Map<MemberEntity, WorldImpact> codegenImpactsForTesting;

  WorldImpact generateCode(
      WorkItem work,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults,
      CodegenInputs codegen) {
    MemberEntity member = work.element;
    if (member.isConstructor &&
        member.enclosingClass == closedWorld.commonElements.jsNullClass) {
      // Work around a problem compiling JSNull's constructor.
      return const WorldImpact();
    }

    CodegenResult result = functionCompiler.compile(
        member, codegen, closedWorld, globalInferenceResults);
    if (result.code != null) {
      generatedCode[member] = result.code;
    }
    if (retainDataForTesting) {
      codegenImpactsForTesting ??= <MemberEntity, WorldImpact>{};
      codegenImpactsForTesting[member] = result.impact;
    }
    WorldImpact worldImpact =
        _codegenImpactTransformer.transformCodegenImpact(result.impact);
    compiler.dumpInfoTask.registerImpact(member, worldImpact);
    return worldImpact;
  }

  NativeResolutionEnqueuer get nativeResolutionEnqueuerForTesting =>
      _nativeResolutionEnqueuer;

  NativeEnqueuer get nativeCodegenEnqueuer => _nativeCodegenEnqueuer;

  /// Unit test hook that returns code of an element as a String.
  ///
  /// Invariant: [element] must be a declaration element.
  String getGeneratedCode(MemberEntity element) {
    return jsAst.prettyPrint(generatedCode[element],
        enableMinification: compiler.options.enableMinification);
  }

  /// Generates the output and returns the total size of the generated code.
  int assembleProgram(JClosedWorld closedWorld, InferredData inferredData,
      CodegenInputs codegen, CodegenWorld codegenWorld) {
    int programSize = emitterTask.assembleProgram(
        _namer, closedWorld, inferredData, codegen, codegenWorld);
    closedWorld.noSuchMethodData.emitDiagnostic(reporter);
    return programSize;
  }

  /// This method is called immediately after the [library] and its parts have
  /// been loaded.
  void setAnnotations(LibraryEntity library) {
    AnnotationProcessor processor =
        compiler.frontendStrategy.annotationProcessor;
    if (maybeEnableNative(library.canonicalUri)) {
      processor.extractNativeAnnotations(library);
    }
    processor.extractJsInteropAnnotations(library);
    Uri uri = library.canonicalUri;
    if (uri == Uris.dart_html) {
      _backendUsageBuilder.registerHtmlIsLoaded();
    }
  }

  /// Called when the compiler starts running the codegen enqueuer. The
  /// [WorldImpact] of enabled backend features is returned.
  CodegenInputs onCodegenStart(JClosedWorld closedWorld) {
    RuntimeTypeTags rtiTags = const RuntimeTypeTags();
    OneShotInterceptorData oneShotInterceptorData = new OneShotInterceptorData(
        closedWorld.interceptorData, closedWorld.commonElements);
    Tracer tracer = new Tracer(closedWorld, compiler.outputProvider);
    _rtiEncoder = new RuntimeTypesEncoderImpl(
        rtiTags,
        closedWorld.nativeData,
        closedWorld.elementEnvironment,
        closedWorld.commonElements,
        closedWorld.rtiNeed);
    _nativeCodegenEnqueuer = new NativeCodegenEnqueuer(
        compiler.options,
        closedWorld.elementEnvironment,
        closedWorld.commonElements,
        closedWorld.dartTypes,
        emitterTask,
        closedWorld.liveNativeClasses,
        closedWorld.nativeData);
    _namer = determineNamer(closedWorld, rtiTags);
    emitterTask.createEmitter(_namer, closedWorld);
    // TODO(johnniwinther): Share the impact object created in
    // createCodegenEnqueuer.
    BackendImpacts impacts = new BackendImpacts(closedWorld.commonElements);
    RuntimeTypesSubstitutions rtiSubstitutions;
    if (compiler.options.disableRtiOptimization) {
      rtiSubstitutions = new TrivialRuntimeTypesSubstitutions(closedWorld);
      _rtiChecksBuilder =
          new TrivialRuntimeTypesChecksBuilder(closedWorld, rtiSubstitutions);
    } else {
      RuntimeTypesImpl runtimeTypesImpl = new RuntimeTypesImpl(closedWorld);
      _rtiChecksBuilder = runtimeTypesImpl;
      rtiSubstitutions = runtimeTypesImpl;
    }

    _codegenImpactTransformer = new CodegenImpactTransformer(
        compiler.options,
        closedWorld.elementEnvironment,
        closedWorld.commonElements,
        impacts,
        closedWorld.nativeData,
        closedWorld.backendUsage,
        closedWorld.rtiNeed,
        nativeCodegenEnqueuer,
        _namer,
        oneShotInterceptorData,
        rtiChecksBuilder,
        emitterTask.nativeEmitter);

    CodegenInputs codegen = new CodegenInputsImpl(emitterTask.emitter,
        oneShotInterceptorData, rtiSubstitutions, rtiEncoder, _namer, tracer);

    functionCompiler.onCodegenStart(codegen);
    return codegen;
  }

  /// Called when code generation has been completed.
  void onCodegenEnd(CodegenInputs codegen) {
    sourceInformationStrategy.onComplete();
    codegen.tracer.close();
  }

  /// Creates an impact strategy to use for compilation.
  ImpactStrategy createImpactStrategy(
      {bool supportDeferredLoad: true, bool supportDumpInfo: true}) {
    return new JavaScriptImpactStrategy(
        impactCacheDeleter, compiler.dumpInfoTask,
        supportDeferredLoad: supportDeferredLoad,
        supportDumpInfo: supportDumpInfo);
  }

  EnqueueTask makeEnqueuer() => new EnqueueTask(compiler);
}

class JavaScriptImpactStrategy extends ImpactStrategy {
  final ImpactCacheDeleter impactCacheDeleter;
  final DumpInfoTask dumpInfoTask;
  final bool supportDeferredLoad;
  final bool supportDumpInfo;

  JavaScriptImpactStrategy(this.impactCacheDeleter, this.dumpInfoTask,
      {this.supportDeferredLoad, this.supportDumpInfo});

  @override
  void visitImpact(var impactSource, WorldImpact impact,
      WorldImpactVisitor visitor, ImpactUseCase impactUse) {
    // TODO(johnniwinther): Compute the application strategy once for each use.
    if (impactUse == ResolutionEnqueuer.IMPACT_USE) {
      if (supportDeferredLoad) {
        impact.apply(visitor);
      } else {
        impact.apply(visitor);
      }
    } else if (impactUse == DeferredLoadTask.IMPACT_USE) {
      impact.apply(visitor);
      // Impacts are uncached globally in [onImpactUsed].
    } else if (impactUse == DumpInfoTask.IMPACT_USE) {
      impact.apply(visitor);
      dumpInfoTask.unregisterImpact(impactSource);
    } else {
      impact.apply(visitor);
    }
  }

  @override
  void onImpactUsed(ImpactUseCase impactUse) {
    if (impactUse == DeferredLoadTask.IMPACT_USE) {
      impactCacheDeleter.emptyCache();
    }
  }
}

class SuperMemberData {
  /// A set of member that are called from subclasses via `super`.
  final Set<MemberEntity> _aliasedSuperMembers = new Setlet<MemberEntity>();

  /// Record that [member] is called from a subclass via `super`.
  bool maybeRegisterAliasedSuperMember(MemberEntity member, Selector selector) {
    if (!canUseAliasedSuperMember(member, selector)) {
      // Invoking a super getter isn't supported, this would require changes to
      // compact field descriptors in the emitter.
      return false;
    }
    _aliasedSuperMembers.add(member);
    return true;
  }

  bool canUseAliasedSuperMember(MemberEntity member, Selector selector) {
    return !selector.isGetter;
  }

  /// Returns `true` if [member] is called from a subclass via `super`.
  bool isAliasedSuperMember(MemberEntity member) {
    return _aliasedSuperMembers.contains(member);
  }
}

/// Interface for resources only used during code generation.
abstract class CodegenInputs {
  ModularEmitter get emitter;
  CheckedModeHelpers get checkedModeHelpers;
  OneShotInterceptorData get oneShotInterceptorData;
  RuntimeTypesSubstitutions get rtiSubstitutions;
  RuntimeTypesEncoder get rtiEncoder;
  ModularNamer get namer;
  SuperMemberData get superMemberData;
  Tracer get tracer;
}

class CodegenInputsImpl implements CodegenInputs {
  @override
  final ModularEmitter emitter;

  @override
  final CheckedModeHelpers checkedModeHelpers = new CheckedModeHelpers();

  @override
  final OneShotInterceptorData oneShotInterceptorData;

  @override
  final RuntimeTypesSubstitutions rtiSubstitutions;

  @override
  final RuntimeTypesEncoder rtiEncoder;

  @override
  final ModularNamer namer;

  @override
  final SuperMemberData superMemberData = new SuperMemberData();

  @override
  final Tracer tracer;

  CodegenInputsImpl(this.emitter, this.oneShotInterceptorData,
      this.rtiSubstitutions, this.rtiEncoder, this.namer, this.tracer);
}
