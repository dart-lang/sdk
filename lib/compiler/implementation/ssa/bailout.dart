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
    // If the instruction is a check, we add its checked input
    // instead. This allows sharing the same environment between
    // different type guards.
    //
    // Also, we don't need to add code motion invariant instructions
    // in the live set (because we generate them at use-site), except
    // for parameters that are not 'this', which is always passed as
    // the receiver.
    if (instruction is HCheck) {
      add(instruction.checkedInput);
    } else if (!instruction.isCodeMotionInvariant()
               || (instruction is HParameterValue && instruction is !HThis)) {
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

  bool get isEmpty => lives.isEmpty && loopMarkers.isEmpty;
}


/**
 * Visits the graph in dominator order and inserts TypeGuards in places where
 * we consider the guard to be of value.
 *
 * Might modify the [types] in an inconsistent way. No further analysis should
 * rely on them.
 */
class SsaTypeGuardInserter extends HGraphVisitor implements OptimizationPhase {
  final Compiler compiler;
  final String name = 'SsaTypeGuardInserter';
  final WorkItem work;
  final HTypeMap types;
  bool calledInLoop = false;
  bool isRecursiveMethod = false;
  int stateId = 1;

  SsaTypeGuardInserter(this.compiler, this.work, this.types);

  void visitGraph(HGraph graph) {
    isRecursiveMethod = graph.isRecursiveMethod;
    calledInLoop = graph.calledInLoop;
    work.guards = <HTypeGuard>[];
    visitDominatorTree(graph);
  }

  void visitBasicBlock(HBasicBlock block) {
    block.forEachPhi(visitInstruction);

    HInstruction instruction = block.first;
    while (instruction != null) {
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

  bool get hasTypeGuards => work.guards.length != 0;

  bool typeGuardWouldBeValuable(HInstruction instruction,
                                HType speculativeType) {
    // If the type itself is not valuable, do not generate a guard for it.
    if (!typeValuable(speculativeType)) return false;

    // Do not insert a type guard if the instruction has a type
    // annotation that disagrees with the speculated type.
    Element source = instruction.sourceElement;
    if (source != null) {
      DartType sourceType = source.computeType(compiler);
      DartType speculatedType = speculativeType.computeType(compiler);
      if (speculatedType != null
          && !compiler.types.isAssignable(speculatedType, sourceType)) {
        return false;
      }
    }

    // Insert type guards for recursive methods.
    if (isRecursiveMethod) return true;

    // Insert type guards if there are uses in loops.
    bool isNested(HBasicBlock inner, HBasicBlock outer) {
      if (identical(inner, outer)) return false;
      if (outer == null) return true;
      while (inner != null) {
        if (identical(inner, outer)) return true;
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

    // To speed up computations on values loaded from arrays, we
    // insert type guards for builtin array indexing operations in
    // nested loops. Since this can blow up code size quite
    // significantly, we only do it if type guards have already been
    // inserted for this method. The code size price for an additional
    // type guard is much smaller than the first one that causes the
    // generation of a bailout method.
    if (instruction is HIndex &&
        (instruction as HIndex).isBuiltin(types) &&
        hasTypeGuards) {
      HBasicBlock loopHeader = instruction.block.enclosingLoopHeader;
      if (loopHeader != null && loopHeader.parentLoopHeader != null) {
        return true;
      }
    }

    // If the instruction is used by a phi where a guard would be
    // valuable, put the guard on that instruction.
    for (HInstruction user in instruction.usedBy) {
      if (user is HPhi
          && user.block.id > instruction.id
          && typeGuardWouldBeValuable(user, speculativeType)) {
        return true;
      }
    }

    // Insert type guards if the method is likely to be called in a
    // loop.
    return calledInLoop;
  }

  bool shouldInsertTypeGuard(HInstruction instruction,
                             HType speculativeType,
                             HType computedType) {
    if (!speculativeType.isUseful()) return false;
    // If the types agree we don't need to check.
    if (speculativeType == computedType) return false;
    // If a bailout check is more expensive than doing the actual operation
    // don't do it either.
    return typeGuardWouldBeValuable(instruction, speculativeType);
  }

  void visitInstruction(HInstruction instruction) {
    HType speculativeType = types[instruction];
    HType computedType = instruction.computeTypeFromInputTypes(types);
    // Currently the type in [types] is the speculative type each instruction
    // would like to have. We start by recomputing the type non-speculatively.
    // If we add a type guard then the guard will expose the speculative type.
    // If we don't add a type guard then this avoids that subsequent
    // instructions use the wrong (speculative) type.
    //
    // Note that just setting the speculative type of the instruction is not
    // complete since the type could lead to a phi node which in turn could
    // change the speculative type. In this case we might miss some guards we
    // would have liked to insert. Most of the time this should however be
    // fine, due to dominator-order visiting.
    types[instruction] = computedType;

    if (shouldInsertTypeGuard(instruction, speculativeType, computedType)) {
      HInstruction insertionPoint;
      if (instruction is HPhi) {
        insertionPoint = instruction.block.first;
      } else if (instruction is HParameterValue) {
        // We insert the type guard at the end of the entry block
        // because if a parameter is live, it must be kept in the live
        // environment. Not doing so would mean we could visit a
        // parameter and remove it from the environment before
        // visiting a type guard.
        insertionPoint = instruction.block.last;
      } else {
        insertionPoint = instruction.next;
      }
      // If the previous instruction is also a type guard, then both
      // guards have the same environment, and can therefore share the
      // same state id.
      HBailoutTarget target;
      int state;
      if (insertionPoint.previous is HTypeGuard) {
        HTypeGuard other = insertionPoint.previous;
        target = other.bailoutTarget;
      } else {
        state = stateId++;
        target = new HBailoutTarget(state);
        insertionPoint.block.addBefore(insertionPoint, target);
      }
      HTypeGuard guard = new HTypeGuard(speculativeType, instruction, target);
      types[guard] = speculativeType;
      work.guards.add(guard);
      instruction.block.rewrite(instruction, guard);
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

  final Map<HBailoutTarget, Environment> capturedEnvironments;
  final Map<HBasicBlock, Environment> liveInstructions;
  Environment environment;

  SsaEnvironmentBuilder(Compiler this.compiler)
    : capturedEnvironments = new Map<HBailoutTarget, Environment>(),
      liveInstructions = new Map<HBasicBlock, Environment>();


  void visitGraph(HGraph graph) {
    visitPostDominatorTree(graph);
    if (!liveInstructions[graph.entry].isEmpty) {
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
      if (successorEnv != null) {
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

  void visitBailoutTarget(HBailoutTarget target) {
    visitInstruction(target);
    capturedEnvironments[target] = new Environment.from(environment);
  }

  void visitInstruction(HInstruction instruction) {
    environment.remove(instruction);
    for (int i = 0, len = instruction.inputs.length; i < len; i++) {
      environment.add(instruction.inputs[i]);
    }
  }

  /**
   * Stores all live variables in the bailout target and the guards.
   */
  void insertCapturedEnvironments() {
    capturedEnvironments.forEach((HBailoutTarget target, Environment env) {
      assert(target.inputs.length == 0);
      target.inputs.addAll(env.lives);
      // TODO(floitsch): we should add the bailout-target's input variables
      // as input to the guards only in the optimized version. The
      // non-optimized version does not use the bailout guards and it is
      // unnecessary to keep the variables alive until the check.
      for (HTypeGuard guard in target.usedBy) {
        // A type-guard initially only has two inputs: the guarded instruction
        // and the bailout-target. Only after adding the environment is it
        // allowed to have more inputs.
        assert(guard.inputs.length == 2);
        guard.inputs.addAll(env.lives);
      }
      for (HInstruction live in env.lives) {
        live.usedBy.add(target);
        live.usedBy.addAll(target.usedBy);
      }
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
  final Set<HInstruction> generateAtUseSite;
  SubGraph subGraph;
  int maxBailoutParameters = 0;

  /**
   * If set to true, the graph has either multiple bailouts in
   * different places, or a bailout inside an if or a loop. For such a
   * graph, the code generator will emit a generic switch.
   */
  bool hasComplexBailoutTargets = false;

  /**
   * The first type guard in the graph.
   */
  HBailoutTarget firstBailoutTarget;

  /**
   * If set, it is the first block in the graph where we generate
   * code. Blocks before this one are dead code in the bailout
   * version.
   */

  SsaBailoutPropagator(this.compiler, this.generateAtUseSite)
      : blocks = <HBasicBlock>[],
        labeledBlockInformations = <HLabeledBlockInformation>[];

  void visitGraph(HGraph graph) {
    subGraph = new SubGraph(graph.entry, graph.exit);
    visitBasicBlock(graph.entry);
    if (!blocks.isEmpty) {
      compiler.internalError('Bailout propagation',
          node: compiler.currentElement.parseNode(compiler));
    }
  }

  void visitBasicBlock(HBasicBlock block) {
    // Abort traversal if we are leaving the currently active sub-graph.
    if (!subGraph.contains(block)) return;

    if (block.isLoopHeader()) {
      blocks.addLast(block);
    } else if (block.isLabeledBlock()
               && (blocks.isEmpty || !identical(blocks.last, block))) {
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
      if (continuation != null) {
        visitBasicBlock(continuation);
      }
    }
  }

  void visitIf(HIf instruction) {
    int preVisitedBlocks = 0;
    HIfBlockInformation info = instruction.blockInformation.body;
    visitStatements(info.thenGraph);
    preVisitedBlocks++;
    visitStatements(info.elseGraph);
    preVisitedBlocks++;

    HBasicBlock joinBlock = instruction.joinBlock;
    if (joinBlock != null
        && !identical(joinBlock.dominator, instruction.block)) {
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
    if (identical(successor.dominator, block)) {
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
    if (!identical(branchBlock.successors[1].dominator, branchBlock)) return;

    visitBasicBlock(branchBlock.successors[1]);
    // With labeled breaks we can have more dominated blocks.
    if (dominated.length >= 3) {
      for (int i = 2; i < dominated.length; i++) {
        visitBasicBlock(dominated[i]);
      }
    }
  }

  visitBailoutTarget(HBailoutTarget target) {
    int inputLength = target.inputs.length;
    if (inputLength > maxBailoutParameters) {
      maxBailoutParameters = inputLength;
    }
    if (blocks.isEmpty) {
      if (firstBailoutTarget == null) {
        firstBailoutTarget = target;
      } else {
        hasComplexBailoutTargets = true;
      }
    } else {
      hasComplexBailoutTargets = true;
      blocks.forEach((HBasicBlock block) {
        block.bailoutTargets.add(target);
      });
    }
  }
}
