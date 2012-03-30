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

  List<HInstruction> buildAndSetLast(HInstruction instruction) {
    remove(instruction);
    List<HInstruction> result = new List<HInstruction>.from(lives);
    result.addLast(instruction);
    add(instruction);
    return result;
  }

  bool isEmpty() => lives.isEmpty();
  bool contains(HInstruction instruction) => lives.contains(instruction);
  bool containsLoopMarker(HBasicBlock block) => loopMarkers.contains(block);
  void clear() => lives.clear();
}

/**
 * Computes the environment for each SSA instruction: visits the graph
 * in post-dominator order. Removes an instruction from the environment
 * and adds its inputs to the environment at the instruction's
 * definition.
 *
 * At the end of the computation, insert type guards in the graph.
 */
class SsaTypeGuardBuilder extends HBaseVisitor implements OptimizationPhase {
  final Compiler compiler;
  final WorkItem work;
  final String name = 'SsaTypeGuardBuilder';
  Environment environment;
  SubGraph subGraph;

  final Map<HInstruction, Environment> capturedEnvironments;

  SsaTypeGuardBuilder(Compiler this.compiler, WorkItem this.work)
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

  void maybeCaptureEnvironment(HInstruction instruction) {
    if (shouldCaptureEnvironment(instruction)) {
      capturedEnvironments[instruction] = new Environment.from(environment);
    }
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
      capturedEnvironments.forEach((instruction, env) {
        if (env.containsLoopMarker(block)) {
          env.removeLoopMarker(block);
          env.addAll(environment);
        }
      });
    }
  }

  void visitPhi(HPhi phi) {
    maybeCaptureEnvironment(phi);
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
    maybeCaptureEnvironment(instruction);
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

  bool shouldCaptureEnvironment(HInstruction instruction) {
    return instruction.type.isKnown() && !instruction.hasExpectedType();
  }

  void insertCapturedEnvironments() {
    work.guards = <HTypeGuard>[];
    int state = 1;
    capturedEnvironments.forEach((HInstruction instruction, Environment env) {
      List<HInstruction> inputs = env.buildAndSetLast(instruction);
      HTypeGuard guard = new HTypeGuard(state++, inputs);
      work.guards.add(guard);
      instruction.block.rewrite(instruction, guard);
      HInstruction insertionPoint = (instruction is HPhi)
          ? instruction.block.first
          : instruction.next;
      insertionPoint.block.addBefore(insertionPoint, guard);
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
