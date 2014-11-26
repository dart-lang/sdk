library dart2js.unsugar_cps;

import '../../cps_ir/cps_ir_nodes.dart';

// TODO(karlklose): share the [ParentVisitor].
import '../../cps_ir/optimizers.dart';
import '../../constants/expressions.dart';
import '../../constants/values.dart';

/// Rewrites the initial CPS IR to make Dart semantics explicit and inserts
/// special nodes that respect JavaScript behavior.
///
/// Performs the following rewrites:
///  - rewrite [IsTrue] in a [Branch] to do boolean conversion.
class UnsugarVisitor extends RecursiveVisitor {
  const UnsugarVisitor();

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
