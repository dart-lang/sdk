// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SsaTypePropagator extends HGraphVisitor implements OptimizationPhase {

  final Map<int, HInstruction> workmap;
  final List<int> worklist;
  final Map<HInstruction, Function> pendingOptimizations;
  final HTypeMap types;

  final Compiler compiler;
  String get name => 'type propagator';

  SsaTypePropagator(this.compiler, this.types)
      : workmap = new Map<int, HInstruction>(),
        worklist = new List<int>(),
        pendingOptimizations = new Map<HInstruction, Function>();

  HType computeType(HInstruction instruction) {
    if (instruction.hasGuaranteedType()) return instruction.guaranteedType;
    return instruction.computeTypeFromInputTypes(types);
  }

  // Re-compute and update the type of the instruction. Returns
  // whether or not the type was changed.
  bool updateType(HInstruction instruction) {
    // The [updateType] method is invoked when one of the inputs of
    // the instruction changes its type. That gives us a new
    // opportunity to consider this instruction for optimizations.
    considerForArgumentTypeOptimization(instruction);
    // Compute old and new types.
    HType oldType = types[instruction];
    HType newType = computeType(instruction);
    // We unconditionally replace the propagated type with the new type. The
    // computeType must make sure that we eventually reach a stable state.
    types[instruction] = newType;
    return oldType != newType;
  }

  void considerForArgumentTypeOptimization(HInstruction instruction) {
    if (instruction is !HBinaryArithmetic) return;
    // Update the pending optimizations map based on the potentially
    // new types of the operands. If the operand types no longer allow
    // us to optimize, we remove the pending optimization.
    HBinaryArithmetic arithmetic = instruction;
    HInstruction left = arithmetic.left;
    HInstruction right = arithmetic.right;
    if (left.isNumber(types) && !right.isNumber(types)) {
      pendingOptimizations[instruction] = () {
        // This callback function is invoked after we're done
        // propagating types. The types shouldn't have changed.
        assert(left.isNumber(types) && !right.isNumber(types));
        convertInput(instruction, right, HType.NUMBER);
      };
    } else {
      pendingOptimizations.remove(instruction);
    }
  }

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
    processWorklist();
  }

  visitBasicBlock(HBasicBlock block) {
    if (block.isLoopHeader()) {
      block.forEachPhi((HPhi phi) {
        HType propagatedType = types[phi];
        // Once the propagation has run once, the propagated type can already
        // be set. In this case we use that one for the first iteration of the
        // loop.
        if (propagatedType.isUnknown()) {
          // Set the initial type for the phi. In theory we would need to mark
          // the type of all other incoming edges as "unitialized" and take this
          // into account when doing the propagation inside the phis. Just
          // setting the propagated type is however easier.
          types[phi] = types[phi.inputs[0]];
        }
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

  void addDependentInstructionsToWorkList(HInstruction instruction) {
    for (int i = 0, length = instruction.usedBy.length; i < length; i++) {
      // The non-speculative type propagator only propagates types forward. We
      // thus only need to add the users of the [instruction] to the list.
      addToWorkList(instruction.usedBy[i]);
    }
  }

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

  void convertInput(HInstruction instruction, HInstruction input, HType type) {
    HTypeConversion converted =
        new HTypeConversion.argumentTypeCheck(type, input);
    instruction.block.addBefore(instruction, converted);
    Set<HInstruction> dominatedUsers = input.dominatedUsers(instruction);
    for (HInstruction user in dominatedUsers) {
      user.changeUse(input, converted);
      addToWorkList(user);
    }
  }
}

class SsaSpeculativeTypePropagator extends SsaTypePropagator {
  final String name = 'speculative type propagator';
  SsaSpeculativeTypePropagator(Compiler compiler, HTypeMap types)
      : super(compiler, types);

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
      HType userType =
          user.computeDesiredTypeForInput(instruction, types);
      // Mainly due to the "if (true)" added by hackAroundPossiblyAbortingBody
      // in builder.dart uninitialized variables will propagate a type of null
      // which will result in a conflicting type when combined with a primitive
      // type. Avoid this to improve generated code.
      // TODO(sgjesse): Reconcider this when hackAroundPossiblyAbortingBody
      // has been removed.
      if (desiredType.isPrimitive() && userType == HType.NULL) continue;
      desiredType = desiredType.intersection(userType);
      // No need to continue if two users disagree on the type.
      if (desiredType.isConflicting()) break;
    }
    return desiredType;
  }

  HType computeType(HInstruction instruction) {
    // Once we are in a conflicting state don't update the type anymore.
    HType oldType = types[instruction];
    if (oldType.isConflicting()) return oldType;

    HType newType = super.computeType(instruction);
    // [computeDesiredType] goes to all usedBys and lets them compute their
    // desired type. By setting the [newType] here we give them more context to
    // work with.
    types[instruction] = newType;
    HType desiredType = computeDesiredType(instruction);
    // If the desired type is conflicting just return the computed type.
    if (desiredType.isConflicting()) return newType;
    // TODO(ngeoffray): Allow speculative optimizations on
    // non-primitive types?
    if (!desiredType.isPrimitive()) return newType;
    return newType.intersection(desiredType);
  }

  // Do not use speculative argument type optimization for now.
  void considerForArgumentTypeOptimization(HInstruction instruction) { }

}
