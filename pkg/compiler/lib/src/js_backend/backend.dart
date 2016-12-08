// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend;

import 'dart:async' show Future;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;

import '../closure.dart';
import '../common.dart';
import '../common/backend_api.dart'
    show
        Backend,
        BackendClasses,
        ImpactTransformer,
        ForeignResolver,
        NativeRegistry;
import '../common/codegen.dart' show CodegenImpact, CodegenWorkItem;
import '../common/names.dart' show Identifiers, Selectors, Uris;
import '../common/resolution.dart' show Frontend, Resolution, ResolutionImpact;
import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../core_types.dart' show CoreClasses, CoreTypes;
import '../dart_types.dart';
import '../deferred_load.dart' show DeferredLoadTask;
import '../dump_info.dart' show DumpInfoTask;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../enqueue.dart'
    show Enqueuer, ResolutionEnqueuer, TreeShakingEnqueuerStrategy;
import '../io/position_information.dart' show PositionSourceInformationStrategy;
import '../io/source_information.dart' show SourceInformationStrategy;
import '../io/start_end_information.dart'
    show StartEndSourceInformationStrategy;
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js/js_source_mapping.dart' show JavaScriptSourceInformationStrategy;
import '../js/rewrite_async.dart';
import '../js_emitter/js_emitter.dart' show CodeEmitterTask;
import '../library_loader.dart' show LibraryLoader, LoadedLibraries;
import '../native/native.dart' as native;
import '../ssa/ssa.dart' show SsaFunctionCompiler;
import '../tree/tree.dart';
import '../types/types.dart';
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
import '../world.dart' show ClosedWorld;
import 'backend_helpers.dart';
import 'backend_impact.dart';
import 'backend_serialization.dart' show JavaScriptBackendSerialization;
import 'checked_mode_helpers.dart';
import 'constant_handler_javascript.dart';
import 'custom_elements_analysis.dart';
import 'enqueuer.dart';
import 'js_interop_analysis.dart' show JsInteropAnalysis;
import '../kernel/task.dart';
import 'lookup_map_analysis.dart' show LookupMapAnalysis;
import 'mirrors_analysis.dart';
import 'namer.dart';
import 'native_data.dart' show NativeData;
import 'no_such_method_registry.dart';
import 'patch_resolver.dart';
import 'type_variable_handler.dart';

part 'runtime_types.dart';

const VERBOSE_OPTIMIZER_HINTS = false;

abstract class FunctionCompiler {
  /// Generates JavaScript code for `work.element`.
  jsAst.Fun compile(CodegenWorkItem work);

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

  final Map<FunctionElement, int> _cachedDecisions =
      new Map<FunctionElement, int>();

  /// Returns the current cache decision. This should only be used for testing.
  int getCurrentCacheDecisionForTesting(Element element) {
    return _cachedDecisions[element];
  }

  // Returns `true`/`false` if we have a cached decision.
  // Returns `null` otherwise.
  bool canInline(FunctionElement element, {bool insideLoop}) {
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

  void markAsInlinable(FunctionElement element, {bool insideLoop}) {
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

  void markAsNonInlinable(FunctionElement element, {bool insideLoop: true}) {
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

  void markAsMustInline(FunctionElement element) {
    _cachedDecisions[element] = _mustInline;
  }
}

enum SyntheticConstantKind {
  DUMMY_INTERCEPTOR,
  EMPTY_VALUE,
  TYPEVARIABLE_REFERENCE, // Reference to a type in reflection data.
  NAME
}

class JavaScriptBackend extends Backend {
  String get patchVersion => emitter.patchVersion;

  bool get supportsReflection => emitter.emitter.supportsReflection;

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
  Map<Element, jsAst.Expression> get generatedCode {
    return codegenEnqueuer.generatedCode;
  }

  FunctionInlineCache inlineCache = new FunctionInlineCache();

  /// If [true], the compiler will emit code that logs whenever a method is
  /// called. When TRACE_METHOD is 'console' this will be logged
  /// directly in the JavaScript console. When TRACE_METHOD is 'post' the
  /// information will be sent to a server via a POST request.
  static const String TRACE_METHOD = const String.fromEnvironment('traceCalls');
  static const bool TRACE_CALLS =
      TRACE_METHOD == 'post' || TRACE_METHOD == 'console';

  TypeMask get stringType => compiler.closedWorld.commonMasks.stringType;
  TypeMask get doubleType => compiler.closedWorld.commonMasks.doubleType;
  TypeMask get intType => compiler.closedWorld.commonMasks.intType;
  TypeMask get uint32Type => compiler.closedWorld.commonMasks.uint32Type;
  TypeMask get uint31Type => compiler.closedWorld.commonMasks.uint31Type;
  TypeMask get positiveIntType =>
      compiler.closedWorld.commonMasks.positiveIntType;
  TypeMask get numType => compiler.closedWorld.commonMasks.numType;
  TypeMask get boolType => compiler.closedWorld.commonMasks.boolType;
  TypeMask get dynamicType => compiler.closedWorld.commonMasks.dynamicType;
  TypeMask get nullType => compiler.closedWorld.commonMasks.nullType;
  TypeMask get emptyType => const TypeMask.nonNullEmpty();
  TypeMask get nonNullType => compiler.closedWorld.commonMasks.nonNullType;

  TypeMask _indexablePrimitiveTypeCache;
  TypeMask get indexablePrimitiveType {
    if (_indexablePrimitiveTypeCache == null) {
      _indexablePrimitiveTypeCache = new TypeMask.nonNullSubtype(
          helpers.jsIndexableClass, compiler.closedWorld);
    }
    return _indexablePrimitiveTypeCache;
  }

  TypeMask _readableArrayTypeCache;
  TypeMask get readableArrayType {
    if (_readableArrayTypeCache == null) {
      _readableArrayTypeCache = new TypeMask.nonNullSubclass(
          helpers.jsArrayClass, compiler.closedWorld);
    }
    return _readableArrayTypeCache;
  }

  TypeMask _mutableArrayTypeCache;
  TypeMask get mutableArrayType {
    if (_mutableArrayTypeCache == null) {
      _mutableArrayTypeCache = new TypeMask.nonNullSubclass(
          helpers.jsMutableArrayClass, compiler.closedWorld);
    }
    return _mutableArrayTypeCache;
  }

  TypeMask _fixedArrayTypeCache;
  TypeMask get fixedArrayType {
    if (_fixedArrayTypeCache == null) {
      _fixedArrayTypeCache = new TypeMask.nonNullExact(
          helpers.jsFixedArrayClass, compiler.closedWorld);
    }
    return _fixedArrayTypeCache;
  }

  TypeMask _extendableArrayTypeCache;
  TypeMask get extendableArrayType {
    if (_extendableArrayTypeCache == null) {
      _extendableArrayTypeCache = new TypeMask.nonNullExact(
          helpers.jsExtendableArrayClass, compiler.closedWorld);
    }
    return _extendableArrayTypeCache;
  }

  TypeMask _unmodifiableArrayTypeCache;
  TypeMask get unmodifiableArrayType {
    if (_unmodifiableArrayTypeCache == null) {
      _unmodifiableArrayTypeCache = new TypeMask.nonNullExact(
          helpers.jsUnmodifiableArrayClass, compiler.closedWorld);
    }
    return _fixedArrayTypeCache;
  }

  /// Maps special classes to their implementation (JSXxx) class.
  Map<ClassElement, ClassElement> implementationClasses;

  bool needToInitializeIsolateAffinityTag = false;
  bool needToInitializeDispatchProperty = false;

  final Namer namer;

  /**
   * A collection of selectors that must have a one shot interceptor
   * generated.
   */
  final Map<jsAst.Name, Selector> oneShotInterceptors;

  /**
   * The members of instantiated interceptor classes: maps a member name to the
   * list of members that have that name. This map is used by the codegen to
   * know whether a send must be intercepted or not.
   */
  final Map<String, Set<Element>> interceptedElements;

  /**
   * The members of mixin classes that are mixed into an instantiated
   * interceptor class.  This is a cached subset of [interceptedElements].
   *
   * Mixin methods are not specialized for the class they are mixed into.
   * Methods mixed into intercepted classes thus always make use of the explicit
   * receiver argument, even when mixed into non-interceptor classes.
   *
   * These members must be invoked with a correct explicit receiver even when
   * the receiver is not an intercepted class.
   */
  final Map<String, Set<Element>> interceptedMixinElements =
      new Map<String, Set<Element>>();

  /**
   * A map of specialized versions of the [getInterceptorMethod].
   * Since [getInterceptorMethod] is a hot method at runtime, we're
   * always specializing it based on the incoming type. The keys in
   * the map are the names of these specialized versions. Note that
   * the generic version that contains all possible type checks is
   * also stored in this map.
   */
  final Map<jsAst.Name, Set<ClassElement>> specializedGetInterceptors;

  /**
   * Set of classes whose methods are intercepted.
   */
  final Set<ClassElement> _interceptedClasses = new Set<ClassElement>();

  /**
   * Set of classes used as mixins on intercepted (native and primitive)
   * classes.  Methods on these classes might also be mixed in to regular Dart
   * (unintercepted) classes.
   */
  final Set<ClassElement> classesMixedIntoInterceptedClasses =
      new Set<ClassElement>();

  /**
   * Set of classes whose `operator ==` methods handle `null` themselves.
   */
  final Set<ClassElement> specialOperatorEqClasses = new Set<ClassElement>();

  /**
   * A set of members that are called from subclasses via `super`.
   */
  final Set<FunctionElement> aliasedSuperMembers =
      new Setlet<FunctionElement>();

  List<CompilerTask> get tasks {
    List<CompilerTask> result = functionCompiler.tasks;
    result.add(emitter);
    result.add(patchResolverTask);
    result.add(kernelTask);
    return result;
  }

  final RuntimeTypes rti;
  final RuntimeTypesEncoder rtiEncoder;

  /// True if a call to preserveMetadataMarker has been seen.  This means that
  /// metadata must be retained for dart:mirrors to work correctly.
  bool mustRetainMetadata = false;

  /// True if any metadata has been retained.  This is slightly different from
  /// [mustRetainMetadata] and tells us if any metadata was retained.  For
  /// example, if [mustRetainMetadata] is true but there is no metadata in the
  /// program, this variable will stil be false.
  bool hasRetainedMetadata = false;

  /// True if a call to preserveUris has been seen and the preserve-uris flag
  /// is set.
  bool mustPreserveUris = false;

  /// True if a call to preserveLibraryNames has been seen.
  bool mustRetainLibraryNames = false;

  /// True if a call to preserveNames has been seen.
  bool mustPreserveNames = false;

  /// True if a call to disableTreeShaking has been seen.
  bool isTreeShakingDisabled = false;

  /// True if there isn't sufficient @MirrorsUsed data.
  bool hasInsufficientMirrorsUsed = false;

  /// True if a core-library function requires the preamble file to function.
  bool requiresPreamble = false;

  /// True if the html library has been loaded.
  bool htmlLibraryIsLoaded = false;

  /// True when we enqueue the loadLibrary code.
  bool isLoadLibraryFunctionResolved = false;

  /// `true` if access to [BackendHelpers.invokeOnMethod] is supported.
  bool hasInvokeOnSupport = false;

  /// `true` if tear-offs are supported for incremental compilation.
  bool hasIncrementalTearOffSupport = false;

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

  /// List of elements that the user has requested for reflection.
  final Set<Element> targetsUsed = new Set<Element>();

  /// List of annotations provided by user that indicate that the annotated
  /// element must be retained.
  final Set<Element> metaTargetsUsed = new Set<Element>();

  /// Set of methods that are needed by reflection. Computed using
  /// [computeMembersNeededForReflection] on first use.
  Set<Element> _membersNeededForReflection = null;
  Iterable<Element> get membersNeededForReflection {
    assert(_membersNeededForReflection != null);
    return _membersNeededForReflection;
  }

  /// List of symbols that the user has requested for reflection.
  final Set<String> symbolsUsed = new Set<String>();

  /// List of elements that the backend may use.
  final Set<Element> helpersUsed = new Set<Element>();

  /// All the checked mode helpers.
  static const checkedModeHelpers = CheckedModeHelper.helpers;

  // Checked mode helpers indexed by name.
  Map<String, CheckedModeHelper> checkedModeHelperByName =
      new Map<String, CheckedModeHelper>.fromIterable(checkedModeHelpers,
          key: (helper) => helper.name);

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

  JavaScriptConstantTask constantCompilerTask;

  JavaScriptImpactTransformer impactTransformer;

  PatchResolverTask patchResolverTask;

  bool enabledNoSuchMethod = false;

  SourceInformationStrategy sourceInformationStrategy;

  JavaScriptBackendSerialization serialization;

  StagedWorldImpactBuilder constantImpactsForResolution =
      new StagedWorldImpactBuilder();

  StagedWorldImpactBuilder constantImpactsForCodegen =
      new StagedWorldImpactBuilder();

  final NativeData nativeData = new NativeData();

  final BackendHelpers helpers;
  final BackendImpacts impacts;
  BackendClasses backendClasses;

  final JSFrontendAccess frontend;

  JavaScriptBackend(Compiler compiler,
      {bool generateSourceMap: true,
      bool useStartupEmitter: false,
      bool useNewSourceInfo: false,
      bool useKernel: false})
      : namer = determineNamer(compiler),
        oneShotInterceptors = new Map<jsAst.Name, Selector>(),
        interceptedElements = new Map<String, Set<Element>>(),
        rti = new _RuntimeTypes(compiler),
        rtiEncoder = new _RuntimeTypesEncoder(compiler),
        specializedGetInterceptors = new Map<jsAst.Name, Set<ClassElement>>(),
        annotations = new Annotations(compiler),
        this.sourceInformationStrategy = generateSourceMap
            ? (useNewSourceInfo
                ? new PositionSourceInformationStrategy()
                : const StartEndSourceInformationStrategy())
            : const JavaScriptSourceInformationStrategy(),
        helpers = new BackendHelpers(compiler),
        impacts = new BackendImpacts(compiler),
        frontend = new JSFrontendAccess(compiler),
        super(compiler) {
    emitter = new CodeEmitterTask(
        compiler, namer, generateSourceMap, useStartupEmitter);
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
    backendClasses = new JavaScriptBackendClasses(helpers);
  }

  ConstantSystem get constantSystem => constants.constantSystem;

  DiagnosticReporter get reporter => compiler.reporter;

  CoreClasses get coreClasses => compiler.coreClasses;

  CoreTypes get coreTypes => compiler.coreTypes;

  Resolution get resolution => compiler.resolution;

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

  static Namer determineNamer(Compiler compiler) {
    return compiler.options.enableMinification
        ? compiler.options.useFrequencyNamer
            ? new FrequencyBasedNamer(compiler)
            : new MinifyNamer(compiler)
        : new Namer(compiler);
  }

  /// The backend must *always* call this method when enqueuing an
  /// element. Calls done by the backend are not seen by global
  /// optimizations, so they would make these optimizations unsound.
  /// Therefore we need to collect the list of helpers the backend may
  /// use.
  // TODO(johnniwinther): Replace this with a more precise modelling; type
  // inference of these elements is disabled.
  Element registerBackendUse(Element element) {
    if (element == null) return null;
    assert(invariant(element, _isValidBackendUse(element),
        message: "Backend use of $element is not allowed."));
    helpersUsed.add(element.declaration);
    if (element.isClass && element.isPatched) {
      // Both declaration and implementation may declare fields, so we
      // add both to the list of helpers.
      helpersUsed.add(element.implementation);
    }
    return element;
  }

  bool _isValidBackendUse(Element element) {
    assert(invariant(element, element.isDeclaration, message: ""));
    if (element == helpers.streamIteratorConstructor ||
        compiler.commonElements.isSymbolConstructor(element) ||
        helpers.isSymbolValidatedConstructor(element) ||
        element == helpers.syncCompleterConstructor ||
        element == coreClasses.symbolClass ||
        element == helpers.objectNoSuchMethod) {
      // TODO(johnniwinther): These are valid but we could be more precise.
      return true;
    } else if (element.implementationLibrary.isPatch ||
        // Needed to detect deserialized injected elements, that is
        // element declared in patch files.
        (element.library.isPlatformLibrary &&
            element.sourcePosition.uri.path
                .contains('_internal/js_runtime/lib/')) ||
        element.library == helpers.jsHelperLibrary ||
        element.library == helpers.interceptorsLibrary ||
        element.library == helpers.isolateHelperLibrary) {
      // TODO(johnniwinther): We should be more precise about these.
      return true;
    } else if (element == coreClasses.listClass ||
        element == helpers.mapLiteralClass ||
        element == coreClasses.functionClass ||
        element == coreClasses.stringClass) {
      // TODO(johnniwinther): Avoid these.
      return true;
    } else if (element == helpers.genericNoSuchMethod ||
        element == helpers.unresolvedConstructorError ||
        element == helpers.malformedTypeError) {
      return true;
    }
    return false;
  }

  bool usedByBackend(Element element) {
    if (element.isRegularParameter ||
        element.isInitializingFormal ||
        element.isField) {
      if (usedByBackend(element.enclosingElement)) return true;
    }
    return helpersUsed.contains(element.declaration);
  }

  bool invokedReflectively(Element element) {
    if (element.isRegularParameter || element.isInitializingFormal) {
      ParameterElement parameter = element;
      if (invokedReflectively(parameter.functionDeclaration)) return true;
    }

    if (element.isField) {
      if (Elements.isStaticOrTopLevel(element) &&
          (element.isFinal || element.isConst)) {
        return false;
      }
    }

    return isAccessibleByReflection(element.declaration);
  }

  bool canBeUsedForGlobalOptimizations(Element element) {
    return !usedByBackend(element) && !invokedReflectively(element);
  }

  bool isInterceptorClass(ClassElement element) {
    if (element == null) return false;
    if (isNativeOrExtendsNative(element)) return true;
    if (interceptedClasses.contains(element)) return true;
    if (classesMixedIntoInterceptedClasses.contains(element)) return true;
    return false;
  }

  jsAst.Name registerOneShotInterceptor(Selector selector) {
    Set<ClassElement> classes = getInterceptedClassesOn(selector.name);
    jsAst.Name name = namer.nameForGetOneShotInterceptor(selector, classes);
    if (!oneShotInterceptors.containsKey(name)) {
      registerSpecializedGetInterceptor(classes);
      oneShotInterceptors[name] = selector;
    }
    return name;
  }

  /**
   * Record that [method] is called from a subclass via `super`.
   */
  bool maybeRegisterAliasedSuperMember(Element member, Selector selector) {
    if (!canUseAliasedSuperMember(member, selector)) {
      // Invoking a super getter isn't supported, this would require changes to
      // compact field descriptors in the emitter.
      // We also turn off this optimization in incremental compilation, to
      // avoid having to regenerate a method just because someone started
      // calling it through super.
      return false;
    }
    aliasedSuperMembers.add(member);
    return true;
  }

  bool canUseAliasedSuperMember(Element member, Selector selector) {
    return !selector.isGetter && !compiler.options.hasIncrementalSupport;
  }

  /**
   * Returns `true` if [member] is called from a subclass via `super`.
   */
  bool isAliasedSuperMember(FunctionElement member) {
    return aliasedSuperMembers.contains(member);
  }

  /// Returns `true` if [element] is part of JsInterop.
  @override
  bool isJsInterop(Element element) => nativeData.isJsInterop(element);

  /// Whether [element] corresponds to a native JavaScript construct either
  /// through the native mechanism (`@Native(...)` or the `native` pseudo
  /// keyword) which is only allowed for internal libraries or via the typed
  /// JavaScriptInterop mechanism which is allowed for user libraries.
  @override
  bool isNative(Element element) => nativeData.isNative(element);

  /// Returns the [NativeBehavior] for calling the native [method].
  native.NativeBehavior getNativeMethodBehavior(FunctionElement method) {
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
        native.NativeBehavior fieldStoreBehavior = native.NativeBehavior
            .ofFieldElementStore(element, compiler.resolution);
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

  bool isNativeOrExtendsNative(ClassElement element) {
    if (element == null) return false;
    if (isNative(element) || isJsInterop(element)) {
      return true;
    }
    assert(element.isResolved);
    return isNativeOrExtendsNative(element.superclass);
  }

  bool isInterceptedMethod(Element element) {
    if (!element.isInstanceMember) return false;
    if (element.isGenerativeConstructorBody) {
      return isNativeOrExtendsNative(element.enclosingClass);
    }
    return interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedGetter(Element element) {
    assert(element.isField);
    return interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedSetter(Element element) {
    assert(element.isField);
    return interceptedElements[element.name] != null;
  }

  bool isInterceptedName(String name) {
    return interceptedElements[name] != null;
  }

  bool isInterceptedSelector(Selector selector) {
    return interceptedElements[selector.name] != null;
  }

  /**
   * Returns `true` iff [selector] matches an element defined in a class mixed
   * into an intercepted class.  These selectors are not eligible for the 'dummy
   * explicit receiver' optimization.
   */
  bool isInterceptedMixinSelector(Selector selector, TypeMask mask) {
    Set<Element> elements =
        interceptedMixinElements.putIfAbsent(selector.name, () {
      Set<Element> elements = interceptedElements[selector.name];
      if (elements == null) return null;
      return elements
          .where((element) => classesMixedIntoInterceptedClasses
              .contains(element.enclosingClass))
          .toSet();
    });

    if (elements == null) return false;
    if (elements.isEmpty) return false;
    return elements.any((element) {
      return selector.applies(element) &&
          (mask == null ||
              mask.canHit(element, selector, compiler.closedWorld));
    });
  }

  /// True if the given class is an internal class used for type inference
  /// and never exists at runtime.
  bool isCompileTimeOnlyClass(ClassElement class_) {
    return class_ == helpers.jsPositiveIntClass ||
        class_ == helpers.jsUInt32Class ||
        class_ == helpers.jsUInt31Class ||
        class_ == helpers.jsFixedArrayClass ||
        class_ == helpers.jsUnmodifiableArrayClass ||
        class_ == helpers.jsMutableArrayClass ||
        class_ == helpers.jsExtendableArrayClass;
  }

  /// Maps compile-time classes to their runtime class.  The runtime class is
  /// always a superclass or the class itself.
  ClassElement getRuntimeClass(ClassElement class_) {
    if (class_.isSubclassOf(helpers.jsIntClass)) return helpers.jsIntClass;
    if (class_.isSubclassOf(helpers.jsArrayClass)) return helpers.jsArrayClass;
    return class_;
  }

  final Map<String, Set<ClassElement>> interceptedClassesCache =
      new Map<String, Set<ClassElement>>();
  final Set<ClassElement> _noClasses = new Set<ClassElement>();

  /// Returns a set of interceptor classes that contain a member named [name]
  ///
  /// Returns an empty set if there is no class. Do not modify the returned set.
  Set<ClassElement> getInterceptedClassesOn(String name) {
    Set<Element> intercepted = interceptedElements[name];
    if (intercepted == null) return _noClasses;
    return interceptedClassesCache.putIfAbsent(name, () {
      // Populate the cache by running through all the elements and
      // determine if the given selector applies to them.
      Set<ClassElement> result = new Set<ClassElement>();
      for (Element element in intercepted) {
        ClassElement classElement = element.enclosingClass;
        if (isCompileTimeOnlyClass(classElement)) continue;
        if (isNativeOrExtendsNative(classElement) ||
            interceptedClasses.contains(classElement)) {
          result.add(classElement);
        }
        if (classesMixedIntoInterceptedClasses.contains(classElement)) {
          Set<ClassElement> nativeSubclasses =
              nativeSubclassesOfMixin(classElement);
          if (nativeSubclasses != null) result.addAll(nativeSubclasses);
        }
      }
      return result;
    });
  }

  Set<ClassElement> nativeSubclassesOfMixin(ClassElement mixin) {
    ClosedWorld closedWorld = compiler.closedWorld;
    Iterable<MixinApplicationElement> uses = closedWorld.mixinUsesOf(mixin);
    Set<ClassElement> result = null;
    for (MixinApplicationElement use in uses) {
      closedWorld.forEachStrictSubclassOf(use, (ClassElement subclass) {
        if (isNativeOrExtendsNative(subclass)) {
          if (result == null) result = new Set<ClassElement>();
          result.add(subclass);
        }
      });
    }
    return result;
  }

  bool operatorEqHandlesNullArgument(FunctionElement operatorEqfunction) {
    return specialOperatorEqClasses.contains(operatorEqfunction.enclosingClass);
  }

  void validateInterceptorImplementsAllObjectMethods(
      ClassElement interceptorClass) {
    if (interceptorClass == null) return;
    interceptorClass.ensureResolved(resolution);
    coreClasses.objectClass.forEachMember((_, Element member) {
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
      cls.forEachMember((ClassElement classElement, Element member) {
        if (member.name == Identifiers.call) {
          return;
        }
        if (member.isSynthesized) return;
        // All methods on [Object] are shadowed by [Interceptor].
        if (classElement == coreClasses.objectClass) return;
        Set<Element> set = interceptedElements.putIfAbsent(
            member.name, () => new Set<Element>());
        set.add(member);
      }, includeSuperAndInjectedMembers: true);

      // Walk superclass chain to find mixins.
      for (; cls != null; cls = cls.superclass) {
        if (cls.isMixinApplication) {
          MixinApplicationElement mixinApplication = cls;
          classesMixedIntoInterceptedClasses.add(mixinApplication.mixin);
        }
      }
    }
  }

  void addInterceptors(ClassElement cls, WorldImpactBuilder impactBuilder,
      {bool forResolution}) {
    if (forResolution) {
      if (_interceptedClasses.add(cls)) {
        cls.ensureResolved(resolution);
        cls.forEachMember((ClassElement classElement, Element member) {
          // All methods on [Object] are shadowed by [Interceptor].
          if (classElement == coreClasses.objectClass) return;
          Set<Element> set = interceptedElements.putIfAbsent(
              member.name, () => new Set<Element>());
          set.add(member);
        }, includeSuperAndInjectedMembers: true);
      }
      _interceptedClasses.add(helpers.jsInterceptorClass);
    }
    impactTransformer.registerBackendInstantiation(impactBuilder, cls);
  }

  Set<ClassElement> get interceptedClasses {
    assert(compiler.enqueuer.resolution.queueIsClosed);
    return _interceptedClasses;
  }

  void registerSpecializedGetInterceptor(Set<ClassElement> classes) {
    jsAst.Name name = namer.nameForGetInterceptor(classes);
    if (classes.contains(helpers.jsInterceptorClass)) {
      // We can't use a specialized [getInterceptorMethod], so we make
      // sure we emit the one with all checks.
      specializedGetInterceptors[name] = interceptedClasses;
    } else {
      specializedGetInterceptors[name] = classes;
    }
  }

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
    DartType type = constant.getType(compiler.coreTypes);
    computeImpactForInstantiatedConstantType(type, impactBuilder);

    if (constant.isFunction) {
      FunctionConstantValue function = constant;
      impactBuilder
          .registerStaticUse(new StaticUse.staticTearOff(function.element));
    } else if (constant.isInterceptor) {
      // An interceptor constant references the class's prototype chain.
      InterceptorConstantValue interceptor = constant;
      computeImpactForInstantiatedConstantType(
          interceptor.dispatchedType, impactBuilder);
    } else if (constant.isType) {
      if (isForResolution) {
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            helpers.createRuntimeType,
            null));
        registerBackendUse(helpers.createRuntimeType);
      }
      impactBuilder.registerTypeUse(
          new TypeUse.instantiation(backendClasses.typeImplementation.rawType));
    }
    lookupMapAnalysis.registerConstantKey(constant);
  }

  void computeImpactForInstantiatedConstantType(
      DartType type, WorldImpactBuilder impactBuilder) {
    DartType instantiatedType =
        type.isFunctionType ? coreTypes.functionType : type;
    if (type is InterfaceType) {
      impactBuilder
          .registerTypeUse(new TypeUse.instantiation(instantiatedType));
      if (classNeedsRtiField(type.element)) {
        impactBuilder.registerStaticUse(new StaticUse.staticInvoke(
            // TODO(johnniwinther): Find the right [CallStructure].
            helpers.setRuntimeTypeInfo,
            null));
      }
      if (type.element == backendClasses.typeImplementation) {
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
      if (cls == coreClasses.intClass ||
          cls == coreClasses.doubleClass ||
          cls == coreClasses.numClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.numClasses);
      } else if (cls == coreClasses.listClass ||
          cls == coreClasses.stringClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.listOrStringClasses);
      } else if (cls == coreClasses.functionClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.functionClass);
      } else if (cls == coreClasses.mapClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.mapClass);
        // For map literals, the dependency between the implementation class
        // and [Map] is not visible, so we have to add it manually.
        rti.registerRtiDependency(helpers.mapLiteralClass, cls);
      } else if (cls == helpers.boundClosureClass) {
        impactTransformer.registerBackendImpact(
            impactBuilder, impacts.boundClosureClass);
      } else if (isNativeOrExtendsNative(cls)) {
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
    if (cls == coreClasses.stringClass || cls == helpers.jsStringClass) {
      addInterceptors(helpers.jsStringClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == coreClasses.listClass ||
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
    } else if (cls == coreClasses.intClass || cls == helpers.jsIntClass) {
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
    } else if (cls == coreClasses.doubleClass || cls == helpers.jsDoubleClass) {
      addInterceptors(helpers.jsDoubleClass, impactBuilder,
          forResolution: forResolution);
      addInterceptors(helpers.jsNumberClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == coreClasses.boolClass || cls == helpers.jsBoolClass) {
      addInterceptors(helpers.jsBoolClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == coreClasses.nullClass || cls == helpers.jsNullClass) {
      addInterceptors(helpers.jsNullClass, impactBuilder,
          forResolution: forResolution);
    } else if (cls == coreClasses.numClass || cls == helpers.jsNumberClass) {
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
    } else if (isNativeOrExtendsNative(cls)) {
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

  void registerInstantiatedType(InterfaceType type) {
    lookupMapAnalysis.registerInstantiatedType(type);
  }

  @override
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

  onResolutionComplete() {
    compiler.enqueuer.resolution.processedEntities.forEach(processAnnotations);
    super.onResolutionComplete();
    computeMembersNeededForReflection();
    rti.computeClassesNeedingRti();
    _registeredMetadata.clear();
  }

  onTypeInferenceComplete() {
    super.onTypeInferenceComplete();
    noSuchMethodRegistry.onTypeInferenceComplete();
  }

  WorldImpact registerCallMethodWithFreeTypeVariables(Element callMethod,
      {bool forResolution}) {
    if (forResolution || methodNeedsRti(callMethod)) {
      return _registerComputeSignature();
    }
    return const WorldImpact();
  }

  WorldImpact registerClosureWithFreeTypeVariables(Element closure,
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

  void registerTypeVariableBoundsSubtypeCheck(
      DartType typeArgument, DartType bound) {
    rti.registerTypeVariableBoundsSubtypeCheck(typeArgument, bound);
  }

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
          if (typeConstant.type is InterfaceType) {
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

  WorldImpact enableNoSuchMethod() {
    return impactTransformer.createImpactFor(impacts.noSuchMethodSupport);
  }

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

  bool isDefaultEqualityImplementation(Element element) {
    assert(element.name == '==');
    ClassElement classElement = element.enclosingClass;
    return classElement == coreClasses.objectClass ||
        classElement == helpers.jsInterceptorClass ||
        classElement == helpers.jsNullClass;
  }

  bool methodNeedsRti(FunctionElement function) {
    return rti.methodsNeedingRti.contains(function) || hasRuntimeTypeSupport;
  }

  CodegenEnqueuer get codegenEnqueuer => compiler.enqueuer.codegen;

  CodegenEnqueuer createCodegenEnqueuer(CompilerTask task, Compiler compiler) {
    return new CodegenEnqueuer(
        task, compiler, const TreeShakingEnqueuerStrategy());
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

    jsAst.Fun function = functionCompiler.compile(work);
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
        : coreClasses.objectClass;
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

  int assembleProgram() {
    int programSize = emitter.assembleProgram();
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

  /**
   * Returns the checked mode helper that will be needed to do a type check/type
   * cast on [type] at runtime. Note that this method is being called both by
   * the resolver with interface types (int, String, ...), and by the SSA
   * backend with implementation types (JSInt, JSString, ...).
   */
  CheckedModeHelper getCheckedModeHelper(DartType type, {bool typeCast}) {
    return getCheckedModeHelperInternal(type,
        typeCast: typeCast, nativeCheckOnly: false);
  }

  /**
   * Returns the native checked mode helper that will be needed to do a type
   * check/type cast on [type] at runtime. If no native helper exists for
   * [type], [:null:] is returned.
   */
  CheckedModeHelper getNativeCheckedModeHelper(DartType type, {bool typeCast}) {
    return getCheckedModeHelperInternal(type,
        typeCast: typeCast, nativeCheckOnly: true);
  }

  /**
   * Returns the checked mode helper for the type check/type cast for [type]. If
   * [nativeCheckOnly] is [:true:], only names for native helpers are returned.
   */
  CheckedModeHelper getCheckedModeHelperInternal(DartType type,
      {bool typeCast, bool nativeCheckOnly}) {
    String name = getCheckedModeHelperNameInternal(type,
        typeCast: typeCast, nativeCheckOnly: nativeCheckOnly);
    if (name == null) return null;
    CheckedModeHelper helper = checkedModeHelperByName[name];
    assert(helper != null);
    return helper;
  }

  String getCheckedModeHelperNameInternal(DartType type,
      {bool typeCast, bool nativeCheckOnly}) {
    assert(type.kind != TypeKind.TYPEDEF);
    if (type.isMalformed) {
      // The same error is thrown for type test and type cast of a malformed
      // type so we only need one check method.
      return 'checkMalformedType';
    }
    Element element = type.element;
    bool nativeCheck =
        nativeCheckOnly || emitter.nativeEmitter.requiresNativeIsCheck(element);

    // TODO(13955), TODO(9731).  The test for non-primitive types should use an
    // interceptor.  The interceptor should be an argument to HTypeConversion so
    // that it can be optimized by standard interceptor optimizations.
    nativeCheck = true;

    if (type.isVoid) {
      assert(!typeCast); // Cannot cast to void.
      if (nativeCheckOnly) return null;
      return 'voidTypeCheck';
    } else if (element == helpers.jsStringClass ||
        element == coreClasses.stringClass) {
      if (nativeCheckOnly) return null;
      return typeCast ? 'stringTypeCast' : 'stringTypeCheck';
    } else if (element == helpers.jsDoubleClass ||
        element == coreClasses.doubleClass) {
      if (nativeCheckOnly) return null;
      return typeCast ? 'doubleTypeCast' : 'doubleTypeCheck';
    } else if (element == helpers.jsNumberClass ||
        element == coreClasses.numClass) {
      if (nativeCheckOnly) return null;
      return typeCast ? 'numTypeCast' : 'numTypeCheck';
    } else if (element == helpers.jsBoolClass ||
        element == coreClasses.boolClass) {
      if (nativeCheckOnly) return null;
      return typeCast ? 'boolTypeCast' : 'boolTypeCheck';
    } else if (element == helpers.jsIntClass ||
        element == coreClasses.intClass ||
        element == helpers.jsUInt32Class ||
        element == helpers.jsUInt31Class ||
        element == helpers.jsPositiveIntClass) {
      if (nativeCheckOnly) return null;
      return typeCast ? 'intTypeCast' : 'intTypeCheck';
    } else if (Elements.isNumberOrStringSupertype(element, compiler)) {
      if (nativeCheck) {
        return typeCast
            ? 'numberOrStringSuperNativeTypeCast'
            : 'numberOrStringSuperNativeTypeCheck';
      } else {
        return typeCast
            ? 'numberOrStringSuperTypeCast'
            : 'numberOrStringSuperTypeCheck';
      }
    } else if (Elements.isStringOnlySupertype(element, compiler)) {
      if (nativeCheck) {
        return typeCast
            ? 'stringSuperNativeTypeCast'
            : 'stringSuperNativeTypeCheck';
      } else {
        return typeCast ? 'stringSuperTypeCast' : 'stringSuperTypeCheck';
      }
    } else if ((element == coreClasses.listClass ||
            element == helpers.jsArrayClass) &&
        type.treatAsRaw) {
      if (nativeCheckOnly) return null;
      return typeCast ? 'listTypeCast' : 'listTypeCheck';
    } else {
      if (Elements.isListSupertype(element, compiler)) {
        if (nativeCheck) {
          return typeCast
              ? 'listSuperNativeTypeCast'
              : 'listSuperNativeTypeCheck';
        } else {
          return typeCast ? 'listSuperTypeCast' : 'listSuperTypeCheck';
        }
      } else {
        if (type.isInterfaceType && !type.treatAsRaw) {
          return typeCast ? 'subtypeCast' : 'assertSubtype';
        } else if (type.isTypeVariable) {
          return typeCast
              ? 'subtypeOfRuntimeTypeCast'
              : 'assertSubtypeOfRuntimeType';
        } else if (type.isFunctionType) {
          return null;
        } else {
          if (nativeCheck) {
            // TODO(karlklose): can we get rid of this branch when we use
            // interceptors?
            return typeCast ? 'interceptedTypeCast' : 'interceptedTypeCheck';
          } else {
            return typeCast ? 'propertyTypeCast' : 'propertyTypeCheck';
          }
        }
      }
    }
  }

  void _registerCheckedModeHelpers(WorldImpactBuilder impactBuilder) {
    // We register all the helpers in the resolution queue.
    // TODO(13155): Find a way to register fewer helpers.
    List<Element> staticUses = <Element>[];
    for (CheckedModeHelper helper in checkedModeHelpers) {
      staticUses.add(helper.getStaticUse(compiler).element);
    }
    impactTransformer.registerBackendImpact(
        impactBuilder, new BackendImpact(globalUses: staticUses));
  }

  /**
   * Returns [:true:] if the checking of [type] is performed directly on the
   * object and not on an interceptor.
   */
  bool hasDirectCheckFor(DartType type) {
    Element element = type.element;
    return element == coreClasses.stringClass ||
        element == coreClasses.boolClass ||
        element == coreClasses.numClass ||
        element == coreClasses.intClass ||
        element == coreClasses.doubleClass ||
        element == helpers.jsArrayClass ||
        element == helpers.jsMutableArrayClass ||
        element == helpers.jsExtendableArrayClass ||
        element == helpers.jsFixedArrayClass ||
        element == helpers.jsUnmodifiableArrayClass;
  }

  bool mayGenerateInstanceofCheck(DartType type) {
    // We can use an instanceof check for raw types that have no subclass that
    // is mixed-in or in an implements clause.

    if (!type.isRaw) return false;
    ClassElement classElement = type.element;
    if (isInterceptorClass(classElement)) return false;
    return compiler.closedWorld.hasOnlySubclasses(classElement);
  }

  WorldImpact registerUsedElement(Element element, {bool forResolution}) {
    WorldImpactBuilderImpl worldImpact = new WorldImpactBuilderImpl();
    if (element == helpers.disableTreeShakingMarker) {
      isTreeShakingDisabled = true;
    } else if (element == helpers.preserveNamesMarker) {
      mustPreserveNames = true;
    } else if (element == helpers.preserveMetadataMarker) {
      mustRetainMetadata = true;
    } else if (element == helpers.preserveUrisMarker) {
      if (compiler.options.preserveUris) mustPreserveUris = true;
    } else if (element == helpers.preserveLibraryNamesMarker) {
      mustRetainLibraryNames = true;
    } else if (element == helpers.getIsolateAffinityTagMarker) {
      needToInitializeIsolateAffinityTag = true;
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

    if (forResolution) {
      if (element.isFunction && element.isInstanceMember) {
        MemberElement function = element;
        ClassElement cls = function.enclosingClass;
        if (function.name == Identifiers.call && !cls.typeVariables.isEmpty) {
          worldImpact.addImpact(registerCallMethodWithFreeTypeVariables(
              function,
              forResolution: true));
        }
      }
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
    }
    return worldImpact;
  }

  /// Called when [:const Symbol(name):] is seen.
  void registerConstSymbol(String name) {
    symbolsUsed.add(name);
    if (name.endsWith('=')) {
      symbolsUsed.add(name.substring(0, name.length - 1));
    }
  }

  /// Should [element] (a getter) that would normally not be generated due to
  /// treeshaking be retained for reflection?
  bool shouldRetainGetter(Element element) {
    return isTreeShakingDisabled && isAccessibleByReflection(element);
  }

  /// Should [element] (a setter) hat would normally not be generated due to
  /// treeshaking be retained for reflection?
  bool shouldRetainSetter(Element element) {
    return isTreeShakingDisabled && isAccessibleByReflection(element);
  }

  /// Should [name] be retained for reflection?
  bool shouldRetainName(String name) {
    if (hasInsufficientMirrorsUsed) return mustPreserveNames;
    if (name == '') return false;
    return symbolsUsed.contains(name);
  }

  bool retainMetadataOf(Element element) {
    if (mustRetainMetadata) hasRetainedMetadata = true;
    if (mustRetainMetadata && referencedFromMirrorSystem(element)) {
      for (MetadataAnnotation metadata in element.metadata) {
        metadata.ensureResolved(resolution);
        ConstantValue constant =
            constants.getConstantValueForMetadata(metadata);
        constants.addCompileTimeConstantForEmission(constant);
      }
      return true;
    }
    return false;
  }

  void onLibraryCreated(LibraryElement library) {
    helpers.onLibraryCreated(library);
  }

  Future onLibraryScanned(LibraryElement library, LibraryLoader loader) {
    return super.onLibraryScanned(library, loader).then((_) {
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
    }).then((_) {
      helpers.onLibraryScanned(library);
      Uri uri = library.canonicalUri;
      if (uri == Uris.dart_html) {
        htmlLibraryIsLoaded = true;
      } else if (uri == LookupMapAnalysis.PACKAGE_LOOKUP_MAP) {
        lookupMapAnalysis.init(library);
      }
      annotations.onLibraryScanned(library);
    });
  }

  Future onLibrariesLoaded(LoadedLibraries loadedLibraries) {
    if (!loadedLibraries.containsLibrary(Uris.dart_core)) {
      return new Future.value();
    }

    helpers.onLibrariesLoaded(loadedLibraries);

    implementationClasses = <ClassElement, ClassElement>{};
    implementationClasses[coreClasses.intClass] = helpers.jsIntClass;
    implementationClasses[coreClasses.boolClass] = helpers.jsBoolClass;
    implementationClasses[coreClasses.numClass] = helpers.jsNumberClass;
    implementationClasses[coreClasses.doubleClass] = helpers.jsDoubleClass;
    implementationClasses[coreClasses.stringClass] = helpers.jsStringClass;
    implementationClasses[coreClasses.listClass] = helpers.jsArrayClass;
    implementationClasses[coreClasses.nullClass] = helpers.jsNullClass;

    // These methods are overwritten with generated versions.
    inlineCache.markAsNonInlinable(helpers.getInterceptorMethod,
        insideLoop: true);

    specialOperatorEqClasses
      ..add(coreClasses.objectClass)
      ..add(helpers.jsInterceptorClass)
      ..add(helpers.jsNullClass);

    validateInterceptorImplementsAllObjectMethods(helpers.jsInterceptorClass);
    // The null-interceptor must also implement *all* methods.
    validateInterceptorImplementsAllObjectMethods(helpers.jsNullClass);

    return new Future.value();
  }

  void registerMirrorUsage(
      Set<String> symbols, Set<Element> targets, Set<Element> metaTargets) {
    if (symbols == null && targets == null && metaTargets == null) {
      // The user didn't specify anything, or there are imports of
      // 'dart:mirrors' without @MirrorsUsed.
      hasInsufficientMirrorsUsed = true;
      return;
    }
    if (symbols != null) symbolsUsed.addAll(symbols);
    if (targets != null) {
      for (Element target in targets) {
        if (target.isAbstractField) {
          AbstractFieldElement field = target;
          targetsUsed.add(field.getter);
          targetsUsed.add(field.setter);
        } else {
          targetsUsed.add(target);
        }
      }
    }
    if (metaTargets != null) metaTargetsUsed.addAll(metaTargets);
  }

  /**
   * Returns `true` if [element] can be accessed through reflection, that is,
   * is in the set of elements covered by a `MirrorsUsed` annotation.
   *
   * This property is used to tag emitted elements with a marker which is
   * checked by the runtime system to throw an exception if an element is
   * accessed (invoked, get, set) that is not accessible for the reflective
   * system.
   */
  bool isAccessibleByReflection(Element element) {
    if (element.isClass) {
      element = getDartClass(element);
    }
    return membersNeededForReflection.contains(element);
  }

  /**
   * Returns true if the element has to be resolved due to a mirrorsUsed
   * annotation. If we have insufficient mirrors used annotations, we only
   * keep additonal elements if treeshaking has been disabled.
   */
  bool requiredByMirrorSystem(Element element) {
    return hasInsufficientMirrorsUsed && isTreeShakingDisabled ||
        matchesMirrorsMetaTarget(element) ||
        targetsUsed.contains(element);
  }

  /**
   * Returns true if the element matches a mirrorsUsed annotation. If
   * we have insufficient mirrorsUsed information, this returns true for
   * all elements, as they might all be potentially referenced.
   */
  bool referencedFromMirrorSystem(Element element, [recursive = true]) {
    Element enclosing = recursive ? element.enclosingElement : null;

    return hasInsufficientMirrorsUsed ||
        matchesMirrorsMetaTarget(element) ||
        targetsUsed.contains(element) ||
        (enclosing != null && referencedFromMirrorSystem(enclosing));
  }

  /**
   * Returns `true` if the element is needed because it has an annotation
   * of a type that is used as a meta target for reflection.
   */
  bool matchesMirrorsMetaTarget(Element element) {
    if (metaTargetsUsed.isEmpty) return false;
    for (MetadataAnnotation metadata in element.metadata) {
      // TODO(kasperl): It would be nice if we didn't have to resolve
      // all metadata but only stuff that potentially would match one
      // of the used meta targets.
      metadata.ensureResolved(resolution);
      ConstantValue value =
          compiler.constants.getConstantValue(metadata.constant);
      if (value == null) continue;
      DartType type = value.getType(compiler.coreTypes);
      if (metaTargetsUsed.contains(type.element)) return true;
    }
    return false;
  }

  /**
   * Visits all classes and computes whether its members are needed for
   * reflection.
   *
   * We have to precompute this set as we cannot easily answer the need for
   * reflection locally when looking at the member: We lack the information by
   * which classes a member is inherited. Called after resolution is complete.
   *
   * We filter out private libraries here, as their elements should not
   * be visible by reflection unless some other interfaces makes them
   * accessible.
   */
  computeMembersNeededForReflection() {
    if (_membersNeededForReflection != null) return;
    if (compiler.commonElements.mirrorsLibrary == null) {
      _membersNeededForReflection = const ImmutableEmptySet<Element>();
      return;
    }
    // Compute a mapping from class to the closures it contains, so we
    // can include the correct ones when including the class.
    Map<ClassElement, List<LocalFunctionElement>> closureMap =
        new Map<ClassElement, List<LocalFunctionElement>>();
    for (LocalFunctionElement closure in compiler.resolverWorld.allClosures) {
      closureMap.putIfAbsent(closure.enclosingClass, () => []).add(closure);
    }
    bool foundClosure = false;
    Set<Element> reflectableMembers = new Set<Element>();
    ResolutionEnqueuer resolution = compiler.enqueuer.resolution;
    for (ClassElement cls in resolution.universe.directlyInstantiatedClasses) {
      // Do not process internal classes.
      if (cls.library.isInternalLibrary || cls.isInjected) continue;
      if (referencedFromMirrorSystem(cls)) {
        Set<Name> memberNames = new Set<Name>();
        // 1) the class (should be resolved)
        assert(invariant(cls, cls.isResolved));
        reflectableMembers.add(cls);
        // 2) its constructors (if resolved)
        cls.constructors.forEach((Element constructor) {
          if (resolution.hasBeenProcessed(constructor)) {
            reflectableMembers.add(constructor);
          }
        });
        // 3) all members, including fields via getter/setters (if resolved)
        cls.forEachClassMember((Member member) {
          MemberElement element = member.element;
          if (resolution.hasBeenProcessed(element)) {
            memberNames.add(member.name);
            reflectableMembers.add(element);
            element.nestedClosures
                .forEach((SynthesizedCallMethodElementX callFunction) {
              reflectableMembers.add(callFunction);
              reflectableMembers.add(callFunction.closureClass);
            });
          }
        });
        // 4) all overriding members of subclasses/subtypes (should be resolved)
        if (compiler.closedWorld.hasAnyStrictSubtype(cls)) {
          compiler.closedWorld.forEachStrictSubtypeOf(cls,
              (ClassElement subcls) {
            subcls.forEachClassMember((Member member) {
              if (memberNames.contains(member.name)) {
                // TODO(20993): find out why this assertion fails.
                // assert(invariant(member.element,
                //    resolution.hasBeenProcessed(member.element)));
                if (resolution.hasBeenProcessed(member.element)) {
                  reflectableMembers.add(member.element);
                }
              }
            });
          });
        }
        // 5) all its closures
        List<LocalFunctionElement> closures = closureMap[cls];
        if (closures != null) {
          reflectableMembers.addAll(closures);
          foundClosure = true;
        }
      } else {
        // check members themselves
        cls.constructors.forEach((ConstructorElement element) {
          if (!resolution.hasBeenProcessed(element)) return;
          if (referencedFromMirrorSystem(element, false)) {
            reflectableMembers.add(element);
          }
        });
        cls.forEachClassMember((Member member) {
          if (!resolution.hasBeenProcessed(member.element)) return;
          if (referencedFromMirrorSystem(member.element, false)) {
            reflectableMembers.add(member.element);
          }
        });
        // Also add in closures. Those might be reflectable is their enclosing
        // member is.
        List<LocalFunctionElement> closures = closureMap[cls];
        if (closures != null) {
          for (LocalFunctionElement closure in closures) {
            if (referencedFromMirrorSystem(closure.memberContext, false)) {
              reflectableMembers.add(closure);
              foundClosure = true;
            }
          }
        }
      }
    }
    // We also need top-level non-class elements like static functions and
    // global fields. We use the resolution queue to decide which elements are
    // part of the live world.
    for (LibraryElement lib in compiler.libraryLoader.libraries) {
      if (lib.isInternalLibrary) continue;
      lib.forEachLocalMember((Element member) {
        if (!member.isClass &&
            resolution.hasBeenProcessed(member) &&
            referencedFromMirrorSystem(member)) {
          reflectableMembers.add(member);
        }
      });
    }
    // And closures inside top-level elements that do not have a surrounding
    // class. These will be in the [:null:] bucket of the [closureMap].
    if (closureMap.containsKey(null)) {
      for (Element closure in closureMap[null]) {
        if (referencedFromMirrorSystem(closure)) {
          reflectableMembers.add(closure);
          foundClosure = true;
        }
      }
    }
    // As we do not think about closures as classes, yet, we have to make sure
    // their superclasses are available for reflection manually.
    if (foundClosure) {
      reflectableMembers.add(helpers.closureClass);
    }
    Set<Element> closurizedMembers = compiler.resolverWorld.closurizedMembers;
    if (closurizedMembers.any(reflectableMembers.contains)) {
      reflectableMembers.add(helpers.boundClosureClass);
    }
    // Add typedefs.
    reflectableMembers.addAll(
        compiler.closedWorld.allTypedefs.where(referencedFromMirrorSystem));
    // Register all symbols of reflectable elements
    for (Element element in reflectableMembers) {
      symbolsUsed.add(element.name);
    }
    _membersNeededForReflection = reflectableMembers;
  }

  // TODO(20791): compute closure classes after resolution and move this code to
  // [computeMembersNeededForReflection].
  void maybeMarkClosureAsNeededForReflection(
      ClosureClassElement globalizedElement,
      FunctionElement callFunction,
      FunctionElement function) {
    if (!_membersNeededForReflection.contains(function)) return;
    _membersNeededForReflection.add(callFunction);
    _membersNeededForReflection.add(globalizedElement);
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
    FunctionElement helper = helpers.isJsIndexable;
    jsAst.Expression helperExpression = emitter.staticFunctionAccess(helper);
    return new jsAst.Call(helperExpression, arguments);
  }

  bool isTypedArray(TypeMask mask) {
    // Just checking for [:TypedData:] is not sufficient, as it is an
    // abstract class any user-defined class can implement. So we also
    // check for the interface [JavaScriptIndexingBehavior].
    ClassElement typedDataClass = compiler.commonElements.typedDataClass;
    return typedDataClass != null &&
        compiler.closedWorld.isInstantiated(typedDataClass) &&
        mask.satisfies(typedDataClass, compiler.closedWorld) &&
        mask.satisfies(
            helpers.jsIndexingBehaviorInterface, compiler.closedWorld);
  }

  bool couldBeTypedArray(TypeMask mask) {
    bool intersects(TypeMask type1, TypeMask type2) =>
        !type1.intersection(type2, compiler.closedWorld).isEmpty;
    // TODO(herhut): Maybe cache the TypeMask for typedDataClass and
    //               jsIndexingBehaviourInterface.
    ClassElement typedDataClass = compiler.commonElements.typedDataClass;
    return typedDataClass != null &&
        compiler.closedWorld.isInstantiated(typedDataClass) &&
        intersects(
            mask, new TypeMask.subtype(typedDataClass, compiler.closedWorld)) &&
        intersects(
            mask,
            new TypeMask.subtype(
                helpers.jsIndexingBehaviorInterface, compiler.closedWorld));
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

    for (Element target in targetsUsed) {
      if (target == null) continue;
      if (target.isField) {
        staticFields.add(target);
      } else if (target.isLibrary || target.isClass) {
        addFieldsInContainer(target);
      }
    }
    return staticFields;
  }

  /// Called when [enqueuer] is empty, but before it is closed.
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

    if (!enqueuer.queueIsEmpty) return false;

    for (ClassElement cls in recentClasses) {
      Element element = cls.lookupLocalMember(Identifiers.noSuchMethod_);
      if (element != null && element.isInstanceMember && element.isFunction) {
        registerNoSuchMethod(element);
      }
    }
    noSuchMethodRegistry.onQueueEmpty();
    if (!enabledNoSuchMethod &&
        (noSuchMethodRegistry.hasThrowingNoSuchMethod ||
            noSuchMethodRegistry.hasComplexNoSuchMethod)) {
      enqueuer.applyImpact(enableNoSuchMethod());
      enabledNoSuchMethod = true;
    }

    if (compiler.options.useKernel && compiler.mainApp != null) {
      kernelTask.buildKernelIr();
    }

    if (compiler.options.hasIncrementalSupport &&
        !hasIncrementalTearOffSupport) {
      // Always enable tear-off closures during incremental compilation.
      Element element = helpers.closureFromTearOff;
      if (element != null) {
        enqueuer.applyImpact(
            impactTransformer.createImpactFor(impacts.closureClass));
      }
      hasIncrementalTearOffSupport = true;
    }

    if (!enqueuer.isResolutionQueue && preMirrorsMethodCount == 0) {
      preMirrorsMethodCount = generatedCode.length;
    }

    if (isTreeShakingDisabled) {
      enqueuer.applyImpact(mirrorsAnalysis.computeImpactForReflectiveElements(
          recentClasses,
          enqueuer.processedClasses,
          compiler.libraryLoader.libraries,
          forResolution: enqueuer.isResolutionQueue));
    } else if (!targetsUsed.isEmpty && enqueuer.isResolutionQueue) {
      // Add all static elements (not classes) that have been requested for
      // reflection. If there is no mirror-usage these are probably not
      // necessary, but the backend relies on them being resolved.
      enqueuer.applyImpact(mirrorsAnalysis
          .computeImpactForReflectiveStaticFields(_findStaticFieldTargets(),
              forResolution: enqueuer.isResolutionQueue));
    }

    if (mustPreserveNames) reporter.log('Preserving names.');

    if (mustRetainMetadata) {
      reporter.log('Retaining metadata.');

      compiler.libraryLoader.libraries.forEach(retainMetadataOf);

      StagedWorldImpactBuilder impactBuilder = enqueuer.isResolutionQueue
          ? constantImpactsForResolution
          : constantImpactsForResolution;
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
          processElementMetadata(element.enclosingClass);
        } else {
          processLibraryMetadata(element.library);
        }
      }
    }

    entities.forEach(processElementMetadata);
  }

  void onQueueClosed() {
    lookupMapAnalysis.onQueueClosed();
    jsInteropAnalysis.onQueueClosed();
  }

  WorldImpact onCodegenStart() {
    lookupMapAnalysis.onCodegenStart();
    if (hasIsolateSupport) {
      return enableIsolateSupport(forResolution: false);
    }
    return const WorldImpact();
  }

  /// Process backend specific annotations.
  void processAnnotations(Element element) {
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
        compiler.inferenceWorld.registerCannotThrow(element);
      } else if (cls == helpers.noSideEffectsClass) {
        hasNoSideEffects = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          reporter.reportHintMessage(
              element, MessageKind.GENERIC, {'text': "Has no side effects"});
        }
        compiler.inferenceWorld.registerSideEffectsFree(element);
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

  FunctionElement helperForBadMain() => helpers.badMain;

  FunctionElement helperForMissingMain() => helpers.missingMain;

  FunctionElement helperForMainArity() => helpers.mainHasTooManyParameters;

  void forgetElement(Element element) {
    constants.forgetElement(element);
    constantCompilerTask.dartConstantCompiler.forgetElement(element);
    aliasedSuperMembers.remove(element);
  }

  @override
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

  @override
  bool enableDeferredLoadingIfSupported(Spannable node) => true;

  @override
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

  @override
  Uri resolvePatchUri(String libraryName, Uri platformConfigUri) {
    String patchLocation = _patchLocations[libraryName];
    if (patchLocation == null) return null;
    return platformConfigUri.resolve(patchLocation);
  }

  @override
  ImpactStrategy createImpactStrategy(
      {bool supportDeferredLoad: true,
      bool supportDumpInfo: true,
      bool supportSerialization: true}) {
    return new JavaScriptImpactStrategy(resolution, compiler.dumpInfoTask,
        supportDeferredLoad: supportDeferredLoad,
        supportDumpInfo: supportDumpInfo,
        supportSerialization: supportSerialization);
  }
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
              new TypeUse.instantiation(backend.coreTypes.nullType));
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
      DartType type = typeUse.type;
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
          new TypeUse.instantiation(backend.compiler.coreTypes.typeType));
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
      registerRequiredType(mapLiteralUse.type);
    }

    for (ListLiteralUse listLiteralUse in worldImpact.listLiterals) {
      // TODO(johnniwinther): Use the [isConstant] and [isEmpty] property when
      // factory constructors are registered directly.
      transformed
          .registerTypeUse(new TypeUse.instantiation(listLiteralUse.type));
      registerRequiredType(listLiteralUse.type);
    }

    if (worldImpact.constSymbolNames.isNotEmpty) {
      registerBackendImpact(transformed, impacts.constSymbol);
      for (String constSymbolName in worldImpact.constSymbolNames) {
        backend.registerConstSymbol(constSymbolName);
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
    backend.registerBackendUse(element);
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
    backend.registerBackendUse(cls);
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
    for (InterfaceType instantiatedType in backendImpact.instantiatedTypes) {
      backend.registerBackendUse(instantiatedType.element);
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
          backend.needToInitializeDispatchProperty = true;
          break;
        case BackendFeature.needToInitializeIsolateAffinityTag:
          backend.needToInitializeIsolateAffinityTag = true;
          break;
      }
    }
  }

  /// Register [type] as required for the runtime type information system.
  void registerRequiredType(DartType type) {
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
  void onIsCheck(DartType type, TransformedWorldImpact transformed) {
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
    if (type is FunctionType) {
      registerBackendImpact(transformed, impacts.functionTypeCheck);
    }
    if (type.element != null && backend.isNative(type.element)) {
      registerBackendImpact(transformed, impacts.nativeTypeCheck);
    }
  }

  void onIsCheckForCodegen(DartType type, TransformedWorldImpact transformed) {
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
      CheckedModeHelper helper =
          backend.getCheckedModeHelper(type, typeCast: false);
      if (helper != null) {
        StaticUse staticUse = helper.getStaticUse(backend.compiler);
        transformed.registerStaticUse(staticUse);
        backend.registerBackendUse(staticUse.element);
      }
      // We also need the native variant of the check (for DOM types).
      helper = backend.getNativeCheckedModeHelper(type, typeCast: false);
      if (helper != null) {
        StaticUse staticUse = helper.getStaticUse(backend.compiler);
        transformed.registerStaticUse(staticUse);
        backend.registerBackendUse(staticUse.element);
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
      DartType type = typeUse.type;
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

    for (Pair<DartType, DartType> check
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
      backend.registerConstSymbol(name);
    }

    for (Set<ClassElement> classes in impact.specializedGetInterceptors) {
      backend.registerSpecializedGetInterceptor(classes);
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
  final BackendHelpers helpers;

  JavaScriptBackendClasses(this.helpers);

  ClassElement get intImplementation => helpers.jsIntClass;
  ClassElement get uint32Implementation => helpers.jsUInt32Class;
  ClassElement get uint31Implementation => helpers.jsUInt31Class;
  ClassElement get positiveIntImplementation => helpers.jsPositiveIntClass;
  ClassElement get doubleImplementation => helpers.jsDoubleClass;
  ClassElement get numImplementation => helpers.jsNumberClass;
  ClassElement get stringImplementation => helpers.jsStringClass;
  ClassElement get listImplementation => helpers.jsArrayClass;
  ClassElement get constListImplementation => helpers.jsUnmodifiableArrayClass;
  ClassElement get fixedListImplementation => helpers.jsFixedArrayClass;
  ClassElement get growableListImplementation => helpers.jsExtendableArrayClass;
  ClassElement get mapImplementation => helpers.mapLiteralClass;
  ClassElement get constMapImplementation => helpers.constMapLiteralClass;
  ClassElement get typeImplementation => helpers.typeLiteralClass;
  ClassElement get boolImplementation => helpers.jsBoolClass;
  ClassElement get nullImplementation => helpers.jsNullClass;
  ClassElement get syncStarIterableImplementation => helpers.syncStarIterable;
  ClassElement get asyncFutureImplementation => helpers.futureImplementation;
  ClassElement get asyncStarStreamImplementation => helpers.controllerStream;
  ClassElement get functionImplementation => helpers.coreClasses.functionClass;
}
