// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

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
  final ConstantSystem constantSystem;
  final Compiler compiler;
  final CodegenWorkItem work;
  HGraph graph;

  SsaSimplifyInterceptors(this.compiler, this.constantSystem, this.work);

  JavaScriptBackend get backend => compiler.backend;

  BackendHelpers get helpers => backend.helpers;

  ClassWorld get classWorld => compiler.world;

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
    var interceptor = invoke.inputs[0];
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

  bool canUseSelfForInterceptor(HInstruction receiver,
                                Set<ClassElement> interceptedClasses) {

    if (receiver.canBePrimitive(compiler)) {
      // Primitives always need interceptors.
      return false;
    }
    if (receiver.canBeNull() &&
        interceptedClasses.contains(helpers.jsNullClass)) {
      // Need the JSNull interceptor.
      return false;
    }

    // All intercepted classes extend `Interceptor`, so if the receiver can't be
    // a class extending `Interceptor` then it can be called directly.
    return new TypeMask.nonNullSubclass(helpers.jsInterceptorClass, classWorld)
        .isDisjoint(receiver.instructionType, classWorld);
  }

  HInstruction tryComputeConstantInterceptor(
      HInstruction input,
      Set<ClassElement> interceptedClasses) {
    if (input == graph.explicitReceiverParameter) {
      // If `explicitReceiverParameter` is set it means the current method is an
      // interceptor method, and `this` is the interceptor.  The caller just did
      // `getInterceptor(foo).currentMethod(foo)` to enter the current method.
      return graph.thisInstruction;
    }

    ClassElement constantInterceptor = tryComputeConstantInterceptorFromType(
        input.instructionType, interceptedClasses);

    if (constantInterceptor == null) return null;

    // If we just happen to be in an instance method of the constant
    // interceptor, `this` is a shorter alias.
    if (constantInterceptor == work.element.enclosingClass &&
        graph.thisInstruction != null) {
      return graph.thisInstruction;
    }

    ConstantValue constant =
        new InterceptorConstantValue(constantInterceptor.thisType);
    return graph.addConstant(constant, compiler);
  }

  ClassElement tryComputeConstantInterceptorFromType(
      TypeMask type,
      Set<ClassElement> interceptedClasses) {

    if (type.isNullable) {
      if (type.isNull) {
        return helpers.jsNullClass;
      }
    } else if (type.containsOnlyInt(classWorld)) {
      return helpers.jsIntClass;
    } else if (type.containsOnlyDouble(classWorld)) {
      return helpers.jsDoubleClass;
    } else if (type.containsOnlyBool(classWorld)) {
      return helpers.jsBoolClass;
    } else if (type.containsOnlyString(classWorld)) {
      return helpers.jsStringClass;
    } else if (type.satisfies(helpers.jsArrayClass, classWorld)) {
      return helpers.jsArrayClass;
    } else if (type.containsOnlyNum(classWorld) &&
        !interceptedClasses.contains(helpers.jsIntClass) &&
        !interceptedClasses.contains(helpers.jsDoubleClass)) {
      // If the method being intercepted is not defined in [int] or [double] we
      // can safely use the number interceptor.  This is because none of the
      // [int] or [double] methods are called from a method defined on [num].
      return helpers.jsNumberClass;
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
      ClassElement element = type.singleClass(classWorld);
      if (element != null && backend.isNative(element)) {
        return element;
      }
    }

    return null;
  }

  HInstruction findDominator(Iterable<HInstruction> instructions) {
    HInstruction result;
    L1: for (HInstruction candidate in instructions) {
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

    Set<ClassElement> interceptedClasses;
    HInstruction dominator = findDominator(node.usedBy);
    // If there is a call that dominates all other uses, we can use just the
    // selector of that instruction.
    if (dominator is HInvokeDynamic &&
        dominator.isCallOnInterceptor(compiler) &&
        node == dominator.receiver &&
        useCount(dominator, node) == 1) {
      interceptedClasses =
            backend.getInterceptedClassesOn(dominator.selector.name);

      // If we found that we need number, we must still go through all
      // uses to check if they require int, or double.
      if (interceptedClasses.contains(helpers.jsNumberClass) &&
          !(interceptedClasses.contains(helpers.jsDoubleClass) ||
            interceptedClasses.contains(helpers.jsIntClass))) {
        for (HInstruction user in node.usedBy) {
          if (user is! HInvoke) continue;
          Set<ClassElement> intercepted =
              backend.getInterceptedClassesOn(user.selector.name);
          if (intercepted.contains(helpers.jsIntClass)) {
            interceptedClasses.add(helpers.jsIntClass);
          }
          if (intercepted.contains(helpers.jsDoubleClass)) {
            interceptedClasses.add(helpers.jsDoubleClass);
          }
        }
      }
    } else {
      interceptedClasses = new Set<ClassElement>();
      for (HInstruction user in node.usedBy) {
        if (user is HInvokeDynamic &&
            user.isCallOnInterceptor(compiler) &&
            node == user.receiver &&
            useCount(user, node) == 1) {
          interceptedClasses.addAll(
              backend.getInterceptedClassesOn(user.selector.name));
        } else if (user is HInvokeSuper &&
                   user.isCallOnInterceptor(compiler) &&
                   node == user.receiver &&
                   useCount(user, node) == 1) {
          interceptedClasses.addAll(
              backend.getInterceptedClassesOn(user.selector.name));
        } else {
          // Use a most general interceptor for other instructions, example,
          // is-checks and escaping interceptors.
          interceptedClasses.addAll(backend.interceptedClasses);
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

    // Do we have an 'almost constant' interceptor?  The receiver could be
    // `null` but not any other JavaScript falsy value, `null` values cause
    // `NoSuchMethodError`s, and if the receiver was not null we would have a
    // constant interceptor `C`.  Then we can use `(receiver && C)` for the
    // interceptor.
    if (receiver.canBeNull() && !node.isConditionalConstantInterceptor) {
      if (!interceptedClasses.contains(helpers.jsNullClass)) {
        // Can use `(receiver && C)` only if receiver is either null or truthy.
        if (!(receiver.canBePrimitiveNumber(compiler) ||
            receiver.canBePrimitiveBoolean(compiler) ||
            receiver.canBePrimitiveString(compiler))) {
          ClassElement interceptorClass = tryComputeConstantInterceptorFromType(
              receiver.instructionType.nonNullable(), interceptedClasses);
          if (interceptorClass != null) {
            HInstruction constantInstruction =
                graph.addConstant(
                    new InterceptorConstantValue(interceptorClass.thisType),
                    compiler);
            node.conditionalConstantInterceptor = constantInstruction;
            constantInstruction.usedBy.add(node);
            return false;
          }
        }
      }
    }

    // Try creating a one-shot interceptor or optimized is-check
    if (compiler.hasIncrementalSupport) return false;
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
        if (backend.mayGenerateInstanceofCheck(user.typeExpression)) {
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
        HConstant nullConstant = graph.addConstantNull(compiler);
        List<HInstruction> inputs = new List<HInstruction>.from(user.inputs);
        inputs[0] = nullConstant;
        HOneShotInterceptor oneShotInterceptor = new HOneShotInterceptor(
            user.selector, user.mask,
            inputs, user.instructionType, interceptedClasses);
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
    HInstruction constant = tryComputeConstantInterceptor(
        node.inputs[1], node.interceptedClasses);

    if (constant == null) return false;

    Selector selector = node.selector;
    TypeMask mask = node.mask;
    HInstruction instruction;
    if (selector.isGetter) {
      instruction = new HInvokeDynamicGetter(
          selector,
          mask,
          node.element,
          <HInstruction>[constant, node.inputs[1]],
          node.instructionType);
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
