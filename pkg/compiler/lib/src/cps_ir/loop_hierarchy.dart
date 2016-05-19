// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.loop_hierarchy;

import 'cps_ir_nodes.dart';
import 'cps_fragment.dart';

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
  int _currentDepth = 0;

  /// The loop target to use for missing code.  Used by [update].
  Continuation _exitLoop;

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

  /// Returns the innermost loop which the given continuation is part of, other
  /// than itself.
  Continuation getEnclosingLoop(Continuation cont) {
    return loopTarget[cont];
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
      ++_currentDepth;
      loopDepth[cont] = _currentDepth;
      Continuation target = _processBlock(cont.body, catchLoop);
      _markInnerLoop(loopTarget[cont], target);
      --_currentDepth;
    } else {
      loopTarget[cont] = _processBlock(cont.body, catchLoop);
    }
    return loopTarget[cont];
  }

  /// Analyzes a basic block and returns the innermost loop that
  /// can be invoked recursively from that block.
  Continuation _processBlock(Expression node, Continuation catchLoop) {
    for (; node != null && node is! TailExpression; node = node.next) {
      if (node is LetCont) {
        for (Continuation cont in node.continuations) {
          _processContinuation(cont, catchLoop);
        }
      } else if (node is LetHandler) {
        catchLoop = _processContinuation(node.handler, catchLoop);
      }
    }
    Continuation target;
    if (node is InvokeContinuation) {
      if (node.isRecursive) {
        target = node.continuation;
      } else {
        target = loopTarget[node.continuation];
      }
    } else if (node is Branch) {
      target = _markInnerLoop(loopTarget[node.trueContinuation],
          loopTarget[node.falseContinuation]);
    } else if (node == null) {
      // If the code ends abruptly, use the exit loop provided in [update].
      target = _exitLoop;
    } else {
      assert(node is Unreachable || node is Throw || node == null);
    }
    return _markInnerLoop(target, catchLoop);
  }

  /// Returns the innermost loop that effectively encloses both
  /// c1 and c2 (or `null` if there is no such loop).
  Continuation lowestCommonAncestor(Continuation c1, Continuation c2) {
    int d1 = getDepth(c1), d2 = getDepth(c2);
    while (c1 != c2) {
      if (d1 <= d2) {
        c2 = getEnclosingLoop(c2);
        d2 = getDepth(c2);
      } else {
        c1 = getEnclosingLoop(c1);
        d1 = getDepth(c1);
      }
    }
    return c1;
  }

  /// Returns the lexical nesting depth of [loop].
  int getDepth(Continuation loop) {
    if (loop == null) return 0;
    return loopDepth[loop];
  }

  /// Sets the loop header for each continuation bound inside the given
  /// fragment.
  ///
  /// If the fragment is open, [exitLoop] denotes the loop header for
  /// the code that will occur after the fragment.
  ///
  /// [catchLoop] is the loop target for the catch clause of the try/catch
  /// surrounding the inserted fragment.
  void update(CpsFragment fragment,
      {Continuation exitLoop, Continuation catchLoop}) {
    if (fragment.isEmpty) return;
    _exitLoop = exitLoop;
    _currentDepth = getDepth(exitLoop);
    _processBlock(fragment.root, catchLoop);
    _exitLoop = null;
  }
}
