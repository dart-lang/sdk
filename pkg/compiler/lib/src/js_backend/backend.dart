// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend;

import '../common.dart';
import '../common/backend_api.dart'
    show ForeignResolver, NativeRegistry, ImpactTransformer;
import '../common/codegen.dart' show CodegenWorkItem;
import '../common/names.dart' show Uris;
import '../common/resolution.dart' show Resolution, Target;
import '../common/tasks.dart' show CompilerTask;
import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../deferred_load.dart' show DeferredLoadTask, OutputUnitData;
import '../dump_info.dart' show DumpInfoTask;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../enqueue.dart'
    show
        DirectEnqueuerStrategy,
        Enqueuer,
        EnqueueTask,
        ResolutionEnqueuer,
        TreeShakingEnqueuerStrategy;
import '../frontend_strategy.dart';
import '../io/source_information.dart' show SourceInformationStrategy;
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js/rewrite_async.dart';
import '../js_emitter/js_emitter.dart' show CodeEmitterTask;
import '../js_emitter/sorter.dart' show Sorter;
import '../library_loader.dart' show LoadedLibraries;
import '../native/native.dart' as native;
import '../native/resolver.dart';
import '../ssa/ssa.dart' show SsaFunctionCompiler;
import '../tracer.dart';
import '../tree/tree.dart';
import '../types/types.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/class_hierarchy_builder.dart'
    show ClassHierarchyBuilder, ClassQueries;
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart';
import '../universe/world_impact.dart'
    show ImpactStrategy, ImpactUseCase, WorldImpact, WorldImpactVisitor;
import '../util/util.dart';
import '../world.dart' show ClosedWorld, ClosedWorldRefiner;
import 'annotations.dart' as optimizerHints;
import 'backend_impact.dart';
import 'backend_serialization.dart' show JavaScriptBackendSerialization;
import 'backend_usage.dart';
import 'checked_mode_helpers.dart';
import 'codegen_listener.dart';
import 'constant_handler_javascript.dart';
import 'custom_elements_analysis.dart';
import 'enqueuer.dart';
import 'impact_transformer.dart';
import 'interceptor_data.dart';
import 'js_interop_analysis.dart' show JsInteropAnalysis;
import 'mirrors_analysis.dart';
import 'mirrors_data.dart';
import 'namer.dart';
import 'native_data.dart';
import 'no_such_method_registry.dart';
import 'patch_resolver.dart';
import 'resolution_listener.dart';
import 'runtime_types.dart';
import 'type_variable_handler.dart';

const VERBOSE_OPTIMIZER_HINTS = false;

abstract class FunctionCompiler {
  void onCodegenStart();

  /// Generates JavaScript code for `work.element`.
  jsAst.Fun compile(CodegenWorkItem work, ClosedWorld closedWorld);

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
  static const int _mustInline = 5;

  final Map<FunctionEntity, int> _cachedDecisions =
      new Map<FunctionEntity, int>();

  /// Checks that [method] is the canonical representative for this method.
  ///
  /// For a [MethodElement] this means it must be the declaration element.
  bool checkFunction(FunctionEntity method) {
    if (method is MethodElement) return method.isDeclaration;
    return true;
  }

  /// Returns the current cache decision. This should only be used for testing.
  int getCurrentCacheDecisionForTesting(FunctionEntity element) {
    assert(checkFunction(element));
    return _cachedDecisions[element];
  }

  // Returns `true`/`false` if we have a cached decision.
  // Returns `null` otherwise.
  bool canInline(FunctionEntity element, {bool insideLoop}) {
    assert(checkFunction(element));
    int decision = _cachedDecisions[element];

    if (decision == null) {
      // These synthetic elements are not yet present when we initially compute
      // this cache from metadata annotations, so look for their parent.
      if (element is ConstructorBodyEntity) {
        ConstructorBodyEntity body = element;
        decision = _cachedDecisions[body.constructor];
      }
      if (decision == null) {
        decision = _unknown;
      }
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
        case _mustInline:
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
        case _mustInline:
          return true;
      }
    }

    // Quiet static checker.
    return null;
  }

  void markAsInlinable(FunctionEntity element, {bool insideLoop}) {
    assert(checkFunction(element));
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
        case _mustInline:
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
        case _mustInline:
          // Do nothing.
          break;
      }
    }
  }

  void markAsNonInlinable(FunctionEntity element, {bool insideLoop: true}) {
    assert(checkFunction(element));
    int oldDecision = _cachedDecisions[element];

    if (oldDecision == null) {
      oldDecision = _unknown;
    }

    if (insideLoop) {
      switch (oldDecision) {
        case _canInlineInLoopMustNotOutside:
        case _canInlineInLoopMayInlineOutside:
        case _canInline:
        case _mustInline:
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
        case _mustInline:
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

  void markAsMustInline(FunctionEntity element) {
    assert(checkFunction(element));
    _cachedDecisions[element] = _mustInline;
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

  /// Returns true if the backend supports reflection.
  bool get supportsReflection => emitter.supportsReflection;

  FunctionCompiler functionCompiler;

  CodeEmitterTask emitter;

  /**
   * The generated code as a js AST for compiled methods.
   */
  final Map<MemberEntity, jsAst.Expression> generatedCode =
      <MemberEntity, jsAst.Expression>{};

  FunctionInlineCache inlineCache = new FunctionInlineCache();

  /// If [true], the compiler will emit code that logs whenever a method is
  /// called. When TRACE_METHOD is 'console' this will be logged
  /// directly in the JavaScript console. When TRACE_METHOD is 'post' the
  /// information will be sent to a server via a POST request.
  static const String TRACE_METHOD = const String.fromEnvironment('traceCalls');
  static const bool TRACE_CALLS =
      TRACE_METHOD == 'post' || TRACE_METHOD == 'console';

  Namer _namer;

  Namer get namer {
    assert(_namer != null,
        failedAt(NO_LOCATION_SPANNABLE, "Namer has not been created yet."));
    return _namer;
  }

  /**
   * Set of classes whose `operator ==` methods handle `null` themselves.
   */
  final Set<ClassEntity> specialOperatorEqClasses = new Set<ClassEntity>();

  List<CompilerTask> get tasks {
    List<CompilerTask> result = functionCompiler.tasks;
    result.add(emitter);
    result.add(patchResolverTask);
    return result;
  }

  RuntimeTypesImpl _rti;

  RuntimeTypesEncoder _rtiEncoder;

  /// True if the html library has been loaded.
  bool htmlLibraryIsLoaded = false;

  /// Codegen handler for reflective access to type variables.
  TypeVariableCodegenAnalysis _typeVariableCodegenAnalysis;

  /// Resolution support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsResolutionAnalysis _customElementsResolutionAnalysis;

  /// Codegen support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsCodegenAnalysis _customElementsCodegenAnalysis;

  /// Codegen support for typed JavaScript interop.
  JsInteropAnalysis jsInteropAnalysis;

  /// Support for classifying `noSuchMethod` implementations.
  NoSuchMethodRegistry noSuchMethodRegistry;

  /// Resolution support for computing reflectable elements.
  MirrorsResolutionAnalysis _mirrorsResolutionAnalysis;

  /// Codegen support for computing reflectable elements.
  MirrorsCodegenAnalysis _mirrorsCodegenAnalysis;

  /// The compiler task responsible for the compilation of constants for both
  /// the frontend and the backend.
  final JavaScriptConstantTask constantCompilerTask;

  /// Backend transformation methods for the world impacts.
  ImpactTransformer impactTransformer;

  CodegenImpactTransformer _codegenImpactTransformer;

  PatchResolverTask patchResolverTask;

  /// The strategy used for collecting and emitting source information.
  SourceInformationStrategy sourceInformationStrategy;

  /// Interface for serialization of backend specific data.
  JavaScriptBackendSerialization serialization;

  NativeDataBuilderImpl _nativeDataBuilder;
  NativeDataBuilder get nativeDataBuilder => _nativeDataBuilder;
  final NativeDataResolver _nativeDataResolver;
  OneShotInterceptorData _oneShotInterceptorData;
  BackendUsageBuilder _backendUsageBuilder;
  MirrorsDataImpl _mirrorsData;
  OutputUnitData _outputUnitData;

  CheckedModeHelpers _checkedModeHelpers;

  final SuperMemberData superMemberData = new SuperMemberData();

  native.NativeResolutionEnqueuer _nativeResolutionEnqueuer;
  native.NativeCodegenEnqueuer _nativeCodegenEnqueuer;

  Target _target;

  Tracer tracer;

  JavaScriptBackend(this.compiler,
      {bool generateSourceMap: true,
      bool useStartupEmitter: false,
      bool useMultiSourceInfo: false,
      bool useNewSourceInfo: false})
      : this.sourceInformationStrategy =
            compiler.backendStrategy.sourceInformationStrategy,
        constantCompilerTask = new JavaScriptConstantTask(compiler),
        _nativeDataResolver = new NativeDataResolverImpl(compiler) {
    CommonElements commonElements = compiler.frontendStrategy.commonElements;
    _target = new JavaScriptBackendTarget(this);
    _mirrorsData = compiler.frontendStrategy.createMirrorsDataBuilder();
    _backendUsageBuilder = new BackendUsageBuilderImpl(commonElements);
    _checkedModeHelpers = new CheckedModeHelpers();
    emitter =
        new CodeEmitterTask(compiler, generateSourceMap, useStartupEmitter);
    jsInteropAnalysis = new JsInteropAnalysis(this);
    _mirrorsResolutionAnalysis =
        compiler.frontendStrategy.createMirrorsResolutionAnalysis(this);

    noSuchMethodRegistry = new NoSuchMethodRegistry(
        commonElements, compiler.frontendStrategy.createNoSuchMethodResolver());
    patchResolverTask = new PatchResolverTask(compiler);
    functionCompiler = new SsaFunctionCompiler(
        this, compiler.measurer, sourceInformationStrategy);
    serialization = new JavaScriptBackendSerialization(this);
  }

  /// The [ConstantSystem] used to interpret compile-time constants for this
  /// backend.
  ConstantSystem get constantSystem => constants.constantSystem;

  DiagnosticReporter get reporter => compiler.reporter;

  Resolution get resolution => compiler.resolution;

  ImpactCacheDeleter get impactCacheDeleter => compiler.impactCacheDeleter;

  Target get target => _target;

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

  /// Codegen handler for reflective access to type variables.
  TypeVariableCodegenAnalysis get typeVariableCodegenAnalysis {
    assert(
        _typeVariableCodegenAnalysis != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "TypeVariableHandler has not been created yet."));
    return _typeVariableCodegenAnalysis;
  }

  MirrorsData get mirrorsData => _mirrorsData;

  MirrorsDataBuilder get mirrorsDataBuilder => _mirrorsData;

  OutputUnitData get outputUnitData => _outputUnitData;

  /// Resolution support for computing reflectable elements.
  MirrorsResolutionAnalysis get mirrorsResolutionAnalysis =>
      _mirrorsResolutionAnalysis;

  /// Codegen support for computing reflectable elements.
  MirrorsCodegenAnalysis get mirrorsCodegenAnalysis {
    assert(
        _mirrorsCodegenAnalysis != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "MirrorsCodegenAnalysis has not been created yet."));
    return _mirrorsCodegenAnalysis;
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
        _rti != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesChecksBuilder has not been created yet."));
    assert(
        !_rti.rtiChecksBuilderClosed,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesChecks has already been computed."));
    return _rti;
  }

  RuntimeTypesSubstitutions get rtiSubstitutions {
    assert(
        _rti != null,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesSubstitutions has not been created yet."));
    return _rti;
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

  MethodElement resolveExternalFunction(MethodElement element) {
    if (isForeign(compiler.frontendStrategy.commonElements, element)) {
      return element;
    }
    if (_nativeDataResolver.isJsInteropMember(element)) {
      if (element.memberName == const PublicName('[]') ||
          element.memberName == const PublicName('[]=')) {
        reporter.reportErrorMessage(
            element, MessageKind.JS_INTEROP_INDEX_NOT_SUPPORTED);
      }
      return element;
    }
    return patchResolverTask.measure(() {
      return patchResolverTask.resolveExternalFunction(element);
    });
  }

  bool isForeign(CommonElements commonElements, Element element) =>
      element.library == commonElements.foreignLibrary;

  bool isBackendLibrary(CommonElements commonElements, LibraryElement library) {
    return library == commonElements.interceptorsLibrary ||
        library == commonElements.jsHelperLibrary;
  }

  Namer determineNamer(
      ClosedWorld closedWorld, CodegenWorldBuilder codegenWorldBuilder) {
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

  /// Called when the closed world from resolution has been computed.
  void onResolutionClosedWorld(
      ClosedWorld closedWorld, ClosedWorldRefiner closedWorldRefiner) {
    for (MemberEntity entity
        in compiler.enqueuer.resolution.processedEntities) {
      processAnnotations(closedWorld.elementEnvironment,
          closedWorld.commonElements, entity, closedWorldRefiner);
    }
    mirrorsDataBuilder.computeMembersNeededForReflection(
        compiler.enqueuer.resolution.worldBuilder, closedWorld);
    mirrorsResolutionAnalysis.onResolutionComplete();
  }

  void onDeferredLoadComplete(OutputUnitData data) {
    _outputUnitData = compiler.backendStrategy.convertOutputUnitData(data);
  }

  void onTypeInferenceComplete(GlobalTypeInferenceResults results) {
    noSuchMethodRegistry.onTypeInferenceComplete(results);
  }

  /// Called when resolving a call to a foreign function.
  native.NativeBehavior resolveForeignCall(Send node, Element element,
      CallStructure callStructure, ForeignResolver resolver) {
    if (element.name == JS) {
      return _nativeDataResolver.resolveJsCall(node, resolver);
    } else if (element.name == JS_EMBEDDED_GLOBAL) {
      return _nativeDataResolver.resolveJsEmbeddedGlobalCall(node, resolver);
    } else if (element.name == JS_BUILTIN) {
      return _nativeDataResolver.resolveJsBuiltinCall(node, resolver);
    } else if (element.name == JS_INTERCEPTOR_CONSTANT) {
      // The type constant that is an argument to JS_INTERCEPTOR_CONSTANT names
      // a class that will be instantiated outside the program by attaching a
      // native class dispatch record referencing the interceptor.
      if (!node.argumentsNode.isEmpty) {
        Node argument = node.argumentsNode.nodes.head;
        ConstantExpression constant = resolver.getConstant(argument);
        if (constant != null && constant.kind == ConstantExpressionKind.TYPE) {
          TypeConstantExpression typeConstant = constant;
          if (typeConstant.type is ResolutionInterfaceType) {
            resolver.registerInstantiatedType(typeConstant.type);
            // No native behavior for this call.
            return null;
          }
        }
      }
      reporter.reportErrorMessage(
          node, MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    }
    // No native behavior for this call.
    return null;
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
    TypeVariableResolutionAnalysis typeVariableResolutionAnalysis =
        new TypeVariableResolutionAnalysis(
            compiler.frontendStrategy.elementEnvironment,
            impacts,
            _backendUsageBuilder);
    _nativeResolutionEnqueuer = new native.NativeResolutionEnqueuer(
        compiler.options,
        elementEnvironment,
        commonElements,
        compiler.frontendStrategy.dartTypes,
        _backendUsageBuilder,
        compiler.frontendStrategy.createNativeClassFinder(nativeBasicData));
    _nativeDataBuilder = new NativeDataBuilderImpl(nativeBasicData);
    _customElementsResolutionAnalysis = new CustomElementsResolutionAnalysis(
        constantSystem,
        elementEnvironment,
        commonElements,
        nativeBasicData,
        _backendUsageBuilder);
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
        mirrorsDataBuilder,
        customElementsResolutionAnalysis,
        rtiNeedBuilder,
        classHierarchyBuilder);
    InterceptorDataBuilder interceptorDataBuilder =
        new InterceptorDataBuilderImpl(
            nativeBasicData, elementEnvironment, commonElements);
    return new ResolutionEnqueuer(
        task,
        compiler.options,
        compiler.reporter,
        compiler.options.analyzeOnly && compiler.options.analyzeMain
            ? const DirectEnqueuerStrategy()
            : const TreeShakingEnqueuerStrategy(),
        new ResolutionEnqueuerListener(
            compiler.options,
            elementEnvironment,
            commonElements,
            impacts,
            nativeBasicData,
            interceptorDataBuilder,
            _backendUsageBuilder,
            rtiNeedBuilder,
            mirrorsDataBuilder,
            noSuchMethodRegistry,
            customElementsResolutionAnalysis,
            mirrorsResolutionAnalysis,
            typeVariableResolutionAnalysis,
            _nativeResolutionEnqueuer,
            compiler.deferredLoadTask),
        compiler.frontendStrategy.createResolutionWorldBuilder(
            nativeBasicData,
            _nativeDataBuilder,
            interceptorDataBuilder,
            _backendUsageBuilder,
            rtiNeedBuilder,
            _nativeResolutionEnqueuer,
            const OpenWorldStrategy(),
            classHierarchyBuilder,
            classQueries),
        compiler.frontendStrategy.createResolutionWorkItemBuilder(
            nativeBasicData,
            _nativeDataBuilder,
            impactTransformer,
            compiler.impactCache));
  }

  /// Creates an [Enqueuer] for code generation specific to this backend.
  CodegenEnqueuer createCodegenEnqueuer(
      CompilerTask task, Compiler compiler, ClosedWorld closedWorld) {
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    CommonElements commonElements = closedWorld.commonElements;
    BackendImpacts impacts = new BackendImpacts(commonElements);
    _typeVariableCodegenAnalysis = new TypeVariableCodegenAnalysis(
        closedWorld.elementEnvironment, this, commonElements, mirrorsData);
    _mirrorsCodegenAnalysis = mirrorsResolutionAnalysis.close();
    _customElementsCodegenAnalysis = new CustomElementsCodegenAnalysis(
        constantSystem,
        commonElements,
        elementEnvironment,
        closedWorld.nativeData);
    _nativeCodegenEnqueuer = new native.NativeCodegenEnqueuer(
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
        const TreeShakingEnqueuerStrategy(),
        compiler.backendStrategy.createCodegenWorldBuilder(
            closedWorld.nativeData, closedWorld, const TypeMaskStrategy()),
        compiler.backendStrategy.createCodegenWorkItemBuilder(closedWorld),
        new CodegenEnqueuerListener(
            elementEnvironment,
            commonElements,
            impacts,
            closedWorld.backendUsage,
            closedWorld.rtiNeed,
            customElementsCodegenAnalysis,
            typeVariableCodegenAnalysis,
            mirrorsCodegenAnalysis,
            nativeCodegenEnqueuer));
  }

  WorldImpact codegen(CodegenWorkItem work, ClosedWorld closedWorld) {
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

    jsAst.Fun function = functionCompiler.compile(work, closedWorld);
    if (function != null) {
      if (function.sourceInformation == null) {
        function = function.withSourceInformation(
            sourceInformationStrategy.buildSourceMappedMarker());
      }
      generatedCode[element] = function;
    }
    WorldImpact worldImpact = _codegenImpactTransformer
        .transformCodegenImpact(work.registry.worldImpact);
    compiler.dumpInfoTask.registerImpact(element, worldImpact);
    return worldImpact;
  }

  native.NativeResolutionEnqueuer get nativeResolutionEnqueuerForTesting =>
      _nativeResolutionEnqueuer;

  native.NativeEnqueuer get nativeCodegenEnqueuer => _nativeCodegenEnqueuer;

  /**
   * Unit test hook that returns code of an element as a String.
   *
   * Invariant: [element] must be a declaration element.
   */
  String getGeneratedCode(MemberEntity element) {
    assert(!(element is MemberElement && !element.isDeclaration),
        failedAt(element));
    return jsAst.prettyPrint(generatedCode[element], compiler.options);
  }

  /// Generates the output and returns the total size of the generated code.
  int assembleProgram(ClosedWorld closedWorld) {
    int programSize = emitter.assembleProgram(namer, closedWorld);
    noSuchMethodRegistry.emitDiagnostic(reporter);
    int totalMethodCount = generatedCode.length;
    // TODO(redemption): Support `preMirrorsMethodCount` for entities.
    if (mirrorsCodegenAnalysis.preMirrorsMethodCount != null &&
        totalMethodCount != mirrorsCodegenAnalysis.preMirrorsMethodCount) {
      int mirrorCount =
          totalMethodCount - mirrorsCodegenAnalysis.preMirrorsMethodCount;
      double percentage = (mirrorCount / totalMethodCount) * 100;
      DiagnosticMessage hint = reporter.createMessage(
          closedWorld.elementEnvironment.mainLibrary,
          MessageKind.MIRROR_BLOAT, {
        'count': mirrorCount,
        'total': totalMethodCount,
        'percentage': percentage.round()
      });

      List<DiagnosticMessage> infos = <DiagnosticMessage>[];
      for (LibraryElement library in compiler.libraryLoader.libraries) {
        if (library.isInternalLibrary) continue;
        for (ImportElement import in library.imports) {
          LibraryElement importedLibrary = import.importedLibrary;
          if (importedLibrary != closedWorld.commonElements.mirrorsLibrary)
            continue;
          MessageKind kind =
              compiler.mirrorUsageAnalyzerTask.hasMirrorUsage(library)
                  ? MessageKind.MIRROR_IMPORT
                  : MessageKind.MIRROR_IMPORT_NO_USAGE;
          reporter.withCurrentElement(library, () {
            infos.add(reporter.createMessage(import, kind));
          });
        }
      }
      reporter.reportHint(hint, infos);
    }
    return programSize;
  }

  /**
   * Returns [:true:] if the checking of [type] is performed directly on the
   * object and not on an interceptor.
   */
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
    if (!compiler.serialization.isDeserialized(library)) {
      AnnotationProcessor processor =
          compiler.frontendStrategy.annotationProcesser;
      if (canLibraryUseNative(library)) {
        processor.extractNativeAnnotations(library);
      }
      processor.extractJsInteropAnnotations(library);
    }
    Uri uri = library.canonicalUri;
    if (uri == Uris.dart_html) {
      htmlLibraryIsLoaded = true;
    }
  }

  /// This method is called when all new libraries loaded through
  /// [LibraryLoader.loadLibrary] has been loaded and their imports/exports
  /// have been computed.
  void onLibrariesLoaded(
      CommonElements commonElements, LoadedLibraries loadedLibraries) {
    if (loadedLibraries.containsLibrary(Uris.dart_core)) {
      assert(loadedLibraries.containsLibrary(Uris.dart_core));
      assert(loadedLibraries.containsLibrary(Uris.dart__interceptors));
      assert(loadedLibraries.containsLibrary(Uris.dart__js_helper));

      // These methods are overwritten with generated versions.
      inlineCache.markAsNonInlinable(commonElements.getInterceptorMethod,
          insideLoop: true);
    }
  }

  /// Called when the compiler starts running the codegen enqueuer. The
  /// [WorldImpact] of enabled backend features is returned.
  WorldImpact onCodegenStart(ClosedWorld closedWorld,
      CodegenWorldBuilder codegenWorldBuilder, Sorter sorter) {
    functionCompiler.onCodegenStart();
    _oneShotInterceptorData = new OneShotInterceptorData(
        closedWorld.interceptorData, closedWorld.commonElements);
    _namer = determineNamer(closedWorld, codegenWorldBuilder);
    tracer = new Tracer(closedWorld, namer, compiler.outputProvider);
    _rtiEncoder = _namer.rtiEncoder = new RuntimeTypesEncoderImpl(
        namer, closedWorld.elementEnvironment, closedWorld.commonElements);
    emitter.createEmitter(namer, closedWorld, codegenWorldBuilder, sorter);
    // TODO(johnniwinther): Share the impact object created in
    // createCodegenEnqueuer.
    BackendImpacts impacts = new BackendImpacts(closedWorld.commonElements);
    _rti = new RuntimeTypesImpl(
        closedWorld.elementEnvironment, closedWorld.dartTypes);
    _codegenImpactTransformer = new CodegenImpactTransformer(
        compiler.options,
        closedWorld.elementEnvironment,
        closedWorld.commonElements,
        impacts,
        checkedModeHelpers,
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

  // Does this element belong in the output
  bool shouldOutput(Element element) => true;

  /// Returns `true` if the `native` pseudo keyword is supported for [library].
  bool canLibraryUseNative(LibraryEntity library) {
    return native.maybeEnableNative(library.canonicalUri,
        allowNativeExtensions: compiler.options.allowNativeExtensions);
  }

  bool isTargetSpecificLibrary(LibraryElement library) {
    Uri canonicalUri = library.canonicalUri;
    if (canonicalUri == Uris.dart__js_helper ||
        canonicalUri == Uris.dart__interceptors) {
      return true;
    }
    return false;
  }

  /// Process backend specific annotations.
  // TODO(johnniwinther): Merge this with [AnnotationProcessor] and use
  // [ElementEnvironment.getMemberMetadata] in [AnnotationProcessor].
  void processAnnotations(
      ElementEnvironment elementEnvironment,
      CommonElements commonElements,
      MemberEntity element,
      ClosedWorldRefiner closedWorldRefiner) {
    if (element is MemberElement && element.isMalformed) {
      // Elements that are marked as malformed during parsing or resolution
      // might be registered here. These should just be ignored.
      return;
    }

    bool hasNoInline = false;
    bool hasForceInline = false;

    if (element.isFunction || element.isConstructor) {
      if (optimizerHints.noInline(
          elementEnvironment, commonElements, element)) {
        hasNoInline = true;
        inlineCache.markAsNonInlinable(element);
      }
      if (optimizerHints.tryInline(
          elementEnvironment, commonElements, element)) {
        hasForceInline = true;
        if (hasNoInline) {
          reporter.reportErrorMessage(element, MessageKind.GENERIC,
              {'text': '@tryInline must not be used with @noInline.'});
        } else {
          inlineCache.markAsMustInline(element);
        }
      }
    }

    if (element.isField) return;
    FunctionEntity method = element;

    LibraryEntity library = method.library;
    if (library.canonicalUri.scheme != 'dart' &&
        !canLibraryUseNative(library)) {
      return;
    }

    bool hasNoThrows = false;
    bool hasNoSideEffects = false;
    for (ConstantValue constantValue
        in elementEnvironment.getMemberMetadata(method)) {
      if (!constantValue.isConstructedObject) continue;
      ObjectConstantValue value = constantValue;
      ClassEntity cls = value.type.element;
      if (cls == commonElements.forceInlineClass) {
        hasForceInline = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              method, MessageKind.GENERIC, {'text': "Must inline"});
        }
        inlineCache.markAsMustInline(method);
      } else if (cls == commonElements.noInlineClass) {
        hasNoInline = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              method, MessageKind.GENERIC, {'text': "Cannot inline"});
        }
        inlineCache.markAsNonInlinable(method);
      } else if (cls == commonElements.noThrowsClass) {
        hasNoThrows = true;
        bool isValid = true;
        if (method.isTopLevel) {
          isValid = true;
        } else if (method.isStatic) {
          isValid = true;
        } else if (method is ConstructorEntity && method.isFactoryConstructor) {
          isValid = true;
        }
        if (!isValid) {
          reporter.internalError(
              method,
              "@NoThrows() is currently limited to top-level"
              " or static functions and factory constructors.");
        }
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              method, MessageKind.GENERIC, {'text': "Cannot throw"});
        }
        closedWorldRefiner.registerCannotThrow(method);
      } else if (cls == commonElements.noSideEffectsClass) {
        hasNoSideEffects = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              method, MessageKind.GENERIC, {'text': "Has no side effects"});
        }
        closedWorldRefiner.registerSideEffectsFree(method);
      }
    }
    if (hasForceInline && hasNoInline) {
      reporter.internalError(
          method, "@ForceInline() must not be used with @NoInline.");
    }
    if (hasNoThrows && !hasNoInline) {
      reporter.internalError(
          method, "@NoThrows() should always be combined with @NoInline.");
    }
    if (hasNoSideEffects && !hasNoInline) {
      reporter.internalError(
          method, "@NoSideEffects() should always be combined with @NoInline.");
    }
  }

  /// Enable deferred loading. Returns `true` if the backend supports deferred
  /// loading.
  bool enableDeferredLoadingIfSupported(Spannable node) => true;

  /// Enable compilation of code with compile time errors. Returns `true` if
  /// supported by the backend.
  bool enableCodegenWithErrorsIfSupported(Spannable node) => true;

  jsAst.Expression rewriteAsync(CommonElements commonElements,
      FunctionEntity element, jsAst.Expression code) {
    AsyncRewriterBase rewriter = null;
    jsAst.Name name = namer.methodPropertyName(element);
    switch (element.asyncMarker) {
      case AsyncMarker.ASYNC:
        rewriter = new AsyncRewriter(reporter, element,
            asyncStart:
                emitter.staticFunctionAccess(commonElements.asyncHelperStart),
            asyncAwait:
                emitter.staticFunctionAccess(commonElements.asyncHelperAwait),
            asyncReturn:
                emitter.staticFunctionAccess(commonElements.asyncHelperReturn),
            asyncRethrow:
                emitter.staticFunctionAccess(commonElements.asyncHelperRethrow),
            wrapBody: emitter.staticFunctionAccess(commonElements.wrapBody),
            completerFactory: emitter
                .staticFunctionAccess(commonElements.syncCompleterConstructor),
            safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
            bodyName: namer.deriveAsyncBodyName(name));
        break;
      case AsyncMarker.SYNC_STAR:
        rewriter = new SyncStarRewriter(reporter, element,
            endOfIteration:
                emitter.staticFunctionAccess(commonElements.endOfIteration),
            iterableFactory: emitter.staticFunctionAccess(
                commonElements.syncStarIterableConstructor),
            yieldStarExpression:
                emitter.staticFunctionAccess(commonElements.yieldStar),
            uncaughtErrorExpression: emitter
                .staticFunctionAccess(commonElements.syncStarUncaughtError),
            safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
            bodyName: namer.deriveAsyncBodyName(name));
        break;
      case AsyncMarker.ASYNC_STAR:
        rewriter = new AsyncStarRewriter(reporter, element,
            asyncStarHelper:
                emitter.staticFunctionAccess(commonElements.asyncStarHelper),
            streamOfController:
                emitter.staticFunctionAccess(commonElements.streamOfController),
            wrapBody: emitter.staticFunctionAccess(commonElements.wrapBody),
            newController: emitter.staticFunctionAccess(
                commonElements.asyncStarControllerConstructor),
            safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
            yieldExpression:
                emitter.staticFunctionAccess(commonElements.yieldSingle),
            yieldStarExpression:
                emitter.staticFunctionAccess(commonElements.yieldStar),
            bodyName: namer.deriveAsyncBodyName(name));
        break;
      default:
        assert(element.asyncMarker == AsyncMarker.SYNC);
        return code;
    }
    return rewriter.rewrite(code);
  }

  /// Creates an impact strategy to use for compilation.
  ImpactStrategy createImpactStrategy(
      {bool supportDeferredLoad: true,
      bool supportDumpInfo: true,
      bool supportSerialization: true}) {
    return new JavaScriptImpactStrategy(
        impactCacheDeleter, compiler.dumpInfoTask,
        supportDeferredLoad: supportDeferredLoad,
        supportDumpInfo: supportDumpInfo,
        supportSerialization: supportSerialization);
  }

  EnqueueTask makeEnqueuer() => new EnqueueTask(compiler);
}

class JavaScriptImpactStrategy extends ImpactStrategy {
  final ImpactCacheDeleter impactCacheDeleter;
  final DumpInfoTask dumpInfoTask;
  final bool supportDeferredLoad;
  final bool supportDumpInfo;
  final bool supportSerialization;

  JavaScriptImpactStrategy(this.impactCacheDeleter, this.dumpInfoTask,
      {this.supportDeferredLoad,
      this.supportDumpInfo,
      this.supportSerialization});

  @override
  void visitImpact(var impactSource, WorldImpact impact,
      WorldImpactVisitor visitor, ImpactUseCase impactUse) {
    // TODO(johnniwinther): Compute the application strategy once for each use.
    if (impactUse == ResolutionEnqueuer.IMPACT_USE) {
      if (supportDeferredLoad || supportSerialization) {
        impact.apply(visitor);
      } else {
        impact.apply(visitor);
        if (impactSource is Element) {
          impactCacheDeleter.uncacheWorldImpact(impactSource);
        }
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
    if (impactUse == DeferredLoadTask.IMPACT_USE && !supportSerialization) {
      // TODO(johnniwinther): Allow emptying when serialization has been
      // performed.
      impactCacheDeleter.emptyCache();
    }
  }
}

class JavaScriptBackendTarget extends Target {
  final JavaScriptBackend _backend;

  JavaScriptBackendTarget(this._backend);

  CommonElements get _commonElements =>
      _backend.compiler.frontendStrategy.commonElements;

  @override
  bool isTargetSpecificLibrary(LibraryElement element) {
    return _backend.isTargetSpecificLibrary(element);
  }

  @override
  void resolveNativeMember(MemberElement element, NativeRegistry registry) {
    return _backend._nativeDataResolver.resolveNativeMember(element, registry);
  }

  @override
  MethodElement resolveExternalFunction(MethodElement element) {
    return _backend.resolveExternalFunction(element);
  }

  @override
  dynamic resolveForeignCall(Send node, Element element,
      CallStructure callStructure, ForeignResolver resolver) {
    return _backend.resolveForeignCall(node, element, callStructure, resolver);
  }

  @override
  bool isDefaultNoSuchMethod(MethodElement element) {
    return _commonElements.isDefaultNoSuchMethodImplementation(element);
  }

  @override
  ClassElement defaultSuperclass(ClassElement element) {
    return _commonElements.getDefaultSuperclass(
        element, _backend.frontendStrategy.nativeBasicData);
  }

  @override
  bool isNativeClass(ClassEntity element) =>
      _backend.compiler.frontendStrategy.nativeBasicData.isNativeClass(element);

  @override
  bool isForeign(Element element) =>
      _backend.isForeign(_commonElements, element);
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
