library dart2js.unsugar_cps;

import '../../cps_ir/cps_ir_nodes.dart';

// TODO(karlklose): share the [ParentVisitor].
import '../../cps_ir/optimizers.dart';
import '../../constants/expressions.dart';
import '../../constants/values.dart';
import '../../elements/elements.dart'
    show ClassElement, FieldElement, FunctionElement, Element;
import '../../js_backend/codegen/glue.dart';
import '../../dart2jslib.dart' show Selector, World;

/// Rewrites the initial CPS IR to make Dart semantics explicit and inserts
/// special nodes that respect JavaScript behavior.
///
/// Performs the following rewrites:
///  - rewrite [IsTrue] in a [Branch] to do boolean conversion.
///  - converts two-parameter exception handlers to one-parameter ones.
class UnsugarVisitor extends RecursiveVisitor {
  Glue _glue;
  ParentVisitor _parentVisitor = new ParentVisitor();

  UnsugarVisitor(this._glue);

  void rewrite(FunctionDefinition function) {
    // Set all parent pointers.
    _parentVisitor.visit(function);
    visit(function);
  }

  @override
  visit(Node node) {
    Node result = node.accept(this);
    return result != null ? result : node;
  }

  Constant get trueConstant {
    return new Constant(
        new PrimitiveConstantExpression(
            new TrueConstantValue()));
  }

  void insertLetPrim(Primitive primitive, Expression node) {
    LetPrim let = new LetPrim(primitive);
    InteriorNode parent = node.parent;
    parent.body = let;
    let.body = node;
    node.parent = let;
    let.parent = parent;
  }

  /// Insert a static call to [function] at the point of [node] with result
  /// [result].
  ///
  /// Rewrite [node] to
  ///
  /// let cont continuation(result) = node
  /// in invoke function arguments continuation
  void insertStaticCall(FunctionElement function, List<Primitive> arguments,
      Parameter result,
      Expression node) {
    InteriorNode parent = node.parent;
    Continuation continuation = new Continuation([result]);
    continuation.body = node;
    _parentVisitor.processContinuation(continuation);

    Selector selector = new Selector.fromElement(function);
    // TODO(johnniwinther): Come up with an implementation of SourceInformation
    // for calls such as this one that don't appear in the original source.
    InvokeStatic invoke =
        new InvokeStatic(function, selector, arguments, continuation, null);
    _parentVisitor.processInvokeStatic(invoke);

    LetCont letCont = new LetCont(continuation, invoke);
    _parentVisitor.processLetCont(letCont);

    parent.body = letCont;
    letCont.parent = parent;
  }

  processLetHandler(LetHandler node) {
    // BEFORE: Handlers have two parameters, exception and stack trace.
    // AFTER: Handlers have a single parameter, which is unwrapped to get
    // the exception and stack trace.
    assert(node.handler.parameters.length == 2);
    Parameter exceptionParameter = node.handler.parameters.first;
    Parameter stackTraceParameter = node.handler.parameters.last;
    Expression body = node.handler.body;
    if (exceptionParameter.hasAtLeastOneUse ||
        stackTraceParameter.hasAtLeastOneUse) {
      Parameter exceptionValue = new Parameter(null);
      exceptionValue.substituteFor(exceptionParameter);
      insertStaticCall(_glue.getExceptionUnwrapper(), [exceptionParameter],
          exceptionValue, body);

      if (stackTraceParameter.hasAtLeastOneUse) {
        Parameter stackTraceValue = new Parameter(null);
        stackTraceValue.substituteFor(stackTraceParameter);
        insertStaticCall(_glue.getTraceFromException(), [exceptionValue],
            stackTraceValue, body);
      }
    }

    assert(stackTraceParameter.hasNoUses);
    node.handler.parameters.removeLast();
  }

  processThrow(Throw node) {
    // The subexpression of throw is wrapped in the JavaScript output.
    Parameter value = new Parameter(null);
    insertStaticCall(_glue.getWrapExceptionHelper(), [node.value.definition],
        value, node);
    node.value.unlink();
    node.value = new Reference<Primitive>(value);
  }

  processInvokeMethod(InvokeMethod node) {
    Selector selector = node.selector;
    // TODO(karlklose):  should we rewrite all selectors?
    if (!_glue.isInterceptedSelector(selector)) return;

    Primitive receiver = node.receiver.definition;
    Set<ClassElement> interceptedClasses =
        _glue.getInterceptedClassesOn(selector);
    _glue.registerSpecializedGetInterceptor(interceptedClasses);

    Primitive intercepted = new Interceptor(receiver, interceptedClasses);
    insertLetPrim(intercepted, node);
    node.arguments.insert(0, node.receiver);
    node.callingConvention = CallingConvention.JS_INTERCEPTED;
    assert(node.isValid);
    node.receiver = new Reference<Primitive>(intercepted);
  }

  Primitive makeNull() {
    NullConstantValue nullConst = new NullConstantValue();
    return new Constant(new PrimitiveConstantExpression(nullConst));
  }

  processInvokeMethodDirectly(InvokeMethodDirectly node) {
    if (_glue.isInterceptedMethod(node.target)) {
      Primitive nullPrim = makeNull();
      insertLetPrim(nullPrim, node);
      node.arguments.insert(0, node.receiver);
      node.receiver = new Reference<Primitive>(nullPrim);
    }
  }

  processBranch(Branch node) {
    // TODO(karlklose): implement the checked mode part of boolean conversion.
    InteriorNode parent = node.parent;
    IsTrue condition = node.condition;
    Primitive t = trueConstant;
    Primitive i = new Identical(condition.value.definition, t);
    LetPrim newNode = new LetPrim(t,
        new LetPrim(i,
            new Branch(new IsTrue(i),
                node.trueContinuation.definition,
                node.falseContinuation.definition)));
    condition.value.unlink();
    node.trueContinuation.unlink();
    node.falseContinuation.unlink();
    parent.body = newNode;
  }
}
