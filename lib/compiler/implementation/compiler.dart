// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * If true, print a warning for each method that was resolved, but not
 * compiled.
 */
final bool REPORT_EXCESS_RESOLUTION = false;

/**
 * If true, trace information on pass2 optimizations.
 */
final bool REPORT_PASS2_OPTIMIZATIONS = false;

class WorkItem {
  final Element element;
  TreeElements resolutionTree;
  bool allowSpeculativeOptimization = true;
  List<HTypeGuard> guards = const <HTypeGuard>[];

  WorkItem(this.element, this.resolutionTree);

  bool isAnalyzed() => resolutionTree !== null;

  String run(Compiler compiler, Enqueuer world) {
    String code = world.universe.generatedCode[element];
    if (code !== null) return code;
    resolutionTree = compiler.analyze(this, world);
    return compiler.codegen(this, world);
  }
}

class Backend {
  final Compiler compiler;

  Backend(this.compiler);

  void enqueueAllTopLevelFunctions(LibraryElement lib, Enqueuer world) {
    lib.forEachExport((Element e) {
      if (e.isFunction()) world.addToWorkList(e);
    });
  }

  abstract void enqueueHelpers(Enqueuer world);
  abstract String codegen(WorkItem work);
  abstract void processNativeClasses(Enqueuer world,
                                     Collection<LibraryElement> libraries);
  abstract void assembleProgram();
  abstract List<CompilerTask> get tasks();
}

class JavaScriptBackend extends Backend {
  SsaBuilderTask builder;
  SsaOptimizerTask optimizer;
  SsaCodeGeneratorTask generator;
  CodeEmitterTask emitter;

  List<CompilerTask> get tasks() {
    return <CompilerTask>[builder, optimizer, generator, emitter];
  }

  JavaScriptBackend(Compiler compiler)
      : emitter = new CodeEmitterTask(compiler),
        super(compiler) {
    builder = new SsaBuilderTask(this);
    optimizer = new SsaOptimizerTask(this);
    generator = new SsaCodeGeneratorTask(this);
  }

  void enqueueHelpers(Enqueuer world) {
    enqueueAllTopLevelFunctions(compiler.jsHelperLibrary, world);
    enqueueAllTopLevelFunctions(compiler.interceptorsLibrary, world);
    for (var helper in [const SourceString('Closure'),
                        const SourceString('ConstantMap'),
                        const SourceString('ConstantProtoMap')]) {
      var e = compiler.findHelper(helper);
      if (e !== null) world.registerInstantiatedClass(e);
    }
  }

  String codegen(WorkItem work) {
    HGraph graph = builder.build(work);
    optimizer.optimize(work, graph);
    if (work.allowSpeculativeOptimization
        && optimizer.trySpeculativeOptimizations(work, graph)) {
      String code = generator.generateBailoutMethod(work, graph);
      compiler.codegenWorld.addBailoutCode(work, code);
      optimizer.prepareForSpeculativeOptimizations(work, graph);
      optimizer.optimize(work, graph);
    }
    return generator.generateMethod(work, graph);
  }

  void processNativeClasses(Enqueuer world,
                            Collection<LibraryElement> libraries) {
    native.processNativeClasses(world, emitter, libraries);
  }

  void assembleProgram() {
    emitter.assembleProgram();
  }
}

class Compiler implements DiagnosticListener {
  final Map<String, LibraryElement> libraries;
  int nextFreeClassId = 0;
  World world;
  String assembledCode;
  Namer namer;
  Types types;
  final bool enableTypeAssertions;
  final bool enableUserAssertions;

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
  Element assertMethod;

  /**
   * Interface used to determine if an object has the JavaScript
   * indexing behavior. The interface is only visible to specific
   * libraries.
   */
  ClassElement jsIndexingBehaviorInterface;

  Element get currentElement() => _currentElement;
  withCurrentElement(Element element, f()) {
    Element old = currentElement;
    _currentElement = element;
    try {
      return f();
    } catch (CompilerCancelledException ex) {
      throw;
    } catch (var ex) {
      unhandledExceptionOnElement(element);
      throw;
    } finally {
      _currentElement = old;
    }
  }

  List<CompilerTask> tasks;
  ScannerTask scanner;
  DietParserTask dietParser;
  ParserTask parser;
  TreeValidatorTask validator;
  UnparseValidator unparseValidator;
  ResolverTask resolver;
  TypeCheckerTask checker;
  Backend backend;
  ConstantHandler constantHandler;
  EnqueueTask enqueuer;

  static final SourceString MAIN = const SourceString('main');
  static final SourceString NO_SUCH_METHOD = const SourceString('noSuchMethod');
  static final SourceString NO_SUCH_METHOD_EXCEPTION =
      const SourceString('NoSuchMethodException');
  static final SourceString START_ROOT_ISOLATE =
      const SourceString('startRootIsolate');
  bool enabledNoSuchMethod = false;

  Stopwatch progress;

  static final int PHASE_SCANNING = 0;
  static final int PHASE_RESOLVING = 1;
  static final int PHASE_COMPILING = 2;
  static final int PHASE_RECOMPILING = 3;
  int phase;

  Compiler([this.tracer = const Tracer(),
            this.enableTypeAssertions = false,
            this.enableUserAssertions = false,
            bool emitJavascript = true,
            validateUnparse = false])
      : libraries = new Map<String, LibraryElement>(),
        world = new World(),
        progress = new Stopwatch.start() {
    namer = new Namer(this);
    constantHandler = new ConstantHandler(this);
    scanner = new ScannerTask(this);
    dietParser = new DietParserTask(this);
    parser = new ParserTask(this);
    validator = new TreeValidatorTask(this);
    unparseValidator = new UnparseValidator(this, validateUnparse);
    resolver = new ResolverTask(this);
    checker = new TypeCheckerTask(this);
    backend = emitJavascript ?
        new JavaScriptBackend(this) : new dart_backend.DartBackend(this);
    enqueuer = new EnqueueTask(this);
    tasks = [scanner, dietParser, parser, resolver, checker,
             unparseValidator, constantHandler, enqueuer];
    tasks.addAll(backend.tasks);
  }

  Universe get resolverWorld() => enqueuer.resolution.universe;
  Universe get codegenWorld() => enqueuer.codegen.universe;

  int getNextFreeClassId() => nextFreeClassId++;

  void ensure(bool condition) {
    if (!condition) cancel('failed assertion in leg');
  }

  void unimplemented(String methodName,
                     [Node node, Token token, HInstruction instruction,
                      Element element]) {
    internalError("$methodName not implemented",
                  node, token, instruction, element);
  }

  void internalError(String message,
                     [Node node, Token token, HInstruction instruction,
                      Element element]) {
    cancel("${red('internal error:')} $message",
           node, token, instruction, element);
  }

  void internalErrorOnElement(Element element, String message) {
    internalError(message, element: element);
  }

  void unhandledExceptionOnElement(Element element) {
    reportDiagnostic(spanFromElement(element),
                     MessageKind.COMPILER_CRASHED.error().toString(),
                     false);
    // TODO(ahe): Obtain the build ID.
    var buildId = 'build number could not be determined';
    print(MessageKind.PLEASE_REPORT_THE_CRASH.message([buildId]));
  }

  void cancel([String reason, Node node, Token token,
               HInstruction instruction, Element element]) {
    assembledCode = null; // Compilation failed. Make sure that we
                          // don't return a bogus result.
    SourceSpan span = const SourceSpan(null, null, null);
    if (node !== null) {
      span = spanFromNode(node);
    } else if (token !== null) {
      span = spanFromTokens(token, token);
    } else if (instruction !== null) {
      span = spanFromElement(currentElement);
    } else if (element !== null) {
      span = spanFromElement(element);
    } else {
      throw 'No error location for error: $reason';
    }
    reportDiagnostic(span, red(reason), true);
    throw new CompilerCancelledException(reason);
  }

  void reportFatalError(String reason, Element element,
                        [Node node, Token token, HInstruction instruction]) {
    withCurrentElement(element, () {
      cancel(reason, node, token, instruction, element);
    });
  }

  void log(message) {
    reportDiagnostic(null, message, false);
  }

  bool run(Uri uri) {
    try {
      runCompiler(uri);
    } catch (CompilerCancelledException exception) {
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
    if (element.enclosingElement === objectClass) {
      enqueuer.resolution.registerDynamicInvocationOf(element);
      return;
    }
    enabledNoSuchMethod = true;
    enqueuer.resolution.registerInvocation(NO_SUCH_METHOD,
                                           Selector.INVOCATION_2);
    enqueuer.codegen.registerInvocation(NO_SUCH_METHOD,
                                        Selector.INVOCATION_2);
  }

  void enableIsolateSupport(LibraryElement element) {
    // TODO(ahe): Move this method to Enqueuer.
    isolateLibrary = element;
    enqueuer.resolution.addToWorkList(element.find(START_ROOT_ISOLATE));
    enqueuer.resolution.addToWorkList(
        element.find(const SourceString('_currentIsolate')));
    enqueuer.resolution.addToWorkList(
        element.find(const SourceString('_callInIsolate')));
    enqueuer.codegen.addToWorkList(element.find(START_ROOT_ISOLATE));
  }

  bool hasIsolateSupport() => isolateLibrary !== null;

  void onLibraryLoaded(LibraryElement library, Uri uri) {
    if (uri.toString() == 'dart:isolate') {
      enableIsolateSupport(library);
    }
    if (dynamicClass !== null) {
      // When loading the built-in libraries, dynamicClass is null. We
      // take advantage of this as core and coreimpl import js_helper
      // and see Dynamic this way.
      withCurrentElement(dynamicClass, () {
        library.define(dynamicClass, this);
      });
    }
  }

  abstract LibraryElement scanBuiltinLibrary(String filename);

  void initializeSpecialClasses() {
    bool coreLibValid = true;
    ClassElement lookupSpecialClass(SourceString name) {
      ClassElement result = coreLibrary.find(name);
      if (result === null) {
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
    closureClass = lookupSpecialClass(const SourceString('Closure'));
    dynamicClass = lookupSpecialClass(const SourceString('Dynamic'));
    nullClass = lookupSpecialClass(const SourceString('Null'));
    types = new Types(dynamicClass);
    if (!coreLibValid) {
      cancel('core library does not contain required classes');
    }

    jsIndexingBehaviorInterface =
        findHelper(const SourceString('JavaScriptIndexingBehavior'));
  }

  void scanBuiltinLibraries() {
    coreImplLibrary = scanBuiltinLibrary('coreimpl');
    jsHelperLibrary = scanBuiltinLibrary('_js_helper');
    interceptorsLibrary = scanBuiltinLibrary('_interceptors');
    coreLibrary = scanBuiltinLibrary('core');

    // Since coreLibrary import the libraries "coreimpl", "js_helper",
    // and "interceptors", coreLibrary is null when they are being
    // built. So we add the implicit import of coreLibrary now. This
    // can be cleaned up when we have proper support for "dart:core"
    // and don't need to access it through the field "coreLibrary".
    // TODO(ahe): Clean this up as described above.
    scanner.importLibrary(coreImplLibrary, coreLibrary, null);
    scanner.importLibrary(jsHelperLibrary, coreLibrary, null);
    scanner.importLibrary(interceptorsLibrary, coreLibrary, null);
    addForeignFunctions(jsHelperLibrary);
    addForeignFunctions(interceptorsLibrary);

    libraries['dart:core'] = coreLibrary;
    libraries['dart:coreimpl'] = coreImplLibrary;

    assertMethod = coreLibrary.find(const SourceString('assert'));

    initializeSpecialClasses();
  }

  /** Define the JS helper functions in the given library. */
  void addForeignFunctions(LibraryElement library) {
    library.define(new ForeignElement(
        const SourceString('JS'), library), this);
    library.define(new ForeignElement(
        const SourceString('UNINTERCEPTED'), library), this);
    library.define(new ForeignElement(
        const SourceString('JS_HAS_EQUALS'), library), this);
    library.define(new ForeignElement(
        const SourceString('JS_CURRENT_ISOLATE'), library), this);
    library.define(new ForeignElement(
        const SourceString('JS_CALL_IN_ISOLATE'), library), this);
    library.define(new ForeignElement(
        const SourceString('DART_CLOSURE_TO_JS'), library), this);
  }

  void runCompiler(Uri uri) {
    scanBuiltinLibraries();
    mainApp = scanner.loadLibrary(uri, null);
    final Element main = mainApp.find(MAIN);
    if (main === null) {
      reportFatalError('Could not find $MAIN', mainApp);
    } else {
      if (!main.isFunction()) reportFatalError('main is not a function', main);
      FunctionElement mainMethod = main;
      FunctionSignature parameters = mainMethod.computeSignature(this);
      parameters.forEachParameter((Element parameter) {
        reportFatalError('main cannot have parameters', parameter);
      });
    }

    // TODO(ahe): Remove this line. Eventually, enqueuer.resolution
    // should know this.
    world.populate(this, libraries.getValues());

    log('Resolving...');
    phase = PHASE_RESOLVING;
    backend.enqueueHelpers(enqueuer.resolution);
    processQueue(enqueuer.resolution, main);
    log('Resolved ${enqueuer.resolution.resolvedElements.length} elements.');

    log('Compiling...');
    phase = PHASE_COMPILING;
    processQueue(enqueuer.codegen, main);
    log("Recompiling ${enqueuer.codegen.recompilationCandidates.length} "
        "methods...");
    phase = PHASE_RECOMPILING;
    processRecompilationQueue(enqueuer.codegen);
    log('Compiled ${codegenWorld.generatedCode.length} methods.');

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
    assert(world.checkNoEnqueuedInvokedInstanceMethods());
    world.registerFieldClosureInvocations();
  }

  void processRecompilationQueue(Enqueuer world) {
    assert(phase == PHASE_RECOMPILING);
    while (!world.recompilationCandidates.isEmpty()) {
      WorkItem work = world.recompilationCandidates.next();
      String oldCode = world.universe.generatedCode[work.element];
      world.universe.generatedCode.remove(work.element);
      world.universe.generatedBailoutCode.remove(work.element);
      withCurrentElement(work.element, () => work.run(this, world));
      String newCode = world.universe.generatedCode[work.element];
      if (REPORT_PASS2_OPTIMIZATIONS && newCode != oldCode) {
        log("Pass 2 optimization:");
        log("Before:\n$oldCode");
        log("After:\n$newCode");
      }
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
          e.kind === ElementKind.ABSTRACT_FIELD) {
        resolved.remove(e);
      }
      if (e.kind === ElementKind.GENERATIVE_CONSTRUCTOR) {
        ClassElement enclosingClass = e.enclosingElement;
        if (enclosingClass.isInterface()) {
          resolved.remove(e);
        }
        resolved.remove(e);

      }
      if (e.getLibrary() === jsHelperLibrary) {
        resolved.remove(e);
      }
      if (e.getLibrary() === interceptorsLibrary) {
        resolved.remove(e);
      }
    }
    log('Excess resolution work: ${resolved.length}.');
    if (!REPORT_EXCESS_RESOLUTION) return;
    for (Element e in resolved) {
      SourceSpan span = spanFromElement(e);
      reportDiagnostic(span, 'Warning: $e resolved but not compiled.', false);
    }
  }

  TreeElements analyzeElement(Element element) {
    TreeElements elements = enqueuer.resolution.getCachedElements(element);
    if (elements !== null) return elements;
    final int allowed = ElementCategory.VARIABLE | ElementCategory.FUNCTION
                        | ElementCategory.FACTORY;
    ElementKind kind = element.kind;
    if (!element.isAccessor() &&
        ((kind === ElementKind.ABSTRACT_FIELD) ||
         (kind.category & allowed) == 0)) {
      return null;
    }
    assert(parser !== null);
    Node tree = parser.parse(element);
    validator.validate(tree);
    unparseValidator.check(element);
    elements = resolver.resolve(element);
    checker.check(tree, elements);
    return elements;
  }

  TreeElements analyze(WorkItem work, Enqueuer world) {
    if (work.isAnalyzed()) return work.resolutionTree;
    if (progress.elapsedInMs() > 500) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      if (phase == PHASE_RESOLVING) {
        log('Resolved ${enqueuer.resolution.resolvedElements.length}'
            'elements.');
        progress.reset();
      }
    }
    Element element = work.element;
    TreeElements result = world.getCachedElements(element);
    if (result !== null) return result;
    if (world !== enqueuer.resolution) {
      internalErrorOnElement(element,
                             'Internal error: unresolved element: $element.');
    }
    result = analyzeElement(element);
    enqueuer.resolution.resolvedElements[element] = result;
    return result;
  }

  String codegen(WorkItem work, Enqueuer world) {
    if (world !== enqueuer.codegen) return null;
    if (progress.elapsedInMs() > 500) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      if (phase == PHASE_COMPILING) {
        log('Compiled ${codegenWorld.generatedCode.length} methods.');
      } else {
        log('Recompiled ${world.recompilationCandidates.processed} methods.');
      }
      progress.reset();
    }
    if (work.element.kind.category == ElementCategory.VARIABLE) {
      constantHandler.compileWorkItem(work);
      return null;
    } else {
      String code = backend.codegen(work);
      codegenWorld.addGeneratedCode(work, code);
      return code;
    }
  }

  void registerInstantiatedClass(ClassElement cls) {
    enqueuer.resolution.registerInstantiatedClass(cls);
    enqueuer.codegen.registerInstantiatedClass(cls);
  }

  void resolveClass(ClassElement element) {
    withCurrentElement(element, () => resolver.resolveClass(element));
  }

  Type resolveTypeAnnotation(Element element, TypeAnnotation annotation) {
    return resolver.resolveTypeAnnotation(element, annotation);
  }

  FunctionSignature resolveSignature(FunctionElement element) {
    return withCurrentElement(element,
                              () => resolver.resolveSignature(element));
  }

  FunctionSignature resolveTypedef(TypedefElement element) {
    return withCurrentElement(element,
                              () => resolver.resolveTypedef(element));
  }

  FunctionType computeFunctionType(Element element,
                                   FunctionSignature signature) {
    return withCurrentElement(element,
        () => resolver.computeFunctionType(element, signature));
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
      if (message.message.kind === MessageKind.NOT_ASSIGNABLE) return;
      if (message.message.kind === MessageKind.MISSING_RETURN) return;
      if (message.message.kind === MessageKind.MAYBE_MISSING_RETURN) return;
      if (message.message.kind === MessageKind.ADDITIONAL_ARGUMENT) return;
      if (message.message.kind === MessageKind.METHOD_NOT_FOUND) return;
    }
    SourceSpan span = spanFromNode(node);

    reportDiagnostic(span, "${magenta('warning:')} $message", false);
  }

  reportError(Node node, var message) {
    SourceSpan span = spanFromNode(node);
    reportDiagnostic(span, "${red('error:')} $message", true);
    throw new CompilerCancelledException(message.toString());
  }

  abstract void reportDiagnostic(SourceSpan span, String message, bool fatal);

  SourceSpan spanFromTokens(Token begin, Token end, [Uri uri]) {
    if (begin === null || end === null) {
      // TODO(ahe): We can almost always do better. Often it is only
      // end that is null. Otherwise, we probably know the current
      // URI.
      throw 'Cannot find tokens to produce error message.';
    }
    if (uri === null) {
      uri = currentElement.getCompilationUnit().script.uri;
    }
    return SourceSpan.withOffsets(begin, end, (beginOffset, endOffset) =>
        new SourceSpan(uri, beginOffset, endOffset));
  }

  SourceSpan spanFromNode(Node node) {
    return spanFromTokens(node.getBeginToken(), node.getEndToken());
  }

  SourceSpan spanFromElement(Element element) {
    if (element.position() === null) {
      // Sometimes, the backend fakes up elements that have no
      // position. So we use the enclosing element instead. It is
      // not a good error location, but cancel really is "internal
      // error" or "not implemented yet", so the vicinity is good
      // enough for now.
      element = element.enclosingElement;
      // TODO(ahe): I plan to overhaul this infrastructure anyways.
    }
    if (element === null) {
      element = currentElement;
    }
    Token position = element.position();
    Uri uri = element.getCompilationUnit().script.uri;
    return (position === null)
        ? new SourceSpan(uri, 0, 0)
        : spanFromTokens(position, position, uri);
  }

  Script readScript(Uri uri, [ScriptTag node]) {
    unimplemented('Compiler.readScript');
  }

  String get legDirectory() {
    unimplemented('Compiler.legDirectory');
  }

  Element findHelper(SourceString name)
      => jsHelperLibrary.findLocal(name);
  Element findInterceptor(SourceString name)
      => interceptorsLibrary.findLocal(name);

  bool get isMockCompilation() => false;
}

class CompilerTask {
  final Compiler compiler;
  final Stopwatch watch;

  CompilerTask(this.compiler) : watch = new Stopwatch();

  String get name() => 'Unknown task';
  int get timing() => watch.elapsedInMs();

  measure(Function action) {
    // TODO(kasperl): Do we have to worry about exceptions here?
    CompilerTask previous = compiler.measuredTask;
    compiler.measuredTask = this;
    if (previous !== null) previous.watch.stop();
    watch.start();
    var result = action();
    watch.stop();
    if (previous !== null) previous.watch.start();
    compiler.measuredTask = previous;
    return result;
  }
}

class CompilerCancelledException implements Exception {
  final String reason;
  CompilerCancelledException(this.reason);

  String toString() {
    String banner = 'compiler cancelled';
    return (reason !== null) ? '$banner: $reason' : '$banner';
  }
}

class Tracer {
  final bool enabled = false;

  const Tracer();

  void traceCompilation(String methodName) {
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

  static withOffsets(Token begin, Token end,
                     f(int beginOffset, int endOffset)) {
    final beginOffset = begin.charOffset;
    // TODO(ahe): Compute proper end offset in token. Right now we use
    // the position of the next token. We want to preserve the
    // invariant that endOffset > beginOffset, but for EOF the
    // charoffset of the next token may be [beginOffset]. This can
    // also happen for synthetized tokens that are produced during
    // error handling.
    final endOffset =
      Math.max((end.next !== null) ? end.next.charOffset : 0, beginOffset + 1);
    assert(endOffset > beginOffset);
    return f(beginOffset, endOffset);
  }
}
