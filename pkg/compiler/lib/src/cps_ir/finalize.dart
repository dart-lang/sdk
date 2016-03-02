library dart2js.cps_ir.finalize;

import 'cps_ir_nodes.dart';
import 'cps_fragment.dart';
import 'optimizers.dart' show Pass;
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../js_backend/backend_helpers.dart';
import '../js/js.dart' as js;

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
      node..replaceUsesWith(node.object)..destroy();
      return cps;
    }
    Continuation fail = cps.letCont();
    Primitive index = node.index;
    if (node.hasIntegerCheck) {
      cps.ifTruthy(cps.applyBuiltin(BuiltinOperator.IsNotUnsigned32BitInteger,
          [index, index]))
          .invokeContinuation(fail);
    } else if (node.hasLowerBoundCheck) {
      cps.ifTruthy(cps.applyBuiltin(BuiltinOperator.NumLt,
          [index, cps.makeZero()]))
          .invokeContinuation(fail);
    }
    if (node.hasUpperBoundCheck) {
      Primitive length = node.length;
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
          [index, length]))
          .invokeContinuation(fail);
    }
    if (node.hasEmptinessCheck) {
      cps.ifTruthy(cps.applyBuiltin(BuiltinOperator.StrictEq,
          [node.length, cps.makeZero()]))
          .invokeContinuation(fail);
    }
    cps.insideContinuation(fail).invokeStaticThrower(
          helpers.throwIndexOutOfRangeException,
          [node.object, index]);
    node..replaceUsesWith(node.object)..destroy();
    return cps;
  }

  void visitGetStatic(GetStatic node) {
    if (node.witnessRef != null) {
      node..witnessRef.unlink()..witnessRef = null;
    }
  }

  void visitForeignCode(ForeignCode node) {
    if (js.isIdentityTemplate(node.codeTemplate)) {
      // The CPS builder replaces identity templates with refinements, except
      // when the refined type is an array type.  Some optimizations assume the
      // type of an object is immutable, but the type of an array can change
      // after allocation.  After the finalize pass, this assumption is no
      // longer needed, so we can replace the remaining idenitity templates.
      Refinement refinement = new Refinement(node.argument(0), node.type)
          ..type = node.type;
      node.replaceWith(refinement);
    }
  }
}
