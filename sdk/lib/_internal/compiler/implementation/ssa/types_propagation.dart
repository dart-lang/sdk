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
  String get name => 'type propagator';

  SsaTypePropagator(this.compiler);

  HType computeType(HInstruction instruction) {
    return instruction.accept(this);
  }

  // Re-compute and update the type of the instruction. Returns
  // whether or not the type was changed.
  bool updateType(HInstruction instruction) {
    // Compute old and new types.
    HType oldType = instruction.instructionType;
    HType newType = computeType(instruction);
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

  HType visitBinaryArithmetic(HBinaryArithmetic instruction) {
    HInstruction left = instruction.left;
    HInstruction right = instruction.right;
    if (left.isInteger() && right.isInteger()) return HType.INTEGER;
    if (left.isDouble()) return HType.DOUBLE;
    return HType.NUMBER;
  }

  HType visitNegate(HNegate instruction) {
    return instruction.operand.instructionType;
  }

  HType visitInstruction(HInstruction instruction) {
    assert(instruction.instructionType != null);
    return instruction.instructionType;
  }

  HType visitPhi(HPhi phi) {
    HType candidateType = HType.CONFLICTING;
    for (int i = 0, length = phi.inputs.length; i < length; i++) {
      HType inputType = phi.inputs[i].instructionType;
      candidateType = candidateType.union(inputType, compiler);
    }
    return candidateType;
  }

  HType visitTypeConversion(HTypeConversion instruction) {
    HType inputType = instruction.checkedInput.instructionType;
    HType checkedType = instruction.checkedType;
    if (instruction.isArgumentTypeCheck || instruction.isReceiverTypeCheck) {
      // We must make sure a type conversion for receiver or argument check
      // does not try to do an int check, because an int check is not enough.
      // We only do an int check if the input is integer or null.
      if (checkedType.isNumber()
          && !checkedType.isDouble()
          && inputType.isIntegerOrNull()) {
        instruction.checkedType = HType.INTEGER;
      } else if (checkedType.isInteger() && !inputType.isIntegerOrNull()) {
        instruction.checkedType = HType.NUMBER;
      }
    }

    HType outputType = checkedType.intersection(inputType, compiler);
    if (outputType.isConflicting()) {
      // Intersection of double and integer conflicts (is empty), but JS numbers
      // can be both int and double at the same time.  For example, the input
      // can be a literal double '8.0' that is marked as an integer (because 'is
      // int' will return 'true').  What we really need to do is make the
      // overlap between int and double values explicit in the HType system.
      if (inputType.isIntegerOrNull() && checkedType.isDoubleOrNull()) {
        if (inputType.canBeNull() && checkedType.canBeNull()) {
          outputType = HType.DOUBLE_OR_NULL;
        } else {
          outputType = HType.DOUBLE;
        }
      }
    }
    return outputType;
  }

  HType visitTypeKnown(HTypeKnown instruction) {
    HInstruction input = instruction.checkedInput;
    return instruction.knownType.intersection(input.instructionType, compiler);
  }

  void convertInput(HInvokeDynamic instruction,
                    HInstruction input,
                    HType type,
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
                               HType type) {
    // In some cases, we want the receiver to be an integer,
    // but that does not mean we will get a NoSuchMethodError
    // if it's not: the receiver could be a double.
    if (type.isInteger()) {
      // If the instruction's type is integer or null, the codegen
      // will emit a null check, which is enough to know if it will
      // hit a noSuchMethod.
      return instruction.instructionType.isIntegerOrNull();
    }
    return true;
  }

  // Add a receiver type check when the call can only hit
  // [noSuchMethod] if the receiver is not of a specific type.
  // Return true if the receiver type check was added.
  bool checkReceiver(HInvokeDynamic instruction) {
    HInstruction receiver = instruction.inputs[1];
    if (receiver.isNumber()) return false;
    if (receiver.isNumberOrNull()) {
      convertInput(instruction,
                   receiver,
                   receiver.instructionType.nonNullable(compiler),
                   HTypeConversion.RECEIVER_TYPE_CHECK);
      return true;
    } else if (instruction.element == null) {
      Iterable<Element> targets =
          compiler.world.allFunctions.filter(instruction.selector);
      if (targets.length == 1) {
        Element target = targets.first;
        ClassElement cls = target.getEnclosingClass();
        HType type = new HType.nonNullSubclass(cls, compiler);
        // TODO(ngeoffray): We currently only optimize on primitive
        // types.
        if (!type.isPrimitive(compiler)) return false;
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
    HType receiverType = left.instructionType;

    HInstruction right = instruction.inputs[2];
    Selector selector = instruction.selector;
    if (selector.isOperator() && receiverType.isNumber()) {
      if (right.isNumber()) return false;
      HType type = right.isIntegerOrNull() ? HType.INTEGER : HType.NUMBER;
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

  HType visitInvokeDynamic(HInvokeDynamic instruction) {
    if (instruction.isInterceptedCall) {
      // We cannot do the following optimization now, because we have
      // to wait for the type propagation to be stable. The receiver
      // of [instruction] might move from number to dynamic.
      pendingOptimizations.putIfAbsent(instruction, () => () {
        Selector selector = instruction.selector;
        if (selector.isOperator() && selector.name != '==') {
          if (checkReceiver(instruction)) {
            addAllUsersBut(instruction, instruction.inputs[1]);
          }
          if (!selector.isUnaryOperator() && checkArgument(instruction)) {
            addAllUsersBut(instruction, instruction.inputs[2]);
          }
        }
      });
    }

    HInstruction receiver = instruction.getDartReceiver(compiler);
    HType receiverType = receiver.instructionType;
    Selector selector = receiverType.refine(instruction.selector, compiler);
    instruction.selector = selector;

    // Try to specialize the receiver after this call.
    if (receiver.dominatedUsers(instruction).length != 1
        && !selector.isClosureCall()) {
      TypeMask oldMask = receiverType.computeMask(compiler);
      TypeMask newMask = compiler.world.allFunctions.receiverType(selector);
      newMask = newMask.intersection(oldMask, compiler);

      if (newMask != oldMask) {
        HType newType = new HType.fromMask(newMask, compiler);
        var next = instruction.next;
        if (next is HTypeKnown && next.checkedInput == receiver) {
          // We already have refined [receiver].
          HType nextType = next.instructionType;
          if (nextType != newType) {
            next.knownType = next.instructionType = newType;
            addDependentInstructionsToWorkList(next);
          }
        } else {
          // Insert a refinement node after the call and update all
          // users dominated by the call to use that node instead of
          // [receiver].
          HTypeKnown converted = new HTypeKnown(newType, receiver);
          instruction.block.addBefore(instruction.next, converted);
          receiver.replaceAllUsersDominatedBy(converted.next, converted);
          addDependentInstructionsToWorkList(converted);
        }
      }
    }

    return instruction.specializer.computeTypeFromInputTypes(
        instruction, compiler);
  }
}
