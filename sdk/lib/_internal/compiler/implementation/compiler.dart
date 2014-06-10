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
  final Element element;
  TreeElements resolutionTree;

  WorkItem(this.element, this.compilationContext) {
    assert(invariant(element, element.isDeclaration));
  }

  void run(Compiler compiler, Enqueuer world);
}

/// [WorkItem] used exclusively by the [ResolutionEnqueuer].
class ResolutionWorkItem extends WorkItem {
  ResolutionWorkItem(Element element,
                     ItemCompilationContext compilationContext)
      : super(element, compilationContext);

  void run(Compiler compiler, ResolutionEnqueuer world) {
    resolutionTree = compiler.analyze(this, world);
  }

  bool isAnalyzed() => resolutionTree != null;
}

// TODO(johnniwinther): Split this class into interface and implementation.
// TODO(johnniwinther): Move this implementation to the JS backend.
class CodegenRegistry extends Registry {
  final Compiler compiler;
  final TreeElements treeElements;

  CodegenRegistry(this.compiler, this.treeElements);

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
  }

  void registerDynamicSetter(Selector selector) {
    world.registerDynamicSetter(selector);
  }

  void registerDynamicGetter(Selector selector) {
    world.registerDynamicGetter(selector);
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
  }

  void registerCompileTimeConstant(Constant constant) {
    backend.registerCompileTimeConstant(constant, this);
    backend.constants.addCompileTimeConstantForEmission(constant);
  }

  void registerTypeVariableBoundsSubtypeCheck(DartType subtype,
                                              DartType supertype) {
    backend.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
  }

  void registerGenericClosure(FunctionElement element) {
    backend.registerGenericClosure(element, world, this);
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
    world.registerConstSymbol(name, this);
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
}

/// [WorkItem] used exclusively by the [CodegenEnqueuer].
class CodegenWorkItem extends WorkItem {
  Registry registry;

  CodegenWorkItem(Element element,
                  ItemCompilationContext compilationContext)
      : super(element, compilationContext);

  void run(Compiler compiler, CodegenEnqueuer world) {
    if (world.isProcessed(element)) return;
    resolutionTree =
        compiler.enqueuer.resolution.getCachedElements(element);
    assert(invariant(element, resolutionTree != null,
        message: 'Resolution tree is null for $element in codegen work item'));
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

  /// Called during post-processing when [constant] has been evaluated.
  void registerMetadataConstant(Constant constant, Registry registry) {}

  /// Called during resolution to notify to the backend that a class is
  /// being instantiated.
  void registerInstantiatedClass(ClassElement cls,
                                 Enqueuer enqueuer,
                                 Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program uses string interpolation.
  void registerStringInterpolation(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program has a catch statement.
  void registerCatchStatement(Enqueuer enqueuer,
                              Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program explicitly throws an exception.
  void registerThrowExpression(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program has a global variable with a lazy initializer.
  void registerLazyField(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program uses a type variable as an expression.
  void registerTypeVariableExpression(Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program uses a type literal.
  void registerTypeLiteral(DartType type,
                           Enqueuer enqueuer,
                           Registry registry) {}

  /// Called during resolution to notify to the backend that the
  /// program has a catch statement with a stack trace.
  void registerStackTraceInCatch(Registry registry) {}

  /// Register an is check to the backend.
  void registerIsCheck(DartType type,
                       Enqueuer enqueuer,
                       Registry registry) {}

  /// Register an as check to the backend.
  void registerAsCheck(DartType type,
                       Enqueuer enqueuer,
                       Registry registry) {}

  /// Register a runtime type variable bound tests between [typeArgument] and
  /// [bound].
  void registerTypeVariableBoundsSubtypeCheck(DartType typeArgument,
                                              DartType bound) {}

  /// Registers that a type variable bounds check might occur at runtime.
  void registerTypeVariableBoundCheck(Registry registry) {}

  /// Register that the application may throw a [NoSuchMethodError].
  void registerThrowNoSuchMethod(Registry registry) {}

  /// Register that the application may throw a [RuntimeError].
  void registerThrowRuntimeError(Registry registry) {}

  /// Register that the application may throw an
  /// [AbstractClassInstantiationError].
  void registerAbstractClassInstantiation(Registry registry) {}

  /// Register that the application may throw a [FallThroughError].
  void registerFallThroughError(Registry registry) {}

  /// Register that a super call will end up calling
  /// [: super.noSuchMethod :].
  void registerSuperNoSuchMethod(Registry registry) {}

  /// Register that the application creates a constant map.
  void registerConstantMap(Registry registry) {}

  /**
   * Call this to register that an instantiated generic class has a call
   * method.
   */
  void registerGenericCallMethod(Element callMethod,
                                 Enqueuer enqueuer,
                                 Registry registry) {}
  /**
   * Call this to register that a getter exists for a function on an
   * instantiated generic class.
   */
  void registerGenericClosure(Element closure,
                              Enqueuer enqueuer,
                              Registry registry) {}
  /**
   * Call this to register that the [:runtimeType:] property has been accessed.
   */
  void registerRuntimeType(Enqueuer enqueuer, Registry registry) {}

  /**
   * Call this method to enable [noSuchMethod] handling in the
   * backend.
   */
  void enableNoSuchMethod(Enqueuer enqueuer) {
    enqueuer.registerInvocation(compiler.noSuchMethodSelector);
  }

  void registerRequiredType(DartType type, Element enclosingElement) {}
  void registerClassUsingVariableExpression(ClassElement cls) {}

  void registerConstSymbol(String name, Registry registry) {}
  void registerNewSymbol(Registry registry) {}
  /// Called when resolving the `Symbol` constructor.
  void registerSymbolConstructor(Registry registry) {}

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

  void registerStaticUse(Element element, Enqueuer enqueuer) {}

  Future onLibraryLoaded(LibraryElement library, Uri uri) {
    return new Future.value();
  }

  /// Called by [MirrorUsageAnalyzerTask] after it has merged all @MirrorsUsed
  /// annotations. The arguments corresponds to the unions of the corresponding
  /// fields of the annotations.
  void registerMirrorUsage(Set<String> symbols,
                           Set<Element> targets,
                           Set<Element> metaTargets) {}

  /// Returns true if this element should be retained for reflection even if it
  /// would normally be tree-shaken away.
  bool isNeededForReflection(Element element) => false;

  /// Returns true if global optimizations such as type inferencing
  /// can apply to this element. One category of elements that do not
  /// apply is runtime helpers that the backend calls, but the
  /// optimizations don't see those calls.
  bool canBeUsedForGlobalOptimizations(Element element) => true;

  /// Called when [enqueuer]'s queue is empty, but before it is closed.
  /// This is used, for example, by the JS backend to enqueue additional
  /// elements needed for reflection.
  void onQueueEmpty(Enqueuer enqueuer) {}

  /// Called after [element] has been resolved.
  // TODO(johnniwinther): Change [TreeElements] to [Registry] or a dependency
  // node. [elements] is currently unused by the implementation.
  void onElementResolved(Element element, TreeElements elements) {}
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
  final Map<String, LibraryElement> libraries =
    new Map<String, LibraryElement>();
  final Stopwatch totalCompileTime = new Stopwatch();
  int nextFreeClassId = 0;
  World world;
  String assembledCode;
  Types types;

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
  // TODO(johnniwinther): This should not be a [ResolutionRegistry].
  final ResolutionRegistry globalDependencies =
      new ResolutionRegistry.internal(null, new TreeElementMapping(null));

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
  final bool disableDeferredLoading;
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
  LibraryElement isolateLibrary;
  LibraryElement isolateHelperLibrary;
  LibraryElement jsHelperLibrary;
  LibraryElement interceptorsLibrary;
  LibraryElement foreignLibrary;

  LibraryElement mainApp;
  FunctionElement mainFunction;

  /// Initialized when dart:mirrors is loaded.
  LibraryElement mirrorsLibrary;

  /// Initialized when dart:typed_data is loaded.
  LibraryElement typedDataLibrary;

  ClassElement objectClass;
  ClassElement closureClass;
  ClassElement boundClosureClass;
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

  ClassElement jsInvocationMirrorClass;
  /// Document class from dart:mirrors.
  ClassElement documentClass;
  Element assertMethod;
  Element identicalFunction;
  Element loadLibraryFunction;
  Element functionApplyMethod;
  Element invokeOnMethod;
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
  LibraryLoader libraryLoader;
  TreeValidatorTask validator;
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

  static const String MAIN = 'main';
  static const String CALL_OPERATOR_NAME = 'call';
  static const String NO_SUCH_METHOD = 'noSuchMethod';
  static const int NO_SUCH_METHOD_ARG_COUNT = 1;
  static const String CREATE_INVOCATION_MIRROR =
      'createInvocationMirror';

  // TODO(ahe): Rename this field and move this logic to backend, similar to how
  // we disable tree-shaking when seeing disableTreeShaking in js_mirrors.dart.
  static const String INVOKE_ON =
      '_getCachedInvocation';

  static const String RUNTIME_TYPE = 'runtimeType';
  static const String START_ROOT_ISOLATE =
      'startRootIsolate';

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

  Stopwatch progress = new Stopwatch()..start();

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
            this.disableTypeInferenceFlag: false,
            this.maxConcreteTypeSize: 5,
            this.enableMinification: false,
            this.enableNativeLiveTypeAnalysis: false,
            bool emitJavaScript: true,
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
            this.disableDeferredLoading: false,
            this.dumpInfo: false,
            this.showPackageWarnings: false,
            this.useContentSecurityPolicy: false,
            this.suppressWarnings: false,
            outputProvider,
            List<String> strips: const []})
      : this.analyzeOnly =
            analyzeOnly || analyzeSignaturesOnly || analyzeAllFlag,
        this.analyzeSignaturesOnly = analyzeSignaturesOnly,
        this.analyzeAllFlag = analyzeAllFlag,
        this.outputProvider = (outputProvider == null)
            ? NullSink.outputProvider
            : outputProvider {
    world = new World(this);
    tracer = new Tracer(this.outputProvider);

    closureMapping.ClosureNamer closureNamer;
    if (emitJavaScript) {
      js_backend.JavaScriptBackend jsBackend =
          new js_backend.JavaScriptBackend(this, generateSourceMap);
      closureNamer = jsBackend.namer;
      backend = jsBackend;
    } else {
      closureNamer = new closureMapping.ClosureNamer();
      backend = new dart_backend.DartBackend(this, strips);
    }

    // No-op in production mode.
    validator = new TreeValidatorTask(this);

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
    } else {
      throw 'No error location.';
    }
  }

  /// Finds the approximate [Element] for [node]. [currentElement] is used as
  /// the default value.
  Element elementFromSpannable(Spannable node) {
    Element element;
    if (node is Element) {
      element = node;
    } else if (node is HInstruction) {
      element = node.sourceElement;
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

  bool hasIsolateSupport() => isolateLibrary != null;

  /**
   * This method is called before [library] import and export scopes have been
   * set up.
   */
  Future onLibraryLoaded(LibraryElement library, Uri uri) {
    if (uri == new Uri(scheme: 'dart', path: 'mirrors')) {
      mirrorsLibrary = library;
      mirrorSystemClass =
          findRequiredElement(library, 'MirrorSystem');
      mirrorsUsedClass =
          findRequiredElement(library, 'MirrorsUsed');
    } else if (uri == new Uri(scheme: 'dart', path: '_native_typed_data')) {
      typedDataLibrary = library;
      typedDataClass =
          findRequiredElement(library, 'NativeTypedData');
    } else if (uri == new Uri(scheme: 'dart', path: '_internal')) {
      symbolImplementationClass =
          findRequiredElement(library, 'Symbol');
    } else if (uri == new Uri(scheme: 'dart', path: 'async')) {
      deferredLibraryClass =
          findRequiredElement(library, 'DeferredLibrary');
    } else if (isolateHelperLibrary == null
	       && (uri == new Uri(scheme: 'dart', path: '_isolate_helper'))) {
      isolateHelperLibrary = library;
    } else if (foreignLibrary == null
	       && (uri == new Uri(scheme: 'dart', path: '_foreign_helper'))) {
      foreignLibrary = library;
    }
    return backend.onLibraryLoaded(library, uri);
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

  Future<LibraryElement> scanBuiltinLibrary(String filename);

  void initializeSpecialClasses() {
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

    final List missingHelperClasses = [];
    ClassElement lookupHelperClass(String name) {
      ClassElement result = jsHelperLibrary.find(name);
      if (result == null) {
        missingHelperClasses.add(name);
      }
      return result;
    }
    jsInvocationMirrorClass = lookupHelperClass('JSInvocationMirror');
    boundClosureClass = lookupHelperClass('BoundClosure');
    closureClass = lookupHelperClass('Closure');
    if (!missingHelperClasses.isEmpty) {
      internalError(jsHelperLibrary,
          'dart:_js_helper library does not contain required classes: '
          '$missingHelperClasses');
    }

    if (types == null) {
      types = new Types(this);
    }
    backend.initializeHelperClasses();

    proxyConstant =
        resolver.constantCompiler.compileConstant(coreLibrary.find('proxy'));
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

  Future scanBuiltinLibraries() {
    return scanBuiltinLibrary('_js_helper').then((LibraryElement library) {
      jsHelperLibrary = library;
      return scanBuiltinLibrary('_interceptors');
    }).then((LibraryElement library) {
      interceptorsLibrary = library;

      assertMethod = jsHelperLibrary.find('assertHelper');
      identicalFunction = coreLibrary.find('identical');

      initializeSpecialClasses();

      functionClass.ensureResolved(this);
      functionApplyMethod =
          functionClass.lookupLocalMember('apply');
      jsInvocationMirrorClass.ensureResolved(this);
      invokeOnMethod = jsInvocationMirrorClass.lookupLocalMember(INVOKE_ON);

      if (preserveComments) {
        var uri = new Uri(scheme: 'dart', path: 'mirrors');
        return libraryLoader.loadLibrary(uri, null, uri).then(
            (LibraryElement libraryElement) {
          documentClass = libraryElement.find('Comment');
        });
      }
    });
  }

  void importHelperLibrary(LibraryElement library) {
    if (jsHelperLibrary != null) {
      libraryLoader.importLibrary(library, jsHelperLibrary, null);
    }
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
    return scanBuiltinLibraries().then((_) {
      if (librariesToAnalyzeWhenRun != null) {
        return Future.forEach(librariesToAnalyzeWhenRun, (libraryUri) {
          log('Analyzing $libraryUri ($buildId)');
          return libraryLoader.loadLibrary(libraryUri, null, libraryUri);
        });
      }
    }).then((_) {
      if (uri != null) {
        if (analyzeOnly) {
          log('Analyzing $uri ($buildId)');
        } else {
          log('Compiling $uri ($buildId)');
        }
        return libraryLoader.loadLibrary(uri, null, uri)
            .then((LibraryElement library) {
          mainApp = library;
        });
      }
    }).then((_) {
      compileLoadedLibraries();
    });
  }

  /// Performs the compilation when all libraries have been loaded.
  void compileLoadedLibraries() {
    Element main = null;
    if (mainApp != null) {
      main = mainApp.findExported(MAIN);
      if (main == null) {
        if (!analyzeOnly) {
          // Allow analyze only of libraries with no main.
          reportFatalError(
              mainApp,
              MessageKind.GENERIC,
              {'text': "Could not find '$MAIN'."});
        } else if (!analyzeAll) {
          reportFatalError(mainApp, MessageKind.GENERIC,
              {'text': "Could not find '$MAIN'. "
                       "No source will be analyzed. "
                       "Use '--analyze-all' to analyze all code in the "
                       "library."});
        }
      } else {
        if (main.isErroneous) {
          reportFatalError(main, MessageKind.GENERIC,
              {'text': "Cannot determine which '$MAIN' to use."});
        } else if (!main.isFunction) {
          reportFatalError(main, MessageKind.GENERIC,
              {'text': "'$MAIN' is not a function."});
        }
        mainFunction = main;
        FunctionSignature parameters = mainFunction.computeSignature(this);
        if (parameters.parameterCount > 2) {
          int index = 0;
          parameters.forEachParameter((Element parameter) {
            if (index++ < 2) return;
            reportError(parameter, MessageKind.GENERIC,
                {'text': "'$MAIN' cannot have more than two parameters."});
          });
        }
      }

      mirrorUsageAnalyzerTask.analyzeUsage(mainApp);

      // In order to see if a library is deferred, we must compute the
      // compile-time constants that are metadata.  This means adding
      // something to the resolution queue.  So we cannot wait with
      // this until after the resolution queue is processed.
      deferredLoadTask.ensureMetadataResolved(this);
    }

    phase = PHASE_RESOLVING;
    if (analyzeAll) {
      libraries.forEach((uri, lib) {
        log('Enqueuing $uri');
        fullyEnqueueLibrary(lib, enqueuer.resolution);
      });
    } else if (analyzeMain && mainApp != null) {
      fullyEnqueueLibrary(mainApp, enqueuer.resolution);
    }
    // Elements required by enqueueHelpers are global dependencies
    // that are not pulled in by a particular element.
    backend.enqueueHelpers(enqueuer.resolution, globalDependencies);
    resolveLibraryMetadata();
    log('Resolving...');
    processQueue(enqueuer.resolution, main);
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
    assert(main != null);
    phase = PHASE_DONE_RESOLVING;

    // TODO(ahe): Remove this line. Eventually, enqueuer.resolution
    // should know this.
    world.populate();
    // Compute whole-program-knowledge that the backend needs. (This might
    // require the information computed in [world.populate].)
    backend.onResolutionComplete();

    deferredLoadTask.onResolutionComplete(main);

    log('Building IR...');
    irBuilder.buildNodes();

    log('Inferring types...');
    typesTask.onResolutionComplete(main);

    if(stopAfterTypeInference) return;

    log('Compiling...');
    phase = PHASE_COMPILING;
    // TODO(johnniwinther): Move these to [CodegenEnqueuer].
    if (hasIsolateSupport()) {
      enqueuer.codegen.addToWorkList(
          isolateHelperLibrary.find(Compiler.START_ROOT_ISOLATE));
      enqueuer.codegen.registerGetOfStaticFunction(main);
    }
    if (enabledNoSuchMethod) {
      backend.enableNoSuchMethod(enqueuer.codegen);
    }
    if (compileAll) {
      libraries.forEach((_, lib) => fullyEnqueueLibrary(lib,
          enqueuer.codegen));
    }
    processQueue(enqueuer.codegen, main);
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
    for (LibraryElement library in libraries.values) {
      if (library.metadata != null) {
        for (MetadataAnnotation metadata in library.metadata) {
          metadata.ensureResolved(this);
        }
      }
    }
  }

  void processQueue(Enqueuer world, Element main) {
    world.nativeEnqueuer.processNativeClasses(libraries.values);
    if (main != null) {
      FunctionElement mainMethod = main;
      if (mainMethod.computeSignature(this).parameterCount != 0) {
        // TODO(ngeoffray, floitsch): we should also ensure that the
        // class IsolateMessage is instantiated. Currently, just enabling
        // isolate support works.
        world.enableIsolateSupport(main.library);
        world.registerInstantiatedClass(listClass, globalDependencies);
        world.registerInstantiatedClass(stringClass, globalDependencies);
      }
      world.addToWorkList(main);
    }
    progress.reset();
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
    var resolved = new Set.from(enqueuer.resolution.resolvedElements.keys);
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
      if (identical(e.library, jsHelperLibrary)) {
        resolved.remove(e);
      }
      if (identical(e.library, interceptorsLibrary)) {
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

  TreeElements analyzeElement(Element element) {
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
    TreeElements elements = world.getCachedElements(element);
    if (elements != null) return elements;
    assert(parser != null);
    Node tree = parser.parse(element);
    assert(invariant(element, !element.isSynthesized || tree == null));
    if (tree != null) validator.validate(tree);
    elements = resolver.resolve(element);
    if (tree != null && elements != null && !analyzeSignaturesOnly &&
        !suppressWarnings) {
      // Only analyze nodes with a corresponding [TreeElements].
      checker.check(elements);
    }
    world.resolvedElements[element] = elements;
    return elements;
  }

  TreeElements analyze(ResolutionWorkItem work, ResolutionEnqueuer world) {
    assert(invariant(work.element, identical(world, enqueuer.resolution)));
    assert(invariant(work.element, !work.isAnalyzed(),
        message: 'Element ${work.element} has already been analyzed'));
    if (progress.elapsedMilliseconds > 500) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      if (phase == PHASE_RESOLVING) {
        log('Resolved ${enqueuer.resolution.resolvedElements.length} '
            'elements.');
        progress.reset();
      }
    }
    Element element = work.element;
    TreeElements result = world.getCachedElements(element);
    if (result != null) return result;
    result = analyzeElement(element);
    backend.onElementResolved(element, result);
    return result;
  }

  void codegen(CodegenWorkItem work, CodegenEnqueuer world) {
    assert(invariant(work.element, identical(world, enqueuer.codegen)));
    if (progress.elapsedMilliseconds > 500) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      log('Compiled ${enqueuer.codegen.generatedCode.length} methods.');
      progress.reset();
    }
    backend.codegen(work);
  }

  FunctionSignature resolveSignature(FunctionElement element) {
    return withCurrentElement(element,
                              () => resolver.resolveSignature(element));
  }

  void reportError(Spannable node,
                   MessageKind messageKind,
                   [Map arguments = const {}]) {
    reportDiagnosticInternal(
        node, messageKind, arguments, api.Diagnostic.ERROR);
  }

  void reportFatalError(Spannable node, MessageKind messageKind,
                        [Map arguments = const {}]) {
    reportError(node, messageKind, arguments);
    // TODO(ahe): Make this only abort the current method.
    throw new CompilerCancelledException(
        'Error: Cannot continue due to previous error.');
  }

  void reportWarning(Spannable node, MessageKind messageKind,
                     [Map arguments = const {}]) {
    // TODO(ahe): Don't suppress these warning when the type checker
    // is more complete.
    if (messageKind == MessageKind.MISSING_RETURN) return;
    if (messageKind == MessageKind.MAYBE_MISSING_RETURN) return;
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
    if (!showPackageWarnings) {
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
    if (Elements.isErroneousElement(element)) {
      element = element.enclosingElement;
    }
    if (element.position == null &&
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
    Element element = instruction.sourceElement;
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

  // TODO(karlklose): split into findHelperFunction and findHelperClass and
  // add a check that the element has the expected kind.
  Element findHelper(String name)
      => jsHelperLibrary.findLocal(name);
  Element findInterceptor(String name)
      => interceptorsLibrary.findLocal(name);

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
    libraries.forEach((_, library) {
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
