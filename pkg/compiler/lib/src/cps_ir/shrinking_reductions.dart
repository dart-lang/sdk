// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.shrinking_reductions;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';

/**
 * [ShrinkingReducer] applies shrinking reductions to CPS terms as described
 * in 'Compiling with Continuations, Continued' by Andrew Kennedy.
 */
class ShrinkingReducer extends Pass {
  String get passName => 'Shrinking reductions';

  final List<_ReductionTask> _worklist = new List<_ReductionTask>();

  /// Applies shrinking reductions to root, mutating root in the process.
  @override
  void rewrite(FunctionDefinition root) {
    _RedexVisitor redexVisitor = new _RedexVisitor(_worklist);

    // Sweep over the term, collecting redexes into the worklist.
    redexVisitor.visit(root);

    _iterateWorklist();
  }

  void _iterateWorklist() {
    while (_worklist.isNotEmpty) {
      _ReductionTask task = _worklist.removeLast();
      _processTask(task);
    }
  }

  /// Call instead of [_iterateWorklist] to check at every step that no
  /// redex was missed.
  void _debugWorklist(FunctionDefinition root) {
    while (_worklist.isNotEmpty) {
      _ReductionTask task = _worklist.removeLast();
      String irBefore = root.debugString({
        task.node: '${task.kind} applied here'
      });
      _processTask(task);
      Set seenRedexes = _worklist.where(isValidTask).toSet();
      Set actualRedexes = (new _RedexVisitor([])..visit(root)).worklist.toSet();
      if (!seenRedexes.containsAll(actualRedexes)) {
        _ReductionTask missedTask =
            actualRedexes.firstWhere((x) => !seenRedexes.contains(x));
        print('\nBEFORE $task:\n');
        print(irBefore);
        print('\nAFTER $task:\n');
        root.debugPrint({
          missedTask.node: 'MISSED ${missedTask.kind}'
        });
        throw 'Missed $missedTask after processing $task';
      }
    }
  }

  bool isValidTask(_ReductionTask task) {
    switch (task.kind) {
      case _ReductionKind.DEAD_VAL:
        return _isDeadVal(task.node);
      case _ReductionKind.DEAD_CONT:
        return _isDeadCont(task.node);
      case _ReductionKind.BETA_CONT_LIN:
        return _isBetaContLin(task.node);
      case _ReductionKind.ETA_CONT:
        return _isEtaCont(task.node);
      case _ReductionKind.DEAD_PARAMETER:
        return _isDeadParameter(task.node);
      case _ReductionKind.BRANCH:
        return _isBranchRedex(task.node);
    }
  }

  /// Removes the given node from the CPS graph, replacing it with its body
  /// and marking it as deleted. The node's parent must be a [[InteriorNode]].
  void _removeNode(InteriorNode node) {
    Node body           = node.body;
    InteriorNode parent = node.parent;
    assert(parent.body == node);

    body.parent = parent;
    parent.body = body;
    node.parent = null;

    // The removed node could be the last node between a continuation and
    // an InvokeContinuation in the body.
    if (parent is Continuation) {
      _checkEtaCont(parent);
      _checkUselessBranchTarget(parent);
    }
  }

  /// Remove a given continuation from the CPS graph.  The LetCont itself is
  /// removed if the given continuation is the only binding.
  void _removeContinuation(Continuation cont) {
    LetCont parent = cont.parent;
    if (parent.continuations.length == 1) {
      _removeNode(parent);
    } else {
      parent.continuations.remove(cont);
    }
    cont.parent = null;
  }

  void _processTask(_ReductionTask task) {
    // Skip tasks for deleted nodes.
    if (task.node.parent == null) {
      return;
    }

    switch (task.kind) {
      case _ReductionKind.DEAD_VAL:
        _reduceDeadVal(task);
        break;
      case _ReductionKind.DEAD_CONT:
        _reduceDeadCont(task);
        break;
      case _ReductionKind.BETA_CONT_LIN:
        _reduceBetaContLin(task);
        break;
      case _ReductionKind.ETA_CONT:
        _reduceEtaCont(task);
        break;
      case _ReductionKind.DEAD_PARAMETER:
        _reduceDeadParameter(task);
        break;
      case _ReductionKind.BRANCH:
        _reduceBranch(task);
        break;
    }
  }

  /// Applies the dead-val reduction:
  ///   letprim x = V in E -> E (x not free in E).
  void _reduceDeadVal(_ReductionTask task) {
    if (_isRemoved(task.node)) return;
    assert(_isDeadVal(task.node));

    LetPrim deadLet = task.node;
    Primitive deadPrim = deadLet.primitive;
    assert(deadPrim.hasNoRefinedUses);
    // The node has no effective uses but can have refinement uses, which
    // themselves can have more refinements uses (but only refinement uses).
    // We must remove the entire refinement tree while looking for redexes
    // whenever we remove one.
    List<Primitive> deadlist = <Primitive>[deadPrim];
    while (deadlist.isNotEmpty) {
      Primitive node = deadlist.removeLast();
      while (node.firstRef != null) {
        Reference ref = node.firstRef;
        Refinement use = ref.parent;
        deadlist.add(use);
        ref.unlink();
      }
      LetPrim binding = node.parent;
      _removeNode(binding); // Remove the binding and check for eta redexes.
    }

    // Perform bookkeeping on removed body and scan for new redexes.
    new _RemovalVisitor(_worklist).visit(deadPrim);
  }

  /// Applies the dead-cont reduction:
  ///   letcont k x = E0 in E1 -> E1 (k not free in E1).
  void _reduceDeadCont(_ReductionTask task) {
    assert(_isDeadCont(task.node));

    // Remove dead continuation.
    Continuation cont = task.node;
    _removeContinuation(cont);

    // Perform bookkeeping on removed body and scan for new redexes.
    new _RemovalVisitor(_worklist).visit(cont);
  }

  /// Applies the beta-cont-lin reduction:
  ///   letcont k x = E0 in E1[k y] -> E1[E0[y/x]] (k not free in E1).
  void _reduceBetaContLin(_ReductionTask task) {
    // Might have been mutated, recheck if reduction is still valid.
    // In the following example, the beta-cont-lin reduction of k0 could have
    // been invalidated by removal of the dead continuation k1:
    //
    //  letcont k0 x0 = E0 in
    //    letcont k1 x1 = k0 x1 in
    //      return x2
    if (!_isBetaContLin(task.node)) {
      return;
    }

    Continuation cont = task.node;
    InvokeContinuation invoke = cont.firstRef.parent;
    InteriorNode invokeParent = invoke.parent;
    Expression body = cont.body;

    // Replace the invocation with the continuation body.
    invokeParent.body = body;
    body.parent = invokeParent;
    cont.body = null;

    // Substitute the invocation argument for the continuation parameter.
    for (int i = 0; i < invoke.argumentRefs.length; i++) {
      Parameter param = cont.parameters[i];
      Primitive argument = invoke.argument(i);
      param.replaceUsesWith(argument);
      argument.useElementAsHint(param.hint);
      _checkConstantBranchCondition(argument);
    }

    // Remove the continuation after inlining it so we can check for eta redexes
    // which may arise after removing the LetCont.
    _removeContinuation(cont);

    // Perform bookkeeping on substituted body and scan for new redexes.
    new _RemovalVisitor(_worklist).visit(invoke);

    if (invokeParent is Continuation) {
      _checkEtaCont(invokeParent);
      _checkUselessBranchTarget(invokeParent);
    }
  }

  /// Applies the eta-cont reduction:
  ///   letcont k x = j x in E -> E[j/k].
  /// If k is unused, degenerates to dead-cont.
  void _reduceEtaCont(_ReductionTask task) {
    // Might have been mutated, recheck if reduction is still valid.
    // In the following example, the eta-cont reduction of k1 could have been
    // invalidated by an earlier beta-cont-lin reduction of k0.
    //
    //  letcont k0 x0 = E0 in
    //    letcont k1 x1 = k0 x1 in E1
    if (!_isEtaCont(task.node)) {
      return;
    }

    // Remove the continuation.
    Continuation cont = task.node;
    _removeContinuation(cont);

    InvokeContinuation invoke = cont.body;
    Continuation wrappedCont = invoke.continuation;

    for (int i = 0; i < cont.parameters.length; ++i) {
      wrappedCont.parameters[i].useElementAsHint(cont.parameters[i].hint);
    }

    // If the invocation of wrappedCont is escaping, then all invocations of
    // cont will be as well, after the reduction.
    if (invoke.isEscapingTry) {
      Reference current = cont.firstRef;
      while (current != null) {
        InvokeContinuation owner = current.parent;
        owner.isEscapingTry = true;
        current = current.next;
      }
    }

    // Replace all occurrences with the wrapped continuation and find redexes.
    while (cont.firstRef != null) {
      Reference ref = cont.firstRef;
      ref.changeTo(wrappedCont);
      Node use = ref.parent;
      if (use is InvokeContinuation && use.parent is Continuation) {
        _checkUselessBranchTarget(use.parent);
      }
    }

    // Perform bookkeeping on removed body and scan for new redexes.
    new _RemovalVisitor(_worklist).visit(cont);
  }

  void _reduceBranch(_ReductionTask task) {
    Branch branch = task.node;
    // Replace Branch with InvokeContinuation of one of the targets. When the
    // branch is deleted the other target becomes unreferenced and the chosen
    // target becomes available for eta-cont and further reductions.
    Continuation target;
    Primitive condition = branch.condition;
    if (condition is Constant) {
      target = isTruthyConstant(condition.value, strict: branch.isStrictCheck)
          ? branch.trueContinuation
          : branch.falseContinuation;
    } else if (_isBranchTargetOfUselessIf(branch.trueContinuation)) {
      target = branch.trueContinuation;
    } else {
      return;
    }

    InvokeContinuation invoke = new InvokeContinuation(
        target, <Primitive>[]
        // TODO(sra): Add sourceInformation.
        /*, sourceInformation: branch.sourceInformation*/);
    branch.parent.body = invoke;
    invoke.parent = branch.parent;
    branch.parent = null;

    new _RemovalVisitor(_worklist).visit(branch);
  }

  void _reduceDeadParameter(_ReductionTask task) {
    // Continuation eta-reduction can destroy a dead parameter redex.  For
    // example, in the term:
    //
    // let cont k0(v0) = /* v0 is not used */ in
    //   let cont k1(v1) = k0(v1) in
    //     call foo () k1
    //
    // Continuation eta-reduction of k1 gives:
    //
    // let cont k0(v0) = /* v0 is not used */ in
    //   call foo () k0
    //
    // Where the dead parameter reduction is no longer valid because we do not
    // allow removing the paramter of call continuations.  We disallow such eta
    // reductions in [_isEtaCont].
    Parameter parameter = task.node;
    if (_isParameterRemoved(parameter)) return;
    assert(_isDeadParameter(parameter));

    Continuation continuation = parameter.parent;
    int index = continuation.parameters.indexOf(parameter);
    assert(index != -1);
    continuation.parameters.removeAt(index);
    parameter.parent = null; // Mark as removed.

    // Remove the index'th argument from each invocation.
    for (Reference ref = continuation.firstRef; ref != null; ref = ref.next) {
      InvokeContinuation invoke = ref.parent;
      Reference<Primitive> argument = invoke.argumentRefs[index];
      argument.unlink();
      invoke.argumentRefs.removeAt(index);
      // Removing an argument can create a dead primitive or an eta-redex
      // in case the parent is a continuation that now has matching parameters.
      _checkDeadPrimitive(argument.definition);
      if (invoke.parent is Continuation) {
        _checkEtaCont(invoke.parent);
        _checkUselessBranchTarget(invoke.parent);
      }
    }

    // Removing an unused parameter can create an eta-redex, in case the
    // body is an InvokeContinuation that now has matching arguments.
    _checkEtaCont(continuation);
  }

  void _checkEtaCont(Continuation continuation) {
    if (_isEtaCont(continuation)) {
      _worklist.add(new _ReductionTask(_ReductionKind.ETA_CONT, continuation));
    }
  }

  void _checkUselessBranchTarget(Continuation continuation) {
    if (_isBranchTargetOfUselessIf(continuation)) {
      _worklist.add(new _ReductionTask(_ReductionKind.BRANCH,
          continuation.firstRef.parent));
    }
  }

  void _checkConstantBranchCondition(Primitive primitive) {
    if (primitive is! Constant) return;
    for (Reference ref = primitive.firstRef; ref != null; ref = ref.next) {
      Node use = ref.parent;
      if (use is Branch) {
        _worklist.add(new _ReductionTask(_ReductionKind.BRANCH, use));
      }
    }
  }

  void _checkDeadPrimitive(Primitive primitive) {
    primitive = primitive.unrefined;
    if (primitive is Parameter) {
      if (_isDeadParameter(primitive)) {
        _worklist.add(new _ReductionTask(_ReductionKind.DEAD_PARAMETER,
                                         primitive));
      }
    } else if (primitive.parent is LetPrim) {
      LetPrim letPrim = primitive.parent;
      if (_isDeadVal(letPrim)) {
        _worklist.add(new _ReductionTask(_ReductionKind.DEAD_VAL, letPrim));
      }
    }
  }
}

bool _isRemoved(InteriorNode node) {
  return node.parent == null;
}

bool _isParameterRemoved(Parameter parameter) {
  // A parameter can be removed directly or because its continuation is removed.
  return parameter.parent == null || _isRemoved(parameter.parent);
}

/// Returns true iff the bound primitive is unused, and has no effects
/// preventing it from being eliminated.
bool _isDeadVal(LetPrim node) {
  return !_isRemoved(node) &&
         node.primitive.hasNoRefinedUses &&
         node.primitive.isSafeForElimination;
}

/// Returns true iff the continuation is unused.
bool _isDeadCont(Continuation cont) {
  return !_isRemoved(cont) &&
         !cont.isReturnContinuation &&
         !cont.hasAtLeastOneUse;
}

/// Returns true iff the continuation has a body (i.e., it is not the return
/// continuation), it is used exactly once, and that use is as the continuation
/// of a continuation invocation.
bool _isBetaContLin(Continuation cont) {
  if (_isRemoved(cont)) return false;

  // There is a restriction on continuation eta-redexes that the body is not an
  // invocation of the return continuation, because that leads to worse code
  // when translating back to direct style (it duplicates returns).  There is no
  // such restriction here because continuation beta-reduction is only performed
  // for singly referenced continuations. Thus, there is no possibility of code
  // duplication.
  if (cont.isReturnContinuation || !cont.hasExactlyOneUse) {
    return false;
  }

  if (cont.firstRef.parent is! InvokeContinuation) return false;

  InvokeContinuation invoke = cont.firstRef.parent;

  // Beta-reduction will move the continuation's body to its unique invocation
  // site.  This is not safe if the body is moved into an exception handler
  // binding.
  if (invoke.isEscapingTry) return false;

  return true;
}

/// Returns true iff the continuation consists of a continuation
/// invocation, passing on all parameters. Special cases exist (see below).
bool _isEtaCont(Continuation cont) {
  if (_isRemoved(cont)) return false;

  if (!cont.isJoinContinuation || cont.body is! InvokeContinuation) {
    return false;
  }

  InvokeContinuation invoke = cont.body;
  Continuation invokedCont = invoke.continuation;

  // Do not eta-reduce return join-points since the direct-style code is worse
  // in the common case (i.e. returns are moved inside `if` branches).
  if (invokedCont.isReturnContinuation) {
    return false;
  }

  // Translation to direct style generates different statements for recursive
  // and non-recursive invokes. It should still be possible to apply eta-cont if
  // this is not a self-invocation.
  //
  // TODO(kmillikin): Remove this restriction if it makes sense to do so.
  if (invoke.isRecursive) {
    return false;
  }

  // If cont has more parameters than the invocation has arguments, the extra
  // parameters will be dead and dead-parameter will eventually create the
  // eta-redex if possible.
  //
  // If the invocation's arguments are simply a permutation of cont's
  // parameters, then there is likewise a possible reduction that involves
  // rewriting the invocations of cont.  We are missing that reduction here.
  //
  // If cont has fewer parameters than the invocation has arguments then a
  // reduction would still possible, since the extra invocation arguments must
  // be in scope at all the invocations of cont.  For example:
  //
  // let cont k1(x1) = k0(x0, x1) in E -eta-> E'
  // where E' has k0(x0, v) substituted for each k1(v).
  //
  // HOWEVER, adding continuation parameters is unlikely to be an optimization
  // since it duplicates assignments used in direct-style to implement parameter
  // passing.
  //
  // TODO(kmillikin): find real occurrences of these patterns, and see if they
  // can be optimized.
  if (cont.parameters.length != invoke.argumentRefs.length) {
    return false;
  }

  // TODO(jgruber): Linear in the parameter count. Can be improved to near
  // constant time by using union-find data structure.
  for (int i = 0; i < cont.parameters.length; i++) {
    if (invoke.argument(i) != cont.parameters[i]) {
      return false;
    }
  }

  return true;
}

Expression _unfoldDeadRefinements(Expression node) {
  while (node is LetPrim) {
    LetPrim let = node;
    Primitive prim = let.primitive;
    if (prim.hasAtLeastOneUse || prim is! Refinement) return node;
    node = node.next;
  }
  return node;
}

bool _isBranchRedex(Branch branch) {
  return _isUselessIf(branch) || branch.condition is Constant;
}

bool _isBranchTargetOfUselessIf(Continuation cont) {
  // A useless-if has an empty then and else branch, e.g. `if (cond);`.
  //
  // Detect T or F in
  //
  //     let cont Join() = ...
  //       in let cont T() = Join()
  //                   F() = Join()
  //         in branch condition T F
  //
  if (!cont.hasExactlyOneUse) return false;
  Node use = cont.firstRef.parent;
  if (use is! Branch) return false;
  return _isUselessIf(use);
}

bool _isUselessIf(Branch branch) {
  Continuation trueCont = branch.trueContinuation;
  Expression trueBody = _unfoldDeadRefinements(trueCont.body);
  if (trueBody is! InvokeContinuation) return false;
  Continuation falseCont = branch.falseContinuation;
  Expression falseBody = _unfoldDeadRefinements(falseCont.body);
  if (falseBody is! InvokeContinuation) return false;
  InvokeContinuation trueInvoke = trueBody;
  InvokeContinuation falseInvoke = falseBody;
  if (trueInvoke.continuation !=
      falseInvoke.continuation) {
    return false;
  }
  // Matching zero arguments should be adequate, since isomorphic true and false
  // invocations should result in redundant phis which are removed elsewhere.
  //
  // Note that the argument lists are not necessarily the same length here,
  // because we could be looking for new redexes in the middle of performing a
  // dead parameter reduction, where some but not all of the invocations have
  // been rewritten.  In that case, we will find the redex (once) after both
  // of these invocations have been rewritten.
  return trueInvoke.argumentRefs.isEmpty && falseInvoke.argumentRefs.isEmpty;
}

bool _isDeadParameter(Parameter parameter) {
  if (_isParameterRemoved(parameter)) return false;

  // We cannot remove function parameters as an intraprocedural optimization.
  if (parameter.parent is! Continuation || parameter.hasAtLeastOneUse) {
    return false;
  }

  // We cannot remove the parameter to a call continuation, because the
  // resulting expression will not be well-formed (call continuations have
  // exactly one argument).  The return continuation is a call continuation, so
  // we cannot remove its dummy parameter.
  Continuation continuation = parameter.parent;
  if (!continuation.isJoinContinuation) return false;

  return true;
}

/// Traverses a term and adds any found redexes to the worklist.
class _RedexVisitor extends TrampolineRecursiveVisitor {
  final List<_ReductionTask> worklist;

  _RedexVisitor(this.worklist);

  void processLetPrim(LetPrim node) {
    if (_isDeadVal(node)) {
      worklist.add(new _ReductionTask(_ReductionKind.DEAD_VAL, node));
    }
  }

  void processBranch(Branch node) {
    if (_isBranchRedex(node)) {
      worklist.add(new _ReductionTask(_ReductionKind.BRANCH, node));
    }
  }

  void processContinuation(Continuation node) {
    // While it would be nice to remove exception handlers that are provably
    // unnecessary (e.g., the body cannot throw), that takes more sophisticated
    // analysis than we do in this pass.
    if (node.parent is LetHandler) return;

    // Continuation beta- and eta-redexes can overlap, namely when an eta-redex
    // is invoked exactly once.  We prioritize continuation beta-redexes over
    // eta-redexes because some reductions (e.g., dead parameter elimination)
    // can destroy a continuation eta-redex.  If we prioritized eta- over
    // beta-redexes, this would implicitly "create" the corresponding beta-redex
    // (in the sense that it would still apply) and the algorithm would not
    // detect it.
    if (_isDeadCont(node)) {
      worklist.add(new _ReductionTask(_ReductionKind.DEAD_CONT, node));
    } else if (_isBetaContLin(node)){
      worklist.add(new _ReductionTask(_ReductionKind.BETA_CONT_LIN, node));
    } else if (_isEtaCont(node)) {
      worklist.add(new _ReductionTask(_ReductionKind.ETA_CONT, node));
    }
  }

  void processParameter(Parameter node) {
    if (_isDeadParameter(node)) {
      worklist.add(new _ReductionTask(_ReductionKind.DEAD_PARAMETER, node));
    }
  }
}

/// Traverses a deleted CPS term, marking nodes that might participate in a
/// redex as deleted and adding newly created redexes to the worklist.
///
/// Deleted nodes that might participate in a reduction task are marked so that
/// any corresponding tasks can be skipped.  Nodes are marked so by setting
/// their parent to the deleted sentinel.
class _RemovalVisitor extends TrampolineRecursiveVisitor {
  final List<_ReductionTask> worklist;

  _RemovalVisitor(this.worklist);

  void processLetPrim(LetPrim node) {
    node.parent = null;
  }

  void processContinuation(Continuation node) {
    node.parent = null;
  }

  void processBranch(Branch node) {
    node.parent = null;
  }

  void processReference(Reference reference) {
    reference.unlink();

    if (reference.definition is Primitive) {
      Primitive primitive = reference.definition.unrefined;
      Node parent = primitive.parent;
      // The parent might be the deleted sentinel, or it might be a
      // Continuation or FunctionDefinition if the primitive is an argument.
      if (parent is LetPrim && _isDeadVal(parent)) {
        worklist.add(new _ReductionTask(_ReductionKind.DEAD_VAL, parent));
      } else if (primitive is Parameter && _isDeadParameter(primitive)) {
        worklist.add(new _ReductionTask(_ReductionKind.DEAD_PARAMETER,
            primitive));
      }
    } else if (reference.definition is Continuation) {
      Continuation cont = reference.definition;
      Node parent = cont.parent;
      // The parent might be the deleted sentinel, or it might be a
      // Body if the continuation is the return continuation.
      if (parent is LetCont) {
        if (cont.isRecursive && cont.hasAtMostOneUse) {
          // Convert recursive to nonrecursive continuations.  If the
          // continuation is still in use, it is either dead and will be
          // removed, or it is called nonrecursively outside its body.
          cont.isRecursive = false;
        }
        if (_isDeadCont(cont)) {
          worklist.add(new _ReductionTask(_ReductionKind.DEAD_CONT, cont));
        } else if (_isBetaContLin(cont)) {
          worklist.add(new _ReductionTask(_ReductionKind.BETA_CONT_LIN, cont));
        } else if (_isBranchTargetOfUselessIf(cont)) {
          worklist.add(
              new _ReductionTask(_ReductionKind.BRANCH, cont.firstRef.parent));
        }
      }
    }
  }
}

enum _ReductionKind {
  DEAD_VAL,
  DEAD_CONT,
  BETA_CONT_LIN,
  ETA_CONT,
  DEAD_PARAMETER,
  BRANCH
}

/// Represents a reduction task on the worklist. Implements both hashCode and
/// operator== since instantiations are used as Set elements.
class _ReductionTask {
  final _ReductionKind kind;
  final Node node;

  int get hashCode {
    return (node.hashCode << 3) | kind.index;
  }

  _ReductionTask(this.kind, this.node) {
    assert(node is Continuation || node is LetPrim || node is Parameter ||
           node is Branch);
  }

  bool operator==(_ReductionTask that) {
    return (that.kind == this.kind && that.node == this.node);
  }

  String toString() => "$kind: $node";
}
