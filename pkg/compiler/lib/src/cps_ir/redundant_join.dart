// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.redundant_join_elimination;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';

/// Eliminates redundant join points.
/// 
/// A redundant join point is a continuation that immediately branches
/// based on one of its parameters, and that parameter is a constant value
/// at every invocation. Each invocation is redirected to jump directly
/// to the branch target.
/// 
/// Internally in this pass, parameters are treated as names with lexical
/// scoping, and a given parameter "name" may be declared by more than
/// one continuation. The reference chains for parameters are therefore 
/// meaningless during this pass, until repaired by [AlphaRenamer] at
/// the end.
class RedundantJoinEliminator extends RecursiveVisitor implements Pass {
  String get passName => 'Redundant join elimination';

  final Set<Branch> workSet = new Set<Branch>();

  void rewrite(FunctionDefinition node) {
    visit(node);

    while (workSet.isNotEmpty) {
      Branch branch = workSet.first;
      workSet.remove(branch);
      rewriteBranch(branch);
    }

    new AlphaRenamer().visit(node);
  }

  void processBranch(Branch node) {
    workSet.add(node);
  }

  /// Returns the body of [node], ignoring all LetCont nodes.
  Expression getEffectiveBody(InteriorNode node) {
    while (true) {
      Expression body = node.body;
      if (body is LetCont) {
        node = body;
      } else {
        return body;
      }
    }
  }

  /// Returns the parent of [node], ignoring all LetCont nodes.
  InteriorNode getEffectiveParent(Expression node) {
    while (true) {
      Node parent = node.parent;
      if (parent is LetCont) {
        node = parent;
      } else {
        return parent;
      }
    }
  }

  void rewriteBranch(Branch branch) {
    InteriorNode parent = getEffectiveParent(branch);
    if (parent is! Continuation) return;
    Continuation branchCont = parent;

    // Other optimizations take care of single-use continuations.
    if (!branchCont.hasMultipleUses) return;

    // It might be beneficial to rewrite calls to recursive continuations,
    // but we currently do not support this.
    if (branchCont.isRecursive) return;

    // Check that the branching condition is a parameter on the
    // enclosing continuation.
    // Note: Do not use the parent pointer for this check, because parameters
    // are temporarily shared between different continuations during this pass.
    Primitive condition = branch.condition.definition;
    int parameterIndex = branchCont.parameters.indexOf(condition);
    if (parameterIndex == -1) return;

    // Check that all callers hit a fixed branch, and count the number
    // of times each branch is hit.
    // We know all callers are InvokeContinuations because they are the only
    // valid uses of a multi-use continuation.
    int trueHits = 0, falseHits = 0;
    InvokeContinuation trueCall, falseCall;
    for (Reference ref = branchCont.firstRef; ref != null; ref = ref.next) {
      InvokeContinuation invoke = ref.parent;
      Primitive argument = invoke.arguments[parameterIndex].definition;
      if (argument is! Constant) return; // Branching condition is unknown.
      Constant constant = argument;
      if (isTruthyConstant(constant.value, strict: branch.isStrictCheck)) {
        ++trueHits;
        trueCall = invoke;
      } else {
        ++falseHits;
        falseCall = invoke;
      }
    }

    // The optimization is now known to be safe, but it only pays off if
    // one of the callers can inline its target, since otherwise we end up
    // replacing a boolean variable with a labeled break.
    // TODO(asgerf): The labeled break might be better? Evaluate.
    if (!(trueHits == 1 && !trueCall.isEscapingTry ||
          falseHits == 1 && !falseCall.isEscapingTry)) {
      return;
    }

    // Lift any continuations bound inside branchCont so they are in scope at 
    // the call sites. When lifting, the parameters of branchCont fall out of
    // scope, so they are added as parameters on each lifted continuation.
    // Schematically:
    // 
    //   (LetCont (branchCont (x1, x2, x3) =
    //        (LetCont (innerCont (y) = ...) in
    //        [... innerCont(y') ...]))
    //
    //     =>
    //
    //   (LetCont (innerCont (y, x1, x2, x3) = ...) in
    //   (LetCont (branchCont (x1, x2, x3) =
    //        [... innerCont(y', x1, x2, x3) ...])
    // 
    // Parameter objects become shared between branchCont and the lifted 
    // continuations. [AlphaRenamer] will clean up at the end of this pass.
    LetCont outerLetCont = branchCont.parent;
    while (branchCont.body is LetCont) {
      LetCont innerLetCont = branchCont.body;
      for (Continuation innerCont in innerLetCont.continuations) {
        innerCont.parameters.addAll(branchCont.parameters);
        for (Reference ref = innerCont.firstRef; ref != null; ref = ref.next) {
          Expression use = ref.parent;
          if (use is InvokeContinuation) {
            for (Parameter param in branchCont.parameters) {
              use.arguments.add(new Reference<Primitive>(param));
            }
          } else {
            // The branch will be eliminated, so don't worry about updating it.
            assert(use == branch);
          }
        }
      }
      innerLetCont.remove();
      innerLetCont.insertAbove(outerLetCont);
    }

    assert(branchCont.body == branch);

    Continuation trueCont = branch.trueContinuation.definition;
    Continuation falseCont = branch.falseContinuation.definition;

    assert(branchCont != trueCont);
    assert(branchCont != falseCont);

    // Rewrite every invocation of branchCont to call either the true or false
    // branch directly. Since these were lifted out above branchCont, they are
    // now in scope.
    // Since trueCont and falseCont were branch targets, they originally
    // had no parameters, and so after the lifting, their parameters are
    // exactly the same as those accepted by branchCont.
    while (branchCont.firstRef != null) {
      Reference reference = branchCont.firstRef;
      InvokeContinuation invoke = branchCont.firstRef.parent;
      Constant condition = invoke.arguments[parameterIndex].definition;
      if (isTruthyConstant(condition.value, strict: branch.isStrictCheck)) {
        invoke.continuation.changeTo(trueCont);
      } else {
        invoke.continuation.changeTo(falseCont);
      }
      assert(branchCont.firstRef != reference);
    }

    // Remove the now-unused branchCont continuation.
    assert(branchCont.hasNoUses);
    branch.trueContinuation.unlink();
    branch.falseContinuation.unlink();
    outerLetCont.continuations.remove(branchCont);
    if (outerLetCont.continuations.isEmpty) {
      outerLetCont.remove();
    }

    // We may have created new redundant join points in the two branches.
    enqueueContinuation(trueCont);
    enqueueContinuation(falseCont);
  }

  void enqueueContinuation(Continuation cont) {
    Expression body = getEffectiveBody(cont);
    if (body is Branch) {
      workSet.add(body);
    }
  }
}

/// Ensures parameter objects are not shared between different continuations,
/// akin to alpha-renaming variables so every variable is named uniquely.
/// For example:
/// 
///   LetCont (k1 x = (return x)) in
///   LetCont (k2 x = (InvokeContinuation k3 x)) in ...
///     => 
///   LetCont (k1 x = (return x)) in
///   LetCont (k2 x' = (InvokeContinuation k3 x')) in ...
/// 
/// After lifting LetConts in the main pass above, parameter objects can have
/// multiple bindings. Each reference implicitly refers to the binding that
/// is currently in scope.
/// 
/// This returns the IR to its normal form after redundant joins have been
/// eliminated.
class AlphaRenamer extends RecursiveVisitor {
  Map<Parameter, Parameter> renaming = <Parameter, Parameter>{};

  processContinuation(Continuation cont) {
    if (cont.isReturnContinuation) return;

    List<Parameter> shadowedKeys = <Parameter>[];
    List<Parameter> shadowedValues = <Parameter>[];

    // Create new parameters and update the environment.
    for (int i = 0; i < cont.parameters.length; ++i) {
      Parameter param = cont.parameters[i];
      shadowedKeys.add(param);
      shadowedValues.add(renaming.remove(param));
      // If the parameter appears to belong to another continuation,
      // create a new parameter object for this continuation.
      if (param.parent != cont) {
        Parameter newParam = new Parameter(param.hint);
        newParam.type = param.type;
        renaming[param] = newParam;
        cont.parameters[i] = newParam;
        newParam.parent = cont;
      }
    }

    pushAction(() {
      // Restore the original environment.
      for (int i = 0; i < cont.parameters.length; ++i) {
        renaming.remove(cont.parameters[i]);
        if (shadowedValues[i] != null) {
          renaming[shadowedKeys[i]] = shadowedValues[i];
        }
      }
    });
  }

  processReference(Reference ref) {
    Parameter target = renaming[ref.definition];
    if (target != null) {
      ref.changeTo(target);
    }
  }
}
