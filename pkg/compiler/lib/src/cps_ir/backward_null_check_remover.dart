library dart2js.cps_ir.backward_null_check_remover;

import 'cps_ir_nodes.dart';
import 'optimizers.dart' show Pass;
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
/// `x.length` will throw when x is null, so the original [NullCheck] is not
/// needed.  This changes the error message, but at least for now we are
/// willing to accept this.
///
/// Note that code motion may not occur after this pass, since the [NullCheck]
/// nodes are not there to restrict it.
//
// TODO(asgerf): It would be nice with a clear specification of when we allow
//   the wording of error message to change.  E.g. "toString" is already pretty
//   bad so changing that should be ok, but changing a field access is not as
//   clear.
//
class BackwardNullCheckRemover extends TrampolineRecursiveVisitor
                               implements Pass {
  String get passName => 'Backward null-check remover';

  final TypeMaskSystem typeSystem;

  /// When the analysis of an expression completes, [nullCheckValue] refers to
  /// a value that is checked in the beginning of that expression.
  Primitive nullCheckedValue;

  BackwardNullCheckRemover(this.typeSystem);

  void rewrite(FunctionDefinition node) {
    visit(node);
  }

  /// Returns a reference to an operand of [prim], where [prim] throws if null
  /// is passed into that operand.
  Reference<Primitive> getNullCheckedOperand(Primitive prim) {
    if (prim is NullCheck) return prim.value;
    if (prim is GetLength) return prim.object;
    if (prim is GetField) return prim.object;
    if (prim is GetIndex) return prim.object;
    if (prim is SetField) return prim.object;
    if (prim is SetIndex) return prim.object;
    if (prim is InvokeMethod && !nullSelectors.contains(prim.selector)) {
      return prim.dartReceiverReference;
    }
    return null;
  }

  static final List<Selector> nullSelectors = <Selector>[
      Selectors.equals, Selectors.hashCode_, Selectors.noSuchMethod_,
      Selectors.runtimeType_];

  /// It has been determined that the null check in [prim] made redundant by
  /// [newNullCheck].  Eliminate [prim] if it is not needed any more.
  void tryEliminateRedundantNullCheck(Primitive prim, Primitive newNullCheck) {
    if (prim is NullCheck) {
      Primitive value = prim.value.definition;
      LetPrim let = prim.parent;
      prim..replaceUsesWith(value)..destroy();
      let.remove();
    } else if (prim is GetLength || prim is GetField || prim is GetIndex) {
      if (prim.hasNoEffectiveUses) {
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

  Expression traverseLetPrim(LetPrim node) {
    Primitive prim = node.primitive;
    Primitive receiver = getNullCheckedOperand(prim)?.definition;
    if (receiver != null) {
      pushAction(() {
        Primitive successor = nullCheckedValue;
        if (successor != null && receiver.sameValue(successor)) {
          tryEliminateRedundantNullCheck(prim, successor);
        }
        nullCheckedValue = receiver;
      });
    } else if (!canMoveAboveNullCheck(prim)) {
      pushAction(() {
        nullCheckedValue = null;
      });
    }
    return node.body;
  }

  Expression traverseContinuation(Continuation cont) {
    pushAction(() {
      nullCheckedValue = null;
    });
    return cont.body;
  }

  Expression traverseLetHandler(LetHandler node) {
    push(node.handler);
    pushAction(() {
      nullCheckedValue = null;
    });
    return node.body;
  }
}
