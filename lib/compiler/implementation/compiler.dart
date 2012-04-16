// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class WorkItem {
  final Element element;
  TreeElements resolutionTree;
  Function run;
  bool allowSpeculativeOptimization = true;
  List<HTypeGuard> guards = const <HTypeGuard>[];

  WorkItem.toCompile(this.element) : resolutionTree = null {
    run = this.compile;
  }

  WorkItem.toCodegen(this.element, this.resolutionTree) {
    run = this.codegen;
  }

  bool isAnalyzed() => resolutionTree != null;

  int hashCode() => element.hashCode();

  String compile(Compiler compiler) {
    return compiler.compile(this);
  }

  String codegen(Compiler compiler) {
    return compiler.codegen(this);
  }
}

class Compiler implements DiagnosticListener {
  Queue<WorkItem> worklist;
  Universe universe;
  String assembledCode;
  Namer namer;
  Types types;

  final Tracer tracer;

  CompilerTask measuredTask;
  Element _currentElement;
  LibraryElement coreLibrary;
  LibraryElement coreImplLibrary;
  LibraryElement isolateLibrary;
  LibraryElement jsHelperLibrary;
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
    } finally {
      _currentElement = old;
    }
  }

  List<CompilerTask> tasks;
  ScannerTask scanner;
  DietParserTask dietParser;
  ParserTask parser;
  TreeValidatorTask validator;
  ResolverTask resolver;
  TypeCheckerTask checker;
  SsaBuilderTask builder;
  SsaOptimizerTask optimizer;
  SsaCodeGeneratorTask generator;
  CodeEmitterTask emitter;
  ConstantHandler constantHandler;
  EnqueueTask enqueuer;

  static final SourceString MAIN = const SourceString('main');
  static final SourceString NO_SUCH_METHOD = const SourceString('noSuchMethod');
  static final SourceString NO_SUCH_METHOD_EXCEPTION =
      const SourceString('NoSuchMethodException');
  static final SourceString START_ROOT_ISOLATE =
      const SourceString('startRootIsolate');
  bool enabledNoSuchMethod = false;

  bool workListIsClosed = false;

  Stopwatch codegenProgress;

  Compiler([this.tracer = const Tracer()])
      : types = new Types(),
        universe = new Universe(),
        worklist = new Queue<WorkItem>(),
        codegenProgress = new Stopwatch.start() {
    namer = new Namer(this);
    constantHandler = new ConstantHandler(this);
    scanner = new ScannerTask(this);
    dietParser = new DietParserTask(this);
    parser = new ParserTask(this);
    validator = new TreeValidatorTask(this);
    resolver = new ResolverTask(this);
    checker = new TypeCheckerTask(this);
    builder = new SsaBuilderTask(this);
    optimizer = new SsaOptimizerTask(this);
    generator = new SsaCodeGeneratorTask(this);
    emitter = new CodeEmitterTask(this);
    enqueuer = new EnqueueTask(this);
    tasks = [scanner, dietParser, parser, resolver, checker,
             builder, optimizer, generator,
             emitter, constantHandler, enqueuer];
  }

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
    withCurrentElement(element, () {
      internalError(message, element: element);
    });
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
    }
    reportDiagnostic(span, red(reason), true);
    throw new CompilerCancelledException(reason);
  }

  void log(message) {
    reportDiagnostic(null, message, false);
  }

  void enqueue(WorkItem work) {
    if (workListIsClosed) {
      internalErrorOnElement(work.element, "work list is closed");
    }
    worklist.add(work);
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
    if (enabledNoSuchMethod) return;
    if (element.enclosingElement == objectClass) return;
    enabledNoSuchMethod = true;
    enqueuer.registerInvocation(NO_SUCH_METHOD, new Invocation(2));
  }

  void enableIsolateSupport(LibraryElement element) {
    isolateLibrary = element;
    addToWorkList(element.find(START_ROOT_ISOLATE));
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
    objectClass = coreLibrary.find(const SourceString('Object'));
    boolClass = coreLibrary.find(const SourceString('bool'));
    numClass = coreLibrary.find(const SourceString('num'));
    intClass = coreLibrary.find(const SourceString('int'));
    doubleClass = coreLibrary.find(const SourceString('double'));
    stringClass = coreLibrary.find(const SourceString('String'));
    functionClass = coreLibrary.find(const SourceString('Function'));
    listClass = coreLibrary.find(const SourceString('List'));
    closureClass = jsHelperLibrary.find(const SourceString('Closure'));
    dynamicClass = jsHelperLibrary.find(const SourceString('Dynamic'));
    nullClass = jsHelperLibrary.find(const SourceString('Null'));
  }

  void scanBuiltinLibraries() {
    coreImplLibrary = scanBuiltinLibrary('coreimpl');
    jsHelperLibrary = scanBuiltinLibrary('_js_helper');
    coreLibrary = scanBuiltinLibrary('core');

    // Since coreLibrary import the libraries "coreimpl", and
    // "js_helper", coreLibrary is null when they are being built. So
    // we add the implicit import of coreLibrary now. This can be
    // cleaned up when we have proper support for "dart:core" and
    // don't need to access it through the field "coreLibrary".
    // TODO(ahe): Clean this up as described above.
    scanner.importLibrary(coreImplLibrary, coreLibrary, null);
    scanner.importLibrary(jsHelperLibrary, coreLibrary, null);
    addForeignFunctions(jsHelperLibrary);

    universe.libraries['dart:core'] = coreLibrary;
    universe.libraries['dart:coreimpl'] = coreImplLibrary;

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
      withCurrentElement(mainApp, () => cancel('Could not find $MAIN'));
    } else {
      withCurrentElement(main, () {
        if (!main.isFunction()) {
          cancel('main is not a function', element: main);
        }
        FunctionElement mainMethod = main;
        FunctionParameters parameters = mainMethod.computeParameters(this);
        if (parameters.parameterCount > 0) {
          cancel('main cannot have parameters', element: mainMethod);
        }
      });
    }
    native.processNativeClasses(this, universe.libraries.getValues());
    enqueue(new WorkItem.toCompile(main));
    codegenProgress.reset();
    while (!worklist.isEmpty()) {
      WorkItem work = worklist.removeLast();
      withCurrentElement(work.element, () => (work.run)(this));
    }
    workListIsClosed = true;
    assert(enqueuer.checkNoEnqueuedInvokedInstanceMethods());
    enqueuer.registerFieldClosureInvocations();
    emitter.assembleProgram();
    if (!worklist.isEmpty()) {
      internalErrorOnElement(worklist.first().element,
                             "work list is not empty");
    }
  }

  TreeElements analyzeElement(Element element) {
    assert(parser !== null);
    Node tree = parser.parse(element);
    validator.validate(tree);
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
      log('compiled ${universe.generatedCode.length} methods');
      codegenProgress.reset();
    }
    if (work.element.kind.category == ElementCategory.VARIABLE) {
      constantHandler.compileWorkItem(work);
      return null;
    } else {
      HGraph graph = builder.build(work);
      optimizer.optimize(work, graph);
      if (work.allowSpeculativeOptimization
          && optimizer.trySpeculativeOptimizations(work, graph)) {
        String code = generator.generateBailoutMethod(work, graph);
        universe.addBailoutCode(work, code);
        optimizer.prepareForSpeculativeOptimizations(work, graph);
        optimizer.optimize(work, graph);
        code = generator.generateMethod(work, graph);
        universe.addGeneratedCode(work, code);
        return code;
      } else {
        String code = generator.generateMethod(work, graph);
        universe.addGeneratedCode(work, code);
        return code;
      }
    }
  }

  String compile(WorkItem work) {
    String code = universe.generatedCode[work.element];
    if (code !== null) return code;
    analyze(work);
    return codegen(work);
  }

  void addToWorkList(Element element) {
    if (workListIsClosed) {
      internalErrorOnElement(element, "work list is closed");
    }
    if (element.kind === ElementKind.GENERATIVE_CONSTRUCTOR) {
      registerInstantiatedClass(element.enclosingElement);
    }
    worklist.add(new WorkItem.toCompile(element));
  }

  void registerStaticUse(Element element) {
    addToWorkList(element);
  }

  void registerGetOfStaticFunction(FunctionElement element) {
    registerStaticUse(element);
    universe.staticFunctionsNeedingGetter.add(element);
  }

  void registerDynamicInvocation(SourceString methodName, Selector selector) {
    assert(selector !== null);
    enqueuer.registerInvocation(methodName, selector);
  }

  void registerDynamicGetter(SourceString methodName) {
    enqueuer.registerGetter(methodName);
  }

  void registerDynamicSetter(SourceString methodName) {
    enqueuer.registerSetter(methodName);
  }

  void registerInstantiatedClass(ClassElement element) {
    universe.instantiatedClasses.add(element);
    enqueuer.onRegisterInstantiatedClass(element);
  }

  // TODO(ngeoffray): This should get a type.
  void registerIsCheck(Element element) {
    universe.isChecks.add(element);
  }

  Type resolveType(ClassElement element) {
    return withCurrentElement(element, () => resolver.resolveType(element));
  }

  FunctionParameters resolveSignature(FunctionElement element) {
    return withCurrentElement(element,
                              () => resolver.resolveSignature(element));
  }

  Constant compileVariable(VariableElement element) {
    return withCurrentElement(element, () {
      return constantHandler.compileVariable(element);
    });
  }

  reportWarning(Node node, var message) {
    if (message is ResolutionWarning) {
      // TODO(ahe): Don't supress this warning when we support type variables.
      if (message.message.kind === MessageKind.CANNOT_RESOLVE_TYPE) return;
    } else if (message is TypeWarning) {
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
    final startOffset = begin.charOffset;
    // TODO(ahe): Compute proper end offset in token. Right now we use
    // the position of the next token. We want to preserve the
    // invariant that endOffset > startOffset, but for EOF the
    // charoffset of the next token may be [startOffset]. This can
    // also happen for synthetized tokens that are produced during
    // error handling.
    final endOffset =
      Math.max((end.next !== null) ? end.next.charOffset : 0, startOffset + 1);
    assert(endOffset > startOffset);
    Uri uri = currentElement.getCompilationUnit().script.uri;
    return new SourceSpan(uri, startOffset, endOffset);
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
      // TODO(ahe): Find the enclosing library.
      return const SourceSpan(null, null, null);
    }
    return spanFromTokens(position, position);
  }

  Script readScript(Uri uri, [ScriptTag node]) {
    unimplemented('Compiler.readScript');
  }

  String get legDirectory() {
    unimplemented('Compiler.legDirectory');
  }

  Element findHelper(SourceString name) => jsHelperLibrary.find(name);

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

interface Tracer default LTracer {
  const Tracer();
  final bool enabled;
  void traceCompilation(String methodName);
  void traceGraph(String name, var graph);
  void close();
}

// TODO(ahe): Remove when the VM supports implicit interfaces.
class LTracer implements Tracer {
  const LTracer();
  final bool enabled = false;
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
}
