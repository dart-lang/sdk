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
 * 2) It specializes interceptors based on the selectors it is being
 * called with.
 *
 * 3) If we know the object is not intercepted, we just use it
 * instead.
 *
 * 4) It replaces all interceptors that are used only once with
 * one-shot interceptors. It saves code size and makes the receiver of
 * an intercepted call a candidate for being generated at use site.
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
    HInstruction constant = tryComputeConstantInterceptor(
        invoke.inputs[1], interceptor.interceptedClasses);
    if (constant != null) {
      invoke.changeUse(interceptor, constant);
    }
    return false;
  }

  bool canUseSelfForInterceptor(HInstruction receiver,
                                Set<ClassElement> interceptedClasses) {
    JavaScriptBackend backend = compiler.backend;
    ClassWorld classWorld = compiler.world;

    if (receiver.canBePrimitive(compiler)) {
      // Primitives always need interceptors.
      return false;
    }
    if (receiver.canBeNull() &&
        interceptedClasses.contains(backend.jsNullClass)) {
      // Need the JSNull interceptor.
      return false;
    }

    // All intercepted classes extend `Interceptor`, so if the receiver can't be
    // a class extending `Interceptor` then it can be called directly.
    return new TypeMask.nonNullSubclass(backend.jsInterceptorClass, classWorld)
        .intersection(receiver.instructionType, classWorld)
        .isEmpty;
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

    ClassElement constantInterceptor;
    ClassWorld classWorld = compiler.world;
    JavaScriptBackend backend = compiler.backend;
    if (input.canBeNull()) {
      if (input.isNull()) {
        constantInterceptor = backend.jsNullClass;
      }
    } else if (input.isInteger(compiler)) {
      constantInterceptor = backend.jsIntClass;
    } else if (input.isDouble(compiler)) {
      constantInterceptor = backend.jsDoubleClass;
    } else if (input.isBoolean(compiler)) {
      constantInterceptor = backend.jsBoolClass;
    } else if (input.isString(compiler)) {
      constantInterceptor = backend.jsStringClass;
    } else if (input.isArray(compiler)) {
      constantInterceptor = backend.jsArrayClass;
    } else if (input.isNumber(compiler) &&
        !interceptedClasses.contains(backend.jsIntClass) &&
        !interceptedClasses.contains(backend.jsDoubleClass)) {
      // If the method being intercepted is not defined in [int] or [double] we
      // can safely use the number interceptor.  This is because none of the
      // [int] or [double] methods are called from a method defined on [num].
      constantInterceptor = backend.jsNumberClass;
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
      ClassElement element = input.instructionType.singleClass(classWorld);
      if (element != null && element.isNative) {
        constantInterceptor = element;
      }
    }

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
    JavaScriptBackend backend = compiler.backend;
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
      if (interceptedClasses.contains(backend.jsNumberClass) &&
          !(interceptedClasses.contains(backend.jsDoubleClass) ||
            interceptedClasses.contains(backend.jsIntClass))) {
        for (HInstruction user in node.usedBy) {
          if (user is! HInvoke) continue;
          Set<ClassElement> intercepted =
              backend.getInterceptedClassesOn(user.selector.name);
          if (intercepted.contains(backend.jsIntClass)) {
            interceptedClasses.add(backend.jsIntClass);
          }
          if (intercepted.contains(backend.jsDoubleClass)) {
            interceptedClasses.add(backend.jsDoubleClass);
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

    HInstruction receiver = node.receiver;

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

    node.interceptedClasses = interceptedClasses;

    // Try creating a one-shot interceptor.
    if (compiler.hasIncrementalSupport) return false;
    if (node.usedBy.length != 1) return false;
    if (node.usedBy[0] is !HInvokeDynamic) return false;

    HInvokeDynamic user = node.usedBy[0];

    // If [node] was loop hoisted, we keep the interceptor.
    if (!user.hasSameLoopHeaderAs(node)) return false;

    // Replace the user with a [HOneShotInterceptor].
    HConstant nullConstant = graph.addConstantNull(compiler);
    List<HInstruction> inputs = new List<HInstruction>.from(user.inputs);
    inputs[0] = nullConstant;
    HOneShotInterceptor interceptor = new HOneShotInterceptor(
        user.selector, inputs, user.instructionType, node.interceptedClasses);
    interceptor.sourcePosition = user.sourcePosition;
    interceptor.sourceElement = user.sourceElement;

    HBasicBlock block = user.block;
    block.addAfter(user, interceptor);
    block.rewrite(user, interceptor);
    block.remove(user);
    return true;
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
    HInstruction instruction;
    if (selector.isGetter) {
      instruction = new HInvokeDynamicGetter(
          selector,
          node.element,
          <HInstruction>[constant, node.inputs[1]],
          node.instructionType);
    } else if (selector.isSetter) {
      instruction = new HInvokeDynamicSetter(
          selector,
          node.element,
          <HInstruction>[constant, node.inputs[1], node.inputs[2]],
          node.instructionType);
    } else {
      List<HInstruction> inputs = new List<HInstruction>.from(node.inputs);
      inputs[0] = constant;
      instruction = new HInvokeDynamicMethod(
          selector, inputs, node.instructionType, true);
    }

    HBasicBlock block = node.block;
    block.addAfter(node, instruction);
    block.rewrite(node, instruction);
    return true;
  }
}
