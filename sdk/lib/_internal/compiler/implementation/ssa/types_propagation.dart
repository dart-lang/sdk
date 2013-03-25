// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

abstract class SsaTypePropagator extends HBaseVisitor
    implements OptimizationPhase {

  final Map<int, HInstruction> workmap;
  final List<int> worklist;
  final Map<HInstruction, Function> pendingOptimizations;

  final Compiler compiler;
  String get name => 'type propagator';

  SsaTypePropagator(this.compiler)
      : workmap = new Map<int, HInstruction>(),
        worklist = new List<int>(),
        pendingOptimizations = new Map<HInstruction, Function>();

  // Compute the (shared) type of the inputs if any. If all inputs
  // have the same known type return it. If any two inputs have
  // different known types, we'll return a conflict -- otherwise we'll
  // simply return an unknown type.
  HType computeInputsType(HPhi phi, bool ignoreUnknowns) {
    HType candidateType = HType.CONFLICTING;
    for (int i = 0, length = phi.inputs.length; i < length; i++) {
      HType inputType = phi.inputs[i].instructionType;
      if (ignoreUnknowns && inputType.isUnknown()) continue;
      // Phis need to combine the incoming types using the union operation.
      // For example, if one incoming edge has type integer and the other has
      // type double, then the phi is either an integer or double and thus has
      // type number.
      candidateType = candidateType.union(inputType, compiler);
      if (candidateType.isUnknown()) return HType.UNKNOWN;
    }
    return candidateType;
  }

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

  void addDependentInstructionsToWorkList(HInstruction instruction) {}

  void addToWorkList(HInstruction instruction) {
    final int id = instruction.id;

    if (!workmap.containsKey(id)) {
      worklist.add(id);
      workmap[id] = instruction;
    }
  }

  void processPendingOptimizations() {
    pendingOptimizations.forEach((instruction, action) => action());
    pendingOptimizations.clear();
  }

  HType visitInvokeDynamic(HInvokeDynamic instruction) {
    HType receiverType = instruction.getDartReceiver(compiler).instructionType;
    Selector refined = receiverType.refine(instruction.selector, compiler);
    HType type = new HType.inferredTypeForSelector(refined, compiler);
    if (type.isUseful()) return type;
    return instruction.specializer.computeTypeFromInputTypes(
        instruction, compiler);
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
    HType inputsType = computeInputsType(phi, false);
    if (inputsType.isConflicting()) return HType.UNKNOWN;
    return inputsType;
  }
}

class SsaNonSpeculativeTypePropagator extends SsaTypePropagator {
  final String name = 'non speculative type propagator';
  DesiredTypeVisitor desiredTypeVisitor;
  SsaNonSpeculativeTypePropagator(Compiler compiler) : super(compiler);

  void addDependentInstructionsToWorkList(HInstruction instruction) {
    for (int i = 0, length = instruction.usedBy.length; i < length; i++) {
      // The non-speculative type propagator only propagates types forward. We
      // thus only need to add the users of the [instruction] to the list.
      addToWorkList(instruction.usedBy[i]);
    }
  }

  void convertInput(HInstruction instruction, HInstruction input, HType type) {
    HTypeConversion converted = new HTypeConversion(
        null, HTypeConversion.ARGUMENT_TYPE_CHECK, type, input);
    instruction.block.addBefore(instruction, converted);
    Set<HInstruction> dominatedUsers = input.dominatedUsers(instruction);
    for (HInstruction user in dominatedUsers) {
      user.changeUse(input, converted);
      addToWorkList(user);
    }
  }

  HType visitInvokeDynamicMethod(HInvokeDynamicMethod instruction) {
    // Update the pending optimizations map based on the potentially
    // new types of the operands. If the operand types no longer allow
    // us to optimize, we remove the pending optimization.
    if (instruction.specializer is BinaryArithmeticSpecializer) {
      HInstruction left = instruction.inputs[1];
      HInstruction right = instruction.inputs[2];
      if (left.isNumber() && !right.isNumber()) {
        pendingOptimizations[instruction] = () {
          // This callback function is invoked after we're done
          // propagating types. The types shouldn't have changed.
          assert(left.isNumber() && !right.isNumber());
          convertInput(instruction, right, HType.NUMBER);
        };
      } else {
        pendingOptimizations.remove(instruction);
      }
    }
    return super.visitInvokeDynamicMethod(instruction);
  }
}

/**
 * Visitor whose methods return the desired type for the input of an
 * instruction.
 */
class DesiredTypeVisitor extends HBaseVisitor {
  final Compiler compiler;
  final SsaTypePropagator propagator;
  HInstruction input;

  DesiredTypeVisitor(this.compiler, this.propagator);

  HType visitInstruction(HInstruction instruction) {
    return HType.UNKNOWN;
  }

  HType visitIntegerCheck(HIntegerCheck instruction) {
    // If the desired type of the input is already a number, we want
    // to specialize it to an integer.
    return input.isNumber() ? HType.INTEGER : HType.UNKNOWN;
  }

  HType visitInvokeDynamic(HInvokeDynamic instruction) {
    return instruction.specializer.computeDesiredTypeForInput(
        instruction, input, compiler);
  }

  HType visitNot(HNot instruction) {
    return HType.BOOLEAN;
  }

  HType visitPhi(HPhi phi) {
    HType propagatedType = phi.instructionType;
    // Best case scenario for a phi is, when all inputs have the same type. If
    // there is no desired outgoing type we therefore try to unify the input
    // types (which is basically the [likelyType]).
    if (propagatedType.isUnknown()) return computeLikelyType(phi);
    // When the desired outgoing type is conflicting we don't need to give any
    // requirements on the inputs.
    if (propagatedType.isConflicting()) return HType.UNKNOWN;
    // Otherwise the input type must match the desired outgoing type.
    return propagatedType;
  }

  HType computeLikelyType(HPhi phi) {
    HType agreedType = propagator.computeInputsType(phi, true);
    if (agreedType.isConflicting()) return HType.UNKNOWN;
    // Don't be too restrictive. If the agreed type is integer or double just
    // say that the likely type is number. If more is expected the type will be
    // propagated back.
    if (agreedType.isNumber()) return HType.NUMBER;
    return agreedType;
  }

  HType visitInterceptor(HInterceptor instruction) {
    if (instruction.interceptedClasses.length != 1) return HType.UNKNOWN;
    // If the only class being intercepted is of type number, we
    // make this interceptor call say it wants that class as input.
    Element interceptor = instruction.interceptedClasses.toList()[0];
    JavaScriptBackend backend = compiler.backend;
    if (interceptor == backend.jsNumberClass) {
      return HType.NUMBER;
    } else if (interceptor == backend.jsIntClass) {
      return HType.INTEGER;
    } else if (interceptor == backend.jsDoubleClass) {
      return HType.DOUBLE;
    }
    return HType.UNKNOWN;
  }

  HType computeDesiredTypeForInput(HInstruction user, HInstruction input) {
    this.input = input;
    HType desired = user.accept(this);
    this.input = null;
    return desired;
  }
}

class SsaSpeculativeTypePropagator extends SsaTypePropagator {
  final String name = 'speculative type propagator';
  DesiredTypeVisitor desiredTypeVisitor;
  final Map<HInstruction, HType> savedTypes;
  SsaSpeculativeTypePropagator(Compiler compiler, this.savedTypes)
      : super(compiler) {
    desiredTypeVisitor = new DesiredTypeVisitor(compiler, this);
  }

  void addDependentInstructionsToWorkList(HInstruction instruction) {
    // The speculative type propagator propagates types forward and backward.
    // Not only do we need to add the users of the [instruction] to the list.
    // We also need to add the inputs fo the [instruction], since they might
    // want to propagate the desired outgoing type.
    for (int i = 0, length = instruction.usedBy.length; i < length; i++) {
      addToWorkList(instruction.usedBy[i]);
    }
    for (int i = 0, length = instruction.inputs.length; i < length; i++) {
      addToWorkList(instruction.inputs[i]);
    }
  }

  HType computeDesiredType(HInstruction instruction) {
    HType desiredType = HType.UNKNOWN;
    for (final user in instruction.usedBy) {
      HType userDesiredType =  desiredTypeVisitor.computeDesiredTypeForInput(
          user, instruction);
      desiredType = desiredType.intersection(userDesiredType, compiler);
      // No need to continue if two users disagree on the type.
      if (desiredType.isConflicting()) break;
    }
    return desiredType;
  }

  HType computeType(HInstruction instruction) {
    // Once we are in a conflicting state don't update the type anymore.
    HType oldType = instruction.instructionType;
    if (oldType.isConflicting()) return oldType;

    HType newType = super.computeType(instruction);
    if (oldType != newType && !savedTypes.containsKey(instruction)) {
      savedTypes[instruction] = oldType;
    }
    // [computeDesiredType] goes to all usedBys and lets them compute their
    // desired type. By setting the [newType] here we give them more context to
    // work with.
    instruction.instructionType = newType;
    HType desiredType = computeDesiredType(instruction);
    // If the desired type is conflicting just return the computed type.
    if (desiredType.isConflicting()) return newType;
    // TODO(ngeoffray): Allow speculative optimizations on
    // non-primitive types?
    if (!desiredType.isPrimitive()) return newType;
    desiredType = newType.intersection(desiredType, compiler);
    if (desiredType != newType && !savedTypes.containsKey(instruction)) {
      savedTypes[instruction] = oldType;
    }
    return desiredType;
  }
}
