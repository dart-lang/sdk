// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.share_interceptors;

import 'optimizers.dart';
import 'cps_ir_nodes.dart';
import 'loop_hierarchy.dart';
import 'cps_fragment.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../js_backend/backend_helpers.dart' show BackendHelpers;
import '../js_backend/js_backend.dart' show JavaScriptBackend;
import '../types/types.dart' show TypeMask;
import '../io/source_information.dart' show SourceInformation;

/// Removes redundant `getInterceptor` calls.
///
/// The pass performs three optimizations for interceptors:
///- pull interceptors out of loops
///- replace interceptors with constants
///- share interceptors when one is in scope of the other
class ShareInterceptors extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Share interceptors';

  /// The innermost loop containing a given primitive.
  final Map<Primitive, Continuation> loopHeaderFor =
      <Primitive, Continuation>{};

  /// An interceptor currently in scope for a given primitive.
  final Map<Primitive, Interceptor> interceptorFor = <Primitive, Interceptor>{};

  /// Interceptors that have been hoisted out of a given loop.
  final Map<Continuation, List<Interceptor>> loopHoistedInterceptors =
      <Continuation, List<Interceptor>>{};

  JavaScriptBackend backend;
  LoopHierarchy loopHierarchy;
  Continuation currentLoopHeader;

  ShareInterceptors(this.backend);

  BackendHelpers get helpers => backend.helpers;

  void rewrite(FunctionDefinition node) {
    loopHierarchy = new LoopHierarchy(node);
    visit(node.body);
    new ShareConstants().visit(node);
  }

  @override
  Expression traverseContinuation(Continuation cont) {
    Continuation oldLoopHeader = currentLoopHeader;
    currentLoopHeader = loopHierarchy.getLoopHeader(cont);
    for (Parameter param in cont.parameters) {
      loopHeaderFor[param] = currentLoopHeader;
    }
    if (cont.isRecursive) {
      pushAction(() {
        // After the loop body has been processed, all interceptors hoisted
        // to this loop fall out of scope and should be removed from the
        // environment.
        List<Interceptor> hoisted = loopHoistedInterceptors[cont];
        if (hoisted != null) {
          for (Interceptor interceptor in hoisted) {
            Primitive input = interceptor.input.definition;
            assert(interceptorFor[input] == interceptor);
            interceptorFor.remove(input);
            constifyInterceptor(interceptor);
          }
        }
      });
    }
    pushAction(() {
      currentLoopHeader = oldLoopHeader;
    });
    return cont.body;
  }

  /// If only one method table can be returned by the given interceptor,
  /// returns a constant for that method table.
  InterceptorConstantValue getInterceptorConstant(Interceptor node) {
    if (node.interceptedClasses.length == 1 &&
        node.isInterceptedClassAlwaysExact) {
      ClassElement interceptorClass = node.interceptedClasses.single;
      return new InterceptorConstantValue(interceptorClass.rawType);
    }
    return null;
  }

  bool hasNoFalsyValues(ClassElement class_) {
    return class_ != helpers.jsInterceptorClass &&
       class_ != helpers.jsNullClass &&
       class_ != helpers.jsBoolClass &&
       class_ != helpers.jsStringClass &&
       !class_.isSubclassOf(helpers.jsNumberClass);
  }

  Continuation getCurrentOuterLoop({Continuation scope}) {
    Continuation inner = null, outer = currentLoopHeader;
    while (outer != scope) {
      inner = outer;
      outer = loopHierarchy.getEnclosingLoop(outer);
    }
    return inner;
  }

  /// Binds the given constant in a primitive, in scope of the [useSite].
  ///
  /// The constant will be hoisted out of loops, and shared with other requests
  /// for the same constant as long as it is in scope.
  Primitive makeConstantFor(ConstantValue constant,
                            {Expression useSite,
                             TypeMask type,
                             SourceInformation sourceInformation,
                             Entity hint}) {
    Constant prim =
        new Constant(constant, sourceInformation: sourceInformation);
    prim.hint = hint;
    prim.type = type;
    LetPrim letPrim = new LetPrim(prim);
    Continuation loop = getCurrentOuterLoop();
    if (loop != null) {
      LetCont loopBinding = loop.parent;
      letPrim.insertAbove(loopBinding);
    } else {
      letPrim.insertAbove(useSite);
    }
    return prim;
  }

  void constifyInterceptor(Interceptor interceptor) {
    LetPrim let = interceptor.parent;
    InterceptorConstantValue constant = getInterceptorConstant(interceptor);

    if (constant == null) return;

    if (interceptor.isAlwaysIntercepted) {
      Primitive constantPrim = makeConstantFor(constant,
          useSite: let,
          type: interceptor.type,
          sourceInformation: interceptor.sourceInformation);
      constantPrim.useElementAsHint(interceptor.hint);
      constantPrim.substituteFor(interceptor);
      interceptor.destroy();
      let.remove();
    } else if (interceptor.isAlwaysNullOrIntercepted) {
      Primitive input = interceptor.input.definition;
      Primitive constantPrim = makeConstantFor(constant,
          useSite: let,
          type: interceptor.type.nonNullable(),
          sourceInformation: interceptor.sourceInformation);
      CpsFragment cps = new CpsFragment(interceptor.sourceInformation);
      Parameter param = new Parameter(interceptor.hint);
      Continuation cont = cps.letCont(<Parameter>[param]);
      if (interceptor.interceptedClasses.every(hasNoFalsyValues)) {
        // If null is the only falsy value, compile as "x && CONST".
        cps.ifFalsy(input).invokeContinuation(cont, [input]);
      } else {
        // If there are other falsy values compile as "x == null ? x : CONST".
        Primitive condition = cps.applyBuiltin(
            BuiltinOperator.LooseEq,
            [input, cps.makeNull()]);
        cps.ifTruthy(condition).invokeContinuation(cont, [input]);
      }
      cps.invokeContinuation(cont, [constantPrim]);
      cps.context = cont;
      cps.insertAbove(let);
      param.substituteFor(interceptor);
      interceptor.destroy();
      let.remove();
    }
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
    Interceptor existing = interceptorFor[input];
    if (existing != null) {
      existing.interceptedClasses.addAll(interceptor.interceptedClasses);
      existing.flags |= interceptor.flags;
      existing.substituteFor(interceptor);
      interceptor.destroy();
      node.remove();
      return next;
    }

    // Put this interceptor in the environment.
    interceptorFor[input] = interceptor;

    // Determine how far the interceptor can be lifted. The outermost loop
    // that contains the input binding should also contain the interceptor
    // binding.
    Continuation referencedLoop =
        lowestCommonAncestor(loopHeaderFor[input], currentLoopHeader);
    if (referencedLoop != currentLoopHeader) {
      Continuation hoistTarget = getCurrentOuterLoop(scope: referencedLoop);
      LetCont loopBinding = hoistTarget.parent;
      node.remove();
      node.insertAbove(loopBinding);
      // Remove the interceptor from the environment after processing the loop.
      loopHoistedInterceptors
          .putIfAbsent(hoistTarget, () => <Interceptor>[])
          .add(interceptor);
    } else {
      // Remove the interceptor from the environment when it falls out of scope.
      pushAction(() {
        assert(interceptorFor[input] == interceptor);
        interceptorFor.remove(input);

        // Now that the final set of intercepted classes has been seen, try to
        // replace it with a constant.
        constifyInterceptor(interceptor);
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

class ShareConstants extends TrampolineRecursiveVisitor {
  Map<ConstantValue, Constant> sharedConstantFor = <ConstantValue, Constant>{};

  Expression traverseLetPrim(LetPrim node) {
    Expression next = node.body;
    if (node.primitive is Constant && shouldShareConstant(node.primitive)) {
      Constant prim = node.primitive;
      Constant existing = sharedConstantFor[prim.value];
      if (existing != null) {
        existing.substituteFor(prim);
        existing.useElementAsHint(prim.hint);
        prim.destroy();
        node.remove();
        return next;
      }
      sharedConstantFor[prim.value] = prim;
      pushAction(() {
        assert(sharedConstantFor[prim.value] == prim);
        sharedConstantFor.remove(prim.value);
      });
    }
    return next;
  }

  bool shouldShareConstant(Constant constant) {
    return constant.value.isInterceptor;
  }
}
