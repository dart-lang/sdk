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
import '../world.dart';
import 'type_mask_system.dart';

/// Replaces `getInterceptor` calls with interceptor constants when possible,
/// or with "almost constant" expressions like "x && CONST" when the input
/// is either null or has a known interceptor.
///
/// Narrows the set of intercepted classes for interceptor calls.
///
/// Replaces calls on interceptors with one-shot interceptors.
class OptimizeInterceptors extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Optimize interceptors';

  final TypeMaskSystem typeSystem;
  final JavaScriptBackend backend;
  LoopHierarchy loopHierarchy;
  Continuation currentLoopHeader;

  OptimizeInterceptors(this.backend, this.typeSystem);

  BackendHelpers get helpers => backend.helpers;
  World get classWorld => backend.compiler.world;

  Map<Interceptor, Continuation> loopHeaderFor = <Interceptor, Continuation>{};

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

  void computeInterceptedClasses(Interceptor interceptor) {
    Set<ClassElement> intercepted = interceptor.interceptedClasses;
    intercepted.clear();
    for (Reference ref = interceptor.firstRef; ref != null; ref = ref.next) {
      Node use = ref.parent;
      if (use is InvokeMethod) {
        TypeMask type = use.receiver.type;
        bool canOccurAsReceiver(ClassElement elem) {
          return classWorld.isInstantiated(elem) &&
              !typeSystem.areDisjoint(
                  type, typeSystem.getInterceptorSubtypes(elem));
        }
        Iterable<ClassElement> classes =
            backend.getInterceptedClassesOn(use.selector.name);
        intercepted.addAll(classes.where(canOccurAsReceiver));
      } else {
        intercepted.clear();
        intercepted.add(backend.helpers.jsInterceptorClass);
        break;
      }
    }
    if (intercepted.contains(backend.helpers.jsInterceptorClass) ||
        intercepted.contains(backend.helpers.jsNullClass)) {
      // If the null value is intercepted, update the type of the interceptor.
      // The Tree IR uses this information to determine if the method lookup
      // on an InvokeMethod might throw.
      interceptor.type = interceptor.type.nonNullable();
    }
  }

  /// True if [node] may return [JSNumber] instead of [JSInt] or [JSDouble].
  bool jsNumberClassSuffices(Interceptor node) {
    // No methods on JSNumber call 'down' to methods on JSInt or JSDouble.  If
    // all uses of the interceptor are for methods is defined only on JSNumber
    // then JSNumber will suffice in place of choosing between JSInt or
    // JSDouble.
    for (Reference ref = node.firstRef; ref != null; ref = ref.next) {
      if (ref.parent is InvokeMethod) {
        InvokeMethod invoke = ref.parent;
        if (invoke.interceptorRef != ref) return false;
        var interceptedClasses =
            backend.getInterceptedClassesOn(invoke.selector.name);
        if (interceptedClasses.contains(helpers.jsDoubleClass)) return false;
        if (interceptedClasses.contains(helpers.jsIntClass)) return false;
        continue;
      }
      // Other uses need full distinction.
      return false;
    }
    return true;
  }

  /// True if [node] can intercept a `null` value and return the [JSNull]
  /// interceptor.
  bool canInterceptNull(Interceptor node) {
    for (Reference ref = node.firstRef; ref != null; ref = ref.next) {
      Node use = ref.parent;
      if (use is InvokeMethod) {
        if (selectorsOnNull.contains(use.selector) &&
            use.receiver.type.isNullable) {
          return true;
        }
      } else {
        return true;
      }
    }
    return false;
  }

  /// Returns the only interceptor class that may be returned by [node], or
  /// `null` if no such class could be found.
  ClassElement getSingleInterceptorClass(Interceptor node) {
    // TODO(asgerf): This could be more precise if we used the use-site type,
    // since the interceptor may have been hoisted out of a loop, where a less
    // precise type is known.
    Primitive input = node.input;
    TypeMask type = input.type;
    if (canInterceptNull(node)) return null;
    type = type.nonNullable();
    if (typeSystem.isDefinitelyArray(type)) {
      return backend.helpers.jsArrayClass;
    }
    if (typeSystem.isDefinitelyInt(type)) {
      return backend.helpers.jsIntClass;
    }
    if (typeSystem.isDefinitelyNum(type) && jsNumberClassSuffices(node)) {
      return backend.helpers.jsNumberClass;
    }
    ClassElement singleClass = type.singleClass(classWorld);
    if (singleClass != null &&
        singleClass.isSubclassOf(backend.helpers.jsInterceptorClass)) {
      return singleClass;
    }
    return null;
  }

  /// Try to replace [interceptor] with a constant, and return `true` if
  /// successful.
  bool constifyInterceptor(Interceptor interceptor) {
    LetPrim let = interceptor.parent;
    Primitive input = interceptor.input;
    ClassElement classElement = getSingleInterceptorClass(interceptor);

    if (classElement == null) return false;
    ConstantValue constant = new InterceptorConstantValue(classElement.rawType);

    if (!input.type.isNullable) {
      Primitive constantPrim = makeConstantFor(constant,
          useSite: let,
          type: interceptor.type,
          sourceInformation: interceptor.sourceInformation);
      constantPrim.useElementAsHint(interceptor.hint);
      interceptor
        ..replaceUsesWith(constantPrim)
        ..destroy();
      let.remove();
    } else {
      Primitive constantPrim = makeConstantFor(constant,
          useSite: let,
          type: interceptor.type.nonNullable(),
          sourceInformation: interceptor.sourceInformation);
      CpsFragment cps = new CpsFragment(interceptor.sourceInformation);
      Parameter param = new Parameter(interceptor.hint);
      param.type = interceptor.type;
      Continuation cont = cps.letCont(<Parameter>[param]);
      if (hasNoFalsyValues(classElement)) {
        // If null is the only falsy value, compile as "x && CONST".
        cps.ifFalsy(input).invokeContinuation(cont, [input]);
      } else {
        // If there are other falsy values compile as "x == null ? x : CONST".
        Primitive condition =
            cps.applyBuiltin(BuiltinOperator.LooseEq, [input, cps.makeNull()]);
        cps.ifTruthy(condition).invokeContinuation(cont, [input]);
      }
      cps.invokeContinuation(cont, [constantPrim]);
      cps.context = cont;
      cps.insertAbove(let);
      interceptor
        ..replaceUsesWith(param)
        ..destroy();
      let.remove();
    }
    return true;
  }

  @override
  Expression traverseLetPrim(LetPrim node) {
    Expression next = node.body;
    visit(node.primitive);
    return next;
  }

  @override
  void visitInterceptor(Interceptor node) {
    if (constifyInterceptor(node)) return;
    computeInterceptedClasses(node);
    if (node.hasExactlyOneUse) {
      // Set the loop header on single-use interceptors so [visitInvokeMethod]
      // can determine if it should become a one-shot interceptor.
      loopHeaderFor[node] = currentLoopHeader;
    }
  }

  @override
  void visitInvokeMethod(InvokeMethod node) {
    if (node.callingConvention != CallingConvention.Intercepted) return;
    Primitive interceptor = node.interceptor;
    if (interceptor is! Interceptor ||
        interceptor.hasMultipleUses ||
        loopHeaderFor[interceptor] != currentLoopHeader) {
      return;
    }
    // TODO(asgerf): Consider heuristics for when to use one-shot interceptors.
    //   E.g. using only one-shot interceptors with a fast path.
    node.makeOneShotIntercepted();
  }

  @override
  void visitTypeTestViaFlag(TypeTestViaFlag node) {
    Primitive interceptor = node.interceptor;
    if (interceptor is! Interceptor ||
        interceptor.hasMultipleUses ||
        loopHeaderFor[interceptor] != currentLoopHeader ||
        !backend.mayGenerateInstanceofCheck(node.dartType)) {
      return;
    }
    Interceptor inter = interceptor;
    Primitive value = inter.input;
    node.replaceWith(new TypeTest(value, node.dartType, [])..type = node.type);
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
        prim
          ..replaceUsesWith(existing)
          ..destroy();
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
