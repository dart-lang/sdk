// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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


  HType computeType(HInstruction instruction) => instruction.computeType();

  // Re-compute and update the type of the instruction. Returns
  // whether or not the type was changed.
  bool updateType(HInstruction instruction) {
    if (instruction.type.isConflicting()) return false;
    // Constants have the type they have. It can't be changed.
    if (instruction.isConstant()) return false;

    HType oldType = instruction.type;
    HType newType = computeType(instruction);
    instruction.type = oldType.combine(newType);
    return oldType !== instruction.type;
  }

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
    processWorklist();
  }

  visitBasicBlock(HBasicBlock block) {
    if (block.isLoopHeader()) {
      block.forEachPhi((HPhi phi) {
        // Set the initial type for the phi.
        phi.type = phi.inputs[0].type;
        addToWorkList(phi);
      });
    } else {
      block.forEachPhi((HPhi phi) {
        if (updateType(phi)) addUsersAndInputsToWorklist(phi);
      });
    }

    HInstruction instruction = block.first;
    while (instruction !== null) {
      if (updateType(instruction)) addUsersAndInputsToWorklist(instruction);
      instruction = instruction.next;
    }
  }

  void processWorklist() {
    while (!worklist.isEmpty()) {
      int id = worklist.removeLast();
      HInstruction instruction = workmap[id];
      assert(instruction !== null);
      workmap.remove(id);
      if (updateType(instruction)) addUsersAndInputsToWorklist(instruction);
    }
  }

  void addUsersAndInputsToWorklist(HInstruction instruction) {
    for (int i = 0, length = instruction.usedBy.length; i < length; i++) {
      addToWorkList(instruction.usedBy[i]);
    }
    for (int i = 0, length = instruction.inputs.length; i < length; i++) {
      addToWorkList(instruction.inputs[i]);
    }
  }

  void addToWorkList(HInstruction instruction) {
    final int id = instruction.id;
    if (!workmap.containsKey(id)) {
      worklist.add(id);
      workmap[id] = instruction;
    }
  }
}

class SsaSpeculativeTypePropagator extends SsaTypePropagator {
  final String name = 'speculative type propagator';
  SsaSpeculativeTypePropagator(Compiler compiler) : super(compiler);

  HType computeType(HInstruction instruction) {
    HType newType = super.computeType(instruction);
    HType desiredType = instruction.computeDesiredType();
    HType combined = newType.combine(desiredType);
    // If the propagated type [newType] does not conflict with the
    // speculated type [desiredType], use it.
    if (combined.isKnown()) return combined;
    return newType;
  }
}
