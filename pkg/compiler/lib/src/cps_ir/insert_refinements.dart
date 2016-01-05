// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cps_ir.optimization.insert_refinements;

import 'optimizers.dart' show Pass;
import 'cps_ir_nodes.dart';
import '../common/names.dart';
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
class InsertRefinements extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Insert refinement nodes';

  final TypeMaskSystem types;

  /// Maps unrefined primitives to its refinement currently in scope (if any).
  final Map<Primitive, Refinement> refinementFor = <Primitive, Refinement>{};

  InsertRefinements(this.types);

  void rewrite(FunctionDefinition node) {
    visit(node.body);
  }

  /// Updates references to refer to the refinement currently in scope.
  void processReference(Reference node) {
    Definition definition = node.definition;
    if (definition is Primitive) {
      Primitive prim = definition.effectiveDefinition;
      Refinement refined = refinementFor[prim];
      if (refined != null && refined != definition) {
        node.changeTo(refined);
      }
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
    } else {
      let.remove(); // Reuse the existing LetCont.
    }
    let.insertAbove(use);
  }

  Primitive unfoldInterceptor(Primitive prim) {
    return prim is Interceptor ? prim.input.definition : prim;
  }

  /// Sets [refined] to be the current refinement for its value, and pushes an
  /// action that will restore the original scope again.
  ///
  /// The refinement is inserted as the child of [insertionParent] if it has
  /// at least one use after its scope has been processed.
  void applyRefinement(InteriorNode insertionParent, Refinement refined) {
    Primitive value = refined.effectiveDefinition;
    Primitive currentRefinement = refinementFor[value];
    refinementFor[value] = refined;
    pushAction(() {
      refinementFor[value] = currentRefinement;
      if (refined.hasNoUses) {
        // Clean up refinements that are not used.
        refined.destroy();
      } else {
        LetPrim let = new LetPrim(refined);
        let.insertBelow(insertionParent);
      }
    });
  }

  /// Enqueues [cont] for processing in a context where [refined] is the
  /// current refinement for its value.
  void pushRefinement(Continuation cont, Refinement refined) {
    pushAction(() {
      applyRefinement(cont, refined);
      push(cont);
    });
  }

  void visitInvokeMethod(InvokeMethod node) {
    // Update references to their current refined values.
    processReference(node.receiver);
    node.arguments.forEach(processReference);

    // If the call is intercepted, we want to refine the actual receiver,
    // not the interceptor.
    Primitive receiver = unfoldInterceptor(node.receiver.definition);

    // Do not try to refine the receiver of closure calls; the class world
    // does not know about closure classes.
    if (!node.selector.isClosureCall) {
      // Filter away receivers that throw on this selector.
      TypeMask type = types.receiverTypeFor(node.selector, node.mask);
      Refinement refinement = new Refinement(receiver, type);
      LetPrim letPrim = node.parent;
      applyRefinement(letPrim, refinement);
    }
  }

  void visitTypeCast(TypeCast node) {
    Primitive value = node.value.definition;

    processReference(node.value);
    node.typeArguments.forEach(processReference);

    // Refine the type of the input.
    TypeMask type = types.subtypesOf(node.dartType).nullable();
    Refinement refinement = new Refinement(value, type);
    LetPrim letPrim = node.parent;
    applyRefinement(letPrim, refinement);
  }

  void visitRefinement(Refinement node) {
    // We found a pre-existing refinement node. These are generated by the
    // IR builder to hold information from --trust-type-annotations.
    // Update its input to use our own current refinement, then update the
    // environment to use this refinement.
    processReference(node.value);
    Primitive value = node.value.definition.effectiveDefinition;
    Primitive oldRefinement = refinementFor[value];
    refinementFor[value] = node;
    pushAction(() {
      refinementFor[value] = oldRefinement;
    });
  }

  bool isTrue(Primitive prim) {
    return prim is Constant && prim.value.isTrue;
  }

  void visitBranch(Branch node) {
    processReference(node.condition);
    Primitive condition = node.condition.definition;

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

    if (condition is InvokeMethod && condition.selector == Selectors.equals) {
      refineEquality(condition.dartReceiver,
                     condition.dartArgument(0),
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
      // Do not push the branch continuations here. visitBranch will do that.
      if (!(cont.hasExactlyOneUse && cont.firstRef.parent is Branch)) {
        push(cont);
      }
    }
    return node.body;
  }
}
