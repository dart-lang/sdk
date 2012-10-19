// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


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
 * A string to identify the revision or build.
 *
 * This ID is displayed if the compiler crashes and in verbose mode, and is
 * an aid in reproducing bug reports.
 *
 * The actual string is rewritten during the SDK build process.
 */
const String BUILD_ID = 'build number could not be determined';

/**
 * Contains backend-specific data that is used throughout the compilation of
 * one work item.
 */
class ItemCompilationContext {
}

class WorkItem {
  final ItemCompilationContext compilationContext;
  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  final Element element;
  TreeElements resolutionTree;
  bool allowSpeculativeOptimization = true;
  List<HTypeGuard> guards = const <HTypeGuard>[];

  WorkItem(this.element, this.resolutionTree, this.compilationContext) {
    assert(invariant(element, element.isDeclaration));
  }

  bool isAnalyzed() => resolutionTree != null;

  void run(Compiler compiler, Enqueuer world) {
    CodeBuffer codeBuffer = world.universe.generatedCode[element];
    if (codeBuffer != null) return;
    resolutionTree = compiler.analyze(this, world);
    compiler.codegen(this, world);
  }
}

abstract class Backend {
  final Compiler compiler;
  final ConstantSystem constantSystem;

  Backend(this.compiler,
          [ConstantSystem constantSystem = DART_CONSTANT_SYSTEM])
      : this.constantSystem = constantSystem;

  void enqueueAllTopLevelFunctions(LibraryElement lib, Enqueuer world) {
    lib.forEachExport((Element e) {
      if (e.isFunction()) world.addToWorkList(e);
    });
  }

  abstract void enqueueHelpers(Enqueuer world);
  abstract void codegen(WorkItem work);
  abstract void processNativeClasses(Enqueuer world,
                                     Collection<LibraryElement> libraries);
  abstract void assembleProgram();
  abstract List<CompilerTask> get tasks;

  // TODO(ahe,karlklose): rename this?
  void dumpInferredTypes() {}

  ItemCompilationContext createItemCompilationContext() {
    return new ItemCompilationContext();
  }

  SourceString getCheckedModeHelper(DartType type) => null;

  abstract Element getInterceptor(Selector selector);
}

abstract class Compiler implements DiagnosticListener {
  final Map<String, LibraryElement> libraries;
  int nextFreeClassId = 0;
  World world;
  String assembledCode;
  Types types;

  final bool enableMinification;
  final bool enableTypeAssertions;
  final bool enableUserAssertions;
  final bool enableConcreteTypeInference;

  bool disableInlining = false;

  // TODO(5074): Remove this field once we don't accept the
  // deprecated parameter specification.
  static final bool REJECT_NAMED_ARGUMENT_AS_POSITIONAL = false;

  final Tracer tracer;

  CompilerTask measuredTask;
  Element _currentElement;
  LibraryElement coreLibrary;
  LibraryElement coreImplLibrary;
  LibraryElement isolateLibrary;
  LibraryElement jsHelperLibrary;
  LibraryElement interceptorsLibrary;
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
  ClassElement mapClass;
  Element assertMethod;
  Element identicalFunction;
  Element functionApplyMethod;

  Element get currentElement => _currentElement;
  withCurrentElement(Element element, f()) {
    Element old = currentElement;
    _currentElement = element;
    try {
      return f();
    } on CompilerCancelledException catch (ex) {
      throw;
    } on StackOverflowException catch (ex) {
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
  EnqueueTask enqueuer;

  static const SourceString MAIN = const SourceString('main');
  static const SourceString CALL_OPERATOR_NAME = const SourceString('call');
  static const SourceString NO_SUCH_METHOD = const SourceString('noSuchMethod');
  static const SourceString RUNTIME_TYPE = const SourceString('runtimeType');
  static const SourceString START_ROOT_ISOLATE =
      const SourceString('startRootIsolate');
  bool enabledNoSuchMethod = false;
  bool enabledRuntimeType = false;
  bool enabledFunctionApply = false;

  Stopwatch progress;

  static const int PHASE_SCANNING = 0;
  static const int PHASE_RESOLVING = 1;
  static const int PHASE_COMPILING = 2;
  int phase;

  bool compilationFailed = false;

  bool hasCrashed = false;

  Compiler({this.tracer: const Tracer(),
            this.enableTypeAssertions: false,
            this.enableUserAssertions: false,
            this.enableConcreteTypeInference: false,
            this.enableMinification: false,
            bool emitJavaScript: true,
            bool generateSourceMap: true,
            bool disallowUnsafeEval: false,
            List<String> strips: const []})
      : libraries = new Map<String, LibraryElement>(),
        progress = new Stopwatch() {
    progress.start();
    world = new World(this);
    scanner = new ScannerTask(this);
    dietParser = new DietParserTask(this);
    parser = new ParserTask(this);
    patchParser = new PatchParserTask(this);
    libraryLoader = new LibraryLoaderTask(this);
    validator = new TreeValidatorTask(this);
    resolver = new ResolverTask(this);
    closureToClassMapper = new closureMapping.ClosureTask(this);
    checker = new TypeCheckerTask(this);
    typesTask = new ti.TypesTask(this, enableConcreteTypeInference);
    backend = emitJavaScript ?
        new js_backend.JavaScriptBackend(this,
                                         generateSourceMap,
                                         disallowUnsafeEval) :
        new dart_backend.DartBackend(this, strips);
    constantHandler = new ConstantHandler(this, backend.constantSystem);
    enqueuer = new EnqueueTask(this);
    tasks = [scanner, dietParser, parser, resolver, closureToClassMapper,
             checker, typesTask, constantHandler, enqueuer];
    tasks.addAll(backend.tasks);
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
    print(MessageKind.PLEASE_REPORT_THE_CRASH.message([BUILD_ID]));
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
      span = spanFromElement(currentElement);
    } else if (element != null) {
      span = spanFromElement(element);
    } else {
      throw 'No error location for error: $reason';
    }
    reportDiagnostic(span, reason, api.Diagnostic.ERROR);
    throw new CompilerCancelledException(reason);
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
    try {
      runCompiler(uri);
    } on CompilerCancelledException catch (exception) {
      log(exception.toString());
      log('compilation failed');
      return false;
    }
    tracer.close();
    log('compilation succeeded');
    return true;
  }

  void enableNoSuchMethod(Element element) {
    // TODO(ahe): Move this method to Enqueuer.
    if (enabledNoSuchMethod) return;
    if (identical(element.getEnclosingClass(), objectClass)) {
      enqueuer.resolution.registerDynamicInvocationOf(element);
      return;
    }
    enabledNoSuchMethod = true;
    Selector selector = new Selector.noSuchMethod();
    enqueuer.resolution.registerInvocation(NO_SUCH_METHOD, selector);
    enqueuer.codegen.registerInvocation(NO_SUCH_METHOD, selector);
  }

  void enableIsolateSupport(LibraryElement element) {
    // TODO(ahe): Move this method to Enqueuer.
    isolateLibrary = element.patch;
    enqueuer.resolution.addToWorkList(isolateLibrary.find(START_ROOT_ISOLATE));
    enqueuer.resolution.addToWorkList(
        isolateLibrary.find(const SourceString('_currentIsolate')));
    enqueuer.resolution.addToWorkList(
        isolateLibrary.find(const SourceString('_callInIsolate')));
    enqueuer.codegen.addToWorkList(isolateLibrary.find(START_ROOT_ISOLATE));
  }

  bool hasIsolateSupport() => isolateLibrary != null;

  /**
   * This method is called before [library] import and export scopes have been
   * set up.
   */
  void onLibraryScanned(LibraryElement library, Uri uri) {
    if (dynamicClass != null) {
      // When loading the built-in libraries, dynamicClass is null. We
      // take advantage of this as core and coreimpl import js_helper
      // and see Dynamic this way.
      withCurrentElement(dynamicClass, () {
        library.addToScope(dynamicClass, this);
      });
    }
  }

  abstract LibraryElement scanBuiltinLibrary(String filename);

  void initializeSpecialClasses() {
    bool coreLibValid = true;
    ClassElement lookupSpecialClass(SourceString name) {
      ClassElement result = coreLibrary.find(name);
      if (result == null) {
        log('core library class $name missing');
        coreLibValid = false;
      }
      return result;
    }
    objectClass = lookupSpecialClass(const SourceString('Object'));
    boolClass = lookupSpecialClass(const SourceString('bool'));
    numClass = lookupSpecialClass(const SourceString('num'));
    intClass = lookupSpecialClass(const SourceString('int'));
    doubleClass = lookupSpecialClass(const SourceString('double'));
    stringClass = lookupSpecialClass(const SourceString('String'));
    functionClass = lookupSpecialClass(const SourceString('Function'));
    listClass = lookupSpecialClass(const SourceString('List'));
    mapClass = lookupSpecialClass(const SourceString('Map'));
    closureClass = lookupSpecialClass(const SourceString('Closure'));
    dynamicClass = lookupSpecialClass(const SourceString('Dynamic_'));
    nullClass = lookupSpecialClass(const SourceString('Null'));
    types = new Types(this, dynamicClass);
    if (!coreLibValid) {
      cancel('core library does not contain required classes');
    }
  }

  void scanBuiltinLibraries() {
    loadCoreImplLibrary();
    jsHelperLibrary = scanBuiltinLibrary('_js_helper');
    interceptorsLibrary = scanBuiltinLibrary('_interceptors');

    // The core and coreimpl libraries were loaded and patched before
    // jsHelperLibrary was initialized, so it wasn't imported into those
    // two libraries during patching.
    importHelperLibrary(coreLibrary);
    importHelperLibrary(coreImplLibrary);
    importHelperLibrary(interceptorsLibrary);

    addForeignFunctions(jsHelperLibrary);
    addForeignFunctions(interceptorsLibrary);

    assertMethod = jsHelperLibrary.find(const SourceString('assertHelper'));
    identicalFunction = coreLibrary.find(const SourceString('identical'));

    initializeSpecialClasses();

    functionClass.ensureResolved(this);
    functionApplyMethod =
        functionClass.lookupLocalMember(const SourceString('apply'));
  }

  void loadCoreImplLibrary() {
    Uri coreImplUri = new Uri.fromComponents(scheme: 'dart', path: 'coreimpl');
    coreImplLibrary = libraryLoader.loadLibrary(coreImplUri, null, coreImplUri);
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
  abstract Uri resolvePatchUri(String dartLibraryPath);

  /** Define the JS helper functions in the given library. */
  void addForeignFunctions(LibraryElement library) {
    library.addToScope(new ForeignElement(
        const SourceString('JS'), library), this);
    library.addToScope(new ForeignElement(
        const SourceString('UNINTERCEPTED'), library), this);
    library.addToScope(new ForeignElement(
        const SourceString('JS_HAS_EQUALS'), library), this);
    library.addToScope(new ForeignElement(
        const SourceString('JS_CURRENT_ISOLATE'), library), this);
    library.addToScope(new ForeignElement(
        const SourceString('JS_CALL_IN_ISOLATE'), library), this);
    library.addToScope(new ForeignElement(
        const SourceString('DART_CLOSURE_TO_JS'), library), this);
  }

  // TODO(karlklose,floitsch): move this to the javascript backend.
  /** Enable the 'JS' helper for a library if needed. */
  void maybeEnableJSHelper(LibraryElement library) {
    String libraryName = library.uri.toString();
    if (library.entryCompilationUnit.script.name.contains(
            'dart/tests/compiler/dart2js_native')
        || libraryName == 'dart:isolate'
        || libraryName == 'dart:math'
        || libraryName == 'dart:html') {
      if (libraryName == 'dart:html') {
        // dart:html needs access to convertDartClosureToJS.
        importHelperLibrary(library);
      }
      library.addToScope(findHelper(const SourceString('JS')), this);
      Element jsIndexingBehaviorInterface =
          findHelper(const SourceString('JavaScriptIndexingBehavior'));
      if (jsIndexingBehaviorInterface != null) {
        library.addToScope(jsIndexingBehaviorInterface, this);
      }
    }
  }

  void runCompiler(Uri uri) {
    log('compiling $uri ($BUILD_ID)');
    scanBuiltinLibraries();
    mainApp = libraryLoader.loadLibrary(uri, null, uri);
    libraries.forEach((_, library) {
      maybeEnableJSHelper(library);
    });
    final Element main = mainApp.find(MAIN);
    if (main == null) {
      reportFatalError('Could not find $MAIN', mainApp);
    } else {
      if (!main.isFunction()) reportFatalError('main is not a function', main);
      FunctionElement mainMethod = main;
      FunctionSignature parameters = mainMethod.computeSignature(this);
      parameters.forEachParameter((Element parameter) {
        reportFatalError('main cannot have parameters', parameter);
      });
    }

    log('Resolving...');
    phase = PHASE_RESOLVING;
    backend.enqueueHelpers(enqueuer.resolution);
    processQueue(enqueuer.resolution, main);
    log('Resolved ${enqueuer.resolution.resolvedElements.length} elements.');

    if (compilationFailed) return;

    log('Inferring types...');
    typesTask.onResolutionComplete(main);

    // TODO(ahe): Remove this line. Eventually, enqueuer.resolution
    // should know this.
    world.populate();

    log('Compiling...');
    phase = PHASE_COMPILING;
    processQueue(enqueuer.codegen, main);
    log('Compiled ${codegenWorld.generatedCode.length} methods.');

    if (compilationFailed) return;

    backend.assembleProgram();

    checkQueues();
  }

  void processQueue(Enqueuer world, Element main) {
    backend.processNativeClasses(world, libraries.getValues());
    world.addToWorkList(main);
    progress.reset();
    world.forEach((WorkItem work) {
      withCurrentElement(work.element, () => work.run(this, world));
    });
    world.queueIsClosed = true;
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
    var resolved = new Set.from(enqueuer.resolution.resolvedElements.getKeys());
    for (Element e in codegenWorld.generatedCode.getKeys()) {
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
    if (!REPORT_EXCESS_RESOLUTION) return;
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
    final int allowed = ElementCategory.VARIABLE | ElementCategory.FUNCTION
                        | ElementCategory.FACTORY;
    ElementKind kind = element.kind;
    if (!element.isAccessor() &&
        ((identical(kind, ElementKind.ABSTRACT_FIELD)) ||
         (kind.category & allowed) == 0)) {
      return null;
    }
    assert(parser != null);
    Node tree = parser.parse(element);
    validator.validate(tree);
    elements = resolver.resolve(element);
    checker.check(tree, elements);
    typesTask.analyze(tree, elements);
    return elements;
  }

  TreeElements analyze(WorkItem work, Enqueuer world) {
    if (work.isAnalyzed()) {
      // TODO(ahe): Clean this up and find a better way for adding all resolved
      // elements.
      enqueuer.resolution.resolvedElements[work.element] = work.resolutionTree;
      return work.resolutionTree;
    }
    if (progress.elapsedInMs() > 500) {
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
    if (!identical(world, enqueuer.resolution)) {
      internalErrorOnElement(element,
                             'Internal error: unresolved element: $element.');
    }
    result = analyzeElement(element);
    assert(invariant(element, element.isDeclaration));
    enqueuer.resolution.resolvedElements[element] = result;
    return result;
  }

  void codegen(WorkItem work, Enqueuer world) {
    if (!identical(world, enqueuer.codegen)) return null;
    if (progress.elapsedInMs() > 500) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      log('Compiled ${codegenWorld.generatedCode.length} methods.');
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

  bool isLazilyInitialized(VariableElement element) {
    Constant initialValue = compileVariable(element);
    return initialValue == null;
  }

  /**
   * Compiles compile-time constants. Never returns [:null:].
   * If the initial value is not a compile-time constants reports an error.
   */
  Constant compileConstant(VariableElement element) {
    return withCurrentElement(element, () {
      return constantHandler.compileConstant(element);
    });
  }

  Constant compileVariable(VariableElement element) {
    return withCurrentElement(element, () {
      return constantHandler.compileVariable(element);
    });
  }

  reportWarning(Node node, var message) {
    if (message is TypeWarning) {
      // TODO(ahe): Don't supress these warning when the type checker
      // is more complete.
      if (identical(message.message.kind, MessageKind.NOT_ASSIGNABLE)) return;
      if (identical(message.message.kind, MessageKind.MISSING_RETURN)) return;
      if (identical(message.message.kind, MessageKind.MAYBE_MISSING_RETURN)) return;
      if (identical(message.message.kind, MessageKind.ADDITIONAL_ARGUMENT)) return;
      if (identical(message.message.kind, MessageKind.METHOD_NOT_FOUND)) return;
    }
    SourceSpan span = spanFromNode(node);

    reportDiagnostic(span, 'Warning: $message', api.Diagnostic.WARNING);
  }

  reportError(Node node, var message) {
    SourceSpan span = spanFromNode(node);
    reportDiagnostic(span, 'Error: $message', api.Diagnostic.ERROR);
    throw new CompilerCancelledException(message.toString());
  }

  void reportMessage(SourceSpan span, Diagnostic message, api.Diagnostic kind) {
    // TODO(ahe): The names Diagnostic and api.Diagnostic are in
    // conflict. Fix it.
    reportDiagnostic(span, "$message", kind);
  }

  abstract void reportDiagnostic(SourceSpan span, String message,
                                 api.Diagnostic kind);

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
    if (element.position() == null) {
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

  Script readScript(Uri uri, [Node node]) {
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

  bool get isMockCompilation => false;
}

class CompilerTask {
  final Compiler compiler;
  final Stopwatch watch;

  CompilerTask(this.compiler) : watch = new Stopwatch();

  String get name => 'Unknown task';
  int get timing => watch.elapsedInMs();

  measure(Function action) {
    // TODO(kasperl): Do we have to worry about exceptions here?
    CompilerTask previous = compiler.measuredTask;
    compiler.measuredTask = this;
    if (previous != null) previous.watch.stop();
    watch.start();
    var result = action();
    watch.stop();
    if (previous != null) previous.watch.start();
    compiler.measuredTask = previous;
    return result;
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
bool invariant(Spannable spannable, var condition, {String message: null}) {
  // TODO(johnniwinther): Use [spannable] and [message] to provide better
  // information on assertion errors.
  if (condition is Function){
    condition = condition();
  }
  if (!condition && message != null) {
    print('assertion failed: $message');
  }
  return spannable != null && condition;
}
