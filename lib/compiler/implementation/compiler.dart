// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    if (!isAnalyzed()) compiler.analyze(this);
    return compiler.codegen(this);
  }
}

class Backend {
  final Compiler compiler;

  Backend(this.compiler);

  abstract String codegen(WorkItem work);
  abstract void processNativeClasses(world, libraries);
  abstract void assembleProgram();
}

class JavaScriptBackend extends Backend {
  SsaBuilderTask builder;
  SsaOptimizerTask optimizer;
  SsaCodeGeneratorTask generator;
  CodeEmitterTask emitter;

  JavaScriptBackend(Compiler compiler)
      : emitter = new CodeEmitterTask(compiler),
        super(compiler) {
    builder = new SsaBuilderTask(this);
    optimizer = new SsaOptimizerTask(this);
    generator = new SsaCodeGeneratorTask(this);
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

  void processNativeClasses(world, libraries) {
    native.processNativeClasses(world, emitter, libraries);
  }

  void assembleProgram() => emitter.assembleProgram();
}

class DartBackend extends Backend {
  DartBackend(Compiler compiler) : super(compiler);
}

class Compiler implements DiagnosticListener {
  final Map<String, LibraryElement> libraries;
  int nextFreeClassId = 0;
  World world;
  String assembledCode;
  Namer namer;
  Types types;
  final bool enableTypeAssertions;

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

  Stopwatch codegenProgress;

  Compiler([this.tracer = const Tracer(),
            this.enableTypeAssertions = false,
            bool emitJavascript = true,
            validateUnparse = false])
      : libraries = new Map<String, LibraryElement>(),
        world = new World(),
        codegenProgress = new Stopwatch.start() {
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
        new JavaScriptBackend(this) : new DartBackend(this);
    enqueuer = new EnqueueTask(this);
    tasks = [scanner, dietParser, parser, resolver, checker,
             unparseValidator, constantHandler, enqueuer];
  }

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
    if (element.enclosingElement == objectClass) return;
    enabledNoSuchMethod = true;
    enqueuer.codegen.registerInvocation(NO_SUCH_METHOD,
                                        new Selector.invocation(2));
  }

  void enableIsolateSupport(LibraryElement element) {
    // TODO(ahe): Move this method to Enqueuer.
    isolateLibrary = element;
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

    // Not yet ready to process the enqueuer.resolution queue...
    // processQueue(enqueuer.resolution);
    processQueue(enqueuer.codegen, main);

    backend.assembleProgram();
    if (!enqueuer.codegen.queue.isEmpty()) {
      internalErrorOnElement(enqueuer.codegen.queue.first().element,
                             "work list is not empty");
    }
  }

  processQueue(Enqueuer world, Element main) {
    backend.processNativeClasses(world, libraries.getValues());
    world.addToWorkList(main);
    codegenProgress.reset();
    while (!world.queue.isEmpty()) {
      WorkItem work = world.queue.removeLast();
      withCurrentElement(work.element, () => work.run(this, world));
    }
    world.queueIsClosed = true;
    assert(world.checkNoEnqueuedInvokedInstanceMethods());
    world.registerFieldClosureInvocations();
  }

  TreeElements analyzeElement(Element element) {
    assert(parser !== null);
    Node tree = parser.parse(element);
    validator.validate(tree);
    unparseValidator.check(element);
    TreeElements elements = resolver.resolve(element);
    checker.check(tree, elements);
    return elements;
  }

  TreeElements analyze(WorkItem work) {
    work.resolutionTree = analyzeElement(work.element);
    return work.resolutionTree;
  }

  String codegen(WorkItem work) {
    if (codegenProgress.elapsedInMs() > 500) {
      // TODO(ahe): Add structured diagnostics to the compiler API and
      // use it to separate this from the --verbose option.
      log('compiled ${codegenWorld.generatedCode.length} methods');
      codegenProgress.reset();
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

  SourceSpan spanFromTokens(Token begin, Token end) {
    if (begin === null || end === null) {
      // TODO(ahe): We can almost always do better. Often it is only
      // end that is null. Otherwise, we probably know the current
      // URI.
      throw 'cannot find tokens to produce error message';
    }
    Uri uri = currentElement.getCompilationUnit().script.uri;
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
    if (position === null) {
      Uri uri = element.getCompilationUnit().script.uri;
      return new SourceSpan(uri, 0, 0);
    }
    return spanFromTokens(position, position);
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
