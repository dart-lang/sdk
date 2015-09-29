// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.share_interceptors;

import 'optimizers.dart';
import 'cps_ir_nodes.dart';
import 'loop_hierarchy.dart';
import '../constants/values.dart';

/// Removes redundant `getInterceptor` calls.
/// 
/// The pass performs three optimizations for interceptors:
///- pull interceptors out of loops
///- replace interceptors with constants
///- share interceptors when one is in scope of the other
class ShareInterceptors extends RecursiveVisitor implements Pass {
  String get passName => 'Share interceptors';

  /// The innermost loop containing a given primitive.
  final Map<Primitive, Continuation> loopHeaderFor =
      <Primitive, Continuation>{};

  /// An interceptor currently in scope for a given primitive.
  final Map<Primitive, Primitive> interceptorFor =
      <Primitive, Primitive>{};

  /// A primitive currently in scope holding a given interceptor constant.
  final Map<ConstantValue, Primitive> sharedConstantFor =
      <ConstantValue, Primitive>{};

  /// Interceptors to be hoisted out of the given loop.
  final Map<Continuation, List<Primitive>> loopHoistedInterceptors =
      <Continuation, List<Primitive>>{};

  LoopHierarchy loopHierarchy;
  Continuation currentLoopHeader;

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
      loopHeaderFor[param] = currentLoopHeader;
    }
    if (cont.isRecursive) {
      pushAction(() {
        // After the loop body has been processed, all interceptors hoisted
        // to this loop fall out of scope and should be removed from the
        // environment.
        List<Primitive> hoisted = loopHoistedInterceptors[cont];
        if (hoisted != null) {
          for (Primitive interceptor in hoisted) {
            if (interceptor is Interceptor) {
              Primitive input = interceptor.input.definition;
              assert(interceptorFor[input] == interceptor);
              interceptorFor.remove(input);
            } else if (interceptor is Constant) {
              assert(sharedConstantFor[interceptor.value] == interceptor);
              sharedConstantFor.remove(interceptor.value);
            } else {
              throw "Unexpected interceptor: $interceptor";
            }
          }
        }
      });
    }
    return cont.body;
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    loopHeaderFor[node.primitive] = currentLoopHeader;
    Expression next = node.body;
    if (node.primitive is! Interceptor) {
      return next;
    }
    Interceptor interceptor = node.primitive;
    Primitive input = interceptor.input.definition;

    // Try to reuse an existing interceptor for the same input.
    Primitive existing = interceptorFor[input];
    if (existing != null) {
      if (existing is Interceptor) {
        existing.interceptedClasses.addAll(interceptor.interceptedClasses);
      }
      existing.substituteFor(interceptor);
      interceptor.destroy();
      node.remove();
      return next;
    }

    // There is no interceptor obtained from this particular input, but
    // there might one obtained from another input that is known to
    // have the same result, so try to reuse that.
    InterceptorConstantValue constant = interceptor.constantValue;
    if (constant != null) {
      existing = sharedConstantFor[constant];
      if (existing != null) {
        existing.substituteFor(interceptor);
        interceptor.destroy();
        node.remove();
        return next;
      }

      // The interceptor could not be shared. Replace it with a constant.
      Constant constantPrim = new Constant(constant);
      node.primitive = constantPrim;
      constantPrim.hint = interceptor.hint;
      constantPrim.type = interceptor.type;
      constantPrim.substituteFor(interceptor);
      interceptor.destroy();
      sharedConstantFor[constant] = constantPrim;
    } else {
      interceptorFor[input] = interceptor;
    }

    // Determine the outermost loop where the input to the interceptor call
    // is available.  Constant interceptors take no input and can thus be
    // hoisted all way to the top-level.
    Continuation referencedLoop = constant != null
        ? null
        : lowestCommonAncestor(loopHeaderFor[input], currentLoopHeader);
    if (referencedLoop != currentLoopHeader) {
      // [referencedLoop] contains the binding for [input], so we cannot hoist
      // the interceptor outside that loop.  Find the loop nested one level
      // inside referencedLoop, and hoist the interceptor just outside that one.
      Continuation loop = currentLoopHeader;
      Continuation enclosing = loopHierarchy.getEnclosingLoop(loop);
      while (enclosing != referencedLoop) {
        assert(loop != null);
        loop = enclosing;
        enclosing = loopHierarchy.getEnclosingLoop(loop);
      }
      assert(loop != null);

      // Move the LetPrim above the loop binding.
      LetCont loopBinding = loop.parent;
      node.remove();
      node.insertAbove(loopBinding);

      // A different loop now contains the interceptor.
      loopHeaderFor[node.primitive] = enclosing;

      // Register the interceptor as hoisted to that loop, so it will be
      // removed from the environment when it falls out of scope.
      loopHoistedInterceptors
          .putIfAbsent(loop, () => <Primitive>[])
          .add(node.primitive);
    } else if (constant != null) {
      // The LetPrim was not hoisted. Remove the bound interceptor from the
      // environment when leaving the LetPrim body.
      pushAction(() {
        assert(sharedConstantFor[constant] == node.primitive);
        sharedConstantFor.remove(constant);
      });
    } else {
      pushAction(() {
        assert(interceptorFor[input] == node.primitive);
        interceptorFor.remove(input);
      });
    }
    return next;
  }

  /// Returns the the innermost loop that effectively encloses both
  /// c1 and c2 (or `null` if there is no such loop).
  Continuation lowestCommonAncestor(Continuation c1, Continuation c2) {
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

  int getDepth(Continuation loop) {
    if (loop == null) return -1;
    return loopHierarchy.loopDepth[loop];
  }
}
