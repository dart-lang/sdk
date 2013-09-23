// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

abstract class SsaTypePropagator extends HBaseVisitor
    implements OptimizationPhase {

  final Map<int, HInstruction> workmap = new Map<int, HInstruction>();
  final List<int> worklist = new List<int>();
  final Map<HInstruction, Function> pendingOptimizations =
      new Map<HInstruction, Function>();  

  final Compiler compiler;
  String get name => 'type propagator';

  SsaTypePropagator(this.compiler);

  // Compute the (shared) type of the inputs if any. If all inputs
  // have the same known type return it. If any two inputs have
  // different known types, we'll return a conflict -- otherwise we'll
  // simply return an unknown type.
  HType computeInputsType(HPhi phi, bool ignoreUnknowns) {
    HType candidateType = HType.CONFLICTING;
    for (int i = 0, length = phi.inputs.length; i < length; i++) {
      HType inputType = phi.inputs[i].instructionType;
      if (inputType.isConflicting()) return HType.CONFLICTING;
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

  HType visitInvokeDynamic(HInvokeDynamic instruction) {
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

  HType visitTypeConversion(HTypeConversion instruction) {
    HType oldType = instruction.instructionType;
    // Do not change a checked mode check.
    if (instruction.isCheckedModeCheck) return oldType;
    // We must make sure a type conversion for receiver or argument check
    // does not try to do an int check, because an int check is not enough.
    // We only do an int check if the input is integer or null.
    HInstruction checked = instruction.checkedInput;
    if (oldType.isNumber()
        && !oldType.isDouble()
        && checked.isIntegerOrNull()) {
      return HType.INTEGER;
    } else if (oldType.isInteger() && !checked.isIntegerOrNull()) {
      return HType.NUMBER;
    }
    return oldType;
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
        HType type = new HType.nonNullSubclass(cls.rawType, compiler);
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
    // We want the righ error in checked mode.
    if (compiler.enableTypeAssertions) return false;
    HInstruction left = instruction.inputs[1];
    HType receiverType = left.instructionType;

    // A [HTypeGuard] holds the speculated type when it is being
    // inserted, so we go find the real receiver type.
    if (left is HTypeGuard) {
      var guard = left;
      while (guard is HTypeGuard && !guard.isEnabled) {
        guard = guard.checkedInput;
      }
      receiverType = guard.instructionType;
    }
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
        if (selector.isOperator()
            && selector.name != const SourceString('==')) {
          if (checkReceiver(instruction)) {
            addAllUsersBut(instruction, instruction.inputs[1]);
          }
          if (!selector.isUnaryOperator() && checkArgument(instruction)) {
            addAllUsersBut(instruction, instruction.inputs[2]);
          }
        }
      });
    }
    return super.visitInvokeDynamic(instruction);
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

  HType visitCheck(HCheck check) {
    // If the desired type of the input is already a number, we want
    // to specialize it to an integer.
    if (input == check.checkedInput
        && check.isInteger()
        && check.checkedInput.isNumberOrNull()) {
      return HType.INTEGER;
    }
    return HType.UNKNOWN;
  }

  HType visitTypeConversion(HTypeConversion check) {
    return HType.UNKNOWN;
  }

  HType visitInvokeDynamic(HInvokeDynamic instruction) {
    return instruction.specializer.computeDesiredTypeForInput(
        instruction, input, compiler);
  }

  HType visitPhi(HPhi phi) {
    // Best case scenario for a phi is, when all inputs have the same type. If
    // there is no desired outgoing type we therefore try to unify the input
    // types (which is basically the [likelyType]).
    HType propagatedType = phi.instructionType;

    // If the incoming type of a phi is an integer, we don't want to
    // be too restrictive for the back edge and desire an integer
    // too. Therefore we only return integer if the phi is used by a
    // bounds check, which includes an integer check.
    if (propagatedType.isInteger()) {
      if (phi.usedBy.any((user) => user is HBoundsCheck && user.index == phi)) {
        return propagatedType;
      }
      return HType.NUMBER;
    }
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
    HType desiredType = instruction.instructionType;
    for (final user in instruction.usedBy) {
      HType userDesiredType =  desiredTypeVisitor.computeDesiredTypeForInput(
          user, instruction);
      desiredType = desiredType.intersection(userDesiredType, compiler);
      // No need to continue if two users disagree on the type.
      if (desiredType.isConflicting()) break;
    }
    return desiredType;
  }
  
  bool hasBeenSpeculativelyOptimized(HInstruction instruction) {
    return savedTypes.containsKey(instruction);
  }

  HType computeType(HInstruction instruction) {
    // Once we are in a conflicting state don't update the type anymore.
    HType oldType = instruction.instructionType;
    if (oldType.isConflicting()) return oldType;

    HType newType = super.computeType(instruction);
    if (oldType != newType && !hasBeenSpeculativelyOptimized(instruction)) {
      savedTypes[instruction] = oldType;
    }
    // [computeDesiredType] goes to all usedBys and lets them compute their
    // desired type. By setting the [newType] here we give them more context to
    // work with.
    instruction.instructionType = newType;
    HType desiredType = computeDesiredType(instruction);
    // If the desired type is conflicting just return the computed type.
    if (desiredType.isConflicting()) return newType;
    if (desiredType.isUnknown() && hasBeenSpeculativelyOptimized(instruction)) {
      // If we ever change our decision for a desired type to unknown,
      // we stop the computation on this instruction.
      return HType.CONFLICTING;
    }
    // TODO(ngeoffray): Allow speculative optimizations on
    // non-primitive types?
    if (!desiredType.isPrimitive(compiler)) return newType;
    // It's not worth having a bailout method just because we want a
    // boolean. Comparing to true is enough.
    if (desiredType.isBooleanOrNull()) return newType;
    desiredType = newType.intersection(desiredType, compiler);
    if (desiredType != newType && !hasBeenSpeculativelyOptimized(instruction)) {
      savedTypes[instruction] = oldType;
    }
    return desiredType;
  }
}
