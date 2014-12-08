// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

class SsaTypePropagator extends HBaseVisitor implements OptimizationPhase {
  final Map<int, HInstruction> workmap = new Map<int, HInstruction>();
  final List<int> worklist = new List<int>();
  final Map<HInstruction, Function> pendingOptimizations =
      new Map<HInstruction, Function>();

  final Compiler compiler;
  final ClassWorld classWorld;
  JavaScriptBackend get backend => compiler.backend;
  String get name => 'type propagator';

  SsaTypePropagator(Compiler compiler)
      : this.compiler = compiler,
        this.classWorld = compiler.world;

  TypeMask computeType(HInstruction instruction) {
    return instruction.accept(this);
  }

  // Re-compute and update the type of the instruction. Returns
  // whether or not the type was changed.
  bool updateType(HInstruction instruction) {
    // Compute old and new types.
    TypeMask oldType = instruction.instructionType;
    TypeMask newType = computeType(instruction);
    assert(newType != null);
    // We unconditionally replace the propagated type with the new type. The
    // computeType must make sure that we eventually reach a stable state.
    instruction.instructionType = newType;
    return oldType != newType;
  }

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
    processWorklist();
  }

  visitBasicBlock(HBasicBlock block) {
    if (block.isLoopHeader()) {
      block.forEachPhi((HPhi phi) {
        // Set the initial type for the phi. We're not using the type
        // the phi thinks it has because new optimizations may imply
        // changing it.
        // In theory we would need to mark
        // the type of all other incoming edges as "unitialized" and take this
        // into account when doing the propagation inside the phis. Just
        // setting the propagated type is however easier.
        phi.instructionType = phi.inputs[0].instructionType;
        addToWorkList(phi);
      });
    } else {
      block.forEachPhi((HPhi phi) {
        if (updateType(phi)) {
          addDependentInstructionsToWorkList(phi);
        }
      });
    }

    HInstruction instruction = block.first;
    while (instruction != null) {
      if (updateType(instruction)) {
        addDependentInstructionsToWorkList(instruction);
      }
      instruction = instruction.next;
    }
  }

  void processWorklist() {
    do {
      while (!worklist.isEmpty) {
        int id = worklist.removeLast();
        HInstruction instruction = workmap[id];
        assert(instruction != null);
        workmap.remove(id);
        if (updateType(instruction)) {
          addDependentInstructionsToWorkList(instruction);
        }
      }
      // While processing the optimizable arithmetic instructions, we
      // may discover better type information for dominated users of
      // replaced operands, so we may need to take another stab at
      // emptying the worklist afterwards.
      processPendingOptimizations();
    } while (!worklist.isEmpty);
  }


  void addToWorkList(HInstruction instruction) {
    final int id = instruction.id;

    if (!workmap.containsKey(id)) {
      worklist.add(id);
      workmap[id] = instruction;
    }
  }

  TypeMask visitBinaryArithmetic(HBinaryArithmetic instruction) {
    HInstruction left = instruction.left;
    HInstruction right = instruction.right;
    if (left.isInteger(compiler) && right.isInteger(compiler)) {
      return backend.intType;
    }
    if (left.isDouble(compiler)) return backend.doubleType;
    return backend.numType;
  }

  TypeMask checkPositiveInteger(HBinaryArithmetic instruction) {
    HInstruction left = instruction.left;
    HInstruction right = instruction.right;
    if (left.isPositiveInteger(compiler) && right.isPositiveInteger(compiler)) {
      return backend.positiveIntType;
    }
    return visitBinaryArithmetic(instruction);
  }

  TypeMask visitMultiply(HMultiply instruction) {
    return checkPositiveInteger(instruction);
  }

  TypeMask visitAdd(HAdd instruction) {
    return checkPositiveInteger(instruction);
  }

  TypeMask visitNegate(HNegate instruction) {
    HInstruction operand = instruction.operand;
    // We have integer subclasses that represent ranges, so widen any int
    // subclass to full integer.
    if (operand.isInteger(compiler)) return backend.intType;
    return instruction.operand.instructionType;
  }

  TypeMask visitInstruction(HInstruction instruction) {
    assert(instruction.instructionType != null);
    return instruction.instructionType;
  }

  TypeMask visitPhi(HPhi phi) {
    TypeMask candidateType = backend.emptyType;
    for (int i = 0, length = phi.inputs.length; i < length; i++) {
      TypeMask inputType = phi.inputs[i].instructionType;
      candidateType = candidateType.union(inputType, classWorld);
    }
    return candidateType;
  }

  TypeMask visitTypeConversion(HTypeConversion instruction) {
    HInstruction input = instruction.checkedInput;
    TypeMask inputType = input.instructionType;
    TypeMask checkedType = instruction.checkedType;
    if (instruction.isArgumentTypeCheck || instruction.isReceiverTypeCheck) {
      // We must make sure a type conversion for receiver or argument check
      // does not try to do an int check, because an int check is not enough.
      // We only do an int check if the input is integer or null.
      if (checkedType.containsOnlyNum(classWorld)
          && !checkedType.containsOnlyDouble(classWorld)
          && input.isIntegerOrNull(compiler)) {
        instruction.checkedType = backend.intType;
      } else if (checkedType.containsOnlyInt(classWorld)
                 && !input.isIntegerOrNull(compiler)) {
        instruction.checkedType = backend.numType;
      }
    }

    TypeMask outputType = checkedType.intersection(inputType, classWorld);
    if (outputType.isEmpty && !outputType.isNullable) {
      // Intersection of double and integer conflicts (is empty), but JS numbers
      // can be both int and double at the same time.  For example, the input
      // can be a literal double '8.0' that is marked as an integer (because 'is
      // int' will return 'true').  What we really need to do is make the
      // overlap between int and double values explicit in the TypeMask system.
      if (inputType.containsOnlyInt(classWorld)
          && checkedType.containsOnlyDouble(classWorld)) {
        if (inputType.isNullable && checkedType.isNullable) {
          outputType = backend.doubleType.nullable();
        } else {
          outputType = backend.doubleType;
        }
      }
    }
    if (inputType != outputType) {
      input.replaceAllUsersDominatedBy(instruction.next, instruction);
    }
    return outputType;
  }

  TypeMask visitTypeKnown(HTypeKnown instruction) {
    HInstruction input = instruction.checkedInput;
    TypeMask inputType = input.instructionType;
    TypeMask outputType =
        instruction.knownType.intersection(inputType, classWorld);
    if (inputType != outputType) {
      input.replaceAllUsersDominatedBy(instruction.next, instruction);
    }
    return outputType;
  }

  void convertInput(HInvokeDynamic instruction,
                    HInstruction input,
                    TypeMask type,
                    int kind) {
    Selector selector = (kind == HTypeConversion.RECEIVER_TYPE_CHECK)
        ? instruction.selector
        : null;
    HTypeConversion converted = new HTypeConversion(
        null, kind, type, input, selector);
    instruction.block.addBefore(instruction, converted);
    input.replaceAllUsersDominatedBy(instruction, converted);
  }

  bool isCheckEnoughForNsmOrAe(HInstruction instruction,
                               TypeMask type) {
    // In some cases, we want the receiver to be an integer,
    // but that does not mean we will get a NoSuchMethodError
    // if it's not: the receiver could be a double.
    if (type.containsOnlyInt(classWorld)) {
      // If the instruction's type is integer or null, the codegen
      // will emit a null check, which is enough to know if it will
      // hit a noSuchMethod.
      return instruction.isIntegerOrNull(compiler);
    }
    return true;
  }

  // Add a receiver type check when the call can only hit
  // [noSuchMethod] if the receiver is not of a specific type.
  // Return true if the receiver type check was added.
  bool checkReceiver(HInvokeDynamic instruction) {
    assert(instruction.isInterceptedCall);
    HInstruction receiver = instruction.inputs[1];
    if (receiver.isNumber(compiler)) return false;
    if (receiver.isNumberOrNull(compiler)) {
      convertInput(instruction,
                   receiver,
                   receiver.instructionType.nonNullable(),
                   HTypeConversion.RECEIVER_TYPE_CHECK);
      return true;
    } else if (instruction.element == null) {
      Iterable<Element> targets =
          compiler.world.allFunctions.filter(instruction.selector);
      if (targets.length == 1) {
        Element target = targets.first;
        ClassElement cls = target.enclosingClass;
        TypeMask type = new TypeMask.nonNullSubclass(
            cls.declaration, classWorld);
        // TODO(ngeoffray): We currently only optimize on primitive
        // types.
        if (!type.satisfies(backend.jsIndexableClass, classWorld) &&
            !type.containsOnlyNum(classWorld) &&
            !type.containsOnlyBool(classWorld)) {
          return false;
        }
        if (!isCheckEnoughForNsmOrAe(receiver, type)) return false;
        instruction.element = target;
        convertInput(instruction,
                     receiver,
                     type,
                     HTypeConversion.RECEIVER_TYPE_CHECK);
        return true;
      }
    }
    return false;
  }

  // Add an argument type check if the argument is not of a type
  // expected by the call.
  // Return true if the argument type check was added.
  bool checkArgument(HInvokeDynamic instruction) {
    // We want the right error in checked mode.
    if (compiler.enableTypeAssertions) return false;
    HInstruction left = instruction.inputs[1];
    HInstruction right = instruction.inputs[2];

    Selector selector = instruction.selector;
    if (selector.isOperator && left.isNumber(compiler)) {
      if (right.isNumber(compiler)) return false;
      TypeMask type = right.isIntegerOrNull(compiler)
          ? right.instructionType.nonNullable()
          : backend.numType;
      // TODO(ngeoffray): Some number operations don't have a builtin
      // variant and will do the check in their method anyway. We
      // still add a check because it allows to GVN these operations,
      // but we should find a better way.
      convertInput(instruction,
                   right,
                   type,
                   HTypeConversion.ARGUMENT_TYPE_CHECK);
      return true;
    }
    return false;
  }

  void processPendingOptimizations() {
    pendingOptimizations.forEach((instruction, action) => action());
    pendingOptimizations.clear();
  }

  void addDependentInstructionsToWorkList(HInstruction instruction) {
    for (int i = 0, length = instruction.usedBy.length; i < length; i++) {
      // The type propagator only propagates types forward. We
      // thus only need to add the users of the [instruction] to the list.
      addToWorkList(instruction.usedBy[i]);
    }
  }

  void addAllUsersBut(HInvokeDynamic invoke, HInstruction instruction) {
    instruction.usedBy.forEach((HInstruction user) {
      if (user != invoke) addToWorkList(user);
    });
  }

  TypeMask visitInvokeDynamic(HInvokeDynamic instruction) {
    if (instruction.isInterceptedCall) {
      // We cannot do the following optimization now, because we have
      // to wait for the type propagation to be stable. The receiver
      // of [instruction] might move from number to dynamic.
      pendingOptimizations.putIfAbsent(instruction, () => () {
        Selector selector = instruction.selector;
        if (selector.isOperator && selector.name != '==') {
          if (checkReceiver(instruction)) {
            addAllUsersBut(instruction, instruction.inputs[1]);
          }
          if (!selector.isUnaryOperator && checkArgument(instruction)) {
            addAllUsersBut(instruction, instruction.inputs[2]);
          }
        }
      });
    }

    HInstruction receiver = instruction.getDartReceiver(compiler);
    TypeMask receiverType = receiver.instructionType;
    Selector selector =
        new TypedSelector(receiverType, instruction.selector, classWorld);
    instruction.selector = selector;

    // Try to specialize the receiver after this call.
    if (receiver.dominatedUsers(instruction).length != 1
        && !selector.isClosureCall) {
      TypeMask newType = compiler.world.allFunctions.receiverType(selector);
      newType = newType.intersection(receiverType, classWorld);
      var next = instruction.next;
      if (next is HTypeKnown && next.checkedInput == receiver) {
        // We already have refined [receiver]. We still update the
        // type of the [HTypeKnown] instruction because it may have
        // been refined with a correct type at the time, but
        // incorrect now.
        if (next.instructionType != newType) {
          next.knownType = next.instructionType = newType;
          addDependentInstructionsToWorkList(next);
        }
      } else if (newType != receiverType) {
        // Insert a refinement node after the call and update all
        // users dominated by the call to use that node instead of
        // [receiver].
        HTypeKnown converted =
            new HTypeKnown.witnessed(newType, receiver, instruction);
        instruction.block.addBefore(instruction.next, converted);
        receiver.replaceAllUsersDominatedBy(converted.next, converted);
        addDependentInstructionsToWorkList(converted);
      }
    }

    return instruction.specializer.computeTypeFromInputTypes(
        instruction, compiler);
  }
}
