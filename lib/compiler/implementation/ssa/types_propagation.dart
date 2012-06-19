// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SsaTypePropagator extends HGraphVisitor implements OptimizationPhase {

  final Map<int, HInstruction> workmap;
  final List<int> worklist;
  final Compiler compiler;
  String get name() => 'type propagator';

  SsaTypePropagator(Compiler this.compiler)
      : workmap = new Map<int, HInstruction>(),
        worklist = new List<int>();


  HType computeType(HInstruction instruction) {
    if (instruction.hasGuaranteedType()) return instruction.guaranteedType;
    return instruction.computeTypeFromInputTypes();
  }

  // Re-compute and update the type of the instruction. Returns
  // whether or not the type was changed.
  bool updateType(HInstruction instruction) {
    // Visit the instruction before computing types.
    visitInstruction(instruction);
    // Compute old and new types.
    HType oldType = instruction.propagatedType;
    HType newType = computeType(instruction);
    // We unconditionally replace the propagated type with the new type. The
    // computeType must make sure that we eventually reach a stable state.
    instruction.propagatedType = newType;
    return oldType != newType;
  }

  void visitInstruction(HInstruction instruction) {
    if (instruction is !HBinaryArithmetic) return;
    HInstruction left = instruction.left;
    if (!left.isNumber()) return;
    HInstruction right = instruction.right;
    // TODO(floitsch): Enable this once we made it so inputs must be
    // integers for all bitwise operations.
    if (false && instruction is HBinaryBitOp) {
      if (!left.isInteger()) convertInput(instruction, left, HType.INTEGER);
      if (!right.isInteger()) convertInput(instruction, right, HType.INTEGER);
    } else {
      if (!right.isNumber()) convertInput(instruction, right, HType.NUMBER);
    }
  }

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
    processWorklist();
  }

  visitBasicBlock(HBasicBlock block) {
    if (block.isLoopHeader()) {
      block.forEachPhi((HPhi phi) {
        // Once the propagation has run once the propagated type can already
        // be set. In this case we use that one for the first iteration of the
        // loop.
        if (phi.propagatedType.isUnknown()) {
          // Set the initial type for the phi. In theory we would need to mark
          // the type of all other incoming edges as "unitialized" and take this
          // into account when doing the propagation inside the phis. Just
          // setting the [propagatedType] is however easier.
          phi.propagatedType = phi.inputs[0].propagatedType;
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
    while (instruction !== null) {
      if (updateType(instruction)) {
        addDependentInstructionsToWorkList(instruction);
      }
      instruction = instruction.next;
    }
  }

  void processWorklist() {
    while (!worklist.isEmpty()) {
      int id = worklist.removeLast();
      HInstruction instruction = workmap[id];
      assert(instruction !== null);
      workmap.remove(id);
      if (updateType(instruction)) {
        addDependentInstructionsToWorkList(instruction);
      }
    }
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

  void convertInput(HInstruction instruction, HInstruction input, HType type) {
    HTypeConversion converted =
        new HTypeConversion.argumentTypeCheck(type, input);
    instruction.block.addBefore(instruction, converted);
    instruction.changeUse(input, converted);
    replaceDominatedUses(input, converted);
  }

  // TODO(kasperl): Get rid of
  // SsaTypeConversionInserter.changeUsesDominatedBy because this is
  // just better.
  void replaceDominatedUses(HInstruction instruction,
                            HInstruction replacement) {
    // Keep track of all instructions that we have to deal with later
    // and count the number of them that are in the current block.
    Set<HInstruction> pending = null;
    int pendingInCurrentBlock = 0;

    // Run through all the users of the instruction and see if they
    // are dominated or potentially dominated by the replacement.
    HBasicBlock block = replacement.block;
    for (int i = 0, length = instruction.usedBy.length; i < length; i++) {
      HInstruction current = instruction.usedBy[i];
      if (current !== replacement && block.dominates(current.block)) {
        if (current.block === block) pendingInCurrentBlock++;
        if (pending === null) pending = new Set<HInstruction>();
        pending.add(current);
      }
    }

    // If there are no pending instructions, we're done.
    if (pending === null) return;

    // Run through all the instructions before the replacement and
    // remove them from the pending set.
    if (pendingInCurrentBlock > 0) {
      HInstruction current = block.first;
      while (current !== replacement) {
        if (pending.contains(current)) {
          pending.remove(current);
          if (--pendingInCurrentBlock == 0) break;
        }
        current = current.next;
      }
    }

    // Run through all the pending instructions. They are the
    // dominated users.
    for (HInstruction current in pending) {
      current.changeUse(instruction, replacement);
      if (updateType(current)) {
        addDependentInstructionsToWorkList(current);
      }
    }
  }
}

class SsaSpeculativeTypePropagator extends SsaTypePropagator {
  final String name = 'speculative type propagator';
  SsaSpeculativeTypePropagator(Compiler compiler) : super(compiler);

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
      HType userType = user.computeDesiredTypeForInput(instruction);
      desiredType = desiredType.intersection(userType);
      // No need to continue if two users disagree on the type.
      if (desiredType.isConflicting()) break;
    }
    return desiredType;
  }

  HType computeType(HInstruction instruction) {
    // Once we are in a conflicting state don't update the type anymore.
    HType oldType = instruction.propagatedType;
    if (oldType.isConflicting()) return oldType;

    HType newType = super.computeType(instruction);
    // [computeDesiredType] goes to all usedBys and lets them compute their
    // desired type. By setting the [newType] here we give them more context to
    // work with.
    instruction.propagatedType = newType;
    HType desiredType = computeDesiredType(instruction);
    // If the desired type is conflicting just return the computed type.
    if (desiredType.isConflicting()) return newType;
    // TODO(ngeoffray): Allow speculative optimizations on
    // non-primitive types?
    if (!desiredType.isPrimitive()) return newType;
    return newType.intersection(desiredType);
  }

  void visitInstruction(HInstruction instruction) { }

}
