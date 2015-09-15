// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.share_interceptors;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';
import 'type_mask_system.dart';
import '../elements/elements.dart';
import '../constants/values.dart';

/// Merges calls to `getInterceptor` when one call is in scope of the other.
///
/// Also replaces `getInterceptor` calls with an interceptor constant when
/// the result is known statically, and there is no interceptor already in
/// scope.
/// 
/// Should run after [LoopInvariantCodeMotion] so interceptors lifted out from
/// loops can be merged.
class ShareInterceptors extends RecursiveVisitor implements Pass {
  String get passName => 'Share interceptors';

  final Map<Primitive, Primitive> interceptorFor =
      <Primitive, Primitive>{};

  final Map<ConstantValue, Primitive> sharedConstantFor =
      <ConstantValue, Primitive>{};

  void rewrite(FunctionDefinition node) {
    visit(node.body);
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    if (node.primitive is Interceptor) {
      Interceptor interceptor = node.primitive;
      Primitive input = interceptor.input.definition;
      Primitive existing = interceptorFor[input];
      if (existing != null) {
        if (existing is Interceptor) {
          existing.interceptedClasses.addAll(interceptor.interceptedClasses);
        }
        existing.substituteFor(interceptor);
      } else if (interceptor.constantValue != null) {
        InterceptorConstantValue value = interceptor.constantValue;
        // There is no interceptor obtained from this particular input, but
        // there might one obtained from another input that is known to
        // have the same result, so try to reuse that.
        Primitive shared = sharedConstantFor[value];
        if (shared != null) {
          shared.substituteFor(interceptor);
        } else {
          Constant constant = new Constant(value);
          constant.hint = interceptor.hint;
          node.primitive = constant;
          constant.parent = node;
          interceptor.input.unlink();
          constant.substituteFor(interceptor);
          interceptorFor[input] = constant;
          sharedConstantFor[value] = constant;
          pushAction(() {
            interceptorFor.remove(input);
            sharedConstantFor.remove(value);

            if (constant.hasExactlyOneUse) {
              // As a heuristic, always sink single-use interceptor constants
              // to their use, even if it is inside a loop.
              Expression use = getEnclosingExpression(constant.firstRef.parent);
              InteriorNode parent = node.parent;
              parent.body = node.body;
              node.body.parent = parent;

              InteriorNode useParent = use.parent;
              useParent.body = node;
              node.body = use;
              use.parent = node;
              node.parent = useParent;
            }
          });
        }
      } else {
        interceptorFor[input] = interceptor;
        pushAction(() {
          interceptorFor.remove(input);
        });
      }
    }
    return node.body;
  }

  Expression getEnclosingExpression(Node node) {
    while (node is! Expression) {
      node = node.parent;
    }
    return node;
  }
}
