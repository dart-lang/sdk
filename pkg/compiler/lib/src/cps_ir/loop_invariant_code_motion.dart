// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.loop_invariant_code_motion;

import 'optimizers.dart';
import 'cps_ir_nodes.dart';
import 'loop_hierarchy.dart';

/// Lifts primitives out of loops when it is safe and profitable.
/// 
/// Currently we only do this for interceptors.
class LoopInvariantCodeMotion extends RecursiveVisitor implements Pass {
  String get passName => 'Loop-invariant code motion';

  final Map<Primitive, Continuation> primitiveLoop = 
      <Primitive, Continuation>{};

  LoopHierarchy loopHierarchy;
  Continuation currentLoopHeader;

  /// When processing the dependencies of a primitive, [referencedLoop]
  /// refers to the innermost loop that contains one of the dependencies
  /// seen so far (or `null` if none of the dependencies are bound in a loop).
  ///
  /// This is used to determine how far the primitive can be lifted without
  /// falling out of scope of its dependencies.
  Continuation referencedLoop;

  void rewrite(FunctionDefinition node) {
    loopHierarchy = new LoopHierarchy(node);
    visit(node.body);
  }

  @override
  Expression traverseContinuation(Continuation cont) {
    Continuation oldLoopHeader = currentLoopHeader;
    pushAction(() {
      currentLoopHeader = oldLoopHeader;
    });
    currentLoopHeader = loopHierarchy.getLoopHeader(cont);
    for (Parameter param in cont.parameters) {
      primitiveLoop[param] = currentLoopHeader;
    }
    return cont.body;
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    primitiveLoop[node.primitive] = currentLoopHeader;
    if (!shouldLift(node.primitive)) {
      return node.body;
    }
    referencedLoop = null;
    visit(node.primitive); // Sets referencedLoop.
    Expression next = node.body;
    if (referencedLoop != currentLoopHeader) {
      // Bind the primitive inside [referencedLoop] (possibly null),
      // immediately before the binding of the inner loop.

      // Find the inner loop.
      Continuation loop = currentLoopHeader;
      Continuation enclosing = loopHierarchy.getEnclosingLoop(loop);
      while (enclosing != referencedLoop) {
        assert(loop != null);
        loop = enclosing;
        enclosing = loopHierarchy.getEnclosingLoop(loop);
      }
      assert(loop != null);

      // Remove LetPrim from its current position.
      node.parent.body = node.body;
      node.body.parent = node.parent;

      // Insert the LetPrim immediately before the loop.
      LetCont loopBinding = loop.parent;
      InteriorNode newParent = loopBinding.parent;
      newParent.body = node;
      node.body = loopBinding;
      loopBinding.parent = node;
      node.parent = newParent;

      // A different loop now contains the primitive.
      primitiveLoop[node.primitive] = enclosing;
    }
    return next;
  }

  /// Returns the the innermost loop that effectively encloses both
  /// c1 and c2 (or `null` if there is no such loop).
  Continuation leastCommonAncestor(Continuation c1, Continuation c2) {
    int d1 = getDepth(c1), d2 = getDepth(c2);
    while (c1 != c2) {
      if (d1 <= d2) {
        c2 = loopHierarchy.getEnclosingLoop(c2);
        d2 = getDepth(c2);
      } else {
        c1 = loopHierarchy.getEnclosingLoop(c1);
        d1 = getDepth(c1);
      }
    }
    return c1;
  }

  @override
  void processReference(Reference ref) {
    Continuation loop = 
        leastCommonAncestor(currentLoopHeader, primitiveLoop[ref.definition]);
    referencedLoop = getInnerLoop(loop, referencedLoop);
  }

  int getDepth(Continuation loop) {
    if (loop == null) return -1;
    return loopHierarchy.loopDepth[loop];
  }

  Continuation getInnerLoop(Continuation loop1, Continuation loop2) {
    if (loop1 == null) return loop2;
    if (loop2 == null) return loop1;
    if (loopHierarchy.loopDepth[loop1] > loopHierarchy.loopDepth[loop2]) {
      return loop1;
    } else {
      return loop2;
    }
  }

  bool shouldLift(Primitive prim) {
    // Interceptors are safe and almost always profitable for lifting
    // out of loops. Several other primitive could be lifted too, but it's not
    // always profitable to do so.
    return prim is Interceptor;
  }
}
