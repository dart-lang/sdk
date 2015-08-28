// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.share_interceptors;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';

/// Merges calls to `getInterceptor` when one call dominates the other.
/// 
/// Should run after [LoopInvariantCodeMotion] so interceptors lifted out from
/// loops can be merged.
class ShareInterceptors extends RecursiveVisitor implements Pass {
  String get passName => 'Share interceptors';

  final Map<Primitive, Interceptor> interceptorFor = 
      <Primitive, Interceptor>{};

  void rewrite(FunctionDefinition node) {
    visit(node.body);
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    if (node.primitive is Interceptor) {
      Interceptor interceptor = node.primitive;
      Primitive input = interceptor.input.definition;
      Interceptor existing = interceptorFor[input];
      if (existing != null) {
        existing.interceptedClasses.addAll(interceptor.interceptedClasses);
        existing.substituteFor(interceptor);
      } else {
        interceptorFor[input] = interceptor;
        pushAction(() {
          interceptorFor.remove(input);
        });
      }
    }
    return node.body;
  }
}
