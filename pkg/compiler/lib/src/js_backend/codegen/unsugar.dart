library dart2js.unsugar_cps;

import '../../cps_ir/cps_ir_nodes.dart';

// TODO(karlklose): share the [ParentVisitor].
import '../../cps_ir/optimizers.dart';
import '../../constants/expressions.dart';
import '../../constants/values.dart';
import '../../elements/elements.dart' show ClassElement, FieldElement;
import '../../js_backend/codegen/glue.dart';
import '../../dart2jslib.dart' show Selector;

/// Rewrites the initial CPS IR to make Dart semantics explicit and inserts
/// special nodes that respect JavaScript behavior.
///
/// Performs the following rewrites:
///  - rewrite [IsTrue] in a [Branch] to do boolean conversion.
class UnsugarVisitor extends RecursiveVisitor {
  Glue _glue;

  UnsugarVisitor(this._glue);

  void rewrite(FunctionDefinition function) {
    // Set all parent pointers.
    new ParentVisitor().visit(function);
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

  processInvokeMethod(InvokeMethod node) {
    Selector selector = node.selector;
    if (!_glue.isInterceptedSelector(selector)) return;

    if (!selector.isCall && !selector.isOperator) {
      // TODO(karlklose): handle special selectors.
      return;
    }

    Set<ClassElement> interceptedClasses =
        _glue.getInterceptedClassesOn(selector);
    _glue.registerSpecializedGetInterceptor(interceptedClasses);

    Primitive receiver = node.receiver.definition;
    Primitive intercepted = new Interceptor(receiver, interceptedClasses);
    insertLetPrim(intercepted, node);
    node.arguments.insert(0, node.receiver);
    node.receiver = new Reference<Primitive>(intercepted);
  }

  Primitive makeNull() {
    NullConstantValue nullConst = new NullConstantValue();
    return new Constant(new PrimitiveConstantExpression(nullConst));
  }

  processInvokeMethodDirectly(InvokeMethodDirectly node) {
    if (_glue.isInterceptedSelector(node.selector)) {
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
