// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.optimize_interceptors;

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

/// Replaces `getInterceptor` calls with interceptor constants when possible,
/// or with "almost constant" expressions like "x && CONST" when the input
/// is either null or has a known interceptor.
//
//  TODO(asgerf): Compute intercepted classes in this pass.
class OptimizeInterceptors extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Optimize interceptors';

  JavaScriptBackend backend;
  LoopHierarchy loopHierarchy;
  Continuation currentLoopHeader;

  OptimizeInterceptors(this.backend);

  BackendHelpers get helpers => backend.helpers;

  void rewrite(FunctionDefinition node) {
    // TODO(asgerf): Computing the LoopHierarchy here may be overkill when all
    //               we want is to hoist constants out of loops.
    loopHierarchy = new LoopHierarchy(node);
    visit(node.body);
    new ShareConstants().visit(node);
  }

  @override
  Expression traverseContinuation(Continuation cont) {
    Continuation oldLoopHeader = currentLoopHeader;
    currentLoopHeader = loopHierarchy.getLoopHeader(cont);
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
      interceptor..replaceUsesWith(constantPrim)..destroy();
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
      interceptor..replaceUsesWith(param)..destroy();
      let.remove();
    }
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    Expression next = node.body;
    if (node.primitive is Interceptor) {
      constifyInterceptor(node.primitive);
    }
    return next;
  }
}

/// Shares interceptor constants when one is in scope of another.
///
/// Interceptor optimization runs after GVN, hence this clean-up step is needed.
///
/// TODO(asgerf): Handle in separate constant optimization pass? With some other
///   constant-related optimizations, like cloning small constants at use-site.
class ShareConstants extends TrampolineRecursiveVisitor {
  Map<ConstantValue, Constant> sharedConstantFor = <ConstantValue, Constant>{};

  Expression traverseLetPrim(LetPrim node) {
    Expression next = node.body;
    if (node.primitive is Constant && shouldShareConstant(node.primitive)) {
      Constant prim = node.primitive;
      Constant existing = sharedConstantFor[prim.value];
      if (existing != null) {
        existing.useElementAsHint(prim.hint);
        prim..replaceUsesWith(existing)..destroy();
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
