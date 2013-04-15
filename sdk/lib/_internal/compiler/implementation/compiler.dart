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
 * If true, dump the inferred types after compilation.
 */
const bool DUMP_INFERRED_TYPES = false;

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
  TreeElements get resolutionTree;

  WorkItem(this.element, this.compilationContext) {
    assert(invariant(element, element.isDeclaration));
  }

  bool isAnalyzed() => resolutionTree != null;

  void run(Compiler compiler, Enqueuer world);
}

/// [WorkItem] used exclusively by the [ResolutionEnqueuer].
class ResolutionWorkItem extends WorkItem {
  TreeElements resolutionTree;

  ResolutionWorkItem(Element element,
                     ItemCompilationContext compilationContext)
      : super(element, compilationContext);

  void run(Compiler compiler, ResolutionEnqueuer world) {
    resolutionTree = compiler.analyze(this, world);
  }
}

/// [WorkItem] used exclusively by the [CodegenEnqueuer].
class CodegenWorkItem extends WorkItem {
  final TreeElements resolutionTree;

  bool allowSpeculativeOptimization = true;
  List<HTypeGuard> guards = const <HTypeGuard>[];

  CodegenWorkItem(Element element,
                  TreeElements this.resolutionTree,
                  ItemCompilationContext compilationContext)
      : super(element, compilationContext) {
    assert(invariant(element, resolutionTree != null,
        message: 'Resolution tree is null for $element in codegen work item'));
  }

  void run(Compiler compiler, CodegenEnqueuer world) {
    if (world.isProcessed(element)) return;
    compiler.codegen(this, world);
  }
}

typedef void PostProcessAction();

class PostProcessTask {
  final Element element;
  final PostProcessAction action;

  PostProcessTask(this.element, this.action);
}

class ReadingFilesTask extends CompilerTask {
  ReadingFilesTask(Compiler compiler) : super(compiler);
  String get name => 'Reading input files';
}

abstract class Backend {
  final Compiler compiler;
  final ConstantSystem constantSystem;

  Backend(this.compiler,
          [ConstantSystem constantSystem = DART_CONSTANT_SYSTEM])
      : this.constantSystem = constantSystem;

  void initializeHelperClasses() {}

  void enqueueAllTopLevelFunctions(LibraryElement lib, Enqueuer world) {
    lib.forEachExport((Element e) {
      if (e.isFunction()) world.addToWorkList(e);
    });
  }

  void enqueueHelpers(ResolutionEnqueuer world, TreeElements elements);
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

  // TODO(ahe,karlklose): rename this?
  void dumpInferredTypes() {}

  ItemCompilationContext createItemCompilationContext() {
    return new ItemCompilationContext();
  }

  bool needsRti(ClassElement cls);

  // The following methods are hooks for the backend to register its
  // helper methods.
  void registerInstantiatedClass(ClassElement cls,
                                 Enqueuer enqueuer,
                                 TreeElements elements) {}
  void registerStringInterpolation(TreeElements elements) {}
  void registerCatchStatement(TreeElements elements) {}
  void registerWrapException(TreeElements elements) {}
  void registerThrowExpression(TreeElements elements) {}
  void registerLazyField(TreeElements elements) {}
  void registerTypeVariableExpression(TreeElements elements) {}
  void registerTypeLiteral(TreeElements elements) {}
  void registerStackTraceInCatch(TreeElements elements) {}
  void registerIsCheck(DartType type,
                       Enqueuer enqueuer,
                       TreeElements elements) {}
  void registerAsCheck(DartType type, TreeElements elements) {}
  void registerThrowNoSuchMethod(TreeElements elements) {}
  void registerThrowRuntimeError(TreeElements elements) {}
  void registerAbstractClassInstantiation(TreeElements elements) {}
  void registerFallThroughError(TreeElements elements) {}
  void registerSuperNoSuchMethod(TreeElements elements) {}
  void registerConstantMap(TreeElements elements) {}
  void registerRuntimeType(TreeElements elements) {}

  void registerRequiredType(DartType type, Element enclosingElement) {}
  void registerClassUsingVariableExpression(ClassElement cls) {}

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

  bool isDefaultNoSuchMethodImplementation(Element element) {
    assert(element.name == Compiler.NO_SUCH_METHOD);
    ClassElement classElement = element.getEnclosingClass();
    return classElement == compiler.objectClass;
  }
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
  final Map<String, LibraryElement> libraries;
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
  final TreeElements globalDependencies = new TreeElementMapping(null);

  final bool enableMinification;
  final bool enableTypeAssertions;
  final bool enableUserAssertions;
  final bool enableConcreteTypeInference;
  /**
   * The maximum size of a concrete type before it widens to dynamic during
   * concrete type inference.
   */
  final int maxConcreteTypeSize;
  final bool analyzeAll;
  final bool analyzeOnly;
  /**
   * If true, skip analysis of method bodies and field initializers. Implies
   * [analyzeOnly].
   */
  final bool analyzeSignaturesOnly;
  final bool enableNativeLiveTypeAnalysis;
  final bool rejectDeprecatedFeatures;
  final bool checkDeprecationInSdk;

  /**
   * If [:true:], comment tokens are collected in [commentMap] during scanning.
   */
  final bool preserveComments;

  /**
   * Is the compiler in verbose mode.
   */
  final bool verbose;

  final api.CompilerOutputProvider outputProvider;

  bool disableInlining = false;

  List<Uri> librariesToAnalyzeWhenRun;

  final Tracer tracer;

  CompilerTask measuredTask;
  Element _currentElement;
  LibraryElement coreLibrary;
  LibraryElement isolateLibrary;
  LibraryElement isolateHelperLibrary;
  LibraryElement jsHelperLibrary;
  LibraryElement interceptorsLibrary;
  LibraryElement foreignLibrary;
  LibraryElement mainApp;

  ClassElement objectClass;
  ClassElement closureClass;
  ClassElement dynamicClass;
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
  ClassElement jsInvocationMirrorClass;
  /// Document class from dart:mirrors.
  ClassElement documentClass;
  Element assertMethod;
  Element identicalFunction;
  Element functionApplyMethod;
  Element invokeOnMethod;
  Element createInvocationMirrorElement;

  Element get currentElement => _currentElement;
  withCurrentElement(Element element, f()) {
    Element old = currentElement;
    _currentElement = element;
    try {
      return f();
    } on SpannableAssertionFailure catch (ex) {
      if (!hasCrashed) {
        SourceSpan span = spanFromSpannable(ex.node);
        reportDiagnostic(span, ex.message, api.Diagnostic.ERROR);
        pleaseReportCrash();
      }
      hasCrashed = true;
      throw;
    } on CompilerCancelledException catch (ex) {
      throw;
    } on StackOverflowError catch (ex) {
      // We cannot report anything useful in this case, because we
      // do not have enough stack space.
      throw;
    } catch (ex) {
      try {
        unhandledExceptionOnElement(element);
      } catch (doubleFault) {
        // Ignoring exceptions in exception handling.
      }
      throw;
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
  ti.TypesTask typesTask;
  Backend backend;
  ConstantHandler constantHandler;
  ConstantHandler metadataHandler;
  EnqueueTask enqueuer;
  CompilerTask fileReadingTask;
  DeferredLoadTask deferredLoadTask;
  String buildId;

  static const SourceString MAIN = const SourceString('main');
  static const SourceString CALL_OPERATOR_NAME = const SourceString('call');
  static const SourceString NO_SUCH_METHOD = const SourceString('noSuchMethod');
  static const int NO_SUCH_METHOD_ARG_COUNT = 1;
  static const SourceString CREATE_INVOCATION_MIRROR =
      const SourceString('createInvocationMirror');
  static const SourceString INVOKE_ON = const SourceString('invokeOn');
  static const SourceString RUNTIME_TYPE = const SourceString('runtimeType');
  static const SourceString START_ROOT_ISOLATE =
      const SourceString('startRootIsolate');

  final Selector iteratorSelector =
      new Selector.getter(const SourceString('iterator'), null);
  final Selector currentSelector =
      new Selector.getter(const SourceString('current'), null);
  final Selector moveNextSelector =
      new Selector.call(const SourceString('moveNext'), null, 0);

  bool enabledNoSuchMethod = false;
  bool enabledRuntimeType = false;
  bool enabledFunctionApply = false;
  bool enabledInvokeOn = false;

  Stopwatch progress;

  static const int PHASE_SCANNING = 0;
  static const int PHASE_RESOLVING = 1;
  static const int PHASE_DONE_RESOLVING = 2;
  static const int PHASE_COMPILING = 3;
  int phase;

  bool compilationFailed = false;

  bool hasCrashed = false;

  Compiler({Tracer tracer: const Tracer(),
            bool enableTypeAssertions: false,
            bool enableUserAssertions: false,
            bool enableConcreteTypeInference: false,
            int maxConcreteTypeSize: 5,
            bool enableMinification: false,
            bool enableNativeLiveTypeAnalysis: false,
            bool emitJavaScript: true,
            bool generateSourceMap: true,
            bool disallowUnsafeEval: false,
            bool analyzeAll: false,
            bool analyzeOnly: false,
            bool analyzeSignaturesOnly: false,
            bool rejectDeprecatedFeatures: false,
            bool checkDeprecationInSdk: false,
            bool preserveComments: false,
            bool verbose: false,
            String this.buildId: "build number could not be determined",
            outputProvider,
            List<String> strips: const []})
      : tracer = tracer,
        enableTypeAssertions = enableTypeAssertions,
        enableUserAssertions = enableUserAssertions,
        enableConcreteTypeInference = enableConcreteTypeInference,
        maxConcreteTypeSize = maxConcreteTypeSize,
        enableMinification = enableMinification,
        enableNativeLiveTypeAnalysis = enableNativeLiveTypeAnalysis,
        analyzeAll = analyzeAll,
        rejectDeprecatedFeatures = rejectDeprecatedFeatures,
        checkDeprecationInSdk = checkDeprecationInSdk,
        preserveComments = preserveComments,
        verbose = verbose,
        libraries = new Map<String, LibraryElement>(),
        progress = new Stopwatch(),
        this.analyzeOnly = analyzeOnly || analyzeSignaturesOnly,
        this.analyzeSignaturesOnly = analyzeSignaturesOnly,
        this.outputProvider =
            (outputProvider == null) ? NullSink.outputProvider : outputProvider

  {
    progress.start();
    world = new World(this);

    closureMapping.ClosureNamer closureNamer;
    if (emitJavaScript) {
      js_backend.JavaScriptBackend jsBackend =
          new js_backend.JavaScriptBackend(this, generateSourceMap,
                                           disallowUnsafeEval);
      closureNamer = jsBackend.namer;
      backend = jsBackend;
    } else {
      closureNamer = new closureMapping.ClosureNamer();
      backend = new dart_backend.DartBackend(this, strips);
    }

    // No-op in production mode.
    validator = new TreeValidatorTask(this);

    tasks = [
      fileReadingTask = new ReadingFilesTask(this),
      libraryLoader = new LibraryLoaderTask(this),
      scanner = new ScannerTask(this),
      dietParser = new DietParserTask(this),
      parser = new ParserTask(this),
      patchParser = new PatchParserTask(this),
      resolver = new ResolverTask(this),
      closureToClassMapper = new closureMapping.ClosureTask(this, closureNamer),
      checker = new TypeCheckerTask(this),
      typesTask = new ti.TypesTask(this),
      constantHandler = new ConstantHandler(this, backend.constantSystem),
      deferredLoadTask = new DeferredLoadTask(this),
      enqueuer = new EnqueueTask(this)];

    tasks.addAll(backend.tasks);
    metadataHandler = new ConstantHandler(
        this, backend.constantSystem, isMetadata: true);
  }

  Universe get resolverWorld => enqueuer.resolution.universe;
  Universe get codegenWorld => enqueuer.codegen.universe;

  int getNextFreeClassId() => nextFreeClassId++;

  void ensure(bool condition) {
    if (!condition) cancel('failed assertion in leg');
  }

  void unimplemented(String methodName,
                     {Node node, Token token, HInstruction instruction,
                      Element element}) {
    internalError("$methodName not implemented",
                  node: node, token: token,
                  instruction: instruction, element: element);
  }

  void internalError(String message,
                     {Node node, Token token, HInstruction instruction,
                      Element element}) {
    cancel('Internal error: $message',
           node: node, token: token,
           instruction: instruction, element: element);
  }

  void internalErrorOnElement(Element element, String message) {
    internalError(message, element: element);
  }

  void unhandledExceptionOnElement(Element element) {
    if (hasCrashed) return;
    hasCrashed = true;
    reportDiagnostic(spanFromElement(element),
                     MessageKind.COMPILER_CRASHED.error().toString(),
                     api.Diagnostic.CRASH);
    pleaseReportCrash();
  }

  void pleaseReportCrash() {
    print(MessageKind.PLEASE_REPORT_THE_CRASH.message({'buildId': buildId}));
  }

  void cancel(String reason, {Node node, Token token,
               HInstruction instruction, Element element}) {
    assembledCode = null; // Compilation failed. Make sure that we
                          // don't return a bogus result.
    SourceSpan span = null;
    if (node != null) {
      span = spanFromNode(node);
    } else if (token != null) {
      span = spanFromTokens(token, token);
    } else if (instruction != null) {
      span = spanFromHInstruction(instruction);
    } else if (element != null) {
      span = spanFromElement(element);
    } else {
      throw 'No error location for error: $reason';
    }
    reportDiagnostic(span, reason, api.Diagnostic.ERROR);
    throw new CompilerCancelledException(reason);
  }

  SourceSpan spanFromSpannable(Spannable node, [Uri uri]) {
    if (node == CURRENT_ELEMENT_SPANNABLE) {
      node = currentElement;
    }
    if (node is Node) {
      return spanFromNode(node, uri);
    } else if (node is Token) {
      return spanFromTokens(node, node, uri);
    } else if (node is HInstruction) {
      return spanFromHInstruction(node);
    } else if (node is Element) {
      return spanFromElement(node);
    } else if (node is MetadataAnnotation) {
      return spanFromTokens(node.beginToken, node.endToken);
    } else {
      throw 'No error location.';
    }
  }

  void reportFatalError(String reason, Element element,
                        {Node node, Token token, HInstruction instruction}) {
    withCurrentElement(element, () {
      cancel(reason, node: node, token: token, instruction: instruction,
             element: element);
    });
  }

  void log(message) {
    reportDiagnostic(null, message, api.Diagnostic.VERBOSE_INFO);
  }

  bool run(Uri uri) {
    totalCompileTime.start();
    try {
      runCompiler(uri);
    } on CompilerCancelledException catch (exception) {
      log('Error: $exception');
      return false;
    } catch (exception) {
      try {
        if (!hasCrashed) {
          hasCrashed = true;
          reportDiagnostic(new SourceSpan(uri, 0, 0),
                           MessageKind.COMPILER_CRASHED.error().toString(),
                           api.Diagnostic.CRASH);
          pleaseReportCrash();
        }
      } catch (doubleFault) {
        // Ignoring exceptions in exception handling.
      }
      throw;
    } finally {
      tracer.close();
      totalCompileTime.stop();
    }
    return true;
  }

  bool hasIsolateSupport() => isolateLibrary != null;

  /**
   * This method is called before [library] import and export scopes have been
   * set up.
   */
  void onLibraryScanned(LibraryElement library, Uri uri) {
    if (dynamicClass != null) {
      // When loading the built-in libraries, dynamicClass is null. We
      // take advantage of this as core imports js_helper and sees [dynamic]
      // this way.
      withCurrentElement(dynamicClass, () {
        library.addToScope(dynamicClass, this);
      });
    }
  }

  LibraryElement scanBuiltinLibrary(String filename);

  void initializeSpecialClasses() {
    final List missingCoreClasses = [];
    ClassElement lookupCoreClass(String name) {
      ClassElement result = coreLibrary.find(new SourceString(name));
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
    if (!missingCoreClasses.isEmpty) {
      internalErrorOnElement(coreLibrary,
          'dart:core library does not contain required classes: '
          '$missingCoreClasses');
    }

    final List missingHelperClasses = [];
    ClassElement lookupHelperClass(String name) {
      ClassElement result = jsHelperLibrary.find(new SourceString(name));
      if (result == null) {
        missingHelperClasses.add(name);
      }
      return result;
    }
    jsInvocationMirrorClass = lookupHelperClass('JSInvocationMirror');
    closureClass = lookupHelperClass('Closure');
    dynamicClass = lookupHelperClass('Dynamic_');
    nullClass = lookupHelperClass('Null');
    if (!missingHelperClasses.isEmpty) {
      internalErrorOnElement(jsHelperLibrary,
          'dart:_js_helper library does not contain required classes: '
          '$missingHelperClasses');
    }

    types = new Types(this, dynamicClass);
    backend.initializeHelperClasses();

    dynamicClass.ensureResolved(this);
  }

  Element _unnamedListConstructor;
  Element get unnamedListConstructor {
    if (_unnamedListConstructor != null) return _unnamedListConstructor;
    Selector callConstructor = new Selector.callConstructor(
        const SourceString(""), listClass.getLibrary());
    return _unnamedListConstructor =
        listClass.lookupConstructor(callConstructor);
  }

  void scanBuiltinLibraries() {
    jsHelperLibrary = scanBuiltinLibrary('_js_helper');
    interceptorsLibrary = scanBuiltinLibrary('_interceptors');
    foreignLibrary = scanBuiltinLibrary('_foreign_helper');
    isolateHelperLibrary = scanBuiltinLibrary('_isolate_helper');
    // The helper library does not use the native language extension,
    // so we manually set the native classes this library defines.
    // TODO(ngeoffray): Enable annotations on these classes.
    ClassElement cls =
        isolateHelperLibrary.find(const SourceString('_WorkerStub'));
    cls.setNative('"*Worker"');

    assertMethod = jsHelperLibrary.find(const SourceString('assertHelper'));
    identicalFunction = coreLibrary.find(const SourceString('identical'));

    initializeSpecialClasses();

    functionClass.ensureResolved(this);
    functionApplyMethod =
        functionClass.lookupLocalMember(const SourceString('apply'));
    jsInvocationMirrorClass.ensureResolved(this);
    invokeOnMethod = jsInvocationMirrorClass.lookupLocalMember(
        const SourceString('invokeOn'));

    if (preserveComments) {
      var uri = new Uri.fromComponents(scheme: 'dart', path: 'mirrors');
      LibraryElement libraryElement =
          libraryLoader.loadLibrary(uri, null, uri);
      documentClass = libraryElement.find(const SourceString('Comment'));
    }
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

  void runCompiler(Uri uri) {
    assert(uri != null || analyzeOnly);
    scanBuiltinLibraries();
    if (librariesToAnalyzeWhenRun != null) {
      for (Uri libraryUri in librariesToAnalyzeWhenRun) {
        log('analyzing $libraryUri ($buildId)');
        libraryLoader.loadLibrary(libraryUri, null, libraryUri);
      }
    }
    if (uri != null) {
      if (analyzeOnly) {
        log('analyzing $uri ($buildId)');
      } else {
        log('compiling $uri ($buildId)');
      }
      mainApp = libraryLoader.loadLibrary(uri, null, uri);
    }
    Element main = null;
    if (mainApp != null) {
      main = mainApp.find(MAIN);
      if (main == null) {
        if (!analyzeOnly) {
          // Allow analyze only of libraries with no main.
          reportFatalError('Could not find $MAIN', mainApp);
        } else if (!analyzeAll) {
          reportFatalError(
              "Could not find $MAIN. "
              "No source will be analyzed. "
              "Use '--analyze-all' to analyze all code in the library.",
              mainApp);
        }
      } else {
        if (!main.isFunction()) {
          reportFatalError('main is not a function', main);
        }
        FunctionElement mainMethod = main;
        FunctionSignature parameters = mainMethod.computeSignature(this);
        parameters.forEachParameter((Element parameter) {
          reportFatalError('main cannot have parameters', parameter);
        });
      }

      // In order to see if a library is deferred, we must compute the
      // compile-time constants that are metadata.  This means adding
      // something to the resolution queue.  So we cannot wait with
      // this until after the resolution queue is processed.
      // TODO(ahe): Clean this up, for example, by not enqueueing
      // classes only used for metadata.
      deferredLoadTask.findDeferredLibraries(mainApp);
    }

    log('Resolving...');
    phase = PHASE_RESOLVING;
    if (analyzeAll) {
      libraries.forEach((_, lib) => fullyEnqueueLibrary(lib));
    }
    // Elements required by enqueueHelpers are global dependencies
    // that are not pulled in by a particular element.
    backend.enqueueHelpers(enqueuer.resolution, globalDependencies);
    processQueue(enqueuer.resolution, main);
    enqueuer.resolution.logSummary(log);

    if (compilationFailed) return;
    if (analyzeOnly) return;
    assert(main != null);
    phase = PHASE_DONE_RESOLVING;

    // TODO(ahe): Remove this line. Eventually, enqueuer.resolution
    // should know this.
    world.populate();
    // Compute whole-program-knowledge that the backend needs. (This might
    // require the information computed in [world.populate].)
    backend.onResolutionComplete();

    deferredLoadTask.onResolutionComplete(main);

    log('Inferring types...');
    typesTask.onResolutionComplete(main);

    log('Compiling...');
    phase = PHASE_COMPILING;
    // TODO(johnniwinther): Move these to [CodegenEnqueuer].
    if (hasIsolateSupport()) {
      enqueuer.codegen.addToWorkList(
          isolateHelperLibrary.find(Compiler.START_ROOT_ISOLATE));
    }
    if (enabledNoSuchMethod) {
      Selector selector = new Selector.noSuchMethod();
      enqueuer.codegen.registerInvocation(NO_SUCH_METHOD, selector);
      enqueuer.codegen.addToWorkList(createInvocationMirrorElement);
    }
    processQueue(enqueuer.codegen, main);
    enqueuer.codegen.logSummary(log);

    if (compilationFailed) return;

    backend.assembleProgram();

    checkQueues();
  }

  void fullyEnqueueLibrary(LibraryElement library) {
    library.forEachLocalMember(fullyEnqueueTopLevelElement);
  }

  void fullyEnqueueTopLevelElement(Element element) {
    if (element.isClass()) {
      ClassElement cls = element;
      cls.ensureResolved(this);
      cls.forEachLocalMember(enqueuer.resolution.addToWorkList);
    } else {
      enqueuer.resolution.addToWorkList(element);
    }
  }

  void processQueue(Enqueuer world, Element main) {
    world.nativeEnqueuer.processNativeClasses(libraries.values);
    if (main != null) {
      world.addToWorkList(main);
    }
    progress.reset();
    world.forEach((WorkItem work) {
      withCurrentElement(work.element, () => work.run(this, world));
    });
    world.queueIsClosed = true;
    world.forEachPostProcessTask((PostProcessTask work) {
      withCurrentElement(work.element, () => work.action());
    });
    if (compilationFailed) return;
    assert(world.checkNoEnqueuedInvokedInstanceMethods());
    if (DUMP_INFERRED_TYPES && phase == PHASE_COMPILING) {
      backend.dumpInferredTypes();
    }
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
        internalErrorOnElement(work.element, "Work list is not empty.");
      });
    }
    if (!REPORT_EXCESS_RESOLUTION) return;
    var resolved = new Set.from(enqueuer.resolution.resolvedElements.keys);
    for (Element e in enqueuer.codegen.generatedCode.keys) {
      resolved.remove(e);
    }
    for (Element e in new Set.from(resolved)) {
      if (e.isClass() ||
          e.isField() ||
          e.isTypeVariable() ||
          e.isTypedef() ||
          identical(e.kind, ElementKind.ABSTRACT_FIELD)) {
        resolved.remove(e);
      }
      if (identical(e.kind, ElementKind.GENERATIVE_CONSTRUCTOR)) {
        ClassElement enclosingClass = e.getEnclosingClass();
        if (enclosingClass.isInterface()) {
          resolved.remove(e);
        }
        resolved.remove(e);

      }
      if (identical(e.getLibrary(), jsHelperLibrary)) {
        resolved.remove(e);
      }
      if (identical(e.getLibrary(), interceptorsLibrary)) {
        resolved.remove(e);
      }
    }
    log('Excess resolution work: ${resolved.length}.');
    for (Element e in resolved) {
      SourceSpan span = spanFromElement(e);
      reportDiagnostic(span, 'Warning: $e resolved but not compiled.',
                       api.Diagnostic.WARNING);
    }
  }

  TreeElements analyzeElement(Element element) {
    assert(invariant(element, element.isDeclaration));
    TreeElements elements = enqueuer.resolution.getCachedElements(element);
    if (elements != null) return elements;
    assert(parser != null);
    Node tree = parser.parse(element);
    validator.validate(tree);
    elements = resolver.resolve(element);
    if (elements != null) {
      // Only analyze nodes with a corresponding [TreeElements].
      checker.check(tree, elements);
    }
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
    assert(invariant(element, element.isDeclaration));
    world.resolvedElements[element] = result;
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

  DartType resolveTypeAnnotation(Element element,
                                 TypeAnnotation annotation) {
    return resolver.resolveTypeAnnotation(element, annotation);
  }

  DartType resolveReturnType(Element element,
                             TypeAnnotation annotation) {
    return resolver.resolveReturnType(element, annotation);
  }

  FunctionSignature resolveSignature(FunctionElement element) {
    return withCurrentElement(element,
                              () => resolver.resolveSignature(element));
  }

  FunctionSignature resolveFunctionExpression(Element element,
                                              FunctionExpression node) {
    return withCurrentElement(element,
        () => resolver.resolveFunctionExpression(element, node));
  }

  void resolveTypedef(TypedefElement element) {
    withCurrentElement(element,
                       () => resolver.resolveTypedef(element));
  }

  FunctionType computeFunctionType(Element element,
                                   FunctionSignature signature) {
    return withCurrentElement(element,
        () => resolver.computeFunctionType(element, signature));
  }

  reportWarning(Node node, var message) {
    if (message is TypeWarning) {
      // TODO(ahe): Don't supress these warning when the type checker
      // is more complete.
      if (identical(message.message.kind, MessageKind.NOT_ASSIGNABLE)) return;
      if (identical(message.message.kind, MessageKind.MISSING_RETURN)) return;
      if (identical(message.message.kind, MessageKind.MAYBE_MISSING_RETURN)) {
        return;
      }
    }
    SourceSpan span = spanFromNode(node);

    reportDiagnostic(span, 'Warning: $message', api.Diagnostic.WARNING);
  }

  // TODO(ahe): Remove this method.
  reportError(Node node, var message) {
    SourceSpan span = spanFromNode(node);
    reportDiagnostic(span, 'Error: $message', api.Diagnostic.ERROR);
    throw new CompilerCancelledException(message.toString());
  }

  // TODO(ahe): Rename to reportError when that method has been removed.
  void reportErrorCode(Spannable node, MessageKind errorCode,
                       [Map arguments = const {}]) {
    reportMessage(spanFromSpannable(node),
                  errorCode.error(arguments),
                  api.Diagnostic.ERROR);
  }

  void reportMessage(SourceSpan span, Diagnostic message, api.Diagnostic kind) {
    // TODO(ahe): The names Diagnostic and api.Diagnostic are in
    // conflict. Fix it.
    reportDiagnostic(span, "$message", kind);
  }

  /// Returns true if a diagnostic was emitted.
  bool onDeprecatedFeature(Spannable span, String feature) {
    if (currentElement == null)
      throw new SpannableAssertionFailure(span, feature);
    if (!checkDeprecationInSdk &&
        currentElement.getLibrary().isPlatformLibrary) {
      return false;
    }
    var kind = rejectDeprecatedFeatures
        ? api.Diagnostic.ERROR : api.Diagnostic.WARNING;
    var message = rejectDeprecatedFeatures
        ? MessageKind.DEPRECATED_FEATURE_ERROR.error({'featureName': feature})
        : MessageKind.DEPRECATED_FEATURE_WARNING.error(
            {'featureName': feature});
    reportMessage(spanFromSpannable(span), message, kind);
    return true;
  }

  void reportDiagnostic(SourceSpan span, String message, api.Diagnostic kind);

  SourceSpan spanFromTokens(Token begin, Token end, [Uri uri]) {
    if (begin == null || end == null) {
      // TODO(ahe): We can almost always do better. Often it is only
      // end that is null. Otherwise, we probably know the current
      // URI.
      throw 'Cannot find tokens to produce error message.';
    }
    if (uri == null && currentElement != null) {
      uri = currentElement.getCompilationUnit().script.uri;
    }
    return SourceSpan.withCharacterOffsets(begin, end,
      (beginOffset, endOffset) => new SourceSpan(uri, beginOffset, endOffset));
  }

  SourceSpan spanFromNode(Node node, [Uri uri]) {
    return spanFromTokens(node.getBeginToken(), node.getEndToken(), uri);
  }

  SourceSpan spanFromElement(Element element) {
    if (Elements.isErroneousElement(element)) {
      element = element.enclosingElement;
    }
    if (element.position() == null && !element.isCompilationUnit()) {
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
    Token position = element.position();
    Uri uri = element.getCompilationUnit().script.uri;
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
    Uri uri = element.getCompilationUnit().script.uri;
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
    unimplemented('Compiler.translateResolvedUri');
  }

  /**
   * Reads the script specified by the [readableUri].
   *
   * See [LibraryLoader] for terminology on URIs.
   */
  Script readScript(Uri readableUri, [Node node]) {
    unimplemented('Compiler.readScript');
  }

  String get legDirectory {
    unimplemented('Compiler.legDirectory');
  }

  // TODO(karlklose): split into findHelperFunction and findHelperClass and
  // add a check that the element has the expected kind.
  Element findHelper(SourceString name)
      => jsHelperLibrary.findLocal(name);
  Element findInterceptor(SourceString name)
      => interceptorsLibrary.findLocal(name);

  Element lookupElementIn(ScopeContainerElement container, SourceString name) {
    Element element = container.localLookup(name);
    if (element == null) {
      throw 'Could not find ${name.slowToString()} in $container';
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
}

class CompilerTask {
  final Compiler compiler;
  final Stopwatch watch;

  CompilerTask(Compiler compiler)
      : this.compiler = compiler,
        watch = (compiler.verbose) ? new Stopwatch() : null;

  String get name => 'Unknown task';
  int get timing => (watch != null) ? watch.elapsedMilliseconds : 0;

  measure(action()) {
    if (watch == null) return action();
    CompilerTask previous = compiler.measuredTask;
    if (identical(this, previous)) return action();
    compiler.measuredTask = this;
    if (previous != null) previous.watch.stop();
    watch.start();
    try {
      return action();
    } finally {
      watch.stop();
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

class Tracer {
  final bool enabled = false;

  const Tracer();

  void traceCompilation(String methodName, ItemCompilationContext context) {
  }

  void traceGraph(String name, var graph) {
  }

  void close() {
  }
}

class SourceSpan {
  final Uri uri;
  final int begin;
  final int end;

  const SourceSpan(this.uri, this.begin, this.end);

  static withCharacterOffsets(Token begin, Token end,
                     f(int beginOffset, int endOffset)) {
    final beginOffset = begin.charOffset;
    final endOffset = end.charOffset + end.slowCharCount;

    // [begin] and [end] might be the same for the same empty token. This
    // happens for instance when scanning '$$'.
    assert(endOffset >= beginOffset);
    return f(beginOffset, endOffset);
  }

  String toString() => 'SourceSpan($uri, $begin, $end)';
}

/**
 * Throws an [InvariantException] if [condition] is [:false:]. [condition] must
 * be either a [:bool:] or a no-arg function returning a [:bool:].
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
  if (condition is Function){
    condition = condition();
  }
  if (spannable == null || !condition) {
    if (message is Function) {
      message = message();
    }
    throw new SpannableAssertionFailure(spannable, message);
  }
  return true;
}

/// A sink that drains into /dev/null.
class NullSink implements EventSink<String> {
  final String name;

  NullSink(this.name);

  add(String value) {}

  void addError(Object error) {}

  void close() {}

  toString() => name;

  /// Convenience method for getting an [api.CompilerOutputProvider].
  static NullSink outputProvider(String name, String extension) {
    return new NullSink('$name.$extension');
  }
}
