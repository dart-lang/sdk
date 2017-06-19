// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show CommonElements;
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../js_backend/interceptor_data.dart';
import '../types/types.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show ClosedWorld;
import 'nodes.dart';
import 'optimize.dart';

/**
 * This phase simplifies interceptors in multiple ways:
 *
 * 1) If the interceptor is for an object whose type is known, it
 * tries to use a constant interceptor instead.
 *
 * 2) Interceptors are specialized based on the selector it is used with.
 *
 * 3) If we know the object is not intercepted, we just use the object
 * instead.
 *
 * 4) Single use interceptors at dynamic invoke sites are replaced with 'one
 * shot interceptors' which are synthesized static helper functions that fetch
 * the interceptor and then call the method.  This saves code size and makes the
 * receiver of an intercepted call a candidate for being generated at use site.
 *
 * 5) Some HIs operations on an interceptor are replaced with a HIs version that
 * uses 'instanceof' rather than testing a type flag.
 *
 */
class SsaSimplifyInterceptors extends HBaseVisitor
    implements OptimizationPhase {
  final String name = "SsaSimplifyInterceptors";
  final ClosedWorld closedWorld;
  final ClassEntity enclosingClass;
  HGraph graph;

  SsaSimplifyInterceptors(this.closedWorld, this.enclosingClass);

  CommonElements get _commonElements => closedWorld.commonElements;

  ConstantSystem get constantSystem => closedWorld.constantSystem;

  InterceptorData get interceptorData => closedWorld.interceptorData;

  void visitGraph(HGraph graph) {
    this.graph = graph;
    visitDominatorTree(graph);
  }

  void visitBasicBlock(HBasicBlock node) {
    currentBlock = node;

    HInstruction instruction = node.first;
    while (instruction != null) {
      bool shouldRemove = instruction.accept(this);
      HInstruction next = instruction.next;
      if (shouldRemove) {
        instruction.block.remove(instruction);
      }
      instruction = next;
    }
  }

  bool visitInstruction(HInstruction instruction) => false;

  bool visitInvoke(HInvoke invoke) {
    if (!invoke.isInterceptedCall) return false;
    dynamic interceptor = invoke.inputs[0];
    if (interceptor is! HInterceptor) return false;

    // TODO(sra): Move this per-call code to visitInterceptor.
    //
    // The interceptor is visited first, so we get here only when the
    // interceptor was not rewritten to a single shared replacement.  I'm not
    // sure we should substitute a constant interceptor on a per-call basis if
    // the interceptor is already available in a local variable, but it is
    // possible that all uses can be rewritten to use different constants.

    // TODO(sra): Also do self-interceptor rewrites on a per-use basis.

    HInstruction constant = tryComputeConstantInterceptor(
        invoke.inputs[1], interceptor.interceptedClasses);
    if (constant != null) {
      invoke.changeUse(interceptor, constant);
    }
    return false;
  }

  bool canUseSelfForInterceptor(
      HInstruction receiver, Set<ClassEntity> interceptedClasses) {
    if (receiver.canBePrimitive(closedWorld)) {
      // Primitives always need interceptors.
      return false;
    }
    if (receiver.canBeNull() &&
        interceptedClasses.contains(_commonElements.jsNullClass)) {
      // Need the JSNull interceptor.
      return false;
    }

    // All intercepted classes extend `Interceptor`, so if the receiver can't be
    // a class extending `Interceptor` then it can be called directly.
    return new TypeMask.nonNullSubclass(
            _commonElements.jsInterceptorClass, closedWorld)
        .isDisjoint(receiver.instructionType, closedWorld);
  }

  HInstruction tryComputeConstantInterceptor(
      HInstruction input, Set<ClassEntity> interceptedClasses) {
    if (input == graph.explicitReceiverParameter) {
      // If `explicitReceiverParameter` is set it means the current method is an
      // interceptor method, and `this` is the interceptor.  The caller just did
      // `getInterceptor(foo).currentMethod(foo)` to enter the current method.
      return graph.thisInstruction;
    }

    ClassEntity constantInterceptor = tryComputeConstantInterceptorFromType(
        input.instructionType, interceptedClasses);

    if (constantInterceptor == null) return null;

    // If we just happen to be in an instance method of the constant
    // interceptor, `this` is a shorter alias.
    if (constantInterceptor == enclosingClass &&
        graph.thisInstruction != null) {
      return graph.thisInstruction;
    }

    ConstantValue constant = new InterceptorConstantValue(constantInterceptor);
    return graph.addConstant(constant, closedWorld);
  }

  ClassEntity tryComputeConstantInterceptorFromType(
      TypeMask type, Set<ClassEntity> interceptedClasses) {
    if (type.isNullable) {
      if (type.isNull) {
        return _commonElements.jsNullClass;
      }
    } else if (type.containsOnlyInt(closedWorld)) {
      return _commonElements.jsIntClass;
    } else if (type.containsOnlyDouble(closedWorld)) {
      return _commonElements.jsDoubleClass;
    } else if (type.containsOnlyBool(closedWorld)) {
      return _commonElements.jsBoolClass;
    } else if (type.containsOnlyString(closedWorld)) {
      return _commonElements.jsStringClass;
    } else if (type.satisfies(_commonElements.jsArrayClass, closedWorld)) {
      return _commonElements.jsArrayClass;
    } else if (type.containsOnlyNum(closedWorld) &&
        !interceptedClasses.contains(_commonElements.jsIntClass) &&
        !interceptedClasses.contains(_commonElements.jsDoubleClass)) {
      // If the method being intercepted is not defined in [int] or [double] we
      // can safely use the number interceptor.  This is because none of the
      // [int] or [double] methods are called from a method defined on [num].
      return _commonElements.jsNumberClass;
    } else {
      // Try to find constant interceptor for a native class.  If the receiver
      // is constrained to a leaf native class, we can use the class's
      // interceptor directly.

      // TODO(sra): Key DOM classes like Node, Element and Event are not leaf
      // classes.  When the receiver type is not a leaf class, we might still be
      // able to use the receiver class as a constant interceptor.  It is
      // usually the case that methods defined on a non-leaf class don't test
      // for a subclass or call methods defined on a subclass.  Provided the
      // code is completely insensitive to the specific instance subclasses, we
      // can use the non-leaf class directly.
      ClassEntity element = type.singleClass(closedWorld);
      if (element != null && closedWorld.nativeData.isNativeClass(element)) {
        return element;
      }
    }

    return null;
  }

  HInstruction findDominator(Iterable<HInstruction> instructions) {
    HInstruction result;
    L1:
    for (HInstruction candidate in instructions) {
      for (HInstruction current in instructions) {
        if (current != candidate && !candidate.dominates(current)) continue L1;
      }
      result = candidate;
      break;
    }
    return result;
  }

  bool visitInterceptor(HInterceptor node) {
    if (node.isConstant()) return false;

    // Specialize the interceptor with set of classes it intercepts, considering
    // all uses.  (The specialized interceptor has a shorter dispatch chain).
    // This operation applies only where the interceptor is used to dispatch a
    // method.  Other uses, e.g. as an ordinary argument or a HIs check use the
    // most general interceptor.
    //
    // TODO(sra): Take into account the receiver type at each call.  e.g:
    //
    //     (a) => a.length + a.hashCode
    //
    // Currently we use the most general interceptor since all intercepted types
    // implement `hashCode`. But in this example, `a.hashCode` is only reached
    // if `a.length` succeeds, which is indicated by the hashCode receiver being
    // a HTypeKnown instruction.

    int useCount(HInstruction user, HInstruction used) =>
        user.inputs.where((input) => input == used).length;

    Set<ClassEntity> interceptedClasses;
    HInstruction dominator = findDominator(node.usedBy);
    // If there is a call that dominates all other uses, we can use just the
    // selector of that instruction.
    if (dominator is HInvokeDynamic &&
        dominator.isCallOnInterceptor(closedWorld) &&
        node == dominator.receiver &&
        useCount(dominator, node) == 1) {
      interceptedClasses = interceptorData.getInterceptedClassesOn(
          dominator.selector.name, closedWorld);

      // If we found that we need number, we must still go through all
      // uses to check if they require int, or double.
      if (interceptedClasses.contains(_commonElements.jsNumberClass) &&
          !(interceptedClasses.contains(_commonElements.jsDoubleClass) ||
              interceptedClasses.contains(_commonElements.jsIntClass))) {
        Set<ClassEntity> required;
        for (HInstruction user in node.usedBy) {
          if (user is! HInvoke) continue;
          Set<ClassEntity> intercepted = interceptorData
              .getInterceptedClassesOn(user.selector.name, closedWorld);
          if (intercepted.contains(_commonElements.jsIntClass)) {
            // TODO(johnniwinther): Use type argument when all uses of
            // intercepted classes expect entities instead of elements.
            required ??= new Set/*<ClassEntity>*/();
            required.add(_commonElements.jsIntClass);
          }
          if (intercepted.contains(_commonElements.jsDoubleClass)) {
            // TODO(johnniwinther): Use type argument when all uses of
            // intercepted classes expect entities instead of elements.
            required ??= new Set/*<ClassEntity>*/();
            required.add(_commonElements.jsDoubleClass);
          }
        }
        // Don't modify the result of [interceptorData.getInterceptedClassesOn].
        if (required != null) {
          interceptedClasses = interceptedClasses.union(required);
        }
      }
    } else {
      // TODO(johnniwinther): Use type argument when all uses of intercepted
      // classes expect entities instead of elements.
      interceptedClasses = new Set/*<ClassEntity>*/();
      for (HInstruction user in node.usedBy) {
        if (user is HInvokeDynamic &&
            user.isCallOnInterceptor(closedWorld) &&
            node == user.receiver &&
            useCount(user, node) == 1) {
          interceptedClasses.addAll(interceptorData.getInterceptedClassesOn(
              user.selector.name, closedWorld));
        } else if (user is HInvokeSuper &&
            user.isCallOnInterceptor(closedWorld) &&
            node == user.receiver &&
            useCount(user, node) == 1) {
          interceptedClasses.addAll(interceptorData.getInterceptedClassesOn(
              user.selector.name, closedWorld));
        } else {
          // Use a most general interceptor for other instructions, example,
          // is-checks and escaping interceptors.
          interceptedClasses.addAll(interceptorData.interceptedClasses);
          break;
        }
      }
    }

    node.interceptedClasses = interceptedClasses;

    HInstruction receiver = node.receiver;

    // TODO(sra): We should consider each use individually and then all uses
    // together.  Each use might permit a different rewrite due to a refined
    // receiver type.  Self-interceptor rewrites are always beneficial since the
    // receiver is live at a invocation.  Constant-interceptor rewrites are only
    // guaranteed to be beneficial if they can eliminate the need for the
    // interceptor or reduce the uses to one that can be simplified with a
    // one-shot interceptor or optimized is-check.

    if (canUseSelfForInterceptor(receiver, interceptedClasses)) {
      return rewriteToUseSelfAsInterceptor(node, receiver);
    }

    // Try computing a constant interceptor.
    HInstruction constantInterceptor =
        tryComputeConstantInterceptor(receiver, interceptedClasses);
    if (constantInterceptor != null) {
      node.block.rewrite(node, constantInterceptor);
      return false;
    }

    // If it is a conditional constant interceptor and was not strengthened to a
    // constant interceptor then there is nothing more we can do.
    if (node.isConditionalConstantInterceptor) return false;

    // Do we have an 'almost constant' interceptor?  The receiver could be
    // `null` but not any other JavaScript falsy value, `null` values cause
    // `NoSuchMethodError`s, and if the receiver was not null we would have a
    // constant interceptor `C`.  Then we can use `(receiver && C)` for the
    // interceptor.
    if (receiver.canBeNull()) {
      if (!interceptedClasses.contains(_commonElements.jsNullClass)) {
        // Can use `(receiver && C)` only if receiver is either null or truthy.
        if (!(receiver.canBePrimitiveNumber(closedWorld) ||
            receiver.canBePrimitiveBoolean(closedWorld) ||
            receiver.canBePrimitiveString(closedWorld))) {
          ClassEntity interceptorClass = tryComputeConstantInterceptorFromType(
              receiver.instructionType.nonNullable(), interceptedClasses);
          if (interceptorClass != null) {
            HInstruction constantInstruction = graph.addConstant(
                new InterceptorConstantValue(interceptorClass), closedWorld);
            node.conditionalConstantInterceptor = constantInstruction;
            constantInstruction.usedBy.add(node);
            return false;
          }
        }
      }
    }

    // Try creating a one-shot interceptor or optimized is-check
    if (node.usedBy.length != 1) return false;
    HInstruction user = node.usedBy.single;

    // If the interceptor [node] was loop hoisted, we keep the interceptor.
    if (!user.hasSameLoopHeaderAs(node)) return false;

    bool replaceUserWith(HInstruction replacement) {
      HBasicBlock block = user.block;
      block.addAfter(user, replacement);
      block.rewrite(user, replacement);
      block.remove(user);
      return false;
    }

    if (user is HIs) {
      // See if we can rewrite the is-check to use 'instanceof', i.e. rewrite
      // "getInterceptor(x).$isT" to "x instanceof T".
      if (node == user.interceptor) {
        if (interceptorData.mayGenerateInstanceofCheck(
            user.typeExpression, closedWorld)) {
          HInstruction instanceofCheck = new HIs.instanceOf(
              user.typeExpression, user.expression, user.instructionType);
          instanceofCheck.sourceInformation = user.sourceInformation;
          instanceofCheck.sourceElement = user.sourceElement;
          return replaceUserWith(instanceofCheck);
        }
      }
    } else if (user is HInvokeDynamic) {
      if (node == user.inputs[0]) {
        // Replace the user with a [HOneShotInterceptor].
        HConstant nullConstant = graph.addConstantNull(closedWorld);
        List<HInstruction> inputs = new List<HInstruction>.from(user.inputs);
        inputs[0] = nullConstant;
        HOneShotInterceptor oneShotInterceptor = new HOneShotInterceptor(
            user.selector,
            user.mask,
            inputs,
            user.instructionType,
            interceptedClasses);
        oneShotInterceptor.sourceInformation = user.sourceInformation;
        oneShotInterceptor.sourceElement = user.sourceElement;
        return replaceUserWith(oneShotInterceptor);
      }
    }

    return false;
  }

  bool rewriteToUseSelfAsInterceptor(HInterceptor node, HInstruction receiver) {
    for (HInstruction user in node.usedBy.toList()) {
      if (user is HIs) {
        user.changeUse(node, receiver);
      } else {
        // Use the potentially self-argument as new receiver. Note that the
        // self-argument could potentially have a tighter type than the
        // receiver which was the input to the interceptor.
        assert(user.inputs[0] == node);
        assert(receiver.nonCheck() == user.inputs[1].nonCheck());
        user.changeUse(node, user.inputs[1]);
      }
    }
    return false;
  }

  bool visitOneShotInterceptor(HOneShotInterceptor node) {
    HInstruction constant =
        tryComputeConstantInterceptor(node.inputs[1], node.interceptedClasses);

    if (constant == null) return false;

    Selector selector = node.selector;
    TypeMask mask = node.mask;
    HInstruction instruction;
    if (selector.isGetter) {
      instruction = new HInvokeDynamicGetter(selector, mask, node.element,
          <HInstruction>[constant, node.inputs[1]], node.instructionType);
    } else if (selector.isSetter) {
      instruction = new HInvokeDynamicSetter(
          selector,
          mask,
          node.element,
          <HInstruction>[constant, node.inputs[1], node.inputs[2]],
          node.instructionType);
    } else {
      List<HInstruction> inputs = new List<HInstruction>.from(node.inputs);
      inputs[0] = constant;
      instruction = new HInvokeDynamicMethod(
          selector, mask, inputs, node.instructionType, true);
    }

    HBasicBlock block = node.block;
    block.addAfter(node, instruction);
    block.rewrite(node, instruction);
    return true;
  }
}
