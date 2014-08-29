// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js;

/**
 * If true, print a warning for each method that was resolved, but not
 * compiled.
 */
const bool REPORT_EXCESS_RESOLUTION = false;

/**
 * Contains backend-specific data that is used throughout the compilation of
 * one work item.
 */
class ItemCompilationContext {
}

abstract class WorkItem {
  final ItemCompilationContext compilationContext;
  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  final AstElement element;
  TreeElements get resolutionTree;

  WorkItem(this.element, this.compilationContext) {
    assert(invariant(element, element.isDeclaration));
  }

  void run(Compiler compiler, Enqueuer world);
}

/// [WorkItem] used exclusively by the [ResolutionEnqueuer].
class ResolutionWorkItem extends WorkItem {
  TreeElements resolutionTree;

  ResolutionWorkItem(AstElement element,
                     ItemCompilationContext compilationContext)
      : super(element, compilationContext);

  void run(Compiler compiler, ResolutionEnqueuer world) {
    compiler.analyze(this, world);
    resolutionTree = element.resolvedAst.elements;
  }

  bool isAnalyzed() => resolutionTree != null;
}

// TODO(johnniwinther): Split this class into interface and implementation.
// TODO(johnniwinther): Move this implementation to the JS backend.
class CodegenRegistry extends Registry {
  final Compiler compiler;
  final TreeElements treeElements;

  CodegenRegistry(this.compiler, this.treeElements);

  bool get isForResolution => false;

  Element get currentElement => treeElements.analyzedElement;

  // TODO(johnniwinther): Remove this getter when [Registry] creates a
  // dependency node.
  Setlet<Element> get otherDependencies => treeElements.otherDependencies;

  CodegenEnqueuer get world => compiler.enqueuer.codegen;
  js_backend.JavaScriptBackend get backend => compiler.backend;

  void registerDependency(Element element) {
    treeElements.registerDependency(element);
  }

  void registerInstantiatedClass(ClassElement element) {
    world.registerInstantiatedClass(element, this);
  }

  void registerInstantiatedType(InterfaceType type) {
    world.registerInstantiatedType(type, this);
  }

  void registerStaticUse(Element element) {
    world.registerStaticUse(element);
  }

  void registerDynamicInvocation(Selector selector) {
    world.registerDynamicInvocation(selector);
    compiler.dumpInfoTask.elementUsesSelector(currentElement, selector);
  }

  void registerDynamicSetter(Selector selector) {
    world.registerDynamicSetter(selector);
    compiler.dumpInfoTask.elementUsesSelector(currentElement, selector);
  }

  void registerDynamicGetter(Selector selector) {
    world.registerDynamicGetter(selector);
    compiler.dumpInfoTask.elementUsesSelector(currentElement, selector);
  }

  void registerGetterForSuperMethod(Element element) {
    world.registerGetterForSuperMethod(element);
  }

  void registerFieldGetter(Element element) {
    world.registerFieldGetter(element);
  }

  void registerFieldSetter(Element element) {
    world.registerFieldSetter(element);
  }

  void registerIsCheck(DartType type) {
    world.registerIsCheck(type, this);
    backend.registerIsCheckForCodegen(type, world, this);
  }

  void registerCompileTimeConstant(Constant constant) {
    backend.registerCompileTimeConstant(constant, this);
    backend.constants.addCompileTimeConstantForEmission(constant);
  }

  void registerTypeVariableBoundsSubtypeCheck(DartType subtype,
                                              DartType supertype) {
    backend.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
  }

  void registerClosureWithFreeTypeVariables(FunctionElement element) {
    backend.registerClosureWithFreeTypeVariables(element, world, this);
  }

  void registerGetOfStaticFunction(FunctionElement element) {
    world.registerGetOfStaticFunction(element);
  }

  void registerSelectorUse(Selector selector) {
    world.registerSelectorUse(selector);
  }

  void registerFactoryWithTypeArguments() {
    world.registerFactoryWithTypeArguments(this);
  }

  void registerConstSymbol(String name) {
    backend.registerConstSymbol(name, this);
  }

  void registerSpecializedGetInterceptor(Set<ClassElement> classes) {
    backend.registerSpecializedGetInterceptor(classes);
  }

  void registerUseInterceptor() {
    backend.registerUseInterceptor(world);
  }

  void registerTypeConstant(ClassElement element) {
    backend.customElementsAnalysis.registerTypeConstant(element, world);
  }

  void registerStaticInvocation(Element element) {
    world.registerStaticUse(element);
  }

  void registerInstantiation(InterfaceType type) {
    world.registerInstantiatedType(type, this);
  }
}

/// [WorkItem] used exclusively by the [CodegenEnqueuer].
class CodegenWorkItem extends WorkItem {
  Registry registry;
  final TreeElements resolutionTree;

  CodegenWorkItem(AstElement element,
                  ItemCompilationContext compilationContext)
      : this.resolutionTree = element.resolvedAst.elements,
        super(element, compilationContext) {
    assert(invariant(element, resolutionTree != null,
        message: 'Resolution tree is null for $element in codegen work item'));
  }

  void run(Compiler compiler, CodegenEnqueuer world) {
    if (world.isProcessed(element)) return;

    registry = new CodegenRegistry(compiler, resolutionTree);
    compiler.codegen(this, world);
  }
}

typedef void DeferredAction();

class DeferredTask {
  final Element element;
  final DeferredAction action;

  DeferredTask(this.element, this.action);
}

/// Interface for registration of element dependencies.
abstract class Registry {
  // TODO(johnniwinther): Remove this getter when [Registry] creates a
  // dependency node.
  Iterable<Element> get otherDependencies;

  void registerDependency(Element element);

  bool get isForResolution;

  void registerStaticInvocation(Element element);

  void registerInstantiation(InterfaceType type);

  void registerGetOfStaticFunction(FunctionElement element);
}

abstract class Backend {
  final Compiler compiler;

  Backend(this.compiler);

  /// The [ConstantSystem] used to interpret compile-time constants for this
  /// backend.
  ConstantSystem get constantSystem;

  /// The constant environment for the backend interpretation of compile-time
  /// constants.
  BackendConstantEnvironment get constants;

  /// The compiler task responsible for the compilation of constants for both
  /// the frontend and the backend.
  ConstantCompilerTask get constantCompilerTask;

  /// Backend callback methods for the resolution phase.
  ResolutionCallbacks get resolutionCallbacks;

  /// Set of classes that need to be considered for reflection although not
  /// otherwise visible during resolution.
  Iterable<ClassElement> classesRequiredForReflection = const [];

  // Given a [FunctionElement], return a buffer with the code generated for it
  // or null if no code was generated.
  CodeBuffer codeOf(Element element) => null;

  void initializeHelperClasses() {}

  void enqueueHelpers(ResolutionEnqueuer world, Registry registry);
  void codegen(CodegenWorkItem work);

  // The backend determines the native resolution enqueuer, with a no-op
  // default, so tools like dart2dart can ignore the native classes.
  native.NativeEnqueuer nativeResolutionEnqueuer(world) {
    return new native.NativeEnqueuer();
  }
  native.NativeEnqueuer nativeCodegenEnqueuer(world) {
    return new native.NativeEnqueuer();
  }

  void assembleProgram();
  List<CompilerTask> get tasks;

  void onResolutionComplete() {}

  ItemCompilationContext createItemCompilationContext() {
    return new ItemCompilationContext();
  }

  bool classNeedsRti(ClassElement cls);
  bool methodNeedsRti(FunctionElement function);

  /// Called during codegen when [constant] has been used.
  void registerCompileTimeConstant(Constant constant, Registry registry) {}

  /// Called during resolution when a metadata [constant] for [annotatedElement]
  /// has been evaluated.
  void registerMetadataConstant(Constant constant,
                                Element annotatedElement,
                                Registry registry) {}

  /// Called during resolution to notify to the backend that a class is
  /// being instantiated.
  void registerInstantiatedClass(ClassElement cls,
                                 Enqueuer enqueuer,
                                 Registry registry) {}

  /// Register an is check to the backend.
  void registerIsCheckForCodegen(DartType type,
                                 Enqueuer enqueuer,
                                 Registry registry) {}

  /// Register a runtime type variable bound tests between [typeArgument] and
  /// [bound].
  void registerTypeVariableBoundsSubtypeCheck(DartType typeArgument,
                                              DartType bound) {}

  /// Returns `true` if [element] represent the assert function.
  bool isAssertMethod(Element element) => false;

  /**
   * Call this to register that an instantiated generic class has a call
   * method.
   */
  void registerCallMethodWithFreeTypeVariables(
      Element callMethod,
      Enqueuer enqueuer,
      Registry registry) {}

  /**
   * Call this to register that a getter exists for a function on an
   * instantiated generic class.
   */
  void registerClosureWithFreeTypeVariables(
      Element closure,
      Enqueuer enqueuer,
      Registry registry) {}

  /// Call this to register that a member has been closurized.
  void registerBoundClosure(Enqueuer enqueuer) {}

  /// Call this to register that a static function has been closurized.
  void registerGetOfStaticFunction(Enqueuer enqueuer) {}

  /**
   * Call this to register that the [:runtimeType:] property has been accessed.
   */
  void registerRuntimeType(Enqueuer enqueuer, Registry registry) {}

  /**
   * Call this method to enable [noSuchMethod] handling in the
   * backend.
   */
  void enableNoSuchMethod(Element context, Enqueuer enqueuer) {
    enqueuer.registerInvocation(compiler.noSuchMethodSelector);
  }

  /// Call this method to enable support for isolates.
  void enableIsolateSupport(Enqueuer enqueuer) {}

  void registerRequiredType(DartType type, Element enclosingElement) {}
  void registerClassUsingVariableExpression(ClassElement cls) {}

  void registerConstSymbol(String name, Registry registry) {}
  void registerNewSymbol(Registry registry) {}

  bool isNullImplementation(ClassElement cls) {
    return cls == compiler.nullClass;
  }

  ClassElement get intImplementation => compiler.intClass;
  ClassElement get doubleImplementation => compiler.doubleClass;
  ClassElement get numImplementation => compiler.numClass;
  ClassElement get stringImplementation => compiler.stringClass;
  ClassElement get listImplementation => compiler.listClass;
  ClassElement get growableListImplementation => compiler.listClass;
  ClassElement get fixedListImplementation => compiler.listClass;
  ClassElement get constListImplementation => compiler.listClass;
  ClassElement get mapImplementation => compiler.mapClass;
  ClassElement get constMapImplementation => compiler.mapClass;
  ClassElement get functionImplementation => compiler.functionClass;
  ClassElement get typeImplementation => compiler.typeClass;
  ClassElement get boolImplementation => compiler.boolClass;
  ClassElement get nullImplementation => compiler.nullClass;
  ClassElement get uint32Implementation => compiler.intClass;
  ClassElement get uint31Implementation => compiler.intClass;
  ClassElement get positiveIntImplementation => compiler.intClass;

  ClassElement defaultSuperclass(ClassElement element) => compiler.objectClass;

  bool isDefaultNoSuchMethodImplementation(Element element) {
    assert(element.name == Compiler.NO_SUCH_METHOD);
    ClassElement classElement = element.enclosingClass;
    return classElement == compiler.objectClass;
  }

  bool isInterceptorClass(ClassElement element) => false;

  /// Returns `true` if [element] is a foreign element, that is, that the
  /// backend has specialized handling for the element.
  bool isForeign(Element element) => false;

  /// Returns `true` if [library] is a backend specific library whose members
  /// have special treatment, such as being allowed to extends blacklisted
  /// classes or member being eagerly resolved.
  bool isBackendLibrary(LibraryElement library) {
    // TODO(johnnwinther): Remove this when patching is only done by the
    // JavaScript backend.
    Uri canonicalUri = library.canonicalUri;
    if (canonicalUri == js_backend.JavaScriptBackend.DART_JS_HELPER ||
        canonicalUri == js_backend.JavaScriptBackend.DART_INTERCEPTORS) {
      return true;
    }
    return false;
  }

  void registerStaticUse(Element element, Enqueuer enqueuer) {}

  /// This method is called immediately after the [LibraryElement] [library] has
  /// been created.
  void onLibraryCreated(LibraryElement library) {}

  /// This method is called immediately after the [library] and its parts have
  /// been scanned.
  Future onLibraryScanned(LibraryElement library, LibraryLoader loader) {
    if (library.isPlatformLibrary && !library.isPatched) {
      // Apply patch, if any.
      Uri patchUri = compiler.resolvePatchUri(library.canonicalUri.path);
      if (patchUri != null) {
        return compiler.patchParser.patchLibrary(loader, patchUri, library);
      }
    }
    if (library.canUseNative) {
      library.forEachLocalMember((Element element) {
        if (element.isClass) {
          checkNativeAnnotation(compiler, element);
        }
      });
    }
    return new Future.value();
  }

  /// This method is called when all new libraries loaded through
  /// [LibraryLoader.loadLibrary] has been loaded and their imports/exports
  /// have been computed.
  Future onLibrariesLoaded(Map<Uri, LibraryElement> loadedLibraries) {
    return new Future.value();
  }

  /// Called by [MirrorUsageAnalyzerTask] after it has merged all @MirrorsUsed
  /// annotations. The arguments corresponds to the unions of the corresponding
  /// fields of the annotations.
  void registerMirrorUsage(Set<String> symbols,
                           Set<Element> targets,
                           Set<Element> metaTargets) {}

  /// Returns true if this element needs reflection information at runtime.
  bool isAccessibleByReflection(Element element) => true;

  /// Returns true if this element is covered by a mirrorsUsed annotation.
  ///
  /// Note that it might still be ok to tree shake the element away if no
  /// reflection is used in the program (and thus [isTreeShakingDisabled] is
  /// still false). Therefore _do not_ use this predicate to decide inclusion
  /// in the tree, use [requiredByMirrorSystem] instead.
  bool referencedFromMirrorSystem(Element element, [recursive]) => false;

  /// Returns true if this element has to be enqueued due to
  /// mirror usage. Might be a subset of [referencedFromMirrorSystem] if
  /// normal tree shaking is still active ([isTreeShakingDisabled] is false).
  bool requiredByMirrorSystem(Element element) => false;

  /// Returns true if global optimizations such as type inferencing
  /// can apply to this element. One category of elements that do not
  /// apply is runtime helpers that the backend calls, but the
  /// optimizations don't see those calls.
  bool canBeUsedForGlobalOptimizations(Element element) => true;

  /// Called when [enqueuer]'s queue is empty, but before it is closed.
  /// This is used, for example, by the JS backend to enqueue additional
  /// elements needed for reflection. [recentClasses] is a collection of
  /// all classes seen for the first time by the [enqueuer] since the last call
  /// to [onQueueEmpty].
  ///
  /// A return value of [:true:] indicates that [recentClasses] has been
  /// processed and its elements do not need to be seen in the next round. When
  /// [:false:] is returned, [onQueueEmpty] will be called again once the
  /// resolution queue has drained and [recentClasses] will be a superset of the
  /// current value.
  ///
  /// There is no guarantee that a class is only present once in
  /// [recentClasses], but every class seen by the [enqueuer] will be present in
  /// [recentClasses] at least once.
  bool onQueueEmpty(Enqueuer enqueuer, Iterable<ClassElement> recentClasses) {
    return true;
  }

  /// Called after [element] has been resolved.
  // TODO(johnniwinther): Change [TreeElements] to [Registry] or a dependency
  // node. [elements] is currently unused by the implementation.
  void onElementResolved(Element element, TreeElements elements) {}

  // Does this element belong in the output
  bool shouldOutput(Element element) => true;

  FunctionElement helperForBadMain() => null;

  FunctionElement helperForMissingMain() => null;

  FunctionElement helperForMainArity() => null;
}

/// Backend callbacks function specific to the resolution phase.
class ResolutionCallbacks {
  /// Register that [node] is a call to `assert`.
  void onAssert(Send node, Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program uses string interpolation.
  void onStringInterpolation(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program has a catch statement.
  void onCatchStatement(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program explicitly throws an exception.
  void onThrowExpression(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program has a global variable with a lazy initializer.
  void onLazyField(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program uses a type variable as an expression.
  void onTypeVariableExpression(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program uses a type literal.
  void onTypeLiteral(DartType type, Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program has a catch statement with a stack trace.
  void onStackTraceInCatch(Registry registry) {}

  /// Register an is check to the backend.
  void onIsCheck(DartType type, Registry registry) {}

  /// Register an as check to the backend.
  void onAsCheck(DartType type, Registry registry) {}

  /// Registers that a type variable bounds check might occur at runtime.
  void onTypeVariableBoundCheck(Registry registry) {}

  /// Register that the application may throw a [NoSuchMethodError].
  void onThrowNoSuchMethod(Registry registry) {}

  /// Register that the application may throw a [RuntimeError].
  void onThrowRuntimeError(Registry registry) {}

  /// Register that the application may throw an
  /// [AbstractClassInstantiationError].
  void onAbstractClassInstantiation(Registry registry) {}

  /// Register that the application may throw a [FallThroughError].
  void onFallThroughError(Registry registry) {}

  /// Register that a super call will end up calling
  /// [: super.noSuchMethod :].
  void onSuperNoSuchMethod(Registry registry) {}

  /// Register that the application creates a constant map.
  void onConstantMap(Registry registry) {}

  /// Called when resolving the `Symbol` constructor.
  void onSymbolConstructor(Registry registry) {}
}

/**
 * Key class used in [TokenMap] in which the hash code for a token is based
 * on the [charOffset].
 */
class TokenKey {
  final Token token;
  TokenKey(this.token);
  int get hashCode => token.charOffset;
  operator==(other) => other is TokenKey && token == other.token;
}

/// Map of tokens and the first associated comment.
/*
 * This implementation was chosen among several candidates for its space/time
 * efficiency by empirical tests of running dartdoc on dartdoc itself. Time
 * measurements for the use of [Compiler.commentMap]:
 *
 * 1) Using [TokenKey] as key (this class): ~80 msec
 * 2) Using [TokenKey] as key + storing a separate map in each script: ~120 msec
 * 3) Using [Token] as key in a [Map]: ~38000 msec
 * 4) Storing comments is new field in [Token]: ~20 msec
 *    (Abandoned due to the increased memory usage)
 * 5) Storing comments in an [Expando]: ~14000 msec
 * 6) Storing token/comments pairs in a linked list: ~5400 msec
 */
class TokenMap {
  Map<TokenKey,Token> comments = new Map<TokenKey,Token>();

  Token operator[] (Token key) {
    if (key == null) return null;
    return comments[new TokenKey(key)];
  }

  void operator[]= (Token key, Token value) {
    if (key == null) return;
    comments[new TokenKey(key)] = value;
  }
}

abstract class Compiler implements DiagnosticListener {
  static final Uri DART_CORE = new Uri(scheme: 'dart', path: 'core');
  static final Uri DART_MIRRORS = new Uri(scheme: 'dart', path: 'mirrors');
  static final Uri DART_NATIVE_TYPED_DATA =
      new Uri(scheme: 'dart', path: '_native_typed_data');
  static final Uri DART_INTERNAL = new Uri(scheme: 'dart', path: '_internal');
  static final Uri DART_ASYNC = new Uri(scheme: 'dart', path: 'async');

  final Stopwatch totalCompileTime = new Stopwatch();
  int nextFreeClassId = 0;
  World world;
  String assembledCode;
  Types types;

  final CacheStrategy cacheStrategy;

  /**
   * Map from token to the first preceeding comment token.
   */
  final TokenMap commentMap = new TokenMap();

  /**
   * Records global dependencies, that is, dependencies that don't
   * correspond to a particular element.
   *
   * We should get rid of this and ensure that all dependencies are
   * associated with a particular element.
   */
  Registry globalDependencies;

  /**
   * Dependencies that are only included due to mirrors.
   *
   * We should get rid of this and ensure that all dependencies are
   * associated with a particular element.
   */
  // TODO(johnniwinther): This should not be a [ResolutionRegistry].
  final Registry mirrorDependencies =
      new ResolutionRegistry.internal(null, new TreeElementMapping(null));

  final bool enableMinification;
  final bool enableTypeAssertions;
  final bool enableUserAssertions;
  final bool trustTypeAnnotations;
  final bool enableConcreteTypeInference;
  final bool disableTypeInferenceFlag;
  final bool dumpInfo;
  final bool useContentSecurityPolicy;

  /**
   * The maximum size of a concrete type before it widens to dynamic during
   * concrete type inference.
   */
  final int maxConcreteTypeSize;
  final bool analyzeAllFlag;
  final bool analyzeOnly;

  /// If true, disable tree-shaking for the main script.
  final bool analyzeMain;

  /**
   * If true, skip analysis of method bodies and field initializers. Implies
   * [analyzeOnly].
   */
  final bool analyzeSignaturesOnly;
  final bool enableNativeLiveTypeAnalysis;

  /**
   * If true, stop compilation after type inference is complete. Used for
   * debugging and testing purposes only.
   */
  bool stopAfterTypeInference = false;

  /**
   * If [:true:], comment tokens are collected in [commentMap] during scanning.
   */
  final bool preserveComments;

  /**
   * Is the compiler in verbose mode.
   */
  final bool verbose;

  /**
   * URI of the main source map if the compiler is generating source
   * maps.
   */
  final Uri sourceMapUri;

  /**
   * URI of the main output if the compiler is generating source maps.
   */
  final Uri outputUri;

  /// Emit terse diagnostics without howToFix.
  final bool terseDiagnostics;

  /// If `true`, warnings and hints not from user code are reported.
  final bool showPackageWarnings;

  /// `true` if the last diagnostic was filtered, in which case the
  /// accompanying info message should be filtered as well.
  bool lastDiagnosticWasFiltered = false;

  /// Map containing information about the warnings and hints that have been
  /// suppressed for each library.
  Map<Uri, SuppressionInfo> suppressedWarnings = <Uri, SuppressionInfo>{};

  final bool suppressWarnings;

  /// If `true`, some values are cached for reuse in incremental compilation.
  /// Incremental compilation is basically calling [run] more than once.
  final bool hasIncrementalSupport;

  api.CompilerOutputProvider outputProvider;

  bool disableInlining = false;

  /// True if compilation was aborted with a [CompilerCancelledException]. Only
  /// set after Future retuned by [run] has completed.
  bool compilerWasCancelled = false;

  List<Uri> librariesToAnalyzeWhenRun;

  Tracer tracer;

  CompilerTask measuredTask;
  Element _currentElement;
  LibraryElement coreLibrary;

  LibraryElement mainApp;
  FunctionElement mainFunction;

  /// Initialized when dart:mirrors is loaded.
  LibraryElement mirrorsLibrary;

  /// Initialized when dart:typed_data is loaded.
  LibraryElement typedDataLibrary;

  ClassElement objectClass;
  ClassElement boolClass;
  ClassElement numClass;
  ClassElement intClass;
  ClassElement doubleClass;
  ClassElement stringClass;
  ClassElement functionClass;
  ClassElement nullClass;
  ClassElement listClass;
  ClassElement typeClass;
  ClassElement mapClass;
  ClassElement symbolClass;
  ClassElement stackTraceClass;
  ClassElement typedDataClass;

  /// The constant for the [proxy] variable defined in dart:core.
  Constant proxyConstant;

  // TODO(johnniwinther): Move this to the JavaScriptBackend.
  /// The constant for the [patch] variable defined in dart:_js_helper.
  Constant patchConstant;

  // TODO(johnniwinther): Move this to the JavaScriptBackend.
  ClassElement nativeAnnotationClass;

  // Initialized after symbolClass has been resolved.
  FunctionElement symbolConstructor;

  // Initialized when dart:mirrors is loaded.
  ClassElement mirrorSystemClass;

  // Initialized when dart:mirrors is loaded.
  ClassElement mirrorsUsedClass;

  // Initialized after mirrorSystemClass has been resolved.
  FunctionElement mirrorSystemGetNameFunction;

  // Initialized when dart:_internal is loaded.
  ClassElement symbolImplementationClass;

  // Initialized when symbolImplementationClass has been resolved.
  FunctionElement symbolValidatedConstructor;

  // Initialized when mirrorsUsedClass has been resolved.
  FunctionElement mirrorsUsedConstructor;

  // Initialized when dart:mirrors is loaded.
  ClassElement deferredLibraryClass;

  /// Document class from dart:mirrors.
  ClassElement documentClass;
  Element identicalFunction;
  Element loadLibraryFunction;
  Element functionApplyMethod;
  Element intEnvironment;
  Element boolEnvironment;
  Element stringEnvironment;

  fromEnvironment(String name) => null;

  Element get currentElement => _currentElement;

  String tryToString(object) {
    try {
      return object.toString();
    } catch (_) {
      return '<exception in toString()>';
    }
  }

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
    } on CompilerCancelledException catch (ex) {
      rethrow;
    } on StackOverflowError catch (ex) {
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

  List<CompilerTask> tasks;
  ScannerTask scanner;
  DietParserTask dietParser;
  ParserTask parser;
  PatchParserTask patchParser;
  LibraryLoaderTask libraryLoader;
  ResolverTask resolver;
  closureMapping.ClosureTask closureToClassMapper;
  TypeCheckerTask checker;
  IrBuilderTask irBuilder;
  ti.TypesTask typesTask;
  Backend backend;

  /// The constant environment for the frontend interpretation of compile-time
  /// constants.
  ConstantEnvironment constants;

  EnqueueTask enqueuer;
  DeferredLoadTask deferredLoadTask;
  MirrorUsageAnalyzerTask mirrorUsageAnalyzerTask;
  DumpInfoTask dumpInfoTask;
  String buildId;

  /// A customizable filter that is applied to enqueued work items.
  QueueFilter enqueuerFilter = new QueueFilter();

  static const String MAIN = 'main';
  static const String CALL_OPERATOR_NAME = 'call';
  static const String NO_SUCH_METHOD = 'noSuchMethod';
  static const int NO_SUCH_METHOD_ARG_COUNT = 1;
  static const String CREATE_INVOCATION_MIRROR =
      'createInvocationMirror';

  static const String RUNTIME_TYPE = 'runtimeType';

  static const String UNDETERMINED_BUILD_ID =
      "build number could not be determined";

  final Selector iteratorSelector =
      new Selector.getter('iterator', null);
  final Selector currentSelector =
      new Selector.getter('current', null);
  final Selector moveNextSelector =
      new Selector.call('moveNext', null, 0);
  final Selector noSuchMethodSelector = new Selector.call(
      Compiler.NO_SUCH_METHOD, null, Compiler.NO_SUCH_METHOD_ARG_COUNT);
  final Selector symbolValidatedConstructorSelector = new Selector.call(
      'validated', null, 1);
  final Selector fromEnvironmentSelector = new Selector.callConstructor(
      'fromEnvironment', null, 2);

  bool enabledNoSuchMethod = false;
  bool enabledRuntimeType = false;
  bool enabledFunctionApply = false;
  bool enabledInvokeOn = false;
  bool hasIsolateSupport = false;

  Stopwatch progress;

  bool get shouldPrintProgress {
    return verbose && progress.elapsedMilliseconds > 500;
  }

  static const int PHASE_SCANNING = 0;
  static const int PHASE_RESOLVING = 1;
  static const int PHASE_DONE_RESOLVING = 2;
  static const int PHASE_COMPILING = 3;
  int phase;

  bool compilationFailed = false;

  bool hasCrashed = false;

  /// Set by the backend if real reflection is detected in use of dart:mirrors.
  bool disableTypeInferenceForMirrors = false;

  Compiler({this.enableTypeAssertions: false,
            this.enableUserAssertions: false,
            this.trustTypeAnnotations: false,
            this.enableConcreteTypeInference: false,
            bool disableTypeInferenceFlag: false,
            this.maxConcreteTypeSize: 5,
            this.enableMinification: false,
            this.enableNativeLiveTypeAnalysis: false,
            bool emitJavaScript: true,
            bool dart2dartMultiFile: false,
            bool generateSourceMap: true,
            bool analyzeAllFlag: false,
            bool analyzeOnly: false,
            this.analyzeMain: false,
            bool analyzeSignaturesOnly: false,
            this.preserveComments: false,
            this.verbose: false,
            this.sourceMapUri: null,
            this.outputUri: null,
            this.buildId: UNDETERMINED_BUILD_ID,
            this.terseDiagnostics: false,
            this.dumpInfo: false,
            this.showPackageWarnings: false,
            this.useContentSecurityPolicy: false,
            this.suppressWarnings: false,
            bool hasIncrementalSupport: false,
            api.CompilerOutputProvider outputProvider,
            List<String> strips: const []})
      : this.disableTypeInferenceFlag =
          disableTypeInferenceFlag || !emitJavaScript,
        this.analyzeOnly =
            analyzeOnly || analyzeSignaturesOnly || analyzeAllFlag,
        this.analyzeSignaturesOnly = analyzeSignaturesOnly,
        this.analyzeAllFlag = analyzeAllFlag,
        this.hasIncrementalSupport = hasIncrementalSupport,
        cacheStrategy = new CacheStrategy(hasIncrementalSupport),
        this.outputProvider = (outputProvider == null)
            ? NullSink.outputProvider
            : outputProvider {
    world = new World(this);
    types = new Types(this);
    tracer = new Tracer(this.outputProvider);

    if (verbose) {
      progress = new Stopwatch()..start();
    }

    // TODO(johnniwinther): Separate the dependency tracking from the enqueueing
    // for global dependencies.
    globalDependencies =
        new CodegenRegistry(this, new TreeElementMapping(null));

    closureMapping.ClosureNamer closureNamer;
    if (emitJavaScript) {
      js_backend.JavaScriptBackend jsBackend =
          new js_backend.JavaScriptBackend(this, generateSourceMap);
      closureNamer = jsBackend.namer;
      backend = jsBackend;
    } else {
      closureNamer = new closureMapping.ClosureNamer();
      backend = new dart_backend.DartBackend(this, strips,
                                             multiFile: dart2dartMultiFile);
    }

    tasks = [
      libraryLoader = new LibraryLoaderTask(this),
      scanner = new ScannerTask(this),
      dietParser = new DietParserTask(this),
      parser = new ParserTask(this),
      patchParser = new PatchParserTask(this),
      resolver = new ResolverTask(this, backend.constantCompilerTask),
      closureToClassMapper = new closureMapping.ClosureTask(this, closureNamer),
      checker = new TypeCheckerTask(this),
      irBuilder = new IrBuilderTask(this),
      typesTask = new ti.TypesTask(this),
      constants = backend.constantCompilerTask,
      deferredLoadTask = new DeferredLoadTask(this),
      mirrorUsageAnalyzerTask = new MirrorUsageAnalyzerTask(this),
      enqueuer = new EnqueueTask(this),
      dumpInfoTask = new DumpInfoTask(this)];

    tasks.addAll(backend.tasks);
  }

  Universe get resolverWorld => enqueuer.resolution.universe;
  Universe get codegenWorld => enqueuer.codegen.universe;

  bool get hasBuildId => buildId != UNDETERMINED_BUILD_ID;

  bool get analyzeAll => analyzeAllFlag || compileAll;

  bool get compileAll => false;

  bool get disableTypeInference => disableTypeInferenceFlag;

  int getNextFreeClassId() => nextFreeClassId++;

  void unimplemented(Spannable spannable, String methodName) {
    internalError(spannable, "$methodName not implemented.");
  }

  void internalError(Spannable node, reason) {
    assembledCode = null; // Compilation failed. Make sure that we
                          // don't return a bogus result.
    String message = tryToString(reason);
    reportDiagnosticInternal(
        node, MessageKind.GENERIC, {'text': message}, api.Diagnostic.CRASH);
    throw 'Internal Error: $message';
  }

  void unhandledExceptionOnElement(Element element) {
    if (hasCrashed) return;
    hasCrashed = true;
    reportDiagnostic(element,
                     MessageKind.COMPILER_CRASHED.message(),
                     api.Diagnostic.CRASH);
    pleaseReportCrash();
  }

  void pleaseReportCrash() {
    print(MessageKind.PLEASE_REPORT_THE_CRASH.message({'buildId': buildId}));
  }

  SourceSpan spanFromSpannable(Spannable node) {
    // TODO(johnniwinther): Disallow `node == null` ?
    if (node == null) return null;
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
    } else if (node is Token) {
      return spanFromTokens(node, node);
    } else if (node is HInstruction) {
      return spanFromHInstruction(node);
    } else if (node is Element) {
      return spanFromElement(node);
    } else if (node is MetadataAnnotation) {
      Uri uri = node.annotatedElement.compilationUnit.script.readableUri;
      return spanFromTokens(node.beginToken, node.endToken, uri);
    } else if (node is Local) {
      Local local = node;
      return spanFromElement(local.executableContext);
    } else {
      throw 'No error location.';
    }
  }

  Element _elementFromHInstruction(HInstruction instruction) {
    return instruction.sourceElement is Element
        ? instruction.sourceElement : null;
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
    reportDiagnostic(null,
        MessageKind.GENERIC.message({'text': '$message'}),
        api.Diagnostic.VERBOSE_INFO);
  }

  Future<bool> run(Uri uri) {
    totalCompileTime.start();

    return new Future.sync(() => runCompiler(uri)).catchError((error) {
      if (error is CompilerCancelledException) {
        compilerWasCancelled = true;
        log('Error: $error');
        return false;
      }

      try {
        if (!hasCrashed) {
          hasCrashed = true;
          if (error is SpannableAssertionFailure) {
            reportAssertionFailure(error);
          } else {
            reportDiagnostic(new SourceSpan(uri, 0, 0),
                             MessageKind.COMPILER_CRASHED.message(),
                             api.Diagnostic.CRASH);
          }
          pleaseReportCrash();
        }
      } catch (doubleFault) {
        // Ignoring exceptions in exception handling.
      }
      throw error;
    }).whenComplete(() {
      tracer.close();
      totalCompileTime.stop();
    }).then((_) {
      return !compilationFailed;
    });
  }

  /// This method is called immediately after the [LibraryElement] [library] has
  /// been created.
  ///
  /// Use this callback method to store references to specific libraries.
  /// Note that [library] has not been scanned yet, nor has its imports/exports
  /// been resolved.
  void onLibraryCreated(LibraryElement library) {
    Uri uri = library.canonicalUri;
    if (uri == DART_CORE) {
      coreLibrary = library;
    } else if (uri == DART_NATIVE_TYPED_DATA) {
      typedDataLibrary = library;
    } else if (uri == DART_MIRRORS) {
      mirrorsLibrary = library;
    }
    backend.onLibraryCreated(library);
  }

  /// This method is called immediately after the [library] and its parts have
  /// been scanned.
  ///
  /// Use this callback method to store references to specific member declared
  /// in certain libraries. Note that [library] has not been patched yet, nor
  /// has its imports/exports been resolved.
  ///
  /// Use [loader] to register the creation and scanning of a patch library
  /// for [library].
  Future onLibraryScanned(LibraryElement library, LibraryLoader loader) {
    Uri uri = library.canonicalUri;
    if (uri == DART_CORE) {
      initializeCoreClasses();
      identicalFunction = coreLibrary.find('identical');
    } else if (uri == DART_INTERNAL) {
      symbolImplementationClass = findRequiredElement(library, 'Symbol');
    } else if (uri == DART_MIRRORS) {
      mirrorSystemClass = findRequiredElement(library, 'MirrorSystem');
      mirrorsUsedClass = findRequiredElement(library, 'MirrorsUsed');
    } else if (uri == DART_ASYNC) {
      deferredLibraryClass = findRequiredElement(library, 'DeferredLibrary');
    } else if (uri == DART_NATIVE_TYPED_DATA) {
      typedDataClass = findRequiredElement(library, 'NativeTypedData');
    } else if (uri == js_backend.JavaScriptBackend.DART_JS_HELPER) {
      nativeAnnotationClass = findRequiredElement(library, 'Native');
    }
    return backend.onLibraryScanned(library, loader);
  }

  /// This method is called when all new libraries loaded through
  /// [LibraryLoader.loadLibrary] has been loaded and their imports/exports
  /// have been computed.
  ///
  /// [loadedLibraries] contains the newly loaded libraries.
  ///
  /// The method returns a [Future] allowing for the loading of additional
  /// libraries.
  Future onLibrariesLoaded(Map<Uri, LibraryElement> loadedLibraries) {
    return new Future.sync(() {
      if (!loadedLibraries.containsKey(DART_CORE)) return new Future.value();

      functionClass.ensureResolved(this);
      functionApplyMethod = functionClass.lookupLocalMember('apply');

      proxyConstant =
          resolver.constantCompiler.compileConstant(coreLibrary.find('proxy'));

      // TODO(johnniwinther): Move this to the JavaScript backend.
      LibraryElement jsHelperLibrary =
          loadedLibraries[js_backend.JavaScriptBackend.DART_JS_HELPER];
      if (jsHelperLibrary != null) {
        patchConstant = resolver.constantCompiler.compileConstant(
            jsHelperLibrary.find('patch'));
      }

      if (preserveComments) {
        return libraryLoader.loadLibrary(DART_MIRRORS)
            .then((LibraryElement libraryElement) {
          documentClass = libraryElement.find('Comment');
        });
      }
    }).then((_) => backend.onLibrariesLoaded(loadedLibraries));
  }

  Element findRequiredElement(LibraryElement library, String name) {
    var element = library.find(name);
    if (element == null) {
      internalError(library,
          "The library '${library.canonicalUri}' does not contain required "
          "element: '$name'.");
      }
    return element;
  }

  void onClassResolved(ClassElement cls) {
    if (mirrorSystemClass == cls) {
      mirrorSystemGetNameFunction =
        cls.lookupLocalMember('getName');
    } else if (symbolClass == cls) {
      symbolConstructor = cls.constructors.head;
    } else if (symbolImplementationClass == cls) {
      symbolValidatedConstructor = symbolImplementationClass.lookupConstructor(
          symbolValidatedConstructorSelector);
    } else if (mirrorsUsedClass == cls) {
      mirrorsUsedConstructor = cls.constructors.head;
    } else if (intClass == cls) {
      intEnvironment = intClass.lookupConstructor(fromEnvironmentSelector);
    } else if (stringClass == cls) {
      stringEnvironment =
          stringClass.lookupConstructor(fromEnvironmentSelector);
    } else if (boolClass == cls) {
      boolEnvironment = boolClass.lookupConstructor(fromEnvironmentSelector);
    }
  }

  void initializeCoreClasses() {
    final List missingCoreClasses = [];
    ClassElement lookupCoreClass(String name) {
      ClassElement result = coreLibrary.find(name);
      if (result == null) {
        missingCoreClasses.add(name);
      }
      return result;
    }
    objectClass = lookupCoreClass('Object');
    boolClass = lookupCoreClass('bool');
    numClass = lookupCoreClass('num');
    intClass = lookupCoreClass('int');
    doubleClass = lookupCoreClass('double');
    stringClass = lookupCoreClass('String');
    functionClass = lookupCoreClass('Function');
    listClass = lookupCoreClass('List');
    typeClass = lookupCoreClass('Type');
    mapClass = lookupCoreClass('Map');
    nullClass = lookupCoreClass('Null');
    stackTraceClass = lookupCoreClass('StackTrace');
    if (!missingCoreClasses.isEmpty) {
      internalError(coreLibrary,
          'dart:core library does not contain required classes: '
          '$missingCoreClasses');
    }

    // The Symbol class may not exist during unit testing.
    // TODO(ahe): It is possible that we have to require the presence
    // of Symbol as we change how we implement noSuchMethod.
    symbolClass = lookupCoreClass('Symbol');
  }

  Element _unnamedListConstructor;
  Element get unnamedListConstructor {
    if (_unnamedListConstructor != null) return _unnamedListConstructor;
    Selector callConstructor = new Selector.callConstructor(
        "", listClass.library);
    return _unnamedListConstructor =
        listClass.lookupConstructor(callConstructor);
  }

  Element _filledListConstructor;
  Element get filledListConstructor {
    if (_filledListConstructor != null) return _filledListConstructor;
    Selector callConstructor = new Selector.callConstructor(
        "filled", listClass.library);
    return _filledListConstructor =
        listClass.lookupConstructor(callConstructor);
  }

  /**
   * Get an [Uri] pointing to a patch for the dart: library with
   * the given path. Returns null if there is no patch.
   */
  Uri resolvePatchUri(String dartLibraryPath);

  Future runCompiler(Uri uri) {
    // TODO(ahe): This prevents memory leaks when invoking the compiler
    // multiple times. Implement a better mechanism where we can store
    // such caches in the compiler and get access to them through a
    // suitably maintained static reference to the current compiler.
    StringToken.canonicalizedSubstrings.clear();
    Selector.canonicalizedValues.clear();
    TypedSelector.canonicalizedValues.clear();

    assert(uri != null || analyzeOnly);
    return new Future.sync(() {
      if (librariesToAnalyzeWhenRun != null) {
        return Future.forEach(librariesToAnalyzeWhenRun, (libraryUri) {
          log('Analyzing $libraryUri ($buildId)');
          return libraryLoader.loadLibrary(libraryUri);
        });
      }
    }).then((_) {
      if (uri != null) {
        if (analyzeOnly) {
          log('Analyzing $uri ($buildId)');
        } else {
          log('Compiling $uri ($buildId)');
        }
        return libraryLoader.loadLibrary(uri).then((LibraryElement library) {
          mainApp = library;
        });
      }
    }).then((_) {
      if (!compilationFailed) {
        // TODO(johnniwinther): Reenable analysis of programs with load failures
        // when these are handled as erroneous libraries/compilation units.
        compileLoadedLibraries();
      }
    });
  }

  void computeMain() {
    if (mainApp == null) return;

    Element main = mainApp.findExported(MAIN);
    ErroneousElement errorElement = null;
    if (main == null) {
      if (analyzeOnly) {
        if (!analyzeAll) {
          errorElement = new ErroneousElementX(
              MessageKind.CONSIDER_ANALYZE_ALL, {'main': MAIN}, MAIN, mainApp);
        }
      } else {
        // Compilation requires a main method.
        errorElement = new ErroneousElementX(
            MessageKind.MISSING_MAIN, {'main': MAIN}, MAIN, mainApp);
      }
      mainFunction = backend.helperForMissingMain();
    } else if (main.isErroneous && main.isSynthesized) {
      if (main is ErroneousElement) {
        errorElement = main;
      } else {
        internalError(main, 'Problem with $MAIN.');
      }
      mainFunction = backend.helperForBadMain();
    } else if (!main.isFunction) {
      errorElement = new ErroneousElementX(
          MessageKind.MAIN_NOT_A_FUNCTION, {'main': MAIN}, MAIN, main);
      mainFunction = backend.helperForBadMain();
    } else {
      mainFunction = main;
      FunctionSignature parameters = mainFunction.computeSignature(this);
      if (parameters.requiredParameterCount > 2) {
        int index = 0;
        parameters.orderedForEachParameter((Element parameter) {
          if (index++ < 2) return;
          errorElement = new ErroneousElementX(
              MessageKind.MAIN_WITH_EXTRA_PARAMETER, {'main': MAIN}, MAIN,
              parameter);
          mainFunction = backend.helperForMainArity();
          // Don't warn about main not being used:
          enqueuer.resolution.registerStaticUse(main);
        });
      }
    }
    if (mainFunction == null) {
      if (errorElement == null && !analyzeOnly && !analyzeAll) {
        internalError(mainApp, "Problem with '$MAIN'.");
      } else {
        mainFunction = errorElement;
      }
    }
    if (errorElement != null && errorElement.isSynthesized) {
      reportWarning(
          errorElement, errorElement.messageKind,
          errorElement.messageArguments);
    }
  }

  /// Performs the compilation when all libraries have been loaded.
  void compileLoadedLibraries() {
    computeMain();

    mirrorUsageAnalyzerTask.analyzeUsage(mainApp);

    // In order to see if a library is deferred, we must compute the
    // compile-time constants that are metadata.  This means adding
    // something to the resolution queue.  So we cannot wait with
    // this until after the resolution queue is processed.
    deferredLoadTask.ensureMetadataResolved(this);

    phase = PHASE_RESOLVING;
    if (analyzeAll) {
      libraryLoader.libraries.forEach((LibraryElement library) {
        log('Enqueuing ${library.canonicalUri}');
        fullyEnqueueLibrary(library, enqueuer.resolution);
      });
    } else if (analyzeMain && mainApp != null) {
      fullyEnqueueLibrary(mainApp, enqueuer.resolution);
    }
    // Elements required by enqueueHelpers are global dependencies
    // that are not pulled in by a particular element.
    backend.enqueueHelpers(enqueuer.resolution, globalDependencies);
    resolveLibraryMetadata();
    log('Resolving...');
    processQueue(enqueuer.resolution, mainFunction);
    enqueuer.resolution.logSummary(log);

    if (compilationFailed) return;
    if (!showPackageWarnings && !suppressWarnings) {
      suppressedWarnings.forEach((Uri uri, SuppressionInfo info) {
        MessageKind kind = MessageKind.HIDDEN_WARNINGS_HINTS;
        if (info.warnings == 0) {
          kind = MessageKind.HIDDEN_HINTS;
        } else if (info.hints == 0) {
          kind = MessageKind.HIDDEN_WARNINGS;
        }
        reportDiagnostic(null,
            kind.message({'warnings': info.warnings,
                          'hints': info.hints,
                          'uri': uri},
                         terseDiagnostics),
            api.Diagnostic.HINT);
      });
    }
    if (analyzeOnly) {
      if (!analyzeAll) {
        // No point in reporting unused code when [analyzeAll] is true: all
        // code is artificially used.
        reportUnusedCode();
      }
      return;
    }
    assert(mainFunction != null);
    phase = PHASE_DONE_RESOLVING;

    world.populate();
    // Compute whole-program-knowledge that the backend needs. (This might
    // require the information computed in [world.populate].)
    backend.onResolutionComplete();

    deferredLoadTask.onResolutionComplete(mainFunction);

    log('Building IR...');
    irBuilder.buildNodes();

    log('Inferring types...');
    typesTask.onResolutionComplete(mainFunction);

    if (stopAfterTypeInference) return;

    log('Compiling...');
    phase = PHASE_COMPILING;
    // TODO(johnniwinther): Move these to [CodegenEnqueuer].
    if (hasIsolateSupport) {
      backend.enableIsolateSupport(enqueuer.codegen);
      enqueuer.codegen.registerGetOfStaticFunction(mainFunction);
    }
    if (enabledNoSuchMethod) {
      backend.enableNoSuchMethod(null, enqueuer.codegen);
    }
    if (compileAll) {
      libraryLoader.libraries.forEach((LibraryElement library) {
        fullyEnqueueLibrary(library, enqueuer.codegen);
      });
    }
    processQueue(enqueuer.codegen, mainFunction);
    enqueuer.codegen.logSummary(log);

    if (compilationFailed) return;

    backend.assembleProgram();

    if (dumpInfo) {
      dumpInfoTask.dumpInfo();
    }

    checkQueues();

    if (compilationFailed) {
      assembledCode = null; // Signals failure.
    }
  }

  void fullyEnqueueLibrary(LibraryElement library, Enqueuer world) {
    void enqueueAll(Element element) {
      fullyEnqueueTopLevelElement(element, world);
    }
    library.implementation.forEachLocalMember(enqueueAll);
  }

  void fullyEnqueueTopLevelElement(Element element, Enqueuer world) {
    if (element.isClass) {
      ClassElement cls = element;
      cls.ensureResolved(this);
      cls.forEachLocalMember(enqueuer.resolution.addToWorkList);
      world.registerInstantiatedClass(element, globalDependencies);
    } else {
      world.addToWorkList(element);
    }
  }

  // Resolves metadata on library elements.  This is necessary in order to
  // resolve metadata classes referenced only from metadata on library tags.
  // TODO(ahe): Figure out how to do this lazily.
  void resolveLibraryMetadata() {
    for (LibraryElement library in libraryLoader.libraries) {
      if (library.metadata != null) {
        for (MetadataAnnotation metadata in library.metadata) {
          metadata.ensureResolved(this);
        }
      }
    }
  }

  void processQueue(Enqueuer world, Element main) {
    world.nativeEnqueuer.processNativeClasses(libraryLoader.libraries);
    if (main != null && !main.isErroneous) {
      FunctionElement mainMethod = main;
      if (mainMethod.computeSignature(this).parameterCount != 0) {
        // TODO(ngeoffray, floitsch): we should also ensure that the
        // class IsolateMessage is instantiated. Currently, just enabling
        // isolate support works.
        world.enableIsolateSupport();
        world.registerInstantiatedClass(listClass, globalDependencies);
        world.registerInstantiatedClass(stringClass, globalDependencies);
      }
      world.addToWorkList(main);
    }
    if (verbose) {
      progress.reset();
    }
    world.forEach((WorkItem work) {
      withCurrentElement(work.element, () => work.run(this, world));
    });
    world.queueIsClosed = true;
    if (compilationFailed) return;
    assert(world.checkNoEnqueuedInvokedInstanceMethods());
  }

  /**
   * Perform various checks of the queues. This includes checking that
   * the queues are empty (nothing was added after we stopped
   * processing the queues). Also compute the number of methods that
   * were resolved, but not compiled (aka excess resolution).
   */
  checkQueues() {
    for (Enqueuer world in [enqueuer.resolution, enqueuer.codegen]) {
      world.forEach((WorkItem work) {
        internalError(work.element, "Work list is not empty.");
      });
    }
    if (!REPORT_EXCESS_RESOLUTION) return;
    var resolved = new Set.from(enqueuer.resolution.resolvedElements);
    for (Element e in enqueuer.codegen.generatedCode.keys) {
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
        ClassElement enclosingClass = e.enclosingClass;
        resolved.remove(e);

      }
      if (backend.isBackendLibrary(e.library)) {
        resolved.remove(e);
      }
    }
    log('Excess resolution work: ${resolved.length}.');
    for (Element e in resolved) {
      reportWarning(e,
          MessageKind.GENERIC,
          {'text': 'Warning: $e resolved but not compiled.'});
    }
  }

  void analyzeElement(Element element) {
    assert(invariant(element,
           element.impliesType ||
           element.isField ||
           element.isFunction ||
           element.isGenerativeConstructor ||
           element.isGetter ||
           element.isSetter,
           message: 'Unexpected element kind: ${element.kind}'));
    assert(invariant(element, element is AnalyzableElement,
        message: 'Element $element is not analyzable.'));
    assert(invariant(element, element.isDeclaration));
    ResolutionEnqueuer world = enqueuer.resolution;
    if (world.hasBeenResolved(element)) return;
    assert(parser != null);
    Node tree = parser.parse(element);
    assert(invariant(element, !element.isSynthesized || tree == null));
    TreeElements elements = resolver.resolve(element);
    if (elements != null) {
      if (tree != null && !analyzeSignaturesOnly &&
          !suppressWarnings) {
        // Only analyze nodes with a corresponding [TreeElements].
        checker.check(elements);
      }
      world.registerResolvedElement(element);
    }
  }

  void analyze(ResolutionWorkItem work, ResolutionEnqueuer world) {
    assert(invariant(work.element, identical(world, enqueuer.resolution)));
    assert(invariant(work.element, !work.isAnalyzed(),
        message: 'Element ${work.element} has already been analyzed'));
    if (shouldPrintProgress) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      if (phase == PHASE_RESOLVING) {
        log('Resolved ${enqueuer.resolution.resolvedElements.length} '
            'elements.');
        progress.reset();
      }
    }
    AstElement element = work.element;
    if (world.hasBeenResolved(element)) return;
    analyzeElement(element);
    backend.onElementResolved(element, element.resolvedAst.elements);
  }

  void codegen(CodegenWorkItem work, CodegenEnqueuer world) {
    assert(invariant(work.element, identical(world, enqueuer.codegen)));
    if (shouldPrintProgress) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      log('Compiled ${enqueuer.codegen.generatedCode.length} methods.');
      progress.reset();
    }
    backend.codegen(work);
  }

  void reportError(Spannable node,
                   MessageKind messageKind,
                   [Map arguments = const {}]) {
    reportDiagnosticInternal(
        node, messageKind, arguments, api.Diagnostic.ERROR);
  }

  /**
   * Reports an error and then aborts the compiler. Avoid using this method.
   *
   * In order to support incremental compilation, it is preferable to use
   * [reportError]. However, care must be taken to leave the compiler in a
   * consistent state, for example, by creating synthetic erroneous objects.
   *
   * If there's absolutely no way to leave the compiler in a consistent state,
   * calling this method is preferred as it will set [compilerWasCancelled] to
   * true which alerts the incremental compiler to discard all state and start
   * a new compiler. Throwing an exception is also better, as this will set
   * [hasCrashed] which the incremental compiler also listens too (but don't
   * throw exceptions, it creates a really bad user experience).
   *
   * In any case, calling this method is a last resort, as it essentially
   * breaks the user experience of the incremental compiler. The purpose of the
   * incremental compiler is to improve developer productivity. Developers
   * frequently make mistakes, so syntax errors and spelling errors are
   * considered normal to the incremental compiler.
   */
  void reportFatalError(Spannable node, MessageKind messageKind,
                        [Map arguments = const {}]) {
    reportError(node, messageKind, arguments);
    // TODO(ahe): Make this only abort the current method.
    throw new CompilerCancelledException(
        'Error: Cannot continue due to previous error.');
  }

  void reportWarning(Spannable node, MessageKind messageKind,
                     [Map arguments = const {}]) {
    reportDiagnosticInternal(
        node, messageKind, arguments, api.Diagnostic.WARNING);
  }

  void reportInfo(Spannable node, MessageKind messageKind,
                  [Map arguments = const {}]) {
    reportDiagnosticInternal(node, messageKind, arguments, api.Diagnostic.INFO);
  }

  void reportHint(Spannable node, MessageKind messageKind,
                  [Map arguments = const {}]) {
    reportDiagnosticInternal(node, messageKind, arguments, api.Diagnostic.HINT);
  }

  void reportDiagnosticInternal(Spannable node,
                                MessageKind messageKind,
                                Map arguments,
                                api.Diagnostic kind) {
    if (!showPackageWarnings && node != NO_LOCATION_SPANNABLE) {
      switch (kind) {
      case api.Diagnostic.WARNING:
      case api.Diagnostic.HINT:
        Element element = elementFromSpannable(node);
        if (!inUserCode(element, assumeInUserCode: true)) {
          Uri uri = getCanonicalUri(element);
          SuppressionInfo info =
              suppressedWarnings.putIfAbsent(uri, () => new SuppressionInfo());
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
    reportDiagnostic(
        node, messageKind.message(arguments, terseDiagnostics), kind);
  }

  void reportDiagnostic(Spannable span,
                        Message message,
                        api.Diagnostic kind);

  void reportAssertionFailure(SpannableAssertionFailure ex) {
    String message = (ex.message != null) ? tryToString(ex.message)
                                          : tryToString(ex);
    SourceSpan span = spanFromSpannable(ex.node);
    reportDiagnosticInternal(
        ex.node, MessageKind.GENERIC, {'text': message}, api.Diagnostic.CRASH);
  }

  SourceSpan spanFromTokens(Token begin, Token end, [Uri uri]) {
    if (begin == null || end == null) {
      // TODO(ahe): We can almost always do better. Often it is only
      // end that is null. Otherwise, we probably know the current
      // URI.
      throw 'Cannot find tokens to produce error message.';
    }
    if (uri == null && currentElement != null) {
      uri = currentElement.compilationUnit.script.readableUri;
    }
    return SourceSpan.withCharacterOffsets(begin, end,
      (beginOffset, endOffset) => new SourceSpan(uri, beginOffset, endOffset));
  }

  SourceSpan spanFromNode(Node node) {
    return spanFromTokens(node.getBeginToken(), node.getEndToken());
  }

  SourceSpan spanFromElement(Element element) {
    while (element != null && element.isSynthesized) {
      element = element.enclosingElement;
    }
    if (element != null &&
        element.position == null &&
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
    Token position = element.position;
    Uri uri = element.compilationUnit.script.readableUri;
    return (position == null)
        ? new SourceSpan(uri, 0, 0)
        : spanFromTokens(position, position, uri);
  }

  SourceSpan spanFromHInstruction(HInstruction instruction) {
    Element element = _elementFromHInstruction(instruction);
    if (element == null) element = currentElement;
    var position = instruction.sourcePosition;
    if (position == null) return spanFromElement(element);
    Token token = position.token;
    if (token == null) return spanFromElement(element);
    Uri uri = element.compilationUnit.script.readableUri;
    return spanFromTokens(token, token, uri);
  }

  /**
   * Translates the [resolvedUri] into a readable URI.
   *
   * The [importingLibrary] holds the library importing [resolvedUri] or
   * [:null:] if [resolvedUri] is loaded as the main library. The
   * [importingLibrary] is used to grant access to internal libraries from
   * platform libraries and patch libraries.
   *
   * If the [resolvedUri] is not accessible from [importingLibrary], this method
   * is responsible for reporting errors.
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Uri translateResolvedUri(LibraryElement importingLibrary,
                           Uri resolvedUri, Node node) {
    unimplemented(importingLibrary, 'Compiler.translateResolvedUri');
    return null;
  }

  /**
   * Reads the script specified by the [readableUri].
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Future<Script> readScript(Spannable node, Uri readableUri) {
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

  Token processAndStripComments(Token currentToken) {
    Token firstToken = currentToken;
    Token prevToken;
    while (currentToken.kind != EOF_TOKEN) {
      if (identical(currentToken.kind, COMMENT_TOKEN)) {
        Token firstCommentToken = currentToken;
        while (identical(currentToken.kind, COMMENT_TOKEN)) {
          currentToken = currentToken.next;
        }
        commentMap[currentToken] = firstCommentToken;
        if (prevToken == null) {
          firstToken = currentToken;
        } else {
          prevToken.next = currentToken;
        }
      }
      prevToken = currentToken;
      currentToken = currentToken.next;
    }
    return firstToken;
  }

  void reportUnusedCode() {
    void checkLive(member) {
      if (member.isFunction) {
        if (!enqueuer.resolution.isLive(member)) {
          reportHint(member, MessageKind.UNUSED_METHOD,
                     {'name': member.name});
        }
      } else if (member.isClass) {
        if (!member.isResolved) {
          reportHint(member, MessageKind.UNUSED_CLASS,
                     {'name': member.name});
        } else {
          member.forEachLocalMember(checkLive);
        }
      } else if (member.isTypedef) {
        if (!member.isResolved) {
          reportHint(member, MessageKind.UNUSED_TYPEDEF,
                     {'name': member.name});
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
    List<Uri> entrypoints = <Uri>[];
    if (mainApp != null) {
      entrypoints.add(mainApp.canonicalUri);
    }
    if (librariesToAnalyzeWhenRun != null) {
      entrypoints.addAll(librariesToAnalyzeWhenRun);
    }
    if (entrypoints.isEmpty && assumeInUserCode) {
      // Assume in user code since [mainApp] has not been set yet.
      return true;
    }
    if (element == null) return false;
    Uri libraryUri = element.library.canonicalUri;
    if (libraryUri.scheme == 'package') {
      for (Uri uri in entrypoints) {
        if (uri.scheme != 'package') continue;
        int slashPos = libraryUri.path.indexOf('/');
        if (slashPos != -1) {
          String packageName = libraryUri.path.substring(0, slashPos + 1);
          if (uri.path.startsWith(packageName)) {
            return true;
          }
        } else {
          if (libraryUri.path == uri.path) {
            return true;
          }
        }
      }
    } else {
      for (Uri uri in entrypoints) {
        if (libraryUri.scheme == uri.scheme) return true;
      }
    }
    return false;
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

}

class CompilerTask {
  final Compiler compiler;
  final Stopwatch watch;
  UserTag profilerTag;

  CompilerTask(Compiler compiler)
      : this.compiler = compiler,
        watch = (compiler.verbose) ? new Stopwatch() : null;

  String get name => 'Unknown task';
  int get timing => (watch != null) ? watch.elapsedMilliseconds : 0;

  UserTag getProfilerTag() {
    if (profilerTag == null) profilerTag = new UserTag(name);
    return profilerTag;
  }

  measure(action()) {
    // In verbose mode when watch != null.
    if (watch == null) return action();
    CompilerTask previous = compiler.measuredTask;
    if (identical(this, previous)) return action();
    compiler.measuredTask = this;
    if (previous != null) previous.watch.stop();
    watch.start();
    UserTag oldTag = getProfilerTag().makeCurrent();
    try {
      return action();
    } finally {
      watch.stop();
      oldTag.makeCurrent();
      if (previous != null) previous.watch.start();
      compiler.measuredTask = previous;
    }
  }

  measureElement(Element element, action()) {
    compiler.withCurrentElement(element, () => measure(action));
  }
}

class CompilerCancelledException implements Exception {
  final String reason;
  CompilerCancelledException(this.reason);

  String toString() {
    String banner = 'compiler cancelled';
    return (reason != null) ? '$banner: $reason' : '$banner';
  }
}

class SourceSpan implements Spannable {
  final Uri uri;
  final int begin;
  final int end;

  const SourceSpan(this.uri, this.begin, this.end);

  static withCharacterOffsets(Token begin, Token end,
                     f(int beginOffset, int endOffset)) {
    final beginOffset = begin.charOffset;
    final endOffset = end.charOffset + end.charCount;

    // [begin] and [end] might be the same for the same empty token. This
    // happens for instance when scanning '$$'.
    assert(endOffset >= beginOffset);
    return f(beginOffset, endOffset);
  }

  String toString() => 'SourceSpan($uri, $begin, $end)';
}

/**
 * Throws a [SpannableAssertionFailure] if [condition] is
 * [:false:]. [condition] must be either a [:bool:] or a no-arg
 * function returning a [:bool:].
 *
 * Use this method to provide better information for assertion by calling
 * [invariant] as the argument to an [:assert:] statement:
 *
 *     assert(invariant(position, isValid));
 *
 * [spannable] must be non-null and will be used to provide positional
 * information in the generated error message.
 */
bool invariant(Spannable spannable, var condition, {var message: null}) {
  // TODO(johnniwinther): Use [spannable] and [message] to provide better
  // information on assertion errors.
  if (spannable == null) {
    throw new SpannableAssertionFailure(CURRENT_ELEMENT_SPANNABLE,
        "Spannable was null for invariant. Use CURRENT_ELEMENT_SPANNABLE.");
  }
  if (condition is Function){
    condition = condition();
  }
  if (!condition) {
    if (message is Function) {
      message = message();
    }
    throw new SpannableAssertionFailure(spannable, message);
  }
  return true;
}

/**
 * Global
 */
bool isPrivateName(String s) => !s.isEmpty && s.codeUnitAt(0) == $_;

/// A sink that drains into /dev/null.
class NullSink implements EventSink<String> {
  final String name;

  NullSink(this.name);

  add(String value) {}

  void addError(Object error, [StackTrace stackTrace]) {}

  void close() {}

  toString() => name;

  /// Convenience method for getting an [api.CompilerOutputProvider].
  static NullSink outputProvider(String name, String extension) {
    return new NullSink('$name.$extension');
  }
}

/// Information about suppressed warnings and hints for a given library.
class SuppressionInfo {
  int warnings = 0;
  int hints = 0;
}

class GenericTask extends CompilerTask {
  final String name;

  GenericTask(this.name, Compiler compiler)
      : super(compiler);
}
