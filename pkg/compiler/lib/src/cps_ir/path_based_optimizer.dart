// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dart2js.cps_ir.path_based_optimizer;

import 'cps_ir_nodes.dart';
import 'optimizers.dart';
import 'cps_fragment.dart';
import '../js_backend/js_backend.dart';
import 'type_mask_system.dart';

/// Optimizations based on intraprocedural forward dataflow analysis, taking
/// into account path information that is not expressed by [Refinement] nodes.
///
/// ---
///
/// Removes branches that branch on the same value as a previously seen branch.
/// For example:
///
///     if (x == y) {
///       if (x == y) TRUE else FALSE
///     }
///
/// ==> ([GVN] pass merges identical expressions)
///
///     var b = (x == y)
///     if (b) {
///       if (b) TRUE else FALSE
///     }
///
///  ==> (this pass removes the duplicate branch)
///
///     var b = (x == y)
///     if (b) {
///       TRUE
///     }
///
/// ---
///
/// Removes interceptors for method calls whose receiver is known to be a
/// self-interceptor. For example:
///
///     x.foo$1();
///     getInterceptor(x).$eq(x, y);
///
/// ==> (`x` is a self-interceptor, remove the `getInterceptor` call)
///
///     x.foo$1();
///     x.$eq(0, y);
///
/// Although there is a [Refinement] node after the call to `x.foo$1()`, the
/// refined type cannot always be represented exactly, and type propagation
/// may therefore not see that `x` is a self-interceptor.
//
// TODO(asgerf): A kind of redundant join can arise where a branching condition
// is known to be true/false on all but one predecessor for a branch. We could
// try to reduce those.
//
// TODO(asgerf): Could be more precise if GVN shared expressions that are not
// in direct scope of one another, e.g. by using phis pass the shared value.
//
class PathBasedOptimizer extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Path-based optimizations';

  // Classification of all values.
  static const int TRUE = 1 << 0;
  static const int SELF_INTERCEPTOR = 1 << 1;
  static const int INTERCEPTED_TRUTHY = 1 << 2;
  static const int FALSE = 1 << 3;
  static const int OTHER_FALSY = 1 << 4;

  static const int TRUTHY = TRUE | SELF_INTERCEPTOR | INTERCEPTED_TRUTHY;
  static const int FALSY = FALSE | OTHER_FALSY;
  static const int ANY = TRUTHY | FALSY;

  final JavaScriptBackend backend;
  final TypeMaskSystem typeSystem;

  PathBasedOptimizer(this.backend, this.typeSystem);

  /// The possible values of the given primitive (or ANY if absent) at the
  /// current traversal position.
  Map<Primitive, int> valueOf = <Primitive, int>{};

  /// The possible values of each primitive at the entry to a continuation.
  ///
  /// Unreachable continuations are absent from the map.
  final Map<Continuation, Map<Primitive, int>> valuesAt =
      <Continuation, Map<Primitive, int>>{};

  void rewrite(FunctionDefinition node) {
    visit(node);
  }

  Map<Primitive, int> copy(Map<Primitive, int> map) {
    return new Map<Primitive, int>.from(map);
  }

  Expression traverseLetHandler(LetHandler node) {
    valuesAt[node.handler] = copy(valueOf);
    push(node.handler);
    return node.body;
  }

  Expression traverseContinuation(Continuation cont) {
    valueOf = valuesAt[cont];
    if (valueOf == null) {
      // Do not go into unreachable code.
      destroyAndReplace(cont.body, new Unreachable());
    }
    return cont.body;
  }

  void visitInvokeContinuation(InvokeContinuation node) {
    Continuation cont = node.continuation;
    if (cont.isReturnContinuation) return;
    if (node.isRecursive) return;
    Map<Primitive, int> target = valuesAt[cont];
    if (target == null) {
      valuesAt[cont] = valueOf;
    } else {
      for (Primitive prim in target.keys) {
        target[prim] |= valueOf[prim] ?? ANY;
      }
    }
  }

  visitBranch(Branch node) {
    Primitive condition = node.condition.effectiveDefinition;
    Continuation trueCont = node.trueContinuation;
    Continuation falseCont = node.falseContinuation;
    if (condition.hasExactlyOneUse) {
      // Handle common case specially. Do not add [condition] to the map if
      // there are no other uses.
      valuesAt[trueCont] = copy(valueOf);
      valuesAt[falseCont] = valueOf;
      return;
    }
    int values = valueOf[condition] ?? ANY;
    int positiveValues = node.isStrictCheck ? TRUE : TRUTHY;
    int negativeValues = (~positiveValues) & ANY;
    if (values & positiveValues == 0) {
      destroyAndReplace(node, new InvokeContinuation(falseCont, []));
      valuesAt[falseCont] = valueOf;
    } else if (values & negativeValues == 0) {
      destroyAndReplace(node, new InvokeContinuation(trueCont, []));
      valuesAt[trueCont] = valueOf;
    } else {
      valuesAt[trueCont] = copy(valueOf)..[condition] = values & positiveValues;
      valuesAt[falseCont] = valueOf..[condition] = values & negativeValues;
    }
  }

  void visitInvokeMethod(InvokeMethod node) {
    int receiverValue = valueOf[node.receiver] ?? ANY;
    if (!backend.isInterceptedSelector(node.selector)) {
      // Only self-interceptors can respond to a non-intercepted selector.
      valueOf[node.receiver] = receiverValue & SELF_INTERCEPTOR;
    } else if (receiverValue & ~SELF_INTERCEPTOR == 0 &&
        node.callingConvention == CallingConvention.Intercepted) {
      // This is an intercepted call whose receiver is definitely a
      // self-interceptor.
      // TODO(25646): If TypeMasks could represent "any self-interceptor" this
      //   optimization should be subsumed by type propagation.
      node.interceptorRef.changeTo(node.receiver);

      // Replace the extra receiver argument with a dummy value if the
      // target definitely does not use it.
      if (typeSystem.targetIgnoresReceiverArgument(
          node.receiver.type, node.selector)) {
        node.makeDummyIntercepted();
      }
    }
  }
}
