library dart2js.cps_ir.backward_null_check_remover;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';
import '../common/names.dart';
import '../universe/selector.dart';
import 'type_mask_system.dart';
import 'cps_fragment.dart';

/// Removes null checks that are follwed by another instruction that will
/// perform the same check.
///
/// For example:
///
///     x.toString; // NullCheck instruction
///     print(x.length);
///
/// ==>
///
///     print(x.length);
///
/// `x.length` will throw when x is null, so the original [ReceiverCheck] is not
/// needed.  This changes the error message, but at least for now we are
/// willing to accept this.
///
/// Note that code motion may not occur after this pass, since the [ReceiverCheck]
/// nodes are not there to restrict it.
//
// TODO(asgerf): It would be nice with a clear specification of when we allow
//   the wording of error message to change.  E.g. "toString" is already pretty
//   bad so changing that should be ok, but changing a field access is not as
//   clear.
//
class BackwardNullCheckRemover extends BlockVisitor implements Pass {
  String get passName => 'Backward null-check remover';

  final TypeMaskSystem typeSystem;

  /// When the analysis of an expression completes, [nullCheckValue] refers to
  /// a value that is checked in the beginning of that expression.
  Primitive nullCheckedValue;

  /// The [nullCheckedValue] at the entry point of a continuation.
  final Map<Continuation, Primitive> nullCheckedValueAt =
      <Continuation, Primitive>{};

  BackwardNullCheckRemover(this.typeSystem);

  void rewrite(FunctionDefinition node) {
    BlockVisitor.traverseInPostOrder(node, this);
  }

  /// Returns an operand of [prim] that throws if null is passed into it.
  Primitive getNullCheckedOperand(Primitive prim) {
    if (prim is ReceiverCheck) return prim.value;
    if (prim is GetLength) return prim.object;
    if (prim is GetField) return prim.object;
    if (prim is GetIndex) return prim.object;
    if (prim is SetField) return prim.object;
    if (prim is SetIndex) return prim.object;
    if (prim is InvokeMethod && !selectorsOnNull.contains(prim.selector)) {
      return prim.dartReceiver;
    }
    if (prim is ForeignCode) {
      return prim.isNullGuardOnNullFirstArgument() ? prim.argument(0) : null;
    }
    return null;
  }

  /// It has been determined that the null check in [prim] made redundant by
  /// [newNullCheck].  Eliminate [prim] if it is not needed any more.
  void tryEliminateRedundantNullCheck(Primitive prim, Primitive newNullCheck) {
    if (prim is ReceiverCheck && prim.isNullCheck) {
      Primitive value = prim.value;
      LetPrim let = prim.parent;
      prim..replaceUsesWith(value)..destroy();
      let.remove();
    } else if (prim is GetLength || prim is GetField || prim is GetIndex) {
      if (prim.hasNoRefinedUses) {
        destroyRefinementsOfDeadPrimitive(prim);
        LetPrim let = prim.parent;
        prim..destroy();
        let.remove();
      }
    }
  }

  /// True if [prim] can be moved above a null check.  This is safe if [prim]
  /// cannot throw or have side effects and does not carry any path-sensitive
  /// type information, such as [Refinement] nodes do.
  //
  // TODO(asgerf): This prevents elimination of the .length created for a bounds
  //   check, because there is a refinement node below it.  To handle this, we
  //   would have to relocate the [Refinement] node below the new null check.
  bool canMoveAboveNullCheck(Primitive prim) {
    return prim.isSafeForReordering;
  }

  void visitLetPrim(LetPrim node) {
    Primitive prim = node.primitive;
    Primitive receiver = getNullCheckedOperand(prim);
    if (receiver != null) {
      if (nullCheckedValue != null && receiver.sameValue(nullCheckedValue)) {
        tryEliminateRedundantNullCheck(prim, nullCheckedValue);
      }
      nullCheckedValue = receiver;
    } else if (!canMoveAboveNullCheck(prim)) {
      nullCheckedValue = null;
    }
  }

  void visitContinuation(Continuation cont) {
    if (nullCheckedValue != null) {
      nullCheckedValueAt[cont] = nullCheckedValue;
      nullCheckedValue = null;
    }
  }

  void visitLetHandler(LetHandler node) {
    nullCheckedValue = null;
  }

  visitInvokeContinuation(InvokeContinuation node) {
    if (!node.isRecursive) {
      nullCheckedValue = nullCheckedValueAt[node.continuation];
    }
  }
}
