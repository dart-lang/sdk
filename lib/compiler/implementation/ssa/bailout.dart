// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BailoutInfo {
  int instructionId;
  int bailoutId;
  BailoutInfo(this.instructionId, this.bailoutId);
}

/**
 * Keeps track of the execution environment for instructions. An
 * execution environment contains the SSA instructions that are live.
 */
class Environment {
  final Set<HInstruction> lives;
  final Set<HBasicBlock> loopMarkers;
  Environment() : lives = new Set<HInstruction>(),
                  loopMarkers = new Set<HBasicBlock>();
  Environment.from(Environment other)
    : lives = new Set<HInstruction>.from(other.lives),
      loopMarkers = new Set<HBasicBlock>.from(other.loopMarkers);

  Environment.forLoopBody(Environment other)
    : lives = new Set<HInstruction>(),
      loopMarkers = new Set<HBasicBlock>.from(other.loopMarkers);

  void remove(HInstruction instruction) {
    lives.remove(instruction);
  }

  void add(HInstruction instruction) {
    if (!instruction.isCodeMotionInvariant()) {
      lives.add(instruction);
    } else {
      for (int i = 0, len = instruction.inputs.length; i < len; i++) {
        add(instruction.inputs[i]);
      }
    }
  }

  void addLoopMarker(HBasicBlock block) {
    loopMarkers.add(block);
  }

  void removeLoopMarker(HBasicBlock block) {
    loopMarkers.remove(block);
  }

  void addAll(Environment other) {
    lives.addAll(other.lives);
    loopMarkers.addAll(other.loopMarkers);
  }

  /**
   * Stores all live variables in the guard. The guarded instruction will be the
   * last input in the guard's input list.
   */
  void storeInGuard(HTypeGuard guard) {
    HInstruction guarded = guard.guarded;
    List<HInstruction> inputs = guard.inputs;
    assert(inputs.length == 1);
    inputs.clear();
    // Remove the guarded from the environment, so that we are sure it is last
    // when we add it again.
    remove(guarded);
    inputs.addAll(lives);
    inputs.addLast(guarded);
    add(guarded);
    for (int i = 0; i < inputs.length - 1; i++) {
      HInstruction input = inputs[i];
      input.usedBy.add(guard);
    }
  }

  bool isEmpty() => lives.isEmpty();
  bool contains(HInstruction instruction) => lives.contains(instruction);
  bool containsLoopMarker(HBasicBlock block) => loopMarkers.contains(block);
  void clear() => lives.clear();
}


/**
 * Visits the graph in dominator order and inserts TypeGuards in places where
 * we consider the guard to be of value.
 *
 * Might modify the [:propagatedType:] fields of the instructions in an
 * inconsistent way. No further analysis should rely on them.
 */
class SsaTypeGuardInserter extends HGraphVisitor implements OptimizationPhase {
  final String name = 'SsaTypeGuardInserter';
  final WorkItem work;
  int stateId = 1;

  SsaTypeGuardInserter(this.work);

  void visitGraph(HGraph graph) {
    work.guards = <HTypeGuard>[];
    visitDominatorTree(graph);
  }

  void visitBasicBlock(HBasicBlock block) {
    block.forEachPhi(visitInstruction);

    HInstruction instruction = block.first;
    while (instruction !== null) {
      // Note that visitInstruction (from the phis and here) might insert an
      // HTypeGuard instruction. We have to skip those.
      if (instruction is !HTypeGuard) visitInstruction(instruction);
      instruction = instruction.next;
    }
  }

  bool shouldInsertTypeGuard(HInstruction instruction) {
    HType speculativeType = instruction.propagatedType;
    HType computedType = instruction.computeTypeFromInputTypes();
    // Start by reverting the propagated type. If we add a type guard then the
    // guard will expose the speculative type. If we don't add a type guard
    // then this avoids subsequent instructions to use the the wrong type.
    //
    // Note that just setting the propagatedType of the instruction is not
    // complete since the type could lead to a phi node which in turn could
    // change the computedType. In this case we might miss some guards we
    // would have liked to insert. Most of the time this should however be
    // fine, due to dominator-order visiting.
    instruction.propagatedType = computedType;

    if (!speculativeType.isUseful()) return false;
    // If the types agree we don't need to check.
    if (speculativeType == computedType) return false;
    // TODO(floitsch): Make the creation of type guards more conditional.
    return true;
  }

  void visitInstruction(HInstruction instruction) {
    HType speculativeType = instruction.propagatedType;
    if (shouldInsertTypeGuard(instruction)) {
      List<HInstruction> inputs = <HInstruction>[instruction];
      HTypeGuard guard = new HTypeGuard(speculativeType, stateId++, inputs);
      guard.propagatedType = speculativeType;
      work.guards.add(guard);
      instruction.block.rewrite(instruction, guard);
      HInstruction insertionPoint = (instruction is HPhi)
          ? instruction.block.first
          : instruction.next;
      insertionPoint.block.addBefore(insertionPoint, guard);
    }
  }
}

/**
 * Computes the environment for each SSA instruction: visits the graph
 * in post-dominator order. Removes an instruction from the environment
 * and adds its inputs to the environment at the instruction's
 * definition.
 *
 * At the end of the computation, insert type guards in the graph.
 */
class SsaEnvironmentBuilder extends HBaseVisitor implements OptimizationPhase {
  final Compiler compiler;
  final String name = 'SsaEnvironmentBuilder';
  Environment environment;
  SubGraph subGraph;

  final Map<HInstruction, Environment> capturedEnvironments;

  SsaEnvironmentBuilder(Compiler this.compiler)
    : capturedEnvironments = new Map<HInstruction, Environment>();


  void visitGraph(HGraph graph) {
    subGraph = new SubGraph(graph.entry, graph.exit);
    environment = new Environment();
    visitBasicBlock(graph.entry);
    if (!environment.isEmpty()) {
      compiler.internalError('Bailout environment computation',
          node: compiler.currentElement.parseNode(compiler));
    }
    insertCapturedEnvironments();
  }

  void visitSubGraph(SubGraph newSubGraph) {
    SubGraph oldSubGraph = subGraph;
    subGraph = newSubGraph;
    visitBasicBlock(subGraph.start);
    subGraph = oldSubGraph;
  }

  void visitBasicBlock(HBasicBlock block) {
    if (!subGraph.contains(block)) return;
    block.last.accept(this);

    HInstruction instruction = block.last.previous;
    while (instruction != null) {
      HInstruction previous = instruction.previous;
      instruction.accept(this);
      instruction = previous;
    }

    for (HPhi phi = block.phis.first; phi != null; phi = phi.next) {
      phi.accept(this);
    }

    if (block.isLoopHeader()) {
      // If the block is a loop header, we need to change every uses
      // of its loop marker to the current set of live instructions.
      // For example with the following loop (read the example in
      // reverse):
      //
      // while (true) { <-- (4) update the marker with the environment
      //   use(x);      <-- (3) environment = {x}
      //   bailout;     <-- (2) has the marker when computed
      // }              <-- (1) create a loop marker
      //
      // The bailout instruction first captures the marker, but it
      // will be replaced by the live environment at the loop entry,
      // in this case {x}.
      environment.removeLoopMarker(block);
      capturedEnvironments.forEach((ignoredInstruction, env) {
        if (env.containsLoopMarker(block)) {
          env.removeLoopMarker(block);
          env.addAll(environment);
        }
      });
    }
  }

  void visitTypeGuard(HTypeGuard guard) {
    environment.remove(guard);
    assert(guard.inputs.length == 1);
    environment.add(guard.guarded);
    capturedEnvironments[guard] = new Environment.from(environment);
  }

  void visitPhi(HPhi phi) {
    environment.remove(phi);
    // If the block is a loop header, we insert the incoming values of
    // the phis, and remove the loop values.
    // If the block is not a loop header, the phi will be handled by
    // the control flow instruction.
    if (phi.block.isLoopHeader()) {
      environment.add(phi.inputs[0]);
      for (int i = 1, len = phi.inputs.length; i < len; i++) {
        environment.remove(phi.inputs[i]);
      }
    }
  }

  void visitInstruction(HInstruction instruction) {
    environment.remove(instruction);
    for (int i = 0, len = instruction.inputs.length; i < len; i++) {
      environment.add(instruction.inputs[i]);
    }
  }

  void visitIf(HIf instruction) {
    HIfBlockInformation info = instruction.blockInformation;
    HBasicBlock joinBlock = info.joinBlock;

    if (joinBlock != null) {
      visitBasicBlock(joinBlock);
    }
    Environment thenEnvironment = new Environment.from(environment);
    Environment elseEnvironment = environment;

    if (joinBlock != null) {
      for (HPhi phi = joinBlock.phis.first; phi != null; phi = phi.next) {
        if (joinBlock.predecessors[0] == instruction.block) {
          // We're dealing with an 'if' without an else branch.
          thenEnvironment.add(phi.inputs[1]);
          elseEnvironment.add(phi.inputs[0]);
        } else {
          thenEnvironment.add(phi.inputs[0]);
          elseEnvironment.add(phi.inputs[1]);
        }
      }
    }

    if (instruction.hasElse) {
      environment = elseEnvironment;
      visitSubGraph(info.elseGraph);
      elseEnvironment = environment;
    }

    environment = thenEnvironment;
    visitSubGraph(info.thenGraph);
    environment.addAll(elseEnvironment);
    visitInstruction(instruction);
  }

  void visitGoto(HGoto goto) {
    HBasicBlock block = goto.block;
    if (block.successors[0].dominator != block) return;
    visitBasicBlock(block.successors[0]);
  }

  void visitBreak(HBreak breakInstruction) {
    compiler.unimplemented("SsaEnvironmentBuilder.visitBreak");
  }

  void visitLoopBranch(HLoopBranch branch) {
    HBasicBlock block = branch.block;

    // Visit the code after the loop.
    visitBasicBlock(block.successors[1]);

    Environment joinEnvironment = environment;

    // When visiting the loop body, we don't require the live
    // instructions after the loop body to be in the environment. They
    // will be either recomputed in the loop header, or inserted
    // with the loop marker. We still need to transfer existing loop
    // markers from the current environment, because they must be live
    // for this loop body.
    environment = new Environment.forLoopBody(environment);

    // Put the loop phis in the environment.
    HBasicBlock header = block.isLoopHeader() ? block : block.parentLoopHeader;
    for (HPhi phi = header.phis.first; phi != null; phi = phi.next) {
      for (int i = 1, len = phi.inputs.length; i < len; i++) {
        environment.add(phi.inputs[i]);
      }
    }

    // Add the loop marker
    environment.addLoopMarker(header);

    if (!branch.isDoWhile()) {
      assert(block.successors[0] == block.dominatedBlocks[0]);
      visitBasicBlock(block.successors[0]);
    }

    // We merge the environment required by the code after the loop,
    // and the code inside the loop.
    environment.addAll(joinEnvironment);
    visitInstruction(branch);
  }

  // Deal with all kinds of control flow instructions. In case we add
  // a new one, we will hit an internal error.
  void visitExit(HExit exit) {}

  void visitReturn(HReturn instruction) {
    environment.clear();
    visitInstruction(instruction);
  }

  void visitThrow(HThrow instruction) {
    environment.clear();
    visitInstruction(instruction);
  }

  void visitControlFlow(HControlFlow instruction) {
    compiler.internalError('Control flow instructions already dealt with.',
                           instruction: instruction);
  }

  void insertCapturedEnvironments() {
    capturedEnvironments.forEach((HTypeGuard guard, Environment env) {
      env.storeInGuard(guard);
    });
  }
}

/**
 * Propagates bailout information to blocks that need it. This visitor
 * is run before codegen, to know which blocks have to deal with
 * bailouts.
 */
class SsaBailoutPropagator extends HBaseVisitor {
  final Compiler compiler;
  final List<HBasicBlock> blocks;

  SsaBailoutPropagator(Compiler this.compiler) : blocks = <HBasicBlock>[];

  void visitGraph(HGraph graph) {
    blocks.addLast(graph.entry);
    visitBasicBlock(graph.entry);
  }

  void visitBasicBlock(HBasicBlock block) {
    if (block.isLoopHeader()) blocks.addLast(block);
    HInstruction instruction = block.first;
    while (instruction != null) {
      instruction.accept(this);
      instruction = instruction.next;
    }
  }

  void enterBlock(HBasicBlock block) {
    if (block == null) return;
    blocks.addLast(block);
    visitBasicBlock(block);
    blocks.removeLast();
  }

  void visitIf(HIf instruction) {
    enterBlock(instruction.thenBlock);
    enterBlock(instruction.elseBlock);
    enterBlock(instruction.joinBlock);
  }

  void visitGoto(HGoto goto) {
    HBasicBlock block = goto.block;
    if (block.successors[0].dominator != block) return;
    visitBasicBlock(block.successors[0]);
  }

  void visitLoopBranch(HLoopBranch branch) {
    HBasicBlock branchBlock = branch.block;
    if (!branch.isDoWhile()) {
      // Not a do while loop. We visit the body of the loop.
      visitBasicBlock(branchBlock.dominatedBlocks[0]);
    }
    blocks.removeLast();
    visitBasicBlock(branchBlock.successors[1]);
  }

  // Deal with all kinds of control flow instructions. In case we add
  // a new one, we will hit an internal error.
  void visitExit(HExit exit) {}
  void visitReturn(HReturn instruction) {}
  void visitThrow(HThrow instruction) {}

  void visitControlFlow(HControlFlow instruction) {
    compiler.internalError('Control flow instructions already dealt with.',
                           instruction: instruction);
  }

  visitTypeGuard(HTypeGuard guard) {
    blocks.forEach((HBasicBlock block) {
      block.guards.add(guard);
    });
  }
}
