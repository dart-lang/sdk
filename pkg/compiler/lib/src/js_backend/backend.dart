// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend;

import '../common.dart';
import '../common/backend_api.dart' show ImpactTransformer;
import '../common/codegen.dart' show CodegenRegistry, CodegenWorkItem;
import '../common/names.dart' show Uris;
import '../common/tasks.dart' show CompilerTask;
import '../common_elements.dart'
    show CommonElements, ElementEnvironment, JElementEnvironment;
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../deferred_load.dart' show DeferredLoadTask;
import '../dump_info.dart' show DumpInfoTask;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../enqueue.dart' show Enqueuer, EnqueueTask, ResolutionEnqueuer;
import '../frontend_strategy.dart';
import '../inferrer/types.dart';
import '../io/source_information.dart'
    show SourceInformation, SourceInformationStrategy;
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_model/elements.dart';
import '../js/rewrite_async.dart';
import '../js_emitter/js_emitter.dart' show CodeEmitterTask;
import '../js_emitter/sorter.dart' show Sorter;
import '../kernel/dart2js_target.dart';
import '../native/enqueue.dart';
import '../ssa/ssa.dart' show SsaFunctionCompiler;
import '../tracer.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/class_hierarchy.dart'
    show ClassHierarchyBuilder, ClassQueries;
import '../universe/codegen_world_builder.dart';
import '../universe/selector.dart' show Selector;
import '../universe/use.dart' show StaticUse;
import '../universe/world_builder.dart';
import '../universe/world_impact.dart'
    show ImpactStrategy, ImpactUseCase, WorldImpact, WorldImpactVisitor;
import '../util/util.dart';
import '../world.dart' show JClosedWorld;
import 'allocator_analysis.dart';
import 'annotations.dart';
import 'backend_impact.dart';
import 'backend_usage.dart';
import 'checked_mode_helpers.dart';
import 'codegen_listener.dart';
import 'constant_handler_javascript.dart';
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
  void onCodegenStart();

  /// Generates JavaScript code for `work.element`.
  jsAst.Fun compile(CodegenWorkItem work, JClosedWorld closedWorld,
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
    annotationsData.nonInlinableFunctions.forEach((FunctionEntity function) {
      markAsNonInlinable(function);
    });
    annotationsData.tryInlineFunctions.forEach((FunctionEntity function) {
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

  CodeEmitterTask emitter;

  /// The generated code as a js AST for compiled methods.
  final Map<MemberEntity, jsAst.Expression> generatedCode =
      <MemberEntity, jsAst.Expression>{};

  Namer _namer;

  Namer get namer {
    assert(_namer != null,
        failedAt(NO_LOCATION_SPANNABLE, "Namer has not been created yet."));
    return _namer;
  }

  /// Set of classes whose `operator ==` methods handle `null` themselves.
  final Set<ClassEntity> specialOperatorEqClasses = new Set<ClassEntity>();

  List<CompilerTask> get tasks {
    List<CompilerTask> result = functionCompiler.tasks;
    result.add(emitter);
    return result;
  }

  RuntimeTypesChecksBuilder _rtiChecksBuilder;

  RuntimeTypesSubstitutions _rtiSubstitutions;

  RuntimeTypesEncoder _rtiEncoder;

  /// True if the html library has been loaded.
  bool htmlLibraryIsLoaded = false;

  /// Resolution support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsResolutionAnalysis _customElementsResolutionAnalysis;

  /// Codegen support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsCodegenAnalysis _customElementsCodegenAnalysis;

  KAllocatorAnalysis _allocatorResolutionAnalysis;

  /// Support for classifying `noSuchMethod` implementations.
  NoSuchMethodRegistry noSuchMethodRegistry;

  /// The compiler task responsible for the compilation of constants for both
  /// the frontend and the backend.
  final JavaScriptConstantTask constantCompilerTask;

  /// Backend transformation methods for the world impacts.
  ImpactTransformer impactTransformer;

  CodegenImpactTransformer _codegenImpactTransformer;

  /// The strategy used for collecting and emitting source information.
  SourceInformationStrategy sourceInformationStrategy;

  NativeDataBuilderImpl _nativeDataBuilder;
  NativeDataBuilder get nativeDataBuilder => _nativeDataBuilder;
  OneShotInterceptorData _oneShotInterceptorData;
  BackendUsageBuilder _backendUsageBuilder;

  CheckedModeHelpers _checkedModeHelpers;

  final SuperMemberData superMemberData = new SuperMemberData();

  NativeResolutionEnqueuer _nativeResolutionEnqueuer;
  NativeCodegenEnqueuer _nativeCodegenEnqueuer;

  Tracer tracer;

  JavaScriptBackend(this.compiler,
      {bool generateSourceMap: true,
      bool useMultiSourceInfo: false,
      bool useNewSourceInfo: false})
      : this.sourceInformationStrategy =
            compiler.backendStrategy.sourceInformationStrategy,
        constantCompilerTask = new JavaScriptConstantTask(compiler) {
    CommonElements commonElements = compiler.frontendStrategy.commonElements;
    _backendUsageBuilder =
        new BackendUsageBuilderImpl(compiler.frontendStrategy);
    _checkedModeHelpers = new CheckedModeHelpers();
    emitter = new CodeEmitterTask(compiler, generateSourceMap);
    noSuchMethodRegistry = new NoSuchMethodRegistryImpl(
        commonElements, compiler.frontendStrategy.createNoSuchMethodResolver());
    functionCompiler = new SsaFunctionCompiler(
        this, compiler.measurer, sourceInformationStrategy);
  }

  /// The [ConstantSystem] used to interpret compile-time constants for this
  /// backend.
  ConstantSystem get constantSystem => constants.constantSystem;

  DiagnosticReporter get reporter => compiler.reporter;

  ImpactCacheDeleter get impactCacheDeleter => compiler.impactCacheDeleter;

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

  OneShotInterceptorData get oneShotInterceptorData {
    assert(
        _oneShotInterceptorData != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "OneShotInterceptorData has not been prepared yet."));
    return _oneShotInterceptorData;
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

  RuntimeTypesSubstitutions get rtiSubstitutions {
    assert(
        _rtiSubstitutions != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesSubstitutions has not been created yet."));
    return _rtiSubstitutions;
  }

  RuntimeTypesEncoder get rtiEncoder {
    assert(
        _rtiEncoder != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesEncoder has not been created."));
    return _rtiEncoder;
  }

  CheckedModeHelpers get checkedModeHelpers => _checkedModeHelpers;

  /// Returns constant environment for the JavaScript interpretation of the
  /// constants.
  JavaScriptConstantCompiler get constants {
    return constantCompilerTask.jsConstantCompiler;
  }

  Namer determineNamer(
      JClosedWorld closedWorld, CodegenWorldBuilder codegenWorldBuilder) {
    return compiler.options.enableMinification
        ? compiler.options.useFrequencyNamer
            ? new FrequencyBasedNamer(closedWorld, codegenWorldBuilder)
            : new MinifyNamer(closedWorld, codegenWorldBuilder)
        : new Namer(closedWorld, codegenWorldBuilder);
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
    frontendStrategy.annotationProcesser.processJsInteropAnnotations(
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
        constantSystem,
        elementEnvironment,
        commonElements,
        nativeBasicData,
        _backendUsageBuilder);
    _allocatorResolutionAnalysis =
        new KAllocatorAnalysis(compiler.frontendStrategy);
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
            _allocatorResolutionAnalysis,
            compiler.deferredLoadTask),
        compiler.frontendStrategy.createResolutionWorldBuilder(
            nativeBasicData,
            _nativeDataBuilder,
            interceptorDataBuilder,
            _backendUsageBuilder,
            rtiNeedBuilder,
            _allocatorResolutionAnalysis,
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
            compiler.impactCache));
  }

  /// Creates an [Enqueuer] for code generation specific to this backend.
  CodegenEnqueuer createCodegenEnqueuer(
      CompilerTask task,
      Compiler compiler,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults) {
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    CommonElements commonElements = closedWorld.commonElements;
    BackendImpacts impacts = new BackendImpacts(commonElements);
    _customElementsCodegenAnalysis = new CustomElementsCodegenAnalysis(
        constantSystem,
        commonElements,
        elementEnvironment,
        closedWorld.nativeData);
    _nativeCodegenEnqueuer = new NativeCodegenEnqueuer(
        compiler.options,
        elementEnvironment,
        commonElements,
        closedWorld.dartTypes,
        emitter,
        closedWorld.liveNativeClasses,
        closedWorld.nativeData);
    return new CodegenEnqueuer(
        task,
        compiler.options,
        compiler.backendStrategy.createCodegenWorldBuilder(
            closedWorld.nativeData,
            closedWorld,
            compiler.abstractValueStrategy.createSelectorStrategy()),
        compiler.backendStrategy
            .createCodegenWorkItemBuilder(closedWorld, globalInferenceResults),
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

  WorldImpact codegen(CodegenWorkItem work, JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults) {
    MemberEntity element = work.element;
    if (compiler.elementHasCompileTimeError(element)) {
      DiagnosticMessage message =
          // If there's more than one error, the first is probably most
          // informative, as the following errors may be side-effects of the
          // first error.
          compiler.elementsWithCompileTimeErrors[element].first;
      String messageText = message.message.computeMessage();
      jsAst.LiteralString messageLiteral =
          js.escapedString("Compile time error in $element: $messageText");
      generatedCode[element] =
          js("function () { throw new Error(#); }", [messageLiteral]);
      return const WorldImpact();
    }
    if (element.isConstructor &&
        element.enclosingClass == closedWorld.commonElements.jsNullClass) {
      // Work around a problem compiling JSNull's constructor.
      return const WorldImpact();
    }

    jsAst.Fun function =
        functionCompiler.compile(work, closedWorld, globalInferenceResults);
    if (function != null) {
      if (function.sourceInformation == null) {
        function = function.withSourceInformation(
            sourceInformationStrategy.buildSourceMappedMarker());
      }
      generatedCode[element] = function;
    }
    if (retainDataForTesting) {
      codegenImpactsForTesting ??= <MemberEntity, WorldImpact>{};
      codegenImpactsForTesting[element] = work.registry.worldImpact;
    }
    WorldImpact worldImpact = _codegenImpactTransformer
        .transformCodegenImpact(work.registry.worldImpact);
    compiler.dumpInfoTask.registerImpact(element, worldImpact);
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
  int assembleProgram(JClosedWorld closedWorld, InferredData inferredData) {
    int programSize = emitter.assembleProgram(namer, closedWorld, inferredData);
    closedWorld.noSuchMethodData.emitDiagnostic(reporter);
    return programSize;
  }

  /// Returns [:true:] if the checking of [type] is performed directly on the
  /// object and not on an interceptor.
  bool hasDirectCheckFor(CommonElements commonElements, DartType type) {
    if (!type.isInterfaceType) return false;
    InterfaceType interfaceType = type;
    ClassEntity element = interfaceType.element;
    return element == commonElements.stringClass ||
        element == commonElements.boolClass ||
        element == commonElements.numClass ||
        element == commonElements.intClass ||
        element == commonElements.doubleClass ||
        element == commonElements.jsArrayClass ||
        element == commonElements.jsMutableArrayClass ||
        element == commonElements.jsExtendableArrayClass ||
        element == commonElements.jsFixedArrayClass ||
        element == commonElements.jsUnmodifiableArrayClass;
  }

  /// This method is called immediately after the [library] and its parts have
  /// been loaded.
  void setAnnotations(LibraryEntity library) {
    AnnotationProcessor processor =
        compiler.frontendStrategy.annotationProcesser;
    if (maybeEnableNative(library.canonicalUri)) {
      processor.extractNativeAnnotations(library);
    }
    processor.extractJsInteropAnnotations(library);
    Uri uri = library.canonicalUri;
    if (uri == Uris.dart_html) {
      htmlLibraryIsLoaded = true;
    }
  }

  /// Called when the compiler starts running the codegen enqueuer. The
  /// [WorldImpact] of enabled backend features is returned.
  WorldImpact onCodegenStart(JClosedWorld closedWorld,
      CodegenWorldBuilder codegenWorldBuilder, Sorter sorter) {
    functionCompiler.onCodegenStart();
    _oneShotInterceptorData = new OneShotInterceptorData(
        closedWorld.interceptorData, closedWorld.commonElements);
    _namer = determineNamer(closedWorld, codegenWorldBuilder);
    tracer = new Tracer(closedWorld, namer, compiler.outputProvider);
    _rtiEncoder = _namer.rtiEncoder = new RuntimeTypesEncoderImpl(
        namer,
        closedWorld.nativeData,
        closedWorld.elementEnvironment,
        closedWorld.commonElements,
        closedWorld.rtiNeed);
    emitter.createEmitter(namer, closedWorld, codegenWorldBuilder, sorter);
    // TODO(johnniwinther): Share the impact object created in
    // createCodegenEnqueuer.
    BackendImpacts impacts = new BackendImpacts(closedWorld.commonElements);
    if (compiler.options.disableRtiOptimization) {
      _rtiSubstitutions = new TrivialRuntimeTypesSubstitutions(closedWorld);
      _rtiChecksBuilder =
          new TrivialRuntimeTypesChecksBuilder(closedWorld, _rtiSubstitutions);
    } else {
      RuntimeTypesImpl runtimeTypesImpl = new RuntimeTypesImpl(closedWorld);
      _rtiChecksBuilder = runtimeTypesImpl;
      _rtiSubstitutions = runtimeTypesImpl;
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
        namer,
        oneShotInterceptorData,
        rtiChecksBuilder);
    return const WorldImpact();
  }

  /// Called when code generation has been completed.
  void onCodegenEnd() {
    sourceInformationStrategy.onComplete();
    tracer.close();
  }

  /// Enable compilation of code with compile time errors. Returns `true` if
  /// supported by the backend.
  bool enableCodegenWithErrorsIfSupported(Spannable node) => true;

  jsAst.Expression rewriteAsync(
      CommonElements commonElements,
      JElementEnvironment elementEnvironment,
      CodegenRegistry registry,
      FunctionEntity element,
      jsAst.Expression code,
      DartType asyncTypeParameter,
      SourceInformation bodySourceInformation,
      SourceInformation exitSourceInformation) {
    if (element.asyncMarker == AsyncMarker.SYNC) return code;

    AsyncRewriterBase rewriter = null;
    jsAst.Name name = namer.methodPropertyName(
        element is JGeneratorBody ? element.function : element);

    switch (element.asyncMarker) {
      case AsyncMarker.ASYNC:
        rewriter = _makeAsyncRewriter(commonElements, elementEnvironment,
            registry, element, code, asyncTypeParameter, name);
        break;
      case AsyncMarker.SYNC_STAR:
        rewriter = new SyncStarRewriter(reporter, element,
            endOfIteration:
                emitter.staticFunctionAccess(commonElements.endOfIteration),
            iterableFactory: emitter
                .staticFunctionAccess(commonElements.syncStarIterableFactory),
            iterableFactoryTypeArguments: _fetchItemType(asyncTypeParameter),
            yieldStarExpression:
                emitter.staticFunctionAccess(commonElements.yieldStar),
            uncaughtErrorExpression: emitter
                .staticFunctionAccess(commonElements.syncStarUncaughtError),
            safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
            bodyName: namer.deriveAsyncBodyName(name));
        registry.registerStaticUse(new StaticUse.staticInvoke(
            commonElements.syncStarIterableFactory,
            const CallStructure.unnamed(1, 1), [
          elementEnvironment.getFunctionAsyncOrSyncStarElementType(element)
        ]));
        break;
      case AsyncMarker.ASYNC_STAR:
        rewriter = new AsyncStarRewriter(reporter, element,
            asyncStarHelper:
                emitter.staticFunctionAccess(commonElements.asyncStarHelper),
            streamOfController:
                emitter.staticFunctionAccess(commonElements.streamOfController),
            wrapBody: emitter.staticFunctionAccess(commonElements.wrapBody),
            newController: emitter.staticFunctionAccess(
                commonElements.asyncStarStreamControllerFactory),
            newControllerTypeArguments: _fetchItemType(asyncTypeParameter),
            safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
            yieldExpression:
                emitter.staticFunctionAccess(commonElements.yieldSingle),
            yieldStarExpression:
                emitter.staticFunctionAccess(commonElements.yieldStar),
            bodyName: namer.deriveAsyncBodyName(name));
        registry.registerStaticUse(new StaticUse.staticInvoke(
            commonElements.asyncStarStreamControllerFactory,
            const CallStructure.unnamed(1, 1), [
          elementEnvironment.getFunctionAsyncOrSyncStarElementType(element)
        ]));
        break;
    }
    return rewriter.rewrite(code, bodySourceInformation, exitSourceInformation);
  }

  /// Returns an optional expression that evaluates [type].  Returns `null` if
  /// the type expression is determined by the outside context and should be
  /// added as a function parameter to the rewritten code.
  // TODO(sra): We could also return an empty list if the generator takes no
  // type (e.g. due to rtiNeed optimization).
  List<jsAst.Expression> _fetchItemType(DartType type) {
    if (type == null) return null;
    var ast = rtiEncoder.getTypeRepresentation(emitter.emitter, type, null);
    return <jsAst.Expression>[ast];
  }

  AsyncRewriter _makeAsyncRewriter(
      CommonElements commonElements,
      JElementEnvironment elementEnvironment,
      CodegenRegistry registry,
      FunctionEntity element,
      jsAst.Expression code,
      DartType elementType,
      jsAst.Name name) {
    var startFunction = commonElements.asyncHelperStartSync;
    var completerFactory = commonElements.asyncAwaitCompleterFactory;

    List<jsAst.Expression> itemTypeExpression = _fetchItemType(elementType);

    var rewriter = new AsyncRewriter(reporter, element,
        asyncStart: emitter.staticFunctionAccess(startFunction),
        asyncAwait:
            emitter.staticFunctionAccess(commonElements.asyncHelperAwait),
        asyncReturn:
            emitter.staticFunctionAccess(commonElements.asyncHelperReturn),
        asyncRethrow:
            emitter.staticFunctionAccess(commonElements.asyncHelperRethrow),
        wrapBody: emitter.staticFunctionAccess(commonElements.wrapBody),
        completerFactory: emitter.staticFunctionAccess(completerFactory),
        completerFactoryTypeArguments: itemTypeExpression,
        safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
        bodyName: namer.deriveAsyncBodyName(name));

    registry.registerStaticUse(new StaticUse.staticInvoke(
        completerFactory,
        const CallStructure.unnamed(0, 1),
        [elementEnvironment.getFunctionAsyncOrSyncStarElementType(element)]));

    return rewriter;
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
