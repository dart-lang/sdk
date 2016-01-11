library dart2js.cps_ir.loop_invariant_branch;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';
import 'loop_hierarchy.dart';
import 'cps_fragment.dart';
import 'redundant_join.dart' show AlphaRenamer;

/// Hoists branches out of loops, where:
/// - the branch is at the entry point of a loop
/// - the branch condition is loop-invariant
/// - one arm of the branch is not effectively part of the loop
///
/// Schematically:
///
///     b = COND
///     while (true) {
///       if (b)
///         BRANCH (contains no continue to loop)
///       else
///         LOOP
///     }
///
///     ==>
///
///     b = COND
///     if (b)
///       BRANCH
///     else
///       while (true)
///         LOOP
///
/// As in [RedundantJoinEliminator], parameters are treated as names with
/// lexical scoping during this pass, and a given parameter "name" may be
/// declared by more than one continuation. The reference chains for parameters
/// are therefore meaningless during this pass, until repaired by [AlphaRenamer]
/// at the end.
class LoopInvariantBranchMotion extends BlockVisitor implements Pass {
  String get passName => 'Loop invariant branch motion';

  LoopHierarchy loopHierarchy;
  final Map<Primitive, Continuation> loopHeaderFor =
      <Primitive, Continuation>{};
  final Map<Continuation, Continuation> catchLoopFor =
      <Continuation, Continuation>{};
  Continuation currentLoopHeader;
  Continuation currentCatchLoop;
  List<Continuation> loops = <Continuation>[];
  bool wasHoisted = false;

  void rewrite(FunctionDefinition node) {
    loopHierarchy = new LoopHierarchy(node);
    BlockVisitor.traverseInPreOrder(node, this);
    // Process loops bottom-up so a branch can be hoisted multiple times.
    loops.reversed.forEach(hoistEntryCheck);
    if (wasHoisted) {
      new AlphaRenamer().visit(node);
    }
  }

  void visitLetHandler(LetHandler node) {
    currentCatchLoop = loopHierarchy.getLoopHeader(node.handler);
  }

  void visitContinuation(Continuation node) {
    currentLoopHeader = loopHierarchy.getLoopHeader(node);
    for (Parameter param in node.parameters) {
      loopHeaderFor[param] = currentLoopHeader;
    }
    catchLoopFor[node] = currentCatchLoop;
    if (node.isRecursive) {
      loops.add(node);
    }
  }

  void visitLetPrim(LetPrim node) {
    loopHeaderFor[node.primitive] = currentLoopHeader;
  }

  void hoistEntryCheck(Continuation loop) {
    // Keep hoisting branches out of the loop, there can be more than one.
    while (tryHoistEntryCheck(loop));
  }

  Expression getEffectiveBody(Expression exp) {
    // TODO(asgerf): We could also bypass constants here but constant pooling
    //               is likely to be a better solution for that.
    while (exp is LetCont) {
      exp = exp.next;
    }
    return exp;
  }

  /// Adds [parameters] to [cont] and updates every invocation to pass the
  /// corresponding parameter values as arguments. Thus, the parameters are
  /// passed in explicitly instead of being captured.
  ///
  /// This only works because [AlphaRenamer] cleans up at the end of this pass.
  ///
  /// Schematically:
  ///
  ///     let outer(x1, x2, x3) =
  ///       let inner(y) = BODY
  ///       [ .. inner(y') .. ]
  ///
  ///   ==> (append parameters)
  ///
  ///     let outer(x1, x2, x3) =
  ///       let inner(y, x1, x2, x3) = BODY
  ///       [ .. inner(y', x1, x2, x3) .. ]
  ///
  ///   ==> (hoist, not performed by this method)
  ///
  ///     let inner(y, x1, x2, x3) = BODY
  ///     let outer(x1, x2, x3) =
  ///       [ .. inner(y', x1, x2, x3) .. ]
  ///
  void appendParameters(Continuation cont, List<Parameter> parameters) {
    cont.parameters.addAll(parameters);
    for (Reference ref = cont.firstRef; ref != null; ref = ref.next) {
      Node use = ref.parent;
      if (use is InvokeContinuation) {
        for (Parameter loopParam in parameters) {
          use.arguments.add(new Reference<Primitive>(loopParam)..parent = use);
        }
      }
    }
  }

  bool tryHoistEntryCheck(Continuation loop) {
    // Check if this is a loop starting with a branch.
    Expression body = getEffectiveBody(loop.body);
    if (body is! Branch) return false;
    Branch branch = body;

    // Is the condition loop invariant?
    Primitive condition = branch.condition.definition;
    if (loopHeaderFor[condition] == loop) return false;

    Continuation trueCont = branch.trueContinuation.definition;
    Continuation falseCont = branch.falseContinuation.definition;
    Continuation hoistedCase; // The branch to hoist.
    Continuation loopCase; // The branch that is part of the loop.

    // Check that one branch is part of the loop, and the other is an exit.
    if (loopHierarchy.getLoopHeader(trueCont) != loop &&
        loopHierarchy.getLoopHeader(falseCont) == loop) {
      hoistedCase = trueCont;
      loopCase = falseCont;
    } else if (loopHierarchy.getLoopHeader(falseCont) != loop &&
               loopHierarchy.getLoopHeader(trueCont) == loop) {
      hoistedCase = falseCont;
      loopCase = trueCont;
    } else {
      return false;
    }

    // Hoist non-loop continuations out of the loop.
    // The hoisted branch can reference other continuations bound in the loop,
    // so to stay in scope, those need to be hoisted as well.
    //
    //     let b = COND
    //     let loop(x) =
    //       let join(y) = JOIN
    //       let hoistCase() = HOIST
    //       let loopCase() = LOOP
    //       branch b hoistCase loopCase
    //     in loop(i)
    //
    //    ==>
    //
    //     let b = COND
    //     let join(y,x) = JOIN
    //     let hoistCase(x) = HOIST
    //     let loop(x) =
    //       let loopCase() = LOOP
    //       branch b hoistCase loopCase
    //     in loop(i)
    //
    LetCont loopBinding = loop.parent;
    Expression it = loop.body;
    while (it is LetCont) {
      LetCont let = it;
      it = let.body;
      for (Continuation cont in let.continuations) {
        if (loopHierarchy.getEnclosingLoop(cont) != loop) {
          appendParameters(cont, loop.parameters);
          new LetCont(cont, null).insertAbove(loopBinding);
        }
      }
      let.continuations.removeWhere((cont) => cont.parent != let);
      if (let.continuations.isEmpty) {
        let.remove();
      }
    }

    // Create a new branch to call the hoisted continuation or the loop:
    //
    //     let loop(x) =
    //       let loopCase() = LOOP
    //       branch b hoistCase loopCase
    //     in loop(i)
    //
    //    ==>
    //
    //     let newTrue() = hoistCase(i)
    //     let newFalse() =
    //       let loop(x) =
    //         let loopCase() = LOOP
    //         branch b hoistCase loopCase
    //     branch b newTrue newFalse
    //
    InvokeContinuation loopEntry = loopBinding.body;
    List<Primitive> loopArgs =
        loopEntry.arguments.map((ref) => ref.definition).toList();
    CpsFragment cps = new CpsFragment();
    cps.branch(condition,
          strict: branch.isStrictCheck,
          negate: hoistedCase == falseCont)
       .invokeContinuation(hoistedCase, loopArgs);

    // The continuations created in the fragment need to have their loop header
    // set so the loop hierarchy remains intact
    loopHierarchy.update(cps,
        exitLoop: loopHierarchy.getEnclosingLoop(loop),
        catchLoop: catchLoopFor[loop]);

    // Insert above the loop. This will put the loop itself in a branch.
    cps.insertAbove(loopBinding);

    // Replace the old branch with the loopCase, still bound inside the loop:
    //
    //   let loop(x) =
    //     let loopCase() = LOOP
    //     branch b hoistCase loopCase
    //   in loop(i)
    //
    //  ==>
    //
    //   let loop(x) =
    //     let loopCase() = LOOP
    //     loopCase()
    //   in loop(i)
    //
    destroyAndReplace(branch, new InvokeContinuation(loopCase, []));

    // Record that at least one branch was hoisted to trigger alpha renaming.
    wasHoisted = true;

    return true;
  }
}
