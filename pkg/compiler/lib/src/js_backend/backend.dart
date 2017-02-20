// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend;

import 'dart:async' show Future;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;

import '../closure.dart';
import '../common.dart';
import '../common/backend_api.dart'
    show BackendClasses, ImpactTransformer, ForeignResolver, NativeRegistry;
import '../common/codegen.dart' show CodegenImpact, CodegenWorkItem;
import '../common/names.dart' show Identifiers, Uris;
import '../common/resolution.dart'
    show Frontend, Resolution, ResolutionImpact, Target;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../core_types.dart' show CommonElements, ElementEnvironment;
import '../deferred_load.dart' show DeferredLoadTask;
import '../dump_info.dart' show DumpInfoTask;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../enqueue.dart'
    show
        Enqueuer,
        EnqueuerListener,
        EnqueueTask,
        ResolutionEnqueuer,
        TreeShakingEnqueuerStrategy;
import '../io/multi_information.dart' show MultiSourceInformationStrategy;
import '../io/position_information.dart' show PositionSourceInformationStrategy;
import '../io/source_information.dart' show SourceInformationStrategy;
import '../io/start_end_information.dart'
    show StartEndSourceInformationStrategy;
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js/js_source_mapping.dart' show JavaScriptSourceInformationStrategy;
import '../js/rewrite_async.dart';
import '../js_emitter/js_emitter.dart' show CodeEmitterTask;
import '../kernel/task.dart';
import '../library_loader.dart' show LibraryLoader, LoadedLibraries;
import '../native/native.dart' as native;
import '../patch_parser.dart'
    show checkNativeAnnotation, checkJsInteropAnnotation;
import '../ssa/ssa.dart' show SsaFunctionCompiler;
import '../tracer.dart';
import '../tree/tree.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/feature.dart';
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart';
import '../universe/use.dart'
    show DynamicUse, StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import '../universe/world_impact.dart'
    show
        ImpactStrategy,
        ImpactUseCase,
        TransformedWorldImpact,
        WorldImpact,
        WorldImpactBuilder,
        WorldImpactBuilderImpl,
        WorldImpactVisitor,
        StagedWorldImpactBuilder;
import '../util/util.dart';
import '../world.dart' show ClosedWorld, ClosedWorldRefiner;
import 'backend_helpers.dart';
import 'backend_impact.dart';
import 'backend_serialization.dart' show JavaScriptBackendSerialization;
import 'backend_usage.dart';
import 'checked_mode_helpers.dart';
import 'constant_handler_javascript.dart';
import 'custom_elements_analysis.dart';
import 'enqueuer.dart';
import 'interceptor_data.dart' show InterceptorData;
import 'js_interop_analysis.dart' show JsInteropAnalysis;
import 'lookup_map_analysis.dart' show LookupMapAnalysis;
import 'mirrors_analysis.dart';
import 'mirrors_data.dart';
import 'namer.dart';
import 'native_data.dart' show NativeData;
import 'no_such_method_registry.dart';
import 'patch_resolver.dart';
import 'type_variable_handler.dart';

part 'runtime_types.dart';

const VERBOSE_OPTIMIZER_HINTS = false;

abstract class FunctionCompiler {
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

  final Map<MethodElement, int> _cachedDecisions =
      new Map<MethodElement, int>();

  /// Returns the current cache decision. This should only be used for testing.
  int getCurrentCacheDecisionForTesting(Element element) {
    return _cachedDecisions[element];
  }

  // Returns `true`/`false` if we have a cached decision.
  // Returns `null` otherwise.
  bool canInline(MethodElement element, {bool insideLoop}) {
    int decision = _cachedDecisions[element];

    if (decision == null) {
      // These synthetic elements are not yet present when we initially compute
      // this cache from metadata annotations, so look for their parent.
      if (element is ConstructorBodyElement) {
        ConstructorBodyElement body = element;
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

  void markAsInlinable(MethodElement element, {bool insideLoop}) {
    int oldDecision = _cachedDecisions[element];

    if (oldDecision == null) {
      oldDecision = _unknown;
    }

    if (insideLoop) {
      switch (oldDecision) {
        case _mustNotInline:
          throw new SpannableAssertionFailure(
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
          throw new SpannableAssertionFailure(
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

  void markAsNonInlinable(MethodElement element, {bool insideLoop: true}) {
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
          throw new SpannableAssertionFailure(
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
          throw new SpannableAssertionFailure(
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

  void markAsMustInline(MethodElement element) {
    _cachedDecisions[element] = _mustInline;
  }
}

enum SyntheticConstantKind {
  DUMMY_INTERCEPTOR,
  EMPTY_VALUE,
  TYPEVARIABLE_REFERENCE, // Reference to a type in reflection data.
  NAME
}

class JavaScriptBackend extends Target implements EnqueuerListener {
  final Compiler compiler;

  String get patchVersion => emitter.patchVersion;

  /// Returns true if the backend supports reflection.
  bool get supportsReflection => emitter.supportsReflection;

  final Annotations annotations;

  /// Set of classes that need to be considered for reflection although not
  /// otherwise visible during resolution.
  Iterable<ClassElement> get classesRequiredForReflection {
    // TODO(herhut): Clean this up when classes needed for rti are tracked.
    return [helpers.closureClass, helpers.jsIndexableClass];
  }

  FunctionCompiler functionCompiler;

  CodeEmitterTask emitter;

  /**
   * The generated code as a js AST for compiled methods.
   */
  final Map<Element, jsAst.Expression> generatedCode =
      <Element, jsAst.Expression>{};

  FunctionInlineCache inlineCache = new FunctionInlineCache();

  /// If [true], the compiler will emit code that logs whenever a method is
  /// called. When TRACE_METHOD is 'console' this will be logged
  /// directly in the JavaScript console. When TRACE_METHOD is 'post' the
  /// information will be sent to a server via a POST request.
  static const String TRACE_METHOD = const String.fromEnvironment('traceCalls');
  static const bool TRACE_CALLS =
      TRACE_METHOD == 'post' || TRACE_METHOD == 'console';

  /// Maps special classes to their implementation (JSXxx) class.
  Map<ClassElement, ClassElement> implementationClasses;

  Namer _namer;

  Namer get namer {
    assert(invariant(NO_LOCATION_SPANNABLE, _namer != null,
        message: "Namer has not been created yet."));
    return _namer;
  }

  /**
   * Set of classes whose `operator ==` methods handle `null` themselves.
   */
  final Set<ClassElement> specialOperatorEqClasses = new Set<ClassElement>();

  /**
   * A set of members that are called from subclasses via `super`.
   */
  final Set<MethodElement> aliasedSuperMembers = new Setlet<MethodElement>();

  List<CompilerTask> get tasks {
    List<CompilerTask> result = functionCompiler.tasks;
    result.add(emitter);
    result.add(patchResolverTask);
    result.add(kernelTask);
    return result;
  }

  final RuntimeTypes rti;
  final RuntimeTypesEncoder rtiEncoder;

  /// True if a call to preserveUris has been seen and the preserve-uris flag
  /// is set.
  bool mustPreserveUris = false;

  /// True if a core-library function requires the preamble file to function.
  bool requiresPreamble = false;

  /// True if the html library has been loaded.
  bool htmlLibraryIsLoaded = false;

  /// True when we enqueue the loadLibrary code.
  bool isLoadLibraryFunctionResolved = false;

  /// `true` if access to [BackendHelpers.invokeOnMethod] is supported.
  bool hasInvokeOnSupport = false;

  /// `true` of `Object.runtimeType` is supported.
  bool hasRuntimeTypeSupport = false;

  /// `true` of use of the `dart:isolate` library is supported.
  bool hasIsolateSupport = false;

  /// `true` of `Function.apply` is supported.
  bool hasFunctionApplySupport = false;

  /// List of constants from metadata.  If metadata must be preserved,
  /// these constants must be registered.
  final List<Dependency> metadataConstants = <Dependency>[];

  /// Set of elements for which metadata has been registered as dependencies.
  final Set<Element> _registeredMetadata = new Set<Element>();

  TypeVariableHandler typeVariableHandler;

  /// Number of methods compiled before considering reflection.
  int preMirrorsMethodCount = 0;

  /// Resolution and codegen support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsAnalysis customElementsAnalysis;

  /// Codegen support for tree-shaking entries of `LookupMap`.
  LookupMapAnalysis lookupMapAnalysis;

  /// Codegen support for typed JavaScript interop.
  JsInteropAnalysis jsInteropAnalysis;

  /// Support for classifying `noSuchMethod` implementations.
  NoSuchMethodRegistry noSuchMethodRegistry;

  /// Resolution and codegen support for computing reflectable elements.
  MirrorsAnalysis mirrorsAnalysis;

  /// Builds kernel representation for the program.
  KernelTask kernelTask;

  /// The compiler task responsible for the compilation of constants for both
  /// the frontend and the backend.
  JavaScriptConstantTask constantCompilerTask;

  /// Backend transformation methods for the world impacts.
  JavaScriptImpactTransformer impactTransformer;

  PatchResolverTask patchResolverTask;

  /// Whether or not `noSuchMethod` support has been enabled.
  bool enabledNoSuchMethod = false;
  bool _noSuchMethodEnabledForCodegen = false;

  /// The strategy used for collecting and emitting source information.
  SourceInformationStrategy sourceInformationStrategy;

  /// Interface for serialization of backend specific data.
  JavaScriptBackendSerialization serialization;

  StagedWorldImpactBuilder constantImpactsForResolution =
      new StagedWorldImpactBuilder();

  StagedWorldImpactBuilder constantImpactsForCodegen =
      new StagedWorldImpactBuilder();

  final NativeData nativeData = new NativeData();
  InterceptorData _interceptorData;
  BackendUsage _backendUsage;
  final MirrorsData mirrorsData;
  CheckedModeHelpers _checkedModeHelpers;

  BackendHelpers helpers;
  final BackendImpacts impacts;

  /// Common classes used by the backend.
  BackendClasses backendClasses;

  /// Backend access to the front-end.
  final JSFrontendAccess frontend;

  Tracer tracer;

  static SourceInformationStrategy createSourceInformationStrategy(
      {bool generateSourceMap: false,
      bool useMultiSourceInfo: false,
      bool useNewSourceInfo: false}) {
    if (!generateSourceMap) return const JavaScriptSourceInformationStrategy();
    if (useMultiSourceInfo) {
      if (useNewSourceInfo) {
        return const MultiSourceInformationStrategy(const [
          const PositionSourceInformationStrategy(),
          const StartEndSourceInformationStrategy()
        ]);
      } else {
        return const MultiSourceInformationStrategy(const [
          const StartEndSourceInformationStrategy(),
          const PositionSourceInformationStrategy()
        ]);
      }
    } else if (useNewSourceInfo) {
      return const PositionSourceInformationStrategy();
    } else {
      return const StartEndSourceInformationStrategy();
    }
  }

  JavaScriptBackend(Compiler compiler,
      {bool generateSourceMap: true,
      bool useStartupEmitter: false,
      bool useMultiSourceInfo: false,
      bool useNewSourceInfo: false,
      bool useKernel: false})
      : rti = new _RuntimeTypes(compiler),
        rtiEncoder = new _RuntimeTypesEncoder(compiler),
        annotations = new Annotations(compiler),
        this.sourceInformationStrategy = createSourceInformationStrategy(
            generateSourceMap: generateSourceMap,
            useMultiSourceInfo: useMultiSourceInfo,
            useNewSourceInfo: useNewSourceInfo),
        impacts = new BackendImpacts(compiler),
        frontend = new JSFrontendAccess(compiler),
        mirrorsData = new MirrorsData(compiler),
        this.compiler = compiler {
    helpers = new BackendHelpers(compiler.elementEnvironment, commonElements);
    _backendUsage = new BackendUsage(commonElements, helpers);
    _checkedModeHelpers = new CheckedModeHelpers(commonElements, helpers);
    emitter =
        new CodeEmitterTask(compiler, generateSourceMap, useStartupEmitter);
    typeVariableHandler = new TypeVariableHandler(compiler);
    customElementsAnalysis = new CustomElementsAnalysis(this);
    lookupMapAnalysis = new LookupMapAnalysis(this, reporter);
    jsInteropAnalysis = new JsInteropAnalysis(this);
    mirrorsAnalysis = new MirrorsAnalysis(this, compiler.resolution);

    noSuchMethodRegistry = new NoSuchMethodRegistry(this);
    kernelTask = new KernelTask(compiler);
    constantCompilerTask = new JavaScriptConstantTask(compiler);
    impactTransformer = new JavaScriptImpactTransformer(this);
    patchResolverTask = new PatchResolverTask(compiler);
    functionCompiler =
        new SsaFunctionCompiler(this, sourceInformationStrategy, useKernel);
    serialization = new JavaScriptBackendSerialization(this);
    _interceptorData = new InterceptorData(nativeData, helpers, commonElements);
    backendClasses = new JavaScriptBackendClasses(
        compiler.elementEnvironment, helpers, nativeData, _interceptorData);
  }

  /// The [ConstantSystem] used to interpret compile-time constants for this
  /// backend.
  ConstantSystem get constantSystem => constants.constantSystem;

  DiagnosticReporter get reporter => compiler.reporter;

  CommonElements get commonElements => compiler.commonElements;

  Resolution get resolution => compiler.resolution;

  InterceptorData get interceptorData => _interceptorData;

  BackendUsage get backendUsage => _backendUsage;

  CheckedModeHelpers get checkedModeHelpers => _checkedModeHelpers;

  /// Returns constant environment for the JavaScript interpretation of the
  /// constants.
  JavaScriptConstantCompiler get constants {
    return constantCompilerTask.jsConstantCompiler;
  }

  @override
  bool isDefaultNoSuchMethod(MethodElement element) {
    return noSuchMethodRegistry.isDefaultNoSuchMethodImplementation(element);
  }

  MethodElement resolveExternalFunction(MethodElement element) {
    if (isForeign(element)) {
      return element;
    }
    if (isJsInterop(element)) {
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

  bool isForeign(Element element) => element.library == helpers.foreignLibrary;

  bool isBackendLibrary(LibraryElement library) {
    return library == helpers.interceptorsLibrary ||
        library == helpers.jsHelperLibrary;
  }

  Namer determineNamer(
      ClosedWorld closedWorld, CodegenWorldBuilder codegenWorldBuilder) {
    return compiler.options.enableMinification
        ? compiler.options.useFrequencyNamer
            ? new FrequencyBasedNamer(this, closedWorld, codegenWorldBuilder)
            : new MinifyNamer(this, closedWorld, codegenWorldBuilder)
        : new Namer(this, closedWorld, codegenWorldBuilder);
  }

  /// Returns true if global optimizations such as type inferencing
  /// can apply to this element. One category of elements that do not
  /// apply is runtime helpers that the backend calls, but the
  /// optimizations don't see those calls.
  bool canBeUsedForGlobalOptimizations(Element element) {
    return !backendUsage.usedByBackend(element) &&
        !mirrorsData.invokedReflectively(element);
  }

  /**
   * Record that [method] is called from a subclass via `super`.
   */
  bool maybeRegisterAliasedSuperMember(
      MemberElement member, Selector selector) {
    if (!canUseAliasedSuperMember(member, selector)) {
      // Invoking a super getter isn't supported, this would require changes to
      // compact field descriptors in the emitter.
      return false;
    }
    aliasedSuperMembers.add(member);
    return true;
  }

  bool canUseAliasedSuperMember(Element member, Selector selector) {
    return !selector.isGetter;
  }

  /**
   * Returns `true` if [member] is called from a subclass via `super`.
   */
  bool isAliasedSuperMember(FunctionElement member) {
    return aliasedSuperMembers.contains(member);
  }

  /// Returns `true` if [element] is implemented via typed JavaScript interop.
  @override
  bool isJsInterop(Element element) => nativeData.isJsInterop(element);

  /// Returns `true` if [element] is a JsInterop class.
  bool isJsInteropClass(ClassElement element) => isJsInterop(element);

  /// Returns `true` if [element] is a JsInterop method.
  bool isJsInteropMethod(MethodElement element) => isJsInterop(element);

  /// Whether [element] corresponds to a native JavaScript construct either
  /// through the native mechanism (`@Native(...)` or the `native` pseudo
  /// keyword) which is only allowed for internal libraries or via the typed
  /// JavaScriptInterop mechanism which is allowed for user libraries.
  @override
  bool isNative(Entity element) => nativeData.isNative(element);

  /// Returns the [NativeBehavior] for calling the native [method].
  native.NativeBehavior getNativeMethodBehavior(MethodElement method) {
    return nativeData.getNativeMethodBehavior(method);
  }

  /// Returns the [NativeBehavior] for reading from the native [field].
  native.NativeBehavior getNativeFieldLoadBehavior(FieldElement field) {
    return nativeData.getNativeFieldLoadBehavior(field);
  }

  /// Returns the [NativeBehavior] for writing to the native [field].
  native.NativeBehavior getNativeFieldStoreBehavior(FieldElement field) {
    return nativeData.getNativeFieldStoreBehavior(field);
  }

  @override
  void resolveNativeElement(Element element, NativeRegistry registry) {
    if (element.isFunction ||
        element.isConstructor ||
        element.isGetter ||
        element.isSetter) {
      compiler.enqueuer.resolution.nativeEnqueuer
          .handleMethodAnnotations(element);
      if (isNative(element)) {
        native.NativeBehavior behavior =
            native.NativeBehavior.ofMethodElement(element, compiler);
        nativeData.setNativeMethodBehavior(element, behavior);
        registry.registerNativeData(behavior);
      }
    } else if (element.isField) {
      compiler.enqueuer.resolution.nativeEnqueuer
          .handleFieldAnnotations(element);
      if (isNative(element)) {
        native.NativeBehavior fieldLoadBehavior =
            native.NativeBehavior.ofFieldElementLoad(element, compiler);
        native.NativeBehavior fieldStoreBehavior =
            native.NativeBehavior.ofFieldElementStore(element, compiler);
        nativeData.setNativeFieldLoadBehavior(element, fieldLoadBehavior);
        nativeData.setNativeFieldStoreBehavior(element, fieldStoreBehavior);

        // TODO(sra): Process fields for storing separately.
        // We have to handle both loading and storing to the field because we
        // only get one look at each member and there might be a load or store
        // we have not seen yet.
        registry.registerNativeData(fieldLoadBehavior);
        registry.registerNativeData(fieldStoreBehavior);
      }
    }
  }

  /// Maps compile-time classes to their runtime class.  The runtime class is
  /// always a superclass or the class itself.
  ClassElement getRuntimeClass(ClassElement class_) {
    if (class_.isSubclassOf(helpers.jsIntClass)) return helpers.jsIntClass;
    if (class_.isSubclassOf(helpers.jsArrayClass)) return helpers.jsArrayClass;
    return class_;
  }

  bool operatorEqHandlesNullArgument(FunctionElement operatorEqfunction) {
    return specialOperatorEqClasses.contains(operatorEqfunction.enclosingClass);
  }

  void validateInterceptorImplementsAllObjectMethods(
      ClassElement interceptorClass) {
    if (interceptorClass == null) return;
    interceptorClass.ensureResolved(resolution);
    ClassElement objectClass = commonElements.objectClass;
    objectClass.forEachMember((_, Element member) {
      if (member.isGenerativeConstructor) return;
      Element interceptorMember = interceptorClass.lookupMember(member.name);
      // Interceptors must override all Object methods due to calling convention
      // differences.
      assert(invariant(interceptorMember,
          interceptorMember.enclosingClass == interceptorClass,
          message:
              "Member ${member.name} not overridden in ${interceptorClass}. "
              "Found $interceptorMember from "
              "${interceptorMember.enclosingClass}."));
    });
  }

  void addInterceptorsForNativeClassMembers(ClassElement cls,
      {bool forResolution}) {
    if (forResolution) {
      cls.ensureResolved(resolution);
      interceptorData.addInterceptorsForNativeClassMembers(cls);
    }
  }

  void addInterceptors(ClassElement cls, WorldImpactBuilder impactBuilder,
      {bool forResolution}) {
    if (forResolution) {
      cls.ensureResolved(resolution);
      interceptorData.addInterceptors(cls);
    }
    impactTransformer.registerBackendInstantiation(impactBuilder, cls);
  }

  /// Called during codegen when [constant] has been used.
  void computeImpactForCompileTimeConstant(ConstantValue constant,
      WorldImpactBuilder impactBuilder, bool isForResolution) {
    computeImpactForCompileTimeConstantInternal(
        constant, impactBuilder, isForResolution);

    if (!isForResolution && lookupMapAnalysis.isLookupMap(constant)) {
      // Note: internally, this registration will temporarily remove the
      // constant dependencies and add them later on-demand.
      lookupMapAnalysis.registerLookupMapReference(constant);
    }

    for (ConstantValue dependency in constant.getDependencies()) {
      computeImpactForCompileTimeConstant(
          dependency, impactBuilder, isForResolution);
    }
  }

  void addCompileTimeConstantForEmission(ConstantValue constant) {
    constants.addCompileTimeConstantForEmission(constant);
  }

  void computeImpactForCompileTimeConstantInternal(ConstantValue constant,
      WorldImpactBuilder impactBuilder, bool isForResolution) {
    ResolutionDartType type = constant.getType(compiler.commonElements);
    computeImpactForInstantiatedConstantType(type, impactBuilder);

    if (constant.isFunction) {
      FunctionConstantValue function = constant;
      impactBuilder
          .registerStaticUse(new StaticUse.staticTearOff(function.element));
    } else if (constant.isInterceptor) {
      // An interceptor constant references the class's prototype chain.
      InterceptorConstantValue interceptor = constant;
      ClassElement cls = interceptor.cls;
      computeImpactForInstantiatedConstantType(cls.thisType, impactBuilder);
    } else if (constant.isType) {
      if (isForResolution) {
        MethodElement helper = helpers.createRuntimeType;
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            helper,
            null));
        backendUsage.registerBackendUse(helper);
      }
      impactBuilder
          .registerTypeUse(new TypeUse.instantiation(backendClasses.typeType));
    }
    lookupMapAnalysis.registerConstantKey(constant);
  }

  void computeImpactForInstantiatedConstantType(
      DartType type, WorldImpactBuilder impactBuilder) {
    if (type is ResolutionInterfaceType) {
      impactBuilder.registerTypeUse(new TypeUse.instantiation(type));
      if (classNeedsRtiField(type.element)) {
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            helpers.setRuntimeTypeInfo,
            null));
      }
      if (type.element == backendClasses.typeClass) {
        // If we use a type literal in a constant, the compile time
        // constant emitter will generate a call to the createRuntimeType
        // helper so we register a use of that.
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            helpers.createRuntimeType,
            null));
      }
    }
  }

  WorldImpact registerInstantiatedClass(ClassElement cls,
      {bool forResolution}) {
    return _processClass(cls, forResolution: forResolution);
  }

  WorldImpact registerImplementedClass(ClassElement cls, {bool forResolution}) {
    return _processClass(cls, forResolution: forResolution);
  }

  WorldImpact _processClass(ClassElement cls, {bool forResolution}) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    if (!cls.typeVariables.isEmpty) {
      typeVariableHandler.registerClassWithTypeVariables(cls,
          forResolution: forResolution);
    }

    // Register any helper that will be needed by the backend.
    if (forResolution) {
      if (cls == commonElements.intClass ||
          cls == commonElements.doubleClass ||
          cls == commonElements.numClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.numClasses);
      } else if (cls == commonElements.listClass ||
          cls == commonElements.stringClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.listOrStringClasses);
      } else if (cls == commonElements.functionClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.functionClass);
      } else if (cls == commonElements.mapClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.mapClass);
        // For map literals, the dependency between the implementation class
        // and [Map] is not visible, so we have to add it manually.
        rti.registerRtiDependency(helpers.mapLiteralClass, cls);
      } else if (cls == helpers.boundClosureClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.boundClosureClass);
      } else if (nativeData.isNativeOrExtendsNative(cls)) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.nativeOrExtendsClass);
      } else if (cls == helpers.mapLiteralClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.mapLiteralClass);
      }
    }
    if (cls == helpers.closureClass) {
      impactTransformer.registerBackendImpact(
          impactBuilder, impacts.closureClass);
    }
    if (cls == commonElements.stringClass || cls == helpers.jsStringClass) {
      addInterceptors(helpers.jsStringClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == commonElements.listClass ||
        cls == helpers.jsArrayClass ||
        cls == helpers.jsFixedArrayClass ||
        cls == helpers.jsExtendableArrayClass ||
        cls == helpers.jsUnmodifiableArrayClass) {
      addInterceptors(helpers.jsArrayClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsMutableArrayClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsFixedArrayClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsExtendableArrayClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsUnmodifiableArrayClass, impactBuilder,
          forResolution: forResolution);
      if (forResolution) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.listClasses);
      }
    } else if (cls == commonElements.intClass || cls == helpers.jsIntClass) {
      addInterceptors(helpers.jsIntClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsPositiveIntClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsUInt32Class, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsUInt31Class, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsNumberClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == commonElements.doubleClass ||
        cls == helpers.jsDoubleClass) {
      addInterceptors(helpers.jsDoubleClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsNumberClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == commonElements.boolClass || cls == helpers.jsBoolClass) {
      addInterceptors(helpers.jsBoolClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == commonElements.nullClass || cls == helpers.jsNullClass) {
      addInterceptors(helpers.jsNullClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == commonElements.numClass || cls == helpers.jsNumberClass) {
      addInterceptors(helpers.jsIntClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsPositiveIntClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsUInt32Class, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsUInt31Class, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsDoubleClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsNumberClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == helpers.jsJavaScriptObjectClass) {
      addInterceptors(helpers.jsJavaScriptObjectClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == helpers.jsPlainJavaScriptObjectClass) {
      addInterceptors(helpers.jsPlainJavaScriptObjectClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == helpers.jsUnknownJavaScriptObjectClass) {
      addInterceptors(helpers.jsUnknownJavaScriptObjectClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == helpers.jsJavaScriptFunctionClass) {
      addInterceptors(helpers.jsJavaScriptFunctionClass, impactBuilder,
          forResolution: forResolution);
    } else if (nativeData.isNativeOrExtendsNative(cls)) {
      addInterceptorsForNativeClassMembers(cls, forResolution: forResolution);
    } else if (cls == helpers.jsIndexingBehaviorInterface) {
      impactTransformer.registerBackendImpact(
          impactBuilder, impacts.jsIndexingBehavior);
    }

    customElementsAnalysis.registerInstantiatedClass(cls,
        forResolution: forResolution);
    if (!forResolution) {
      lookupMapAnalysis.registerInstantiatedClass(cls);
    }

    return impactBuilder;
  }

  void registerInstantiatedType(ResolutionInterfaceType type) {
    lookupMapAnalysis.registerInstantiatedType(type);
  }

  /// Compute the [WorldImpact] for backend helper methods.
  WorldImpact computeHelpersImpact() {
    assert(helpers.interceptorsLibrary != null);
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    // TODO(ngeoffray): Not enqueuing those two classes currently make
    // the compiler potentially crash. However, any reasonable program
    // will instantiate those two classes.
    addInterceptors(helpers.jsBoolClass, impactBuilder, forResolution: true);
    addInterceptors(helpers.jsNullClass, impactBuilder, forResolution: true);
    if (compiler.options.enableTypeAssertions) {
      impactTransformer.registerBackendImpact(
          impactBuilder, impacts.enableTypeAssertions);
    }

    if (TRACE_CALLS) {
      impactTransformer.registerBackendImpact(
          impactBuilder, impacts.traceHelper);
    }
    impactTransformer.registerBackendImpact(
        impactBuilder, impacts.assertUnreachable);
    _registerCheckedModeHelpers(impactBuilder);
    return impactBuilder;
  }

  void onResolutionComplete(
      ClosedWorld closedWorld, ClosedWorldRefiner closedWorldRefiner) {
    for (Entity entity in compiler.enqueuer.resolution.processedEntities) {
      processAnnotations(entity, closedWorldRefiner);
    }
    mirrorsData.computeMembersNeededForReflection(closedWorld);
    rti.computeClassesNeedingRti(
        compiler.enqueuer.resolution.worldBuilder, closedWorld);
    _registeredMetadata.clear();
    interceptorData.onResolutionComplete(closedWorld);
  }

  void onTypeInferenceComplete() {
    noSuchMethodRegistry.onTypeInferenceComplete();
  }

  /// Called to register that an instantiated generic class has a call method.
  /// Any backend specific [WorldImpact] of this is returned.
  ///
  /// Note: The [callMethod] is registered even thought it doesn't reference
  /// the type variables.
  WorldImpact registerCallMethodWithFreeTypeVariables(Element callMethod,
      {bool forResolution}) {
    if (forResolution || methodNeedsRti(callMethod)) {
      return _registerComputeSignature();
    }
    return const WorldImpact();
  }

  WorldImpact registerClosureWithFreeTypeVariables(MethodElement closure,
      {bool forResolution}) {
    if (forResolution || methodNeedsRti(closure)) {
      return _registerComputeSignature();
    }
    return const WorldImpact();
  }

  WorldImpact registerBoundClosure() {
    return impactTransformer.createImpactFor(impacts.memberClosure);
  }

  WorldImpact registerGetOfStaticFunction() {
    return impactTransformer.createImpactFor(impacts.staticClosure);
  }

  WorldImpact _registerComputeSignature() {
    return impactTransformer.createImpactFor(impacts.computeSignature);
  }

  /// Called to register that the `runtimeType` property has been accessed. Any
  /// backend specific [WorldImpact] of this is returned.
  WorldImpact registerRuntimeType() {
    return impactTransformer.createImpactFor(impacts.runtimeTypeSupport);
  }

  /// Register a runtime type variable bound tests between [typeArgument] and
  /// [bound].
  void registerTypeVariableBoundsSubtypeCheck(
      ResolutionDartType typeArgument, ResolutionDartType bound) {
    rti.registerTypeVariableBoundsSubtypeCheck(typeArgument, bound);
  }

  /// Returns the [WorldImpact] of enabling deferred loading.
  WorldImpact computeDeferredLoadingImpact() {
    return impactTransformer.createImpactFor(impacts.deferredLoading);
  }

  /// Called to register a `noSuchMethod` implementation.
  void registerNoSuchMethod(MethodElement noSuchMethod) {
    noSuchMethodRegistry.registerNoSuchMethod(noSuchMethod);
  }

  /// Called when resolving a call to a foreign function.
  native.NativeBehavior resolveForeignCall(Send node, Element element,
      CallStructure callStructure, ForeignResolver resolver) {
    native.NativeResolutionEnqueuer nativeEnqueuer =
        compiler.enqueuer.resolution.nativeEnqueuer;
    if (element.name == BackendHelpers.JS) {
      return nativeEnqueuer.resolveJsCall(node, resolver);
    } else if (element.name == BackendHelpers.JS_EMBEDDED_GLOBAL) {
      return nativeEnqueuer.resolveJsEmbeddedGlobalCall(node, resolver);
    } else if (element.name == BackendHelpers.JS_BUILTIN) {
      return nativeEnqueuer.resolveJsBuiltinCall(node, resolver);
    } else if (element.name == BackendHelpers.JS_INTERCEPTOR_CONSTANT) {
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

  WorldImpact computeNoSuchMethodImpact() {
    return impactTransformer.createImpactFor(impacts.noSuchMethodSupport);
  }

  /// Called to enable support for isolates. Any backend specific [WorldImpact]
  /// of this is returned.
  WorldImpact enableIsolateSupport({bool forResolution}) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    // TODO(floitsch): We should also ensure that the class IsolateMessage is
    // instantiated. Currently, just enabling isolate support works.
    if (compiler.mainFunction != null) {
      // The JavaScript backend implements [Isolate.spawn] by looking up
      // top-level functions by name. So all top-level function tear-off
      // closures have a private name field.
      //
      // The JavaScript backend of [Isolate.spawnUri] uses the same internal
      // implementation as [Isolate.spawn], and fails if it cannot look main up
      // by name.
      impactBuilder.registerStaticUse(
          new StaticUse.staticTearOff(compiler.mainFunction));
    }
    impactTransformer.registerBackendImpact(
        impactBuilder, impacts.isolateSupport);
    if (forResolution) {
      impactTransformer.registerBackendImpact(
          impactBuilder, impacts.isolateSupportForResolution);
    }
    return impactBuilder;
  }

  bool classNeedsRti(ClassElement cls) {
    if (hasRuntimeTypeSupport) return true;
    return rti.classesNeedingRti.contains(cls.declaration);
  }

  bool classNeedsRtiField(ClassElement cls) {
    if (cls.rawType.typeArguments.isEmpty) return false;
    if (hasRuntimeTypeSupport) return true;
    return rti.classesNeedingRti.contains(cls.declaration);
  }

  bool isComplexNoSuchMethod(FunctionElement element) =>
      noSuchMethodRegistry.isComplex(element);

  bool methodNeedsRti(FunctionElement function) {
    return rti.methodsNeedingRti.contains(function) || hasRuntimeTypeSupport;
  }

  CodegenEnqueuer get codegenEnqueuer => compiler.enqueuer.codegen;

  /// Creates an [Enqueuer] for code generation specific to this backend.
  CodegenEnqueuer createCodegenEnqueuer(CompilerTask task, Compiler compiler) {
    return new CodegenEnqueuer(
        task, this, compiler.options, const TreeShakingEnqueuerStrategy());
  }

  WorldImpact codegen(CodegenWorkItem work) {
    Element element = work.element;
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
      return const CodegenImpact();
    }
    var kind = element.kind;
    if (kind == ElementKind.TYPEDEF) {
      return const WorldImpact();
    }
    if (element.isConstructor &&
        element.enclosingClass == helpers.jsNullClass) {
      // Work around a problem compiling JSNull's constructor.
      return const CodegenImpact();
    }
    if (kind.category == ElementCategory.VARIABLE) {
      VariableElement variableElement = element;
      ConstantExpression constant = variableElement.constant;
      if (constant != null) {
        ConstantValue initialValue = constants.getConstantValue(constant);
        if (initialValue != null) {
          computeImpactForCompileTimeConstant(
              initialValue, work.registry.worldImpact, false);
          addCompileTimeConstantForEmission(initialValue);
          // We don't need to generate code for static or top-level
          // variables. For instance variables, we may need to generate
          // the checked setter.
          if (Elements.isStaticOrTopLevel(element)) {
            return impactTransformer
                .transformCodegenImpact(work.registry.worldImpact);
          }
        } else {
          assert(invariant(
              variableElement,
              variableElement.isInstanceMember ||
                  constant.isImplicit ||
                  constant.isPotential,
              message: "Constant expression without value: "
                  "${constant.toStructuredText()}."));
        }
      } else {
        // If the constant-handler was not able to produce a result we have to
        // go through the builder (below) to generate the lazy initializer for
        // the static variable.
        // We also need to register the use of the cyclic-error helper.
        work.registry.worldImpact.registerStaticUse(new StaticUse.staticInvoke(
            helpers.cyclicThrowHelper, CallStructure.ONE_ARG));
      }
    }

    jsAst.Fun function = functionCompiler.compile(work, _closedWorld);
    if (function.sourceInformation == null) {
      function = function.withSourceInformation(
          sourceInformationStrategy.buildSourceMappedMarker());
    }
    generatedCode[element] = function;
    WorldImpact worldImpact =
        impactTransformer.transformCodegenImpact(work.registry.worldImpact);
    compiler.dumpInfoTask.registerImpact(element, worldImpact);
    return worldImpact;
  }

  native.NativeEnqueuer nativeResolutionEnqueuer() {
    return new native.NativeResolutionEnqueuer(compiler);
  }

  native.NativeEnqueuer nativeCodegenEnqueuer() {
    return new native.NativeCodegenEnqueuer(compiler, emitter);
  }

  ClassElement defaultSuperclass(ClassElement element) {
    if (isJsInterop(element)) {
      return helpers.jsJavaScriptObjectClass;
    }
    // Native classes inherit from Interceptor.
    return isNative(element)
        ? helpers.jsInterceptorClass
        : commonElements.objectClass;
  }

  /**
   * Unit test hook that returns code of an element as a String.
   *
   * Invariant: [element] must be a declaration element.
   */
  String getGeneratedCode(Element element) {
    assert(invariant(element, element.isDeclaration));
    return jsAst.prettyPrint(generatedCode[element], compiler);
  }

  /// Generates the output and returns the total size of the generated code.
  int assembleProgram(ClosedWorld closedWorld) {
    int programSize = emitter.assembleProgram(namer, closedWorld);
    noSuchMethodRegistry.emitDiagnostic();
    int totalMethodCount = generatedCode.length;
    if (totalMethodCount != preMirrorsMethodCount) {
      int mirrorCount = totalMethodCount - preMirrorsMethodCount;
      double percentage = (mirrorCount / totalMethodCount) * 100;
      DiagnosticMessage hint =
          reporter.createMessage(compiler.mainApp, MessageKind.MIRROR_BLOAT, {
        'count': mirrorCount,
        'total': totalMethodCount,
        'percentage': percentage.round()
      });

      List<DiagnosticMessage> infos = <DiagnosticMessage>[];
      for (LibraryElement library in compiler.libraryLoader.libraries) {
        if (library.isInternalLibrary) continue;
        for (ImportElement import in library.imports) {
          LibraryElement importedLibrary = import.importedLibrary;
          if (importedLibrary != compiler.commonElements.mirrorsLibrary)
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

  Element getDartClass(Element element) {
    for (ClassElement dartClass in implementationClasses.keys) {
      if (element == implementationClasses[dartClass]) {
        return dartClass;
      }
    }
    return element;
  }

  void _registerCheckedModeHelpers(WorldImpactBuilder impactBuilder) {
    // We register all the helpers in the resolution queue.
    // TODO(13155): Find a way to register fewer helpers.
    List<Element> staticUses = <Element>[];
    for (CheckedModeHelper helper in CheckedModeHelpers.helpers) {
      staticUses.add(helper.getStaticUse(helpers).element);
    }
    impactTransformer.registerBackendImpact(
        impactBuilder, new BackendImpact(globalUses: staticUses));
  }

  /**
   * Returns [:true:] if the checking of [type] is performed directly on the
   * object and not on an interceptor.
   */
  bool hasDirectCheckFor(ResolutionDartType type) {
    Element element = type.element;
    return element == commonElements.stringClass ||
        element == commonElements.boolClass ||
        element == commonElements.numClass ||
        element == commonElements.intClass ||
        element == commonElements.doubleClass ||
        element == helpers.jsArrayClass ||
        element == helpers.jsMutableArrayClass ||
        element == helpers.jsExtendableArrayClass ||
        element == helpers.jsFixedArrayClass ||
        element == helpers.jsUnmodifiableArrayClass;
  }

  bool mayGenerateInstanceofCheck(ResolutionDartType type) {
    // We can use an instanceof check for raw types that have no subclass that
    // is mixed-in or in an implements clause.

    if (!type.isRaw) return false;
    ClassElement classElement = type.element;
    if (interceptorData.isInterceptorClass(classElement)) return false;
    return _closedWorld.hasOnlySubclasses(classElement);
  }

  WorldImpact registerUsedElement(MemberElement element, {bool forResolution}) {
    WorldImpactBuilderImpl worldImpact = new WorldImpactBuilderImpl();
    if (element == helpers.disableTreeShakingMarker) {
      mirrorsData.isTreeShakingDisabled = true;
    } else if (element == helpers.preserveNamesMarker) {
      mirrorsData.mustPreserveNames = true;
    } else if (element == helpers.preserveMetadataMarker) {
      mirrorsData.mustRetainMetadata = true;
    } else if (element == helpers.preserveUrisMarker) {
      if (compiler.options.preserveUris) mustPreserveUris = true;
    } else if (element == helpers.preserveLibraryNamesMarker) {
      mirrorsData.mustRetainLibraryNames = true;
    } else if (element == helpers.getIsolateAffinityTagMarker) {
      backendUsage.needToInitializeIsolateAffinityTag = true;
    } else if (element.isDeferredLoaderGetter) {
      // TODO(sigurdm): Create a function registerLoadLibraryAccess.
      if (!isLoadLibraryFunctionResolved) {
        isLoadLibraryFunctionResolved = true;
        if (forResolution) {
          impactTransformer.registerBackendImpact(
              worldImpact, impacts.loadLibrary);
        }
      }
    } else if (element == helpers.requiresPreambleMarker) {
      requiresPreamble = true;
    } else if (element == helpers.invokeOnMethod && forResolution) {
      hasInvokeOnSupport = true;
    }
    customElementsAnalysis.registerStaticUse(element,
        forResolution: forResolution);

    if (element.isFunction && element.isInstanceMember) {
      MemberElement function = element;
      ClassElement cls = function.enclosingClass;
      if (function.name == Identifiers.call && !cls.typeVariables.isEmpty) {
        worldImpact.addImpact(registerCallMethodWithFreeTypeVariables(function,
            forResolution: forResolution));
      }
    }
    if (forResolution) {
      // Enable isolate support if we start using something from the isolate
      // library, or timers for the async library.  We exclude constant fields,
      // which are ending here because their initializing expression is
      // compiled.
      LibraryElement library = element.library;
      if (!hasIsolateSupport && !(element.isField && element.isConst)) {
        Uri uri = library.canonicalUri;
        if (uri == Uris.dart_isolate) {
          hasIsolateSupport = true;
          worldImpact
              .addImpact(enableIsolateSupport(forResolution: forResolution));
        } else if (uri == Uris.dart_async) {
          if (element.name == '_createTimer' ||
              element.name == '_createPeriodicTimer') {
            // The [:Timer:] class uses the event queue of the isolate
            // library, so we make sure that event queue is generated.
            hasIsolateSupport = true;
            worldImpact
                .addImpact(enableIsolateSupport(forResolution: forResolution));
          }
        }
      }

      if (element.isGetter && element.name == Identifiers.runtimeType_) {
        // Enable runtime type support if we discover a getter called
        // runtimeType. We have to enable runtime type before hitting the
        // codegen, so that constructors know whether they need to generate code
        // for runtime type.
        hasRuntimeTypeSupport = true;
        // TODO(ahe): Record precise dependency here.
        worldImpact.addImpact(registerRuntimeType());
      } else if (compiler.commonElements.isFunctionApplyMethod(element)) {
        hasFunctionApplySupport = true;
      }
    } else {
      // TODO(sigmund): add other missing dependencies (internals, selectors
      // enqueued after allocations).
      compiler.dumpInfoTask.registerDependency(element);
    }
    return worldImpact;
  }

  /// This method is called immediately after the [library] and its parts have
  /// been scanned.
  Future onLibraryScanned(LibraryElement library, LibraryLoader loader) {
    if (!compiler.serialization.isDeserialized(library)) {
      if (canLibraryUseNative(library)) {
        library.forEachLocalMember((Element element) {
          if (element.isClass) {
            checkNativeAnnotation(compiler, element);
          }
        });
      }
      checkJsInteropAnnotation(compiler, library);
      library.forEachLocalMember((Element element) {
        checkJsInteropAnnotation(compiler, element);
        if (element.isClass && isJsInterop(element)) {
          ClassElement classElement = element;
          classElement.forEachMember((_, memberElement) {
            checkJsInteropAnnotation(compiler, memberElement);
          });
        }
      });
    }
    if (library.isPlatformLibrary &&
        // Don't patch library currently disallowed.
        !library.isSynthesized &&
        !library.isPatched &&
        // Don't patch deserialized libraries.
        !compiler.serialization.isDeserialized(library)) {
      // Apply patch, if any.
      Uri patchUri = compiler.resolvePatchUri(library.canonicalUri.path);
      if (patchUri != null) {
        return compiler.patchParser.patchLibrary(loader, patchUri, library);
      }
    }
    Uri uri = library.canonicalUri;
    if (uri == Uris.dart_html) {
      htmlLibraryIsLoaded = true;
    } else if (uri == LookupMapAnalysis.PACKAGE_LOOKUP_MAP) {
      lookupMapAnalysis.init(library);
    }
    annotations.onLibraryScanned(library);
    return new Future.value();
  }

  /// This method is called when all new libraries loaded through
  /// [LibraryLoader.loadLibrary] has been loaded and their imports/exports
  /// have been computed.
  Future onLibrariesLoaded(LoadedLibraries loadedLibraries) {
    if (!loadedLibraries.containsLibrary(Uris.dart_core)) {
      return new Future.value();
    }

    helpers.onLibrariesLoaded(loadedLibraries);

    implementationClasses = <ClassElement, ClassElement>{};
    implementationClasses[commonElements.intClass] = helpers.jsIntClass;
    implementationClasses[commonElements.boolClass] = helpers.jsBoolClass;
    implementationClasses[commonElements.numClass] = helpers.jsNumberClass;
    implementationClasses[commonElements.doubleClass] = helpers.jsDoubleClass;
    implementationClasses[commonElements.stringClass] = helpers.jsStringClass;
    implementationClasses[commonElements.listClass] = helpers.jsArrayClass;
    implementationClasses[commonElements.nullClass] = helpers.jsNullClass;

    // These methods are overwritten with generated versions.
    inlineCache.markAsNonInlinable(helpers.getInterceptorMethod,
        insideLoop: true);

    specialOperatorEqClasses
      ..add(commonElements.objectClass)
      ..add(helpers.jsInterceptorClass)
      ..add(helpers.jsNullClass);

    validateInterceptorImplementsAllObjectMethods(helpers.jsInterceptorClass);
    // The null-interceptor must also implement *all* methods.
    validateInterceptorImplementsAllObjectMethods(helpers.jsNullClass);

    return new Future.value();
  }

  jsAst.Call generateIsJsIndexableCall(
      jsAst.Expression use1, jsAst.Expression use2) {
    String dispatchPropertyName = embeddedNames.DISPATCH_PROPERTY_NAME;
    jsAst.Expression dispatchProperty =
        emitter.generateEmbeddedGlobalAccess(dispatchPropertyName);

    // We pass the dispatch property record to the isJsIndexable
    // helper rather than reading it inside the helper to increase the
    // chance of making the dispatch record access monomorphic.
    jsAst.PropertyAccess record =
        new jsAst.PropertyAccess(use2, dispatchProperty);

    List<jsAst.Expression> arguments = <jsAst.Expression>[use1, record];
    MethodElement helper = helpers.isJsIndexable;
    jsAst.Expression helperExpression = emitter.staticFunctionAccess(helper);
    return new jsAst.Call(helperExpression, arguments);
  }

  /// Returns all static fields that are referenced through [targetsUsed].
  /// If the target is a library or class all nested static fields are
  /// included too.
  Iterable<Element> _findStaticFieldTargets() {
    List staticFields = [];

    void addFieldsInContainer(ScopeContainerElement container) {
      container.forEachLocalMember((Element member) {
        if (!member.isInstanceMember && member.isField) {
          staticFields.add(member);
        } else if (member.isClass) {
          addFieldsInContainer(member);
        }
      });
    }

    for (Element target in mirrorsData.targetsUsed) {
      if (target == null) continue;
      if (target.isField) {
        staticFields.add(target);
      } else if (target.isLibrary || target.isClass) {
        addFieldsInContainer(target);
      }
    }
    return staticFields;
  }

  bool onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    // Add elements used synthetically, that is, through features rather than
    // syntax, for instance custom elements.
    //
    // Return early if any elements are added to avoid counting the elements as
    // due to mirrors.
    enqueuer.applyImpact(customElementsAnalysis.flush(
        forResolution: enqueuer.isResolutionQueue));
    enqueuer.applyImpact(
        lookupMapAnalysis.flush(forResolution: enqueuer.isResolutionQueue));
    enqueuer.applyImpact(
        typeVariableHandler.flush(forResolution: enqueuer.isResolutionQueue));

    if (enqueuer.isResolutionQueue) {
      for (ClassElement cls in recentClasses) {
        Element element = cls.lookupLocalMember(Identifiers.noSuchMethod_);
        if (element != null && element.isInstanceMember && element.isFunction) {
          registerNoSuchMethod(element);
        }
      }
    }
    noSuchMethodRegistry.onQueueEmpty();
    if (enqueuer.isResolutionQueue) {
      if (!enabledNoSuchMethod &&
          (noSuchMethodRegistry.hasThrowingNoSuchMethod ||
              noSuchMethodRegistry.hasComplexNoSuchMethod)) {
        enqueuer.applyImpact(computeNoSuchMethodImpact());
        enabledNoSuchMethod = true;
      }
    } else {
      if (enabledNoSuchMethod && !_noSuchMethodEnabledForCodegen) {
        enqueuer.applyImpact(computeNoSuchMethodImpact());
        _noSuchMethodEnabledForCodegen = true;
      }
    }

    if (!enqueuer.queueIsEmpty) return false;

    if (compiler.options.useKernel && compiler.mainApp != null) {
      kernelTask.buildKernelIr();
    }

    if (!enqueuer.isResolutionQueue && preMirrorsMethodCount == 0) {
      preMirrorsMethodCount = generatedCode.length;
    }

    if (mirrorsData.isTreeShakingDisabled) {
      enqueuer.applyImpact(mirrorsAnalysis.computeImpactForReflectiveElements(
          recentClasses,
          enqueuer.processedClasses,
          compiler.libraryLoader.libraries,
          forResolution: enqueuer.isResolutionQueue));
    } else if (!mirrorsData.targetsUsed.isEmpty && enqueuer.isResolutionQueue) {
      // Add all static elements (not classes) that have been requested for
      // reflection. If there is no mirror-usage these are probably not
      // necessary, but the backend relies on them being resolved.
      enqueuer.applyImpact(mirrorsAnalysis
          .computeImpactForReflectiveStaticFields(_findStaticFieldTargets(),
              forResolution: enqueuer.isResolutionQueue));
    }

    if (mirrorsData.mustPreserveNames) reporter.log('Preserving names.');

    if (mirrorsData.mustRetainMetadata) {
      reporter.log('Retaining metadata.');

      compiler.libraryLoader.libraries.forEach(mirrorsData.retainMetadataOf);

      StagedWorldImpactBuilder impactBuilder = enqueuer.isResolutionQueue
          ? constantImpactsForResolution
          : constantImpactsForCodegen;
      if (enqueuer.isResolutionQueue && !enqueuer.queueIsClosed) {
        /// Register the constant value of [metadata] as live in resolution.
        void registerMetadataConstant(MetadataAnnotation metadata) {
          ConstantValue constant =
              constants.getConstantValueForMetadata(metadata);
          Dependency dependency =
              new Dependency(constant, metadata.annotatedElement);
          metadataConstants.add(dependency);
          computeImpactForCompileTimeConstant(
              dependency.constant, impactBuilder, enqueuer.isResolutionQueue);
        }

        // TODO(johnniwinther): We should have access to all recently processed
        // elements and process these instead.
        processMetadata(compiler.enqueuer.resolution.processedEntities,
            registerMetadataConstant);
      } else {
        for (Dependency dependency in metadataConstants) {
          computeImpactForCompileTimeConstant(
              dependency.constant, impactBuilder, enqueuer.isResolutionQueue);
        }
        metadataConstants.clear();
      }
      enqueuer.applyImpact(impactBuilder.flush());
    }
    return true;
  }

  /// Call [registerMetadataConstant] on all metadata from [entities].
  void processMetadata(
      Iterable<Entity> entities, void onMetadata(MetadataAnnotation metadata)) {
    void processLibraryMetadata(LibraryElement library) {
      if (_registeredMetadata.add(library)) {
        library.metadata.forEach(onMetadata);
        library.entryCompilationUnit.metadata.forEach(onMetadata);
        for (ImportElement import in library.imports) {
          import.metadata.forEach(onMetadata);
        }
      }
    }

    void processElementMetadata(Element element) {
      if (_registeredMetadata.add(element)) {
        element.metadata.forEach(onMetadata);
        if (element.isFunction) {
          FunctionElement function = element;
          for (ParameterElement parameter in function.parameters) {
            parameter.metadata.forEach(onMetadata);
          }
        }
        if (element.enclosingClass != null) {
          // Only process library of top level fields/methods
          // (and not for classes).
          // TODO(johnniwinther): Fix this: We are missing some metadata on
          // libraries (example: in co19/Language/Metadata/before_export_t01).
          if (element.enclosingElement is ClassElement) {
            // Use [enclosingElement] instead of [enclosingClass] to ensure that
            // we process patch class metadata for patch and injected members.
            processElementMetadata(element.enclosingElement);
          }
        } else {
          processLibraryMetadata(element.library);
        }
      }
    }

    entities.forEach(processElementMetadata);
  }

  /// Called after the queue is closed. [onQueueEmpty] may be called multiple
  /// times, but [onQueueClosed] is only called once.
  void onQueueClosed() {
    lookupMapAnalysis.onQueueClosed();
    jsInteropAnalysis.onQueueClosed();
  }

  // TODO(johnniwinther): Create a CodegenPhase object for the backend to hold
  // data only available during code generation.
  ClosedWorld _closedWorldCache;
  ClosedWorld get _closedWorld {
    assert(invariant(NO_LOCATION_SPANNABLE, _closedWorldCache != null,
        message: "ClosedWorld has not be set yet."));
    return _closedWorldCache;
  }

  void set _closedWorld(ClosedWorld value) {
    _closedWorldCache = value;
  }

  /// Called when the compiler starts running the codegen enqueuer. The
  /// [WorldImpact] of enabled backend features is returned.
  WorldImpact onCodegenStart(ClosedWorld closedWorld) {
    _closedWorld = closedWorld;
    _namer = determineNamer(_closedWorld, compiler.codegenWorldBuilder);
    tracer = new Tracer(_closedWorld, namer, compiler);
    emitter.createEmitter(_namer, _closedWorld);
    lookupMapAnalysis.onCodegenStart();
    if (hasIsolateSupport) {
      return enableIsolateSupport(forResolution: false);
    }
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
  bool canLibraryUseNative(LibraryElement library) {
    return native.maybeEnableNative(compiler, library);
  }

  @override
  bool isTargetSpecificLibrary(LibraryElement library) {
    Uri canonicalUri = library.canonicalUri;
    if (canonicalUri == BackendHelpers.DART_JS_HELPER ||
        canonicalUri == BackendHelpers.DART_INTERCEPTORS) {
      return true;
    }
    return false;
  }

  /// Process backend specific annotations.
  void processAnnotations(
      Element element, ClosedWorldRefiner closedWorldRefiner) {
    if (element.isMalformed) {
      // Elements that are marked as malformed during parsing or resolution
      // might be registered here. These should just be ignored.
      return;
    }

    Element implementation = element.implementation;
    if (element.isFunction || element.isConstructor) {
      if (annotations.noInline(implementation)) {
        inlineCache.markAsNonInlinable(implementation);
      }
    }

    LibraryElement library = element.library;
    if (!library.isPlatformLibrary && !canLibraryUseNative(library)) return;
    bool hasNoInline = false;
    bool hasForceInline = false;
    bool hasNoThrows = false;
    bool hasNoSideEffects = false;
    for (MetadataAnnotation metadata in element.implementation.metadata) {
      metadata.ensureResolved(resolution);
      ConstantValue constantValue =
          compiler.constants.getConstantValue(metadata.constant);
      if (!constantValue.isConstructedObject) continue;
      ObjectConstantValue value = constantValue;
      ClassElement cls = value.type.element;
      if (cls == helpers.forceInlineClass) {
        hasForceInline = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              element, MessageKind.GENERIC, {'text': "Must inline"});
        }
        inlineCache.markAsMustInline(element);
      } else if (cls == helpers.noInlineClass) {
        hasNoInline = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              element, MessageKind.GENERIC, {'text': "Cannot inline"});
        }
        inlineCache.markAsNonInlinable(element);
      } else if (cls == helpers.noThrowsClass) {
        hasNoThrows = true;
        if (!Elements.isStaticOrTopLevelFunction(element) &&
            !element.isFactoryConstructor) {
          reporter.internalError(
              element,
              "@NoThrows() is currently limited to top-level"
              " or static functions and factory constructors.");
        }
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              element, MessageKind.GENERIC, {'text': "Cannot throw"});
        }
        closedWorldRefiner.registerCannotThrow(element);
      } else if (cls == helpers.noSideEffectsClass) {
        hasNoSideEffects = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              element, MessageKind.GENERIC, {'text': "Has no side effects"});
        }
        closedWorldRefiner.registerSideEffectsFree(element);
      }
    }
    if (hasForceInline && hasNoInline) {
      reporter.internalError(
          element, "@ForceInline() must not be used with @NoInline.");
    }
    if (hasNoThrows && !hasNoInline) {
      reporter.internalError(
          element, "@NoThrows() should always be combined with @NoInline.");
    }
    if (hasNoSideEffects && !hasNoInline) {
      reporter.internalError(element,
          "@NoSideEffects() should always be combined with @NoInline.");
    }
  }

  MethodElement helperForBadMain() => helpers.badMain;

  MethodElement helperForMissingMain() => helpers.missingMain;

  MethodElement helperForMainArity() => helpers.mainHasTooManyParameters;

  /// Computes the [WorldImpact] of calling [mainMethod] as the entry point.
  WorldImpact computeMainImpact(MethodElement mainMethod,
      {bool forResolution}) {
    WorldImpactBuilderImpl mainImpact = new WorldImpactBuilderImpl();
    if (mainMethod.parameters.isNotEmpty) {
      impactTransformer.registerBackendImpact(
          mainImpact, impacts.mainWithArguments);
      mainImpact.registerStaticUse(
          new StaticUse.staticInvoke(mainMethod, CallStructure.TWO_ARGS));
      // If the main method takes arguments, this compilation could be the
      // target of Isolate.spawnUri. Strictly speaking, that can happen also if
      // main takes no arguments, but in this case the spawned isolate can't
      // communicate with the spawning isolate.
      mainImpact.addImpact(enableIsolateSupport(forResolution: forResolution));
    }
    mainImpact.registerStaticUse(
        new StaticUse.staticInvoke(mainMethod, CallStructure.NO_ARGS));
    return mainImpact;
  }

  /// Returns the filename for the output-unit named [name].
  ///
  /// The filename is of the form "<main output file>_<name>.part.js".
  /// If [addExtension] is false, the ".part.js" suffix is left out.
  String deferredPartFileName(String name, {bool addExtension: true}) {
    assert(name != "");
    String outPath = compiler.options.outputUri != null
        ? compiler.options.outputUri.path
        : "out";
    String outName = outPath.substring(outPath.lastIndexOf('/') + 1);
    String extension = addExtension ? ".part.js" : "";
    return "${outName}_$name$extension";
  }

  /// Enable deferred loading. Returns `true` if the backend supports deferred
  /// loading.
  bool enableDeferredLoadingIfSupported(Spannable node) => true;

  /// Enable compilation of code with compile time errors. Returns `true` if
  /// supported by the backend.
  bool enableCodegenWithErrorsIfSupported(Spannable node) => true;

  jsAst.Expression rewriteAsync(
      FunctionElement element, jsAst.Expression code) {
    AsyncRewriterBase rewriter = null;
    jsAst.Name name = namer.methodPropertyName(element);
    switch (element.asyncMarker) {
      case AsyncMarker.ASYNC:
        rewriter = new AsyncRewriter(reporter, element,
            asyncHelper: emitter.staticFunctionAccess(helpers.asyncHelper),
            wrapBody: emitter.staticFunctionAccess(helpers.wrapBody),
            newCompleter:
                emitter.staticFunctionAccess(helpers.syncCompleterConstructor),
            safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
            bodyName: namer.deriveAsyncBodyName(name));
        break;
      case AsyncMarker.SYNC_STAR:
        rewriter = new SyncStarRewriter(reporter, element,
            endOfIteration:
                emitter.staticFunctionAccess(helpers.endOfIteration),
            newIterable: emitter
                .staticFunctionAccess(helpers.syncStarIterableConstructor),
            yieldStarExpression:
                emitter.staticFunctionAccess(helpers.yieldStar),
            uncaughtErrorExpression:
                emitter.staticFunctionAccess(helpers.syncStarUncaughtError),
            safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
            bodyName: namer.deriveAsyncBodyName(name));
        break;
      case AsyncMarker.ASYNC_STAR:
        rewriter = new AsyncStarRewriter(reporter, element,
            asyncStarHelper:
                emitter.staticFunctionAccess(helpers.asyncStarHelper),
            streamOfController:
                emitter.staticFunctionAccess(helpers.streamOfController),
            wrapBody: emitter.staticFunctionAccess(helpers.wrapBody),
            newController: emitter
                .staticFunctionAccess(helpers.asyncStarControllerConstructor),
            safeVariableName: namer.safeVariablePrefixForAsyncRewrite,
            yieldExpression: emitter.staticFunctionAccess(helpers.yieldSingle),
            yieldStarExpression:
                emitter.staticFunctionAccess(helpers.yieldStar),
            bodyName: namer.deriveAsyncBodyName(name));
        break;
      default:
        assert(element.asyncMarker == AsyncMarker.SYNC);
        return code;
    }
    return rewriter.rewrite(code);
  }

  /// The locations of js patch-files relative to the sdk-descriptors.
  static const _patchLocations = const <String, String>{
    "async": "_internal/js_runtime/lib/async_patch.dart",
    "collection": "_internal/js_runtime/lib/collection_patch.dart",
    "convert": "_internal/js_runtime/lib/convert_patch.dart",
    "core": "_internal/js_runtime/lib/core_patch.dart",
    "developer": "_internal/js_runtime/lib/developer_patch.dart",
    "io": "_internal/js_runtime/lib/io_patch.dart",
    "isolate": "_internal/js_runtime/lib/isolate_patch.dart",
    "math": "_internal/js_runtime/lib/math_patch.dart",
    "mirrors": "_internal/js_runtime/lib/mirrors_patch.dart",
    "typed_data": "_internal/js_runtime/lib/typed_data_patch.dart",
    "_internal": "_internal/js_runtime/lib/internal_patch.dart"
  };

  /// Returns the location of the patch-file associated with [libraryName]
  /// resolved from [plaformConfigUri].
  ///
  /// Returns null if there is none.
  Uri resolvePatchUri(String libraryName, Uri platformConfigUri) {
    String patchLocation = _patchLocations[libraryName];
    if (patchLocation == null) return null;
    return platformConfigUri.resolve(patchLocation);
  }

  /// Creates an impact strategy to use for compilation.
  ImpactStrategy createImpactStrategy(
      {bool supportDeferredLoad: true,
      bool supportDumpInfo: true,
      bool supportSerialization: true}) {
    return new JavaScriptImpactStrategy(resolution, compiler.dumpInfoTask,
        supportDeferredLoad: supportDeferredLoad,
        supportDumpInfo: supportDumpInfo,
        supportSerialization: supportSerialization);
  }

  EnqueueTask makeEnqueuer() => new EnqueueTask(compiler);
}

class JSFrontendAccess implements Frontend {
  final Compiler compiler;

  JSFrontendAccess(this.compiler);

  Resolution get resolution => compiler.resolution;

  @override
  ResolutionImpact getResolutionImpact(Element element) {
    return resolution.getResolutionImpact(element);
  }
}

/// Handling of special annotations for tests.
class Annotations {
  static final Uri PACKAGE_EXPECT =
      new Uri(scheme: 'package', path: 'expect/expect.dart');

  final Compiler compiler;

  ClassElement expectNoInlineClass;
  ClassElement expectTrustTypeAnnotationsClass;
  ClassElement expectAssumeDynamicClass;

  JavaScriptBackend get backend => compiler.backend;

  DiagnosticReporter get reporter => compiler.reporter;

  Annotations(this.compiler);

  void onLibraryScanned(LibraryElement library) {
    if (library.canonicalUri == PACKAGE_EXPECT) {
      expectNoInlineClass = library.find('NoInline');
      expectTrustTypeAnnotationsClass = library.find('TrustTypeAnnotations');
      expectAssumeDynamicClass = library.find('AssumeDynamic');
      if (expectNoInlineClass == null ||
          expectTrustTypeAnnotationsClass == null ||
          expectAssumeDynamicClass == null) {
        // This is not the package you're looking for.
        expectNoInlineClass = null;
        expectTrustTypeAnnotationsClass = null;
        expectAssumeDynamicClass = null;
      }
    }
  }

  /// Returns `true` if inlining is disabled for [element].
  bool noInline(Element element) {
    if (_hasAnnotation(element, expectNoInlineClass)) {
      // TODO(floitsch): restrict to elements from the test directory.
      return true;
    }
    return _hasAnnotation(element, backend.helpers.noInlineClass);
  }

  /// Returns `true` if parameter and returns types should be trusted for
  /// [element].
  bool trustTypeAnnotations(Element element) {
    return _hasAnnotation(element, expectTrustTypeAnnotationsClass);
  }

  /// Returns `true` if inference of parameter types is disabled for [element].
  bool assumeDynamic(Element element) {
    return _hasAnnotation(element, expectAssumeDynamicClass);
  }

  /// Returns `true` if [element] is annotated with [annotationClass].
  bool _hasAnnotation(Element element, ClassElement annotationClass) {
    if (annotationClass == null) return false;
    return reporter.withCurrentElement(element, () {
      for (MetadataAnnotation metadata in element.metadata) {
        assert(invariant(metadata, metadata.constant != null,
            message: "Unevaluated metadata constant."));
        ConstantValue value =
            compiler.constants.getConstantValue(metadata.constant);
        if (value.isConstructedObject) {
          ConstructedConstantValue constructedConstant = value;
          if (constructedConstant.type.element == annotationClass) {
            return true;
          }
        }
      }
      return false;
    });
  }
}

class JavaScriptImpactTransformer extends ImpactTransformer {
  final JavaScriptBackend backend;

  JavaScriptImpactTransformer(this.backend);

  BackendImpacts get impacts => backend.impacts;

  @override
  WorldImpact transformResolutionImpact(
      ResolutionEnqueuer enqueuer, ResolutionImpact worldImpact) {
    TransformedWorldImpact transformed =
        new TransformedWorldImpact(worldImpact);
    for (Feature feature in worldImpact.features) {
      switch (feature) {
        case Feature.ABSTRACT_CLASS_INSTANTIATION:
          registerBackendImpact(
              transformed, impacts.abstractClassInstantiation);
          break;
        case Feature.ASSERT:
          registerBackendImpact(transformed, impacts.assertWithoutMessage);
          break;
        case Feature.ASSERT_WITH_MESSAGE:
          registerBackendImpact(transformed, impacts.assertWithMessage);
          break;
        case Feature.ASYNC:
          registerBackendImpact(transformed, impacts.asyncBody);
          break;
        case Feature.ASYNC_FOR_IN:
          registerBackendImpact(transformed, impacts.asyncForIn);
          break;
        case Feature.ASYNC_STAR:
          registerBackendImpact(transformed, impacts.asyncStarBody);
          break;
        case Feature.CATCH_STATEMENT:
          registerBackendImpact(transformed, impacts.catchStatement);
          break;
        case Feature.COMPILE_TIME_ERROR:
          if (backend.compiler.options.generateCodeWithCompileTimeErrors) {
            // TODO(johnniwinther): This should have its own uncatchable error.
            registerBackendImpact(transformed, impacts.throwRuntimeError);
          }
          break;
        case Feature.FALL_THROUGH_ERROR:
          registerBackendImpact(transformed, impacts.fallThroughError);
          break;
        case Feature.FIELD_WITHOUT_INITIALIZER:
        case Feature.LOCAL_WITHOUT_INITIALIZER:
          transformed.registerTypeUse(
              new TypeUse.instantiation(backend.commonElements.nullType));
          registerBackendImpact(transformed, impacts.nullLiteral);
          break;
        case Feature.LAZY_FIELD:
          registerBackendImpact(transformed, impacts.lazyField);
          break;
        case Feature.STACK_TRACE_IN_CATCH:
          registerBackendImpact(transformed, impacts.stackTraceInCatch);
          break;
        case Feature.STRING_INTERPOLATION:
          registerBackendImpact(transformed, impacts.stringInterpolation);
          break;
        case Feature.STRING_JUXTAPOSITION:
          registerBackendImpact(transformed, impacts.stringJuxtaposition);
          break;
        case Feature.SUPER_NO_SUCH_METHOD:
          registerBackendImpact(transformed, impacts.superNoSuchMethod);
          break;
        case Feature.SYMBOL_CONSTRUCTOR:
          registerBackendImpact(transformed, impacts.symbolConstructor);
          break;
        case Feature.SYNC_FOR_IN:
          registerBackendImpact(transformed, impacts.syncForIn);
          break;
        case Feature.SYNC_STAR:
          registerBackendImpact(transformed, impacts.syncStarBody);
          break;
        case Feature.THROW_EXPRESSION:
          registerBackendImpact(transformed, impacts.throwExpression);
          break;
        case Feature.THROW_NO_SUCH_METHOD:
          registerBackendImpact(transformed, impacts.throwNoSuchMethod);
          break;
        case Feature.THROW_RUNTIME_ERROR:
          registerBackendImpact(transformed, impacts.throwRuntimeError);
          break;
        case Feature.TYPE_VARIABLE_BOUNDS_CHECK:
          registerBackendImpact(transformed, impacts.typeVariableBoundCheck);
          break;
      }
    }

    bool hasAsCast = false;
    bool hasTypeLiteral = false;
    for (TypeUse typeUse in worldImpact.typeUses) {
      ResolutionDartType type = typeUse.type;
      switch (typeUse.kind) {
        case TypeUseKind.INSTANTIATION:
        case TypeUseKind.MIRROR_INSTANTIATION:
        case TypeUseKind.NATIVE_INSTANTIATION:
          registerRequiredType(type);
          break;
        case TypeUseKind.IS_CHECK:
          onIsCheck(type, transformed);
          break;
        case TypeUseKind.AS_CAST:
          onIsCheck(type, transformed);
          hasAsCast = true;
          break;
        case TypeUseKind.CHECKED_MODE_CHECK:
          if (backend.compiler.options.enableTypeAssertions) {
            onIsCheck(type, transformed);
          }
          break;
        case TypeUseKind.CATCH_TYPE:
          onIsCheck(type, transformed);
          break;
        case TypeUseKind.TYPE_LITERAL:
          backend.customElementsAnalysis.registerTypeLiteral(type);
          if (type.isTypeVariable && type is! MethodTypeVariableType) {
            // GENERIC_METHODS: The `is!` test above filters away method type
            // variables, because they have the value `dynamic` with the
            // incomplete support for generic methods offered with
            // '--generic-method-syntax'. This must be revised in order to
            // support generic methods fully.
            ClassElement cls = type.element.enclosingClass;
            backend.rti.registerClassUsingTypeVariableExpression(cls);
            registerBackendImpact(transformed, impacts.typeVariableExpression);
          }
          hasTypeLiteral = true;
          break;
      }
    }

    if (hasAsCast) {
      registerBackendImpact(transformed, impacts.asCheck);
    }

    if (hasTypeLiteral) {
      transformed.registerTypeUse(
          new TypeUse.instantiation(backend.compiler.commonElements.typeType));
      registerBackendImpact(transformed, impacts.typeLiteral);
    }

    for (MapLiteralUse mapLiteralUse in worldImpact.mapLiterals) {
      // TODO(johnniwinther): Use the [isEmpty] property when factory
      // constructors are registered directly.
      if (mapLiteralUse.isConstant) {
        registerBackendImpact(transformed, impacts.constantMapLiteral);
      } else {
        transformed
            .registerTypeUse(new TypeUse.instantiation(mapLiteralUse.type));
      }
      ResolutionInterfaceType type = mapLiteralUse.type;
      registerRequiredType(type);
    }

    for (ListLiteralUse listLiteralUse in worldImpact.listLiterals) {
      // TODO(johnniwinther): Use the [isConstant] and [isEmpty] property when
      // factory constructors are registered directly.
      transformed
          .registerTypeUse(new TypeUse.instantiation(listLiteralUse.type));
      ResolutionInterfaceType type = listLiteralUse.type;
      registerRequiredType(type);
    }

    if (worldImpact.constSymbolNames.isNotEmpty) {
      registerBackendImpact(transformed, impacts.constSymbol);
      for (String constSymbolName in worldImpact.constSymbolNames) {
        backend.mirrorsData.registerConstSymbol(constSymbolName);
      }
    }

    for (StaticUse staticUse in worldImpact.staticUses) {
      switch (staticUse.kind) {
        case StaticUseKind.CLOSURE:
          registerBackendImpact(transformed, impacts.closure);
          LocalFunctionElement closure = staticUse.element;
          if (closure.type.containsTypeVariables) {
            registerBackendImpact(transformed, impacts.computeSignature);
          }
          break;
        case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        case StaticUseKind.CONSTRUCTOR_INVOKE:
          registerRequiredType(staticUse.type);
          break;
        default:
      }
    }

    for (ConstantExpression constant in worldImpact.constantLiterals) {
      switch (constant.kind) {
        case ConstantExpressionKind.NULL:
          registerBackendImpact(transformed, impacts.nullLiteral);
          break;
        case ConstantExpressionKind.BOOL:
          registerBackendImpact(transformed, impacts.boolLiteral);
          break;
        case ConstantExpressionKind.INT:
          registerBackendImpact(transformed, impacts.intLiteral);
          break;
        case ConstantExpressionKind.DOUBLE:
          registerBackendImpact(transformed, impacts.doubleLiteral);
          break;
        case ConstantExpressionKind.STRING:
          registerBackendImpact(transformed, impacts.stringLiteral);
          break;
        default:
          assert(invariant(NO_LOCATION_SPANNABLE, false,
              message: "Unexpected constant literal: ${constant.kind}."));
      }
    }

    for (native.NativeBehavior behavior in worldImpact.nativeData) {
      enqueuer.nativeEnqueuer
          .registerNativeBehavior(transformed, behavior, worldImpact);
    }

    return transformed;
  }

  WorldImpact createImpactFor(BackendImpact impact) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    registerBackendImpact(impactBuilder, impact);
    return impactBuilder;
  }

  void registerBackendStaticUse(
      WorldImpactBuilder worldImpact, MethodElement element,
      {bool isGlobal: false}) {
    backend.backendUsage.registerBackendUse(element);
    worldImpact.registerStaticUse(
        // TODO(johnniwinther): Store the correct use in impacts.
        new StaticUse.foreignUse(element));
    if (isGlobal) {
      backend.compiler.globalDependencies.registerDependency(element);
    }
  }

  void registerBackendInstantiation(
      WorldImpactBuilder worldImpact, ClassElement cls,
      {bool isGlobal: false}) {
    cls.ensureResolved(backend.resolution);
    backend.backendUsage.registerBackendUse(cls);
    worldImpact.registerTypeUse(new TypeUse.instantiation(cls.rawType));
    if (isGlobal) {
      backend.compiler.globalDependencies.registerDependency(cls);
    }
  }

  void registerBackendImpact(
      WorldImpactBuilder worldImpact, BackendImpact backendImpact) {
    for (Element staticUse in backendImpact.staticUses) {
      assert(staticUse != null);
      registerBackendStaticUse(worldImpact, staticUse);
    }
    for (Element staticUse in backendImpact.globalUses) {
      assert(staticUse != null);
      registerBackendStaticUse(worldImpact, staticUse, isGlobal: true);
    }
    for (Selector selector in backendImpact.dynamicUses) {
      assert(selector != null);
      worldImpact.registerDynamicUse(new DynamicUse(selector, null));
    }
    for (ResolutionInterfaceType instantiatedType
        in backendImpact.instantiatedTypes) {
      backend.backendUsage.registerBackendUse(instantiatedType.element);
      worldImpact.registerTypeUse(new TypeUse.instantiation(instantiatedType));
    }
    for (ClassElement cls in backendImpact.instantiatedClasses) {
      registerBackendInstantiation(worldImpact, cls);
    }
    for (ClassElement cls in backendImpact.globalClasses) {
      registerBackendInstantiation(worldImpact, cls, isGlobal: true);
    }
    for (BackendImpact otherImpact in backendImpact.otherImpacts) {
      registerBackendImpact(worldImpact, otherImpact);
    }
    for (BackendFeature feature in backendImpact.features) {
      switch (feature) {
        case BackendFeature.needToInitializeDispatchProperty:
          backend.backendUsage.needToInitializeDispatchProperty = true;
          break;
        case BackendFeature.needToInitializeIsolateAffinityTag:
          backend.backendUsage.needToInitializeIsolateAffinityTag = true;
          break;
      }
    }
  }

  /// Register [type] as required for the runtime type information system.
  void registerRequiredType(ResolutionDartType type) {
    if (!type.isInterfaceType) return;
    // If [argument] has type variables or is a type variable, this method
    // registers a RTI dependency between the class where the type variable is
    // defined (that is the enclosing class of the current element being
    // resolved) and the class of [type]. If the class of [type] requires RTI,
    // then the class of the type variable does too.
    ClassElement contextClass = Types.getClassContext(type);
    if (contextClass != null) {
      backend.rti.registerRtiDependency(type.element, contextClass);
    }
  }

  // TODO(johnniwinther): Maybe split this into [onAssertType] and [onTestType].
  void onIsCheck(ResolutionDartType type, TransformedWorldImpact transformed) {
    registerRequiredType(type);
    type.computeUnaliased(backend.resolution);
    type = type.unaliased;
    registerBackendImpact(transformed, impacts.typeCheck);

    bool inCheckedMode = backend.compiler.options.enableTypeAssertions;
    if (inCheckedMode) {
      registerBackendImpact(transformed, impacts.checkedModeTypeCheck);
    }
    if (type.isMalformed) {
      registerBackendImpact(transformed, impacts.malformedTypeCheck);
    }
    if (!type.treatAsRaw || type.containsTypeVariables || type.isFunctionType) {
      registerBackendImpact(transformed, impacts.genericTypeCheck);
      if (inCheckedMode) {
        registerBackendImpact(transformed, impacts.genericCheckedModeTypeCheck);
      }
      if (type.isTypeVariable) {
        registerBackendImpact(transformed, impacts.typeVariableTypeCheck);
        if (inCheckedMode) {
          registerBackendImpact(
              transformed, impacts.typeVariableCheckedModeTypeCheck);
        }
      }
    }
    if (type is ResolutionFunctionType) {
      registerBackendImpact(transformed, impacts.functionTypeCheck);
    }
    if (type.element != null && backend.isNative(type.element)) {
      registerBackendImpact(transformed, impacts.nativeTypeCheck);
    }
  }

  void onIsCheckForCodegen(
      ResolutionDartType type, TransformedWorldImpact transformed) {
    if (type.isDynamic) return;
    type = type.unaliased;
    registerBackendImpact(transformed, impacts.typeCheck);

    bool inCheckedMode = backend.compiler.options.enableTypeAssertions;
    // [registerIsCheck] is also called for checked mode checks, so we
    // need to register checked mode helpers.
    if (inCheckedMode) {
      // All helpers are added to resolution queue in enqueueHelpers. These
      // calls to [enqueue] with the resolution enqueuer serve as assertions
      // that the helper was in fact added.
      // TODO(13155): Find a way to enqueue helpers lazily.
      CheckedModeHelper helper = backend.checkedModeHelpers
          .getCheckedModeHelper(type, typeCast: false);
      if (helper != null) {
        StaticUse staticUse = helper.getStaticUse(backend.helpers);
        transformed.registerStaticUse(staticUse);
        backend.backendUsage.registerBackendUse(staticUse.element);
      }
      // We also need the native variant of the check (for DOM types).
      helper = backend.checkedModeHelpers
          .getNativeCheckedModeHelper(type, typeCast: false);
      if (helper != null) {
        StaticUse staticUse = helper.getStaticUse(backend.helpers);
        transformed.registerStaticUse(staticUse);
        backend.backendUsage.registerBackendUse(staticUse.element);
      }
    }
    if (!type.treatAsRaw || type.containsTypeVariables) {
      registerBackendImpact(transformed, impacts.genericIsCheck);
    }
    if (type.element != null && backend.isNative(type.element)) {
      // We will neeed to add the "$is" and "$as" properties on the
      // JavaScript object prototype, so we make sure
      // [:defineProperty:] is compiled.
      registerBackendImpact(transformed, impacts.nativeTypeCheck);
    }
  }

  @override
  WorldImpact transformCodegenImpact(CodegenImpact impact) {
    TransformedWorldImpact transformed = new TransformedWorldImpact(impact);

    for (TypeUse typeUse in impact.typeUses) {
      ResolutionDartType type = typeUse.type;
      switch (typeUse.kind) {
        case TypeUseKind.INSTANTIATION:
          backend.lookupMapAnalysis.registerInstantiatedType(type);
          break;
        case TypeUseKind.IS_CHECK:
          onIsCheckForCodegen(type, transformed);
          break;
        default:
      }
    }

    for (ConstantValue constant in impact.compileTimeConstants) {
      backend.computeImpactForCompileTimeConstant(constant, transformed, false);
      backend.addCompileTimeConstantForEmission(constant);
    }

    for (Pair<ResolutionDartType, ResolutionDartType> check
        in impact.typeVariableBoundsSubtypeChecks) {
      backend.registerTypeVariableBoundsSubtypeCheck(check.a, check.b);
    }

    for (StaticUse staticUse in impact.staticUses) {
      switch (staticUse.kind) {
        case StaticUseKind.CLOSURE:
          LocalFunctionElement closure = staticUse.element;
          if (backend.methodNeedsRti(closure)) {
            registerBackendImpact(transformed, impacts.computeSignature);
          }
          break;
        case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        case StaticUseKind.CONSTRUCTOR_INVOKE:
          backend.lookupMapAnalysis.registerInstantiatedType(staticUse.type);
          break;
        default:
      }
    }

    for (String name in impact.constSymbols) {
      backend.mirrorsData.registerConstSymbol(name);
    }

    for (Set<ClassElement> classes in impact.specializedGetInterceptors) {
      backend.interceptorData
          .registerSpecializedGetInterceptor(classes, backend.namer);
    }

    if (impact.usesInterceptor) {
      if (backend.codegenEnqueuer.nativeEnqueuer.hasInstantiatedNativeClasses) {
        registerBackendImpact(transformed, impacts.interceptorUse);
      }
    }

    for (ClassElement element in impact.typeConstants) {
      backend.customElementsAnalysis.registerTypeConstant(element);
      backend.lookupMapAnalysis.registerTypeConstant(element);
    }

    for (FunctionElement element in impact.asyncMarkers) {
      switch (element.asyncMarker) {
        case AsyncMarker.ASYNC:
          registerBackendImpact(transformed, impacts.asyncBody);
          break;
        case AsyncMarker.SYNC_STAR:
          registerBackendImpact(transformed, impacts.syncStarBody);
          break;
        case AsyncMarker.ASYNC_STAR:
          registerBackendImpact(transformed, impacts.asyncStarBody);
          break;
      }
    }

    // TODO(johnniwinther): Remove eager registration.
    return transformed;
  }
}

/// Records that [constant] is used by the element behind [registry].
class Dependency {
  final ConstantValue constant;
  final Element annotatedElement;

  const Dependency(this.constant, this.annotatedElement);

  String toString() => '$annotatedElement:${constant.toStructuredText()}';
}

class JavaScriptImpactStrategy extends ImpactStrategy {
  final Resolution resolution;
  final DumpInfoTask dumpInfoTask;
  final bool supportDeferredLoad;
  final bool supportDumpInfo;
  final bool supportSerialization;

  JavaScriptImpactStrategy(this.resolution, this.dumpInfoTask,
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
          resolution.uncacheWorldImpact(impactSource);
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
      resolution.emptyCache();
    }
  }
}

class JavaScriptBackendClasses implements BackendClasses {
  final ElementEnvironment _env;
  final BackendHelpers helpers;
  final NativeData _nativeData;
  final InterceptorData _interceptorData;

  JavaScriptBackendClasses(
      this._env, this.helpers, this._nativeData, this._interceptorData);

  ClassElement get intClass => helpers.jsIntClass;
  ClassElement get uint32Class => helpers.jsUInt32Class;
  ClassElement get uint31Class => helpers.jsUInt31Class;
  ClassElement get positiveIntClass => helpers.jsPositiveIntClass;
  ClassElement get doubleClass => helpers.jsDoubleClass;
  ClassElement get numClass => helpers.jsNumberClass;
  ClassElement get stringClass => helpers.jsStringClass;
  ClassElement get listClass => helpers.jsArrayClass;
  ClassElement get mutableListClass => helpers.jsMutableArrayClass;
  ClassElement get constListClass => helpers.jsUnmodifiableArrayClass;
  ClassElement get fixedListClass => helpers.jsFixedArrayClass;
  ClassElement get growableListClass => helpers.jsExtendableArrayClass;
  ClassElement get mapClass => helpers.mapLiteralClass;
  ClassElement get constMapClass => helpers.constMapLiteralClass;
  ClassElement get typeClass => helpers.typeLiteralClass;
  InterfaceType get typeType => _env.getRawType(typeClass);

  ClassElement get boolClass => helpers.jsBoolClass;
  ClassElement get nullClass => helpers.jsNullClass;
  ClassElement get syncStarIterableClass => helpers.syncStarIterable;
  ClassElement get asyncFutureClass => helpers.futureImplementation;
  ClassElement get asyncStarStreamClass => helpers.controllerStream;
  ClassElement get functionClass => helpers.commonElements.functionClass;
  ClassElement get indexableClass => helpers.jsIndexableClass;
  ClassElement get mutableIndexableClass => helpers.jsMutableIndexableClass;
  ClassElement get indexingBehaviorClass => helpers.jsIndexingBehaviorInterface;
  ClassElement get interceptorClass => helpers.jsInterceptorClass;

  bool isDefaultEqualityImplementation(MemberElement element) {
    assert(element.name == '==');
    ClassElement classElement = element.enclosingClass;
    return classElement == helpers.commonElements.objectClass ||
        classElement == helpers.jsInterceptorClass ||
        classElement == helpers.jsNullClass;
  }

  @override
  bool isInterceptorClass(ClassElement cls) {
    return _interceptorData.isInterceptorClass(cls);
  }

  @override
  bool isNativeClass(ClassElement element) {
    return _nativeData.isNative(element);
  }

  @override
  bool isNativeMember(MemberElement element) {
    return _nativeData.isNative(element);
  }

  InterfaceType getConstantMapTypeFor(InterfaceType sourceType,
      {bool hasProtoKey: false, bool onlyStringKeys: false}) {
    ClassElement classElement = onlyStringKeys
        ? (hasProtoKey
            ? helpers.constantProtoMapClass
            : helpers.constantStringMapClass)
        : helpers.generalConstantMapClass;
    List<DartType> typeArgument = sourceType.typeArguments;
    if (sourceType.treatAsRaw) {
      return _env.getRawType(classElement);
    } else {
      return _env.createInterfaceType(classElement, typeArgument);
    }
  }

  @override
  FieldEntity get symbolField => helpers.symbolImplementationField;

  @override
  InterfaceType get symbolType {
    return _env.getRawType(helpers.symbolImplementationClass);
  }
}
