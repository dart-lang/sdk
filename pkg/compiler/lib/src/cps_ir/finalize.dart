library dart2js.cps_ir.finalize;

import 'cps_ir_nodes.dart';
import 'cps_fragment.dart';
import 'optimizers.dart' show Pass;
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../js_backend/backend_helpers.dart';

/// A transformation pass that must run immediately before the tree IR builder.
///
/// This expands [BoundsCheck] nodes into more low-level operations.
class Finalize extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Finalize';

  JavaScriptBackend backend;
  BackendHelpers get helpers => backend.helpers;

  Finalize(this.backend);

  void rewrite(FunctionDefinition node) {
    visit(node);
  }

  Expression traverseLetPrim(LetPrim node) {
    CpsFragment cps = visit(node.primitive);
    if (cps == null) return node.body;
    cps.insertBelow(node);
    Expression next = node.body;
    node.remove();
    return next;
  }

  bool areAdjacent(Primitive first, Primitive second) {
    return first.parent == second.parent.parent;
  }

  CpsFragment visitBoundsCheck(BoundsCheck node) {
    CpsFragment cps = new CpsFragment(node.sourceInformation);
    if (node.hasNoChecks) {
      node..replaceUsesWith(node.object.definition)..destroy();
      return cps;
    }
    Continuation fail = cps.letCont();
    if (node.hasLowerBoundCheck) {
      cps.ifTruthy(cps.applyBuiltin(BuiltinOperator.NumLt,
          [node.index.definition, cps.makeZero()]))
          .invokeContinuation(fail);
    }
    if (node.hasUpperBoundCheck) {
      Primitive length = node.length.definition;
      if (length is GetLength &&
          length.hasExactlyOneUse &&
          areAdjacent(length, node)) {
        // Rebind the GetLength here, so it does not get stuck outside the
        // condition, blocked from propagating by the lower bounds check.
        LetPrim lengthBinding = length.parent;
        lengthBinding.remove();
        cps.letPrim(length);
      }
      cps.ifTruthy(cps.applyBuiltin(BuiltinOperator.NumGe,
          [node.index.definition, length]))
          .invokeContinuation(fail);
    }
    if (node.hasEmptinessCheck) {
      cps.ifTruthy(cps.applyBuiltin(BuiltinOperator.StrictEq,
          [node.length.definition, cps.makeZero()]))
          .invokeContinuation(fail);
    }
    cps.insideContinuation(fail).invokeStaticThrower(
          helpers.throwIndexOutOfRangeException,
          [node.object.definition, node.index.definition]);
    node..replaceUsesWith(node.object.definition)..destroy();
    return cps;
  }

  void visitGetStatic(GetStatic node) {
    if (node.witness != null) {
      node..witness.unlink()..witness = null;
    }
  }
}
