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

  bool isEmpty() => lives.isEmpty() && loopMarkers.isEmpty();
}


/**
 * Visits the graph in dominator order and inserts TypeGuards in places where
 * we consider the guard to be of value.
 *
 * Might modify the [:propagatedType:] fields of the instructions in an
 * inconsistent way. No further analysis should rely on them.
 */
class SsaTypeGuardInserter extends HGraphVisitor implements OptimizationPhase {
  final Compiler compiler;
  final String name = 'SsaTypeGuardInserter';
  final WorkItem work;
  bool calledInLoop = false;
  bool isRecursiveMethod = false;
  int stateId = 1;

  SsaTypeGuardInserter(this.compiler, this.work);

  void visitGraph(HGraph graph) {
    isRecursiveMethod = graph.isRecursiveMethod;
    calledInLoop = graph.calledInLoop;
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

  // Primitive types that are not null are valuable. These include
  // indexable arrays.
  bool typeValuable(HType type) {
    return type.isPrimitive() && !type.isNull();
  }

  bool typeGuardWouldBeValuable(HInstruction instruction,
                                HType speculativeType) {
    // If the type itself is not valuable, do not generate a guard for it.
    if (!typeValuable(speculativeType)) return false;

    // Do not insert a type guard if the instruction has a type
    // annotation that disagrees with the speculated type.
    Element source = instruction.sourceElement;
    if (source !== null) {
      Type sourceType = source.computeType(compiler);
      Type speculatedType = speculativeType.computeType(compiler);
      if (speculatedType !== null
          && !compiler.types.isAssignable(speculatedType, sourceType)) {
        return false;
      }
    }

    // Insert type guards for recursive methods.
    if (isRecursiveMethod) return true;

    // Insert type guards if there are uses in loops.
    bool isNested(HBasicBlock inner, HBasicBlock outer) {
      if (inner === outer) return false;
      if (outer === null) return true;
      while (inner !== null) {
        if (inner === outer) return true;
        inner = inner.parentLoopHeader;
      }
      return false;
    }

    // If the instruction is not in a loop then the header will be null.
    HBasicBlock currentLoopHeader = instruction.block.enclosingLoopHeader;
    for (HInstruction user in instruction.usedBy) {
      HBasicBlock userLoopHeader = user.block.enclosingLoopHeader;
      if (isNested(userLoopHeader, currentLoopHeader)) return true;
    }

    // Insert type guards if the method is likely to be called in a
    // loop.
    return calledInLoop;
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
    // If a bailout check is more expensive than doing the actual operation
    // don't do it either.
    return typeGuardWouldBeValuable(instruction, speculativeType);
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

  final Map<HInstruction, Environment> capturedEnvironments;
  final Map<HBasicBlock, Environment> liveInstructions;
  Environment environment;

  SsaEnvironmentBuilder(Compiler this.compiler)
    : capturedEnvironments = new Map<HInstruction, Environment>(),
      liveInstructions = new Map<HBasicBlock, Environment>();


  void visitGraph(HGraph graph) {
    visitPostDominatorTree(graph);
    if (!liveInstructions[graph.entry].isEmpty()) {
      compiler.internalError('Bailout environment computation',
          node: compiler.currentElement.parseNode(compiler));
    }
    updateLoopMarkers();
    insertCapturedEnvironments();
  }

  void updateLoopMarkers() {
    // If the block is a loop header, we need to merge the loop
    // header's live instructions into every environment that contains
    // the loop marker.
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
    capturedEnvironments.forEach((ignoredInstruction, env) {
      env.loopMarkers.forEach((HBasicBlock header) {
        env.removeLoopMarker(header);
        env.addAll(liveInstructions[header]);
      });
    });
  }

  void visitBasicBlock(HBasicBlock block) {
    environment = new Environment();

    // Add to the environment the live instructions of its successor, as well as
    // the inputs of the phis of the successor that flow from this block.
    for (int i = 0; i < block.successors.length; i++) {
      HBasicBlock successor = block.successors[i];
      Environment successorEnv = liveInstructions[successor];
      if (successorEnv !== null) {
        environment.addAll(successorEnv);
      } else {
        // If we haven't computed the liveInstructions of that successor, we
        // know it must be a loop header.
        assert(successor.isLoopHeader());
        environment.addLoopMarker(successor);
      }

      int index = successor.predecessors.indexOf(block);
      for (HPhi phi = successor.phis.first; phi != null; phi = phi.next) {
        environment.add(phi.inputs[index]);
      }
    }

    // Iterate over all instructions to remove an instruction from the
    // environment and add its inputs.
    HInstruction instruction = block.last;
    while (instruction != null) {
      instruction.accept(this);
      instruction = instruction.previous;
    }

    // We just remove the phis from the environment. The inputs of the
    // phis will be put in the environment of the predecessors.
    for (HPhi phi = block.phis.first; phi != null; phi = phi.next) {
      environment.remove(phi);
    }

    // If the block is a loop header, we can remove the loop marker,
    // because it will just recompute the loop phis.
    if (block.isLoopHeader()) {
      environment.removeLoopMarker(block);
    }

    // Finally save the liveInstructions of that block.
    liveInstructions[block] = environment;
  }

  void visitTypeGuard(HTypeGuard guard) {
    visitInstruction(guard);
    capturedEnvironments[guard] = new Environment.from(environment);
  }

  void visitInstruction(HInstruction instruction) {
    environment.remove(instruction);
    for (int i = 0, len = instruction.inputs.length; i < len; i++) {
      environment.add(instruction.inputs[i]);
    }
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
  final List<HLabeledBlockInformation> labeledBlockInformations;
  SubGraph subGraph;

  SsaBailoutPropagator(Compiler this.compiler)
      : blocks = <HBasicBlock>[],
        labeledBlockInformations = <HLabeledBlockInformation>[];

  void visitGraph(HGraph graph) {
    subGraph = new SubGraph(graph.entry, graph.exit);
    blocks.addLast(graph.entry);
    visitBasicBlock(graph.entry);
    blocks.removeLast();
    if (!blocks.isEmpty()) {
      compiler.internalError('Bailout propagation',
          node: compiler.currentElement.parseNode(compiler));
    }
  }

  void visitBasicBlock(HBasicBlock block) {
    // Abort traversal if we are leaving the currently active sub-graph.
    if (!subGraph.contains(block)) return;

    if (block.isLoopHeader()) {
      blocks.addLast(block);
    } else if (block.isLabeledBlock() && blocks.last() !== block) {
      HLabeledBlockInformation info = block.blockFlow.body;
      visitStatements(info.body);
      return;
    }

    HInstruction instruction = block.first;
    while (instruction != null) {
      instruction.accept(this);
      instruction = instruction.next;
    }
  }

  void visitStatements(HStatementInformation info) {
    assert(info is HSubGraphBlockInformation);
    HSubGraphBlockInformation graph = info;
    visitSubGraph(graph.subGraph);
  }

  void visitSubGraph(SubGraph graph) {
    SubGraph oldSubGraph = subGraph;
    subGraph = graph;
    HBasicBlock start = graph.start;
    blocks.addLast(start);
    visitBasicBlock(start);
    blocks.removeLast();
    subGraph = oldSubGraph;

    if (start.isLabeledBlock()) {
      HBasicBlock continuation = start.blockFlow.continuation;
      if (continuation !== null) {
        visitBasicBlock(continuation);
      }
    }
  }

  void visitIf(HIf instruction) {
    int preVisitedBlocks = 0;
    HIfBlockInformation info = instruction.blockInformation.body;
    visitStatements(info.thenGraph);
    preVisitedBlocks++;
    if (instruction.hasElse) {
      visitStatements(info.elseGraph);
      preVisitedBlocks++;
    }

    HBasicBlock joinBlock = instruction.joinBlock;
    if (joinBlock !== null
        && joinBlock.dominator !== instruction.block) {
      // The join block is dominated by a block in one of the branches.
      // The subgraph traversal never reached it, so we visit it here
      // instead.
      visitBasicBlock(joinBlock);
    }

    // Visit all the dominated blocks that are not part of the then or else
    // branches, and is not the join block.
    // Depending on how the then/else branches terminate
    // (e.g., return/throw/break) there can be any number of these.
    List<HBasicBlock> dominated = instruction.block.dominatedBlocks;
    int dominatedCount = dominated.length;
    for (int i = preVisitedBlocks; i < dominatedCount; i++) {
      HBasicBlock dominatedBlock = dominated[i];
      visitBasicBlock(dominatedBlock);
    }
  }

  void visitGoto(HGoto goto) {
    HBasicBlock block = goto.block;
    HBasicBlock successor = block.successors[0];
    if (successor.dominator === block) {
      visitBasicBlock(block.successors[0]);
    }
  }

  void visitLoopBranch(HLoopBranch branch) {
    HBasicBlock branchBlock = branch.block;
    List<HBasicBlock> dominated = branchBlock.dominatedBlocks;
    // For a do-while loop, the body has already been visited.
    if (!branch.isDoWhile()) {
      visitBasicBlock(dominated[0]);
    }
    blocks.removeLast();

    // If the branch does not dominate the code after the loop, the
    // dominator will visit it.
    if (branchBlock.successors[1].dominator !== branchBlock) return;

    visitBasicBlock(branchBlock.successors[1]);
    // With labeled breaks we can have more dominated blocks.
    if (dominated.length >= 3) {
      for (int i = 2; i < dominated.length; i++) {
        visitBasicBlock(dominated[i]);
      }
    }
  }

  visitTypeGuard(HTypeGuard guard) {
    blocks.forEach((HBasicBlock block) {
      block.guards.add(guard);
    });
  }
}
