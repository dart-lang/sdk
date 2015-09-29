// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cps_ir.optimization.insert_refinements;

import 'optimizers.dart' show Pass;
import 'shrinking_reductions.dart' show ParentVisitor;
import 'cps_ir_nodes.dart';
import '../types/constants.dart';
import '../constants/values.dart';
import '../common/names.dart';
import '../universe/universe.dart';
import '../elements/elements.dart';
import '../types/types.dart' show TypeMask;
import 'type_mask_system.dart';

/// Inserts [Refinement] nodes in the IR to allow for sparse path-sensitive
/// type analysis in the [TypePropagator] pass.
///
/// Refinement nodes are inserted at the arms of a [Branch] node with a
/// condition of form `x is T` or `x == null`.
///
/// Refinement nodes are inserted after a method invocation to refine the
/// receiver to the types that can respond to the given selector.
class InsertRefinements extends RecursiveVisitor implements Pass {
  String get passName => 'Insert refinement nodes';

  final TypeMaskSystem types;

  /// Maps unrefined primitives to its refinement currently in scope (if any).
  final Map<Primitive, Refinement> refinementFor = <Primitive, Refinement>{};

  InsertRefinements(this.types);

  void rewrite(FunctionDefinition node) {
    new ParentVisitor().visit(node);
    visit(node.body);
  }

  /// Updates references to refer to the refinement currently in scope.
  void processReference(Reference node) {
    Refinement refined = refinementFor[node.definition];
    if (refined != null) {
      node.changeTo(refined);
    }
  }

  /// Sinks the binding of [cont] to immediately above [use].
  ///
  /// This is used to ensure that everything in scope at [use] is also in scope
  /// inside [cont], so refinements can be inserted inside [cont] without
  /// accidentally referencing a primitive out of scope.
  ///
  /// It is always safe to do this for single-use continuations, because
  /// strictly more things are in scope at the use site, and there can't be any
  /// other use of [cont] that might fall out of scope since there is only
  /// that single use.
  void sinkContinuationToUse(Continuation cont, Expression use) {
    assert(cont.hasExactlyOneUse && cont.firstRef.parent == use);
    assert(!cont.isRecursive);
    LetCont let = cont.parent;
    InteriorNode useParent = use.parent;
    if (useParent == let) return;
    if (let.continuations.length > 1) {
      // Create a new LetCont binding only this continuation.
      let.continuations.remove(cont);
      let = new LetCont(cont, null);
      cont.parent = let;
    } else {
      let.remove(); // Reuse the existing LetCont.
    }
    let.insertAbove(use);
  }

  Primitive unfoldInterceptor(Primitive prim) {
    return prim is Interceptor ? prim.input.definition : prim;
  }

  /// Enqueues [cont] for processing in a context where [refined] is the
  /// current refinement for its value.
  void pushRefinement(Continuation cont, Refinement refined) {
    Primitive value = refined.effectiveDefinition;
    Primitive currentRefinement = refinementFor[value];
    pushAction(() {
      refinementFor[value] = currentRefinement;
      if (refined.hasNoUses) {
        // Clean up refinements that are not used.
        refined.destroy();
      } else {
        LetPrim let = new LetPrim(refined);
        refined.parent = let;
        let.insertBelow(cont);
      }
    });
    push(cont);
    pushAction(() {
      refinementFor[value] = refined;
    });
  }

  void visitInvokeMethod(InvokeMethod node) {
    Continuation cont = node.continuation.definition;

    // Update references to their current refined values.
    processReference(node.receiver);
    node.arguments.forEach(processReference);

    // If the call is intercepted, we want to refine the actual receiver,
    // not the interceptor.
    Primitive receiver = unfoldInterceptor(node.receiver.definition);

    // Sink the continuation to the call to ensure everything in scope
    // here is also in scope inside the continuations.
    sinkContinuationToUse(cont, node);

    if (node.selector.isClosureCall) {
      // Do not try to refine the receiver of closure calls; the class world
      // does not know about closure classes.
      push(cont);
    } else {
      // Filter away receivers that throw on this selector.
      TypeMask type = types.receiverTypeFor(node.selector, node.mask);
      pushRefinement(cont, new Refinement(receiver, type));
    }
  }

  CallExpression getCallWithResult(Primitive prim) {
    if (prim is Parameter && prim.parent is Continuation) {
      Continuation cont = prim.parent;
      if (cont.hasExactlyOneUse && cont.firstRef.parent is CallExpression) {
        return cont.firstRef.parent;
      }
    }
    return null;
  }

  bool isTrue(Primitive prim) {
    return prim is Constant && prim.value.isTrue;
  }

  void visitBranch(Branch node) {
    processReference(node.condition);
    Primitive condition = node.condition.definition;
    CallExpression call = getCallWithResult(condition);

    Continuation trueCont = node.trueContinuation.definition;
    Continuation falseCont = node.falseContinuation.definition;

    // Sink both continuations to the Branch to ensure everything in scope
    // here is also in scope inside the continuations.
    sinkContinuationToUse(trueCont, node);
    sinkContinuationToUse(falseCont, node);

    // If the condition is an 'is' check, promote the checked value.
    if (condition is TypeTest) {
      Primitive value = condition.value.definition;
      TypeMask type = types.subtypesOf(condition.dartType);
      Primitive refinedValue = new Refinement(value, type);
      pushRefinement(trueCont, refinedValue);
      push(falseCont);
      return;
    }

    // If the condition is comparison with a constant, promote the other value.
    // This can happen either for calls to `==` or `identical` calls, such
    // as the ones inserted by the unsugaring pass.

    void refineEquality(Primitive first,
                        Primitive second,
                        Continuation trueCont,
                        Continuation falseCont) {
      if (second is Constant && second.value.isNull) {
        Refinement refinedTrue = new Refinement(first, types.nullType);
        Refinement refinedFalse = new Refinement(first, types.nonNullType);
        pushRefinement(trueCont, refinedTrue);
        pushRefinement(falseCont, refinedFalse);
      } else if (first is Constant && first.value.isNull) {
        Refinement refinedTrue = new Refinement(second, types.nullType);
        Refinement refinedFalse = new Refinement(second, types.nonNullType);
        pushRefinement(trueCont, refinedTrue);
        pushRefinement(falseCont, refinedFalse);
      } else {
        push(trueCont);
        push(falseCont);
      }
    }

    if (call is InvokeMethod && call.selector == Selectors.equals) {
      refineEquality(call.arguments[0].definition,
                     call.arguments[1].definition,
                     trueCont,
                     falseCont);
      return;
    }

    if (condition is ApplyBuiltinOperator &&
        condition.operator == BuiltinOperator.Identical) {
      refineEquality(condition.arguments[0].definition,
                     condition.arguments[1].definition,
                     trueCont,
                     falseCont);
      return;
    }

    push(trueCont);
    push(falseCont);
  }

  @override
  Expression traverseLetCont(LetCont node) {
    for (Continuation cont in node.continuations) {
      if (cont.hasExactlyOneUse &&
          (cont.firstRef.parent is InvokeMethod ||
           cont.firstRef.parent is Branch)) {
        // Do not push the continuation here.
        // visitInvokeMethod and visitBranch will do that.
      } else {
        push(cont);
      }
    }
    return node.body;
  }
}
