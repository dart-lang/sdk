// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.let_sinking;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';

/// Sinks single-use primitives to the use when this is safe and profitable.
///
/// To avoid sinking non-constant primitives into loops, this pass performs a
/// control-flow analysis to determine the effective nesting of loops.
///
/// In the example below, the value 'p' can be sunk to its use site in the
/// 'else' branch because that branch is not effectively part of a loop,
/// despite being lexically nested in a recursive continuation.
///
///   let prim p = getInterceptor(<something>)
///   let rec kont x =
///     if (<loop condition>)
///       <loop body>
///       InvokeContinuation kont x'
///     else
///       <after loop>
///       return p.foo()
///
class LetSinker extends RecursiveVisitor implements Pass {
  String get passName => 'Let sinking';

  LoopHierarchy loopHierarchy;
  List<Continuation> stack = <Continuation>[];

  /// Maps a sinkable primitive to its loop header.
  Map<Primitive, Continuation> loopHeaderForPrimitive =
      <Primitive, Continuation>{};

  Continuation currentLoopHeader;

  void rewrite(FunctionDefinition node) {
    new ParentVisitor().visit(node);
    loopHierarchy = new LoopHierarchy(node);
    visit(node.body);
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    Primitive prim = node.primitive;
    if (prim.hasExactlyOneUse && prim.isSafeForReordering) {
      // This can potentially be sunk. Register the loop header, so when we
      // find the use site, we can check if they are in the same loop.
      loopHeaderForPrimitive[prim] = currentLoopHeader;
      pushAction(() {
        if (node.primitive != null) {
          // The primitive could not be sunk. Try to sink dependencies here.
          visit(node.primitive);
        } else {
          // The primitive was sunk. Destroy the old LetPrim.
          InteriorNode parent = node.parent;
          parent.body = node.body;
          node.body.parent = parent;
        }
      });
    } else {
      visit(node.primitive);
    }

    // Visit the body, wherein this primitive may be sunk to its use site.
    return node.body;
  }

  @override
  Expression traverseContinuation(Continuation cont) {
    Continuation oldLoopHeader = currentLoopHeader;
    pushAction(() {
      currentLoopHeader = oldLoopHeader;
    });
    currentLoopHeader = loopHierarchy.getLoopHeader(cont);
    return cont.body;
  }

  void processReference(Reference ref) {
    Definition definition = ref.definition;
    if (definition is Primitive && 
        definition is! Parameter &&
        definition.hasExactlyOneUse &&
        definition.isSafeForReordering) {
      // Check if use is in the same loop.
      Continuation bindingLoop = loopHeaderForPrimitive.remove(definition);
      if (bindingLoop == currentLoopHeader || definition is Constant) {
        // Sink the definition.

        Expression use = getEnclosingExpression(ref.parent);
        LetPrim binding = definition.parent;
        binding.primitive = null;  // Mark old binding for deletion.
        LetPrim newBinding = new LetPrim(definition);
        definition.parent = newBinding;
        InteriorNode useParent = use.parent;
        useParent.body = newBinding;
        newBinding.body = use;
        use.parent = newBinding;
        newBinding.parent = useParent;

        // Now that the final binding location has been found, sink the
        // dependencies of the definition down here as well.
        visit(definition); 
      }
    }
  }

  Expression getEnclosingExpression(Node node) {
    while (node is! Expression) {
      node = node.parent;
    }
    return node;
  }
}

/// Determines the effective nesting of loops.
/// 
/// The effective nesting of loops is different from the lexical nesting, since
/// recursive continuations can generally contain all the code following 
/// after the loop in addition to the looping code itself.
/// 
/// For example, the 'else' branch below is not effectively part of the loop:
/// 
///   let rec kont x = 
///     if (<loop condition>) 
///       <loop body>
///       InvokeContinuation kont x'
///     else 
///       <after loop>
///       return p.foo()
/// 
/// We use the term "loop" to mean recursive continuation.
/// The `null` value is used to represent a context not part of any loop.
class LoopHierarchy {
  /// Nesting depth of the given loop.
  Map<Continuation, int> loopDepth = <Continuation, int>{};

  /// The innermost loop (other than itself) that may be invoked recursively
  /// as a result of invoking the given continuation.
  Map<Continuation, Continuation> loopTarget = <Continuation, Continuation>{};

  /// Current nesting depth.
  int currentDepth = 0;

  /// Computes the loop hierarchy for the given function.
  /// 
  /// Parent pointers must be computed for [node].
  LoopHierarchy(FunctionDefinition node) {
    _processBlock(node.body, null);
  }

  /// Returns the innermost loop which [cont] is effectively part of.
  Continuation getLoopHeader(Continuation cont) {
    return cont.isRecursive ? cont : loopTarget[cont];
  }

  /// Marks the innermost loop as a subloop of the other loop.
  /// 
  /// Returns the innermost loop.
  /// 
  /// Both continuations, [c1] and [c2] may be null (i.e. no loop).
  /// 
  /// A loop is said to be a subloop of an enclosing loop if it can invoke
  /// that loop recursively. This information is stored in [loopTarget].
  /// 
  /// This method is only invoked with two distinct loops if there is a
  /// point that can reach a recursive invocation of both loops.
  /// This implies that one loop is nested in the other, because they must
  /// both be in scope at that point.
  Continuation _markInnerLoop(Continuation c1, Continuation c2) {
    assert(c1 == null || c1.isRecursive);
    assert(c2 == null || c2.isRecursive);
    if (c1 == null) return c2;
    if (c2 == null) return c1;
    if (c1 == c2) return c1;
    if (loopDepth[c1] > loopDepth[c2]) {
      loopTarget[c1] = _markInnerLoop(loopTarget[c1], c2);
      return c1;
    } else {
      loopTarget[c2] = _markInnerLoop(loopTarget[c2], c1);
      return c2;
    }
  }

  /// Analyzes the body of [cont] and returns the innermost loop
  /// that can be invoked recursively from [cont] (other than [cont] itself).
  /// 
  /// [catchLoop] is the innermost loop that can be invoked recursively
  /// from the current exception handler.
  Continuation _processContinuation(Continuation cont, Continuation catchLoop) {
    if (cont.isRecursive) {
      ++currentDepth;
      loopDepth[cont] = currentDepth;
      Continuation target = _processBlock(cont.body, catchLoop);
      _markInnerLoop(loopTarget[cont], target);
      --currentDepth;
    } else {
      loopTarget[cont] = _processBlock(cont.body, catchLoop);
    }
    return loopTarget[cont];
  }

  bool _isCallContinuation(Continuation cont) {
    return cont.hasExactlyOneUse && cont.firstRef.parent is CallExpression;
  }

  /// Analyzes a basic block and returns the innermost loop that
  /// can be invoked recursively from that block.
  Continuation _processBlock(Expression node, Continuation catchLoop) {
    List<Continuation> callContinuations = <Continuation>[];
    for (; node is! TailExpression; node = node.next) {
      if (node is LetCont) {
        for (Continuation cont in node.continuations) {
          if (!_isCallContinuation(cont)) {
            // Process non-call continuations at the binding site, so they
            // their loop target is known at all use sites.
            _processContinuation(cont, catchLoop);
          } else {
            // To avoid deep recursion, do not analyze call continuations
            // recursively. This basic block traversal steps into the
            // call contiunation after visiting its use site. We store the
            // continuations in a list so we can set the loop target once
            // it is known.
            callContinuations.add(cont);
          }
        }
      } else if (node is LetHandler) {
        catchLoop = _processContinuation(node.handler, catchLoop);
      }
    }
    Continuation target;
    if (node is InvokeContinuation) {
      if (node.isRecursive) {
        target = node.continuation.definition;
      } else {
        target = loopTarget[node.continuation.definition];
      }
    } else if (node is Branch) {
      target = _markInnerLoop(
          loopTarget[node.trueContinuation.definition],
          loopTarget[node.falseContinuation.definition]);
    } else {
      assert(node is Unreachable || node is Throw);
    }
    target = _markInnerLoop(target, catchLoop);
    for (Continuation cont in callContinuations) {
      // Store the loop target on each call continuation in the basic block.
      // Because we walk over call continuations as part of the basic block
      // traversal, these do not get their loop target set otherwise.
      loopTarget[cont] = target;
    }
    return target;
  }
}
