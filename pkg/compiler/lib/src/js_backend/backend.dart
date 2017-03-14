// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend;

import 'dart:async' show Future;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;

import '../common.dart';
import '../common/backend_api.dart'
    show BackendClasses, ForeignResolver, NativeRegistry;
import '../common/codegen.dart' show CodegenImpact, CodegenWorkItem;
import '../common/names.dart' show Identifiers, Uris;
import '../common/resolution.dart'
    show Frontend, Resolution, ResolutionImpact, Target;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../common_elements.dart' show CommonElements, ElementEnvironment;
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
import '../options.dart' show CompilerOptions;
import '../patch_parser.dart'
    show checkNativeAnnotation, checkJsInteropAnnotation;
import '../ssa/ssa.dart' show SsaFunctionCompiler;
import '../tracer.dart';
import '../tree/tree.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart';
import '../universe/use.dart' show StaticUse, TypeUse;
import '../universe/world_impact.dart'
    show
        ImpactStrategy,
        ImpactUseCase,
        WorldImpact,
        WorldImpactBuilder,
        WorldImpactVisitor;
import '../util/util.dart';
import '../world.dart' show ClosedWorld, ClosedWorldRefiner;
import 'annotations.dart';
import 'backend_helpers.dart';
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
import 'lookup_map_analysis.dart'
    show LookupMapLibraryAccess, LookupMapAnalysis;
import 'mirrors_analysis.dart';
import 'mirrors_data.dart';
import 'namer.dart';
import 'native_data.dart' show NativeData;
import 'no_such_method_registry.dart';
import 'patch_resolver.dart';
import 'resolution_listener.dart';
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

class JavaScriptBackend extends Target {
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

  final RuntimeTypesNeedBuilder _rtiNeedBuilder =
      new _RuntimeTypesNeedBuilder();
  RuntimeTypesNeed _rtiNeed;
  final _RuntimeTypes _rti;
  RuntimeTypesChecks _rtiChecks;

  RuntimeTypesEncoder _rtiEncoder;

  /// True if the html library has been loaded.
  bool htmlLibraryIsLoaded = false;

  /// Resolution analysis for tracking reflective access to type variables.
  TypeVariableAnalysis typeVariableAnalysis;

  /// Codegen handler for reflective access to type variables.
  TypeVariableHandler typeVariableHandler;

  /// Resolution and codegen support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsAnalysis customElementsAnalysis;

  /// Resolution support for tree-shaking entries of `LookupMap`.
  LookupMapLibraryAccess lookupMapLibraryAccess;

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
  final JavaScriptConstantTask constantCompilerTask;

  /// Backend transformation methods for the world impacts.
  JavaScriptImpactTransformer impactTransformer;

  PatchResolverTask patchResolverTask;

  /// The strategy used for collecting and emitting source information.
  SourceInformationStrategy sourceInformationStrategy;

  /// Interface for serialization of backend specific data.
  JavaScriptBackendSerialization serialization;

  final NativeData nativeData = new NativeData();
  InterceptorDataBuilder _interceptorDataBuilder;
  InterceptorData _interceptorData;
  OneShotInterceptorData _oneShotInterceptorData;
  BackendUsage _backendUsage;
  BackendUsageBuilder _backendUsageBuilder;
  MirrorsData mirrorsData;
  CheckedModeHelpers _checkedModeHelpers;

  ResolutionEnqueuerListener _resolutionEnqueuerListener;
  CodegenEnqueuerListener _codegenEnqueuerListener;

  BackendHelpers helpers;
  BackendImpacts impacts;

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
      : _rti = new _RuntimeTypes(compiler),
        annotations = new Annotations(compiler),
        this.sourceInformationStrategy = createSourceInformationStrategy(
            generateSourceMap: generateSourceMap,
            useMultiSourceInfo: useMultiSourceInfo,
            useNewSourceInfo: useNewSourceInfo),
        frontend = new JSFrontendAccess(compiler),
        constantCompilerTask = new JavaScriptConstantTask(compiler),
        this.compiler = compiler {
    helpers = new BackendHelpers(compiler.elementEnvironment, commonElements);
    impacts = new BackendImpacts(compiler.options, commonElements, helpers);
    backendClasses = new JavaScriptBackendClasses(
        compiler.elementEnvironment, helpers, nativeData);
    mirrorsData = new MirrorsData(
        compiler, compiler.options, commonElements, helpers, constants);
    _backendUsageBuilder = new BackendUsageBuilderImpl(
        compiler.elementEnvironment, commonElements, helpers);
    _checkedModeHelpers = new CheckedModeHelpers(commonElements, helpers);
    emitter =
        new CodeEmitterTask(compiler, generateSourceMap, useStartupEmitter);
    typeVariableAnalysis = new TypeVariableAnalysis(
        compiler.elementEnvironment, impacts, backendUsageBuilder);
    typeVariableHandler = new TypeVariableHandler(this, helpers, mirrorsData);
    customElementsAnalysis = new CustomElementsAnalysis(
        this,
        compiler.resolution,
        commonElements,
        backendClasses,
        helpers,
        nativeData,
        backendUsageBuilder);
    jsInteropAnalysis = new JsInteropAnalysis(this);
    mirrorsAnalysis = new MirrorsAnalysis(this, compiler.resolution);
    lookupMapLibraryAccess =
        new LookupMapLibraryAccess(reporter, compiler.elementEnvironment);
    lookupMapAnalysis = new LookupMapAnalysis(this, compiler.options, reporter,
        compiler.elementEnvironment, commonElements, backendClasses);

    noSuchMethodRegistry = new NoSuchMethodRegistry(this);
    kernelTask = new KernelTask(compiler);
    impactTransformer = new JavaScriptImpactTransformer(this);
    patchResolverTask = new PatchResolverTask(compiler);
    functionCompiler =
        new SsaFunctionCompiler(this, sourceInformationStrategy, useKernel);
    serialization = new JavaScriptBackendSerialization(nativeData);
    _interceptorDataBuilder =
        new InterceptorDataBuilderImpl(nativeData, helpers, commonElements);
    _resolutionEnqueuerListener = new ResolutionEnqueuerListener(
        this,
        compiler.options,
        compiler.elementEnvironment,
        commonElements,
        helpers,
        impacts,
        nativeData,
        _interceptorDataBuilder,
        _backendUsageBuilder,
        _rtiNeedBuilder,
        mirrorsData,
        noSuchMethodRegistry,
        customElementsAnalysis,
        lookupMapLibraryAccess,
        mirrorsAnalysis);
    _codegenEnqueuerListener = new CodegenEnqueuerListener(
        this,
        compiler.elementEnvironment,
        commonElements,
        helpers,
        impacts,
        mirrorsData,
        customElementsAnalysis,
        typeVariableHandler,
        lookupMapAnalysis,
        mirrorsAnalysis);
  }

  /// The [ConstantSystem] used to interpret compile-time constants for this
  /// backend.
  ConstantSystem get constantSystem => constants.constantSystem;

  DiagnosticReporter get reporter => compiler.reporter;

  CommonElements get commonElements => compiler.commonElements;

  Resolution get resolution => compiler.resolution;

  InterceptorData get interceptorData {
    assert(invariant(NO_LOCATION_SPANNABLE, _interceptorData != null,
        message: "InterceptorData has not been computed yet."));
    return _interceptorData;
  }

  OneShotInterceptorData get oneShotInterceptorData {
    assert(invariant(NO_LOCATION_SPANNABLE, _oneShotInterceptorData != null,
        message: "OneShotInterceptorData has not been prepared yet."));
    return _oneShotInterceptorData;
  }

  BackendUsage get backendUsage {
    assert(invariant(NO_LOCATION_SPANNABLE, _backendUsage != null,
        message: "BackendUsage has not been computed yet."));
    return _backendUsage;
  }

  BackendUsageBuilder get backendUsageBuilder {
    assert(invariant(NO_LOCATION_SPANNABLE, _backendUsage == null,
        message: "BackendUsage has already been computed."));
    return _backendUsageBuilder;
  }

  RuntimeTypesNeed get rtiNeed {
    assert(invariant(NO_LOCATION_SPANNABLE, _rtiNeed != null,
        message: "RuntimeTypesNeed has not been computed yet."));
    return _rtiNeed;
  }

  RuntimeTypesNeedBuilder get rtiNeedBuilder {
    assert(invariant(NO_LOCATION_SPANNABLE, _rtiNeed == null,
        message: "RuntimeTypesNeed has already been computed."));
    return _rtiNeedBuilder;
  }

  RuntimeTypesChecks get rtiChecks {
    assert(invariant(NO_LOCATION_SPANNABLE, _rtiChecks != null,
        message: "RuntimeTypesChecks has not been computed yet."));
    return _rtiChecks;
  }

  RuntimeTypesChecksBuilder get rtiChecksBuilder {
    assert(invariant(NO_LOCATION_SPANNABLE, _rtiChecks == null,
        message: "RuntimeTypesChecks has already been computed."));
    return _rti;
  }

  RuntimeTypesSubstitutions get rtiSubstitutions => _rti;

  RuntimeTypesEncoder get rtiEncoder {
    assert(invariant(NO_LOCATION_SPANNABLE, _rtiEncoder != null,
        message: "RuntimeTypesEncoder has not been created."));
    return _rtiEncoder;
  }

  CheckedModeHelpers get checkedModeHelpers => _checkedModeHelpers;

  EnqueuerListener get resolutionEnqueuerListener =>
      _resolutionEnqueuerListener;

  EnqueuerListener get codegenEnqueuerListener => _codegenEnqueuerListener;

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

  /// Called during codegen when [constant] has been used.
  void computeImpactForCompileTimeConstant(
      ConstantValue constant, WorldImpactBuilder impactBuilder,
      {bool forResolution}) {
    computeImpactForCompileTimeConstantInternal(constant, impactBuilder,
        forResolution: forResolution);

    if (!forResolution && lookupMapAnalysis.isLookupMap(constant)) {
      // Note: internally, this registration will temporarily remove the
      // constant dependencies and add them later on-demand.
      lookupMapAnalysis.registerLookupMapReference(constant);
    }

    for (ConstantValue dependency in constant.getDependencies()) {
      computeImpactForCompileTimeConstant(dependency, impactBuilder,
          forResolution: forResolution);
    }
  }

  void addCompileTimeConstantForEmission(ConstantValue constant) {
    constants.addCompileTimeConstantForEmission(constant);
  }

  void computeImpactForCompileTimeConstantInternal(
      ConstantValue constant, WorldImpactBuilder impactBuilder,
      {bool forResolution}) {
    ResolutionDartType type = constant.getType(compiler.commonElements);
    computeImpactForInstantiatedConstantType(type, impactBuilder,
        forResolution: forResolution);

    if (constant.isFunction) {
      FunctionConstantValue function = constant;
      impactBuilder
          .registerStaticUse(new StaticUse.staticTearOff(function.element));
    } else if (constant.isInterceptor) {
      // An interceptor constant references the class's prototype chain.
      InterceptorConstantValue interceptor = constant;
      ClassElement cls = interceptor.cls;
      computeImpactForInstantiatedConstantType(cls.thisType, impactBuilder,
          forResolution: forResolution);
    } else if (constant.isType) {
      if (forResolution) {
        MethodElement helper = helpers.createRuntimeType;
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            helper,
            null));
        backendUsageBuilder.registerBackendUse(helper);
      }
      impactBuilder
          .registerTypeUse(new TypeUse.instantiation(backendClasses.typeType));
    }
    if (!forResolution) lookupMapAnalysis.registerConstantKey(constant);
  }

  void computeImpactForInstantiatedConstantType(
      DartType type, WorldImpactBuilder impactBuilder,
      {bool forResolution}) {
    if (type is ResolutionInterfaceType) {
      impactBuilder.registerTypeUse(new TypeUse.instantiation(type));
      if (!forResolution && rtiNeed.classNeedsRtiField(type.element)) {
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

  void onResolutionComplete(
      ClosedWorld closedWorld, ClosedWorldRefiner closedWorldRefiner) {
    for (Entity entity in compiler.enqueuer.resolution.processedEntities) {
      processAnnotations(entity, closedWorldRefiner);
    }
    mirrorsData.computeMembersNeededForReflection(
        compiler.enqueuer.resolution.worldBuilder, closedWorld);
    _backendUsage = _backendUsageBuilder.close();
    _rtiNeed = rtiNeedBuilder.computeRuntimeTypesNeed(
        compiler.enqueuer.resolution.worldBuilder,
        closedWorld,
        compiler.types,
        commonElements,
        helpers,
        _backendUsage,
        enableTypeAssertions: compiler.options.enableTypeAssertions);
    _interceptorData =
        _interceptorDataBuilder.onResolutionComplete(closedWorld);
    _oneShotInterceptorData =
        new OneShotInterceptorData(interceptorData, helpers);
    mirrorsAnalysis.onResolutionComplete();
  }

  void onTypeInferenceComplete() {
    noSuchMethodRegistry.onTypeInferenceComplete();
  }

  /// Register a runtime type variable bound tests between [typeArgument] and
  /// [bound].
  void registerTypeVariableBoundsSubtypeCheck(
      ResolutionDartType typeArgument, ResolutionDartType bound) {
    rtiChecksBuilder.registerTypeVariableBoundsSubtypeCheck(
        typeArgument, bound);
  }

  /// Returns the [WorldImpact] of enabling deferred loading.
  WorldImpact computeDeferredLoadingImpact() {
    backendUsageBuilder.processBackendImpact(impacts.deferredLoading);
    return impacts.deferredLoading.createImpact(compiler.elementEnvironment);
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

  bool isComplexNoSuchMethod(FunctionElement element) =>
      noSuchMethodRegistry.isComplex(element);

  bool methodNeedsRti(FunctionElement function) {
    return rtiNeed.methodNeedsRti(function);
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
              initialValue, work.registry.worldImpact,
              forResolution: false);
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

  /// Called to finalize the [RuntimeTypesChecks] information.
  void finalizeRti() {
    _rtiChecks = rtiChecksBuilder.computeRequiredChecks();
  }

  /// Generates the output and returns the total size of the generated code.
  int assembleProgram(ClosedWorld closedWorld) {
    int programSize = emitter.assembleProgram(namer, closedWorld);
    noSuchMethodRegistry.emitDiagnostic();
    int totalMethodCount = generatedCode.length;
    if (totalMethodCount != mirrorsAnalysis.preMirrorsMethodCount) {
      int mirrorCount =
          totalMethodCount - mirrorsAnalysis.preMirrorsMethodCount;
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
    if (interceptorData.isInterceptedClass(classElement)) return false;
    return _closedWorld.hasOnlySubclasses(classElement);
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
    } else if (uri == LookupMapLibraryAccess.PACKAGE_LOOKUP_MAP) {
      lookupMapLibraryAccess.init(library);
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
    _rtiEncoder =
        _namer.rtiEncoder = new _RuntimeTypesEncoder(_namer, emitter, helpers);

    lookupMapAnalysis.onCodegenStart(lookupMapLibraryAccess);
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

  JavaScriptBackendClasses(this._env, this.helpers, this._nativeData);

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
