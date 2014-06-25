// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

class HValidator extends HInstructionVisitor {
  bool isValid = true;
  HGraph graph;

  void visitGraph(HGraph visitee) {
    graph = visitee;
    visitDominatorTree(visitee);
  }

  void markInvalid(String reason) {
    print(reason);
    isValid = false;
  }

  // Note that during construction of the Ssa graph the basic blocks are
  // not required to be valid yet.
  void visitBasicBlock(HBasicBlock block) {
    currentBlock = block;
    if (!isValid) return;  // Don't need to continue if we are already invalid.

    // Test that the last instruction is a branching instruction and that the
    // basic block contains the branch-target.
    if (block.first == null || block.last == null) {
      markInvalid("empty block");
    }
    if (block.last is !HControlFlow) {
      markInvalid("block ends with non-tail node.");
    }
    if (block.last is HIf && block.successors.length != 2) {
      markInvalid("If node without two successors");
    }
    if (block.last is HConditionalBranch && block.successors.length != 2) {
        markInvalid("Conditional node without two successors");
      }
    if (block.last is HLoopBranch) {
      // Assert that the block we inserted to avoid critical edges satisfies
      // our assumptions. That is, it must not contain any instructions
      // (although it may contain phi-updates).
      HBasicBlock avoidCriticalEdgeBlock = block.successors.last;
      if (avoidCriticalEdgeBlock.first is! HGoto) {
        markInvalid("Critical edge block contains instructions");
      }
    }
    if (block.last is HGoto && block.successors.length != 1) {
      markInvalid("Goto node with not exactly one successor");
    }
    if (block.last is HJump && block.successors.length != 1) {
      markInvalid("Break or continue node without one successor");
    }
    if ((block.last is HReturn || block.last is HThrow) &&
        (block.successors.length != 1 || !block.successors[0].isExitBlock())) {
      markInvalid("Return or throw node with > 1 successor "
                  "or not going to exit-block");
    }
    if (block.last is HExit && !block.successors.isEmpty) {
      markInvalid("Exit block with successor");
    }

    if (block.successors.isEmpty && !block.isExitBlock()) {
      markInvalid("Non-exit block without successor");
    }

    // Check that successors ids are always higher than the current one.
    // TODO(floitsch): this is, of course, not true for back-branches.
    if (block.id == null) markInvalid("block without id");
    for (HBasicBlock successor in block.successors) {
      if (!isValid) break;
      if (successor.id == null) markInvalid("successor without id");
      if (successor.id <= block.id && !successor.isLoopHeader()) {
        markInvalid("successor with lower id, but not a loop-header");
      }
    }
    // Make sure we don't have a critical edge.
    if (isValid && block.successors.length > 1 &&
        block.last is! HTry && block.last is! HExitTry &&
        block.last is! HSwitch) {
      for (HBasicBlock successor in block.successors) {
        if (!isValid) break;
        if (successor.predecessors.length >= 2) {
          markInvalid("SSA graph contains critical edge.");
        }
      }
    }

    // Check that the entries in the dominated-list are sorted.
    int lastId = 0;
    for (HBasicBlock dominated in block.dominatedBlocks) {
      if (!isValid) break;
      if (!identical(dominated.dominator, block)) {
        markInvalid("dominated block not pointing back");
      }
      if (dominated.id == null || dominated.id <= lastId) {
        markInvalid("dominated.id == null or dominated has <= id");
      }
      lastId = dominated.id;
    }

    if (!isValid) return;
    block.forEachPhi(visitInstruction);

    // Check that the blocks of the parameters of a phi are dominating the
    // corresponding predecessor block. Note that a block dominates
    // itself.
    block.forEachPhi((HPhi phi) {
      assert(phi.inputs.length <= block.predecessors.length);
      for (int i = 0; i < phi.inputs.length; i++) {
        HInstruction input = phi.inputs[i];
        if (!input.block.dominates(block.predecessors[i])) {
          markInvalid("Definition does not dominate use");
        }
      }
    });

    // Check that the blocks of the inputs of an instruction dominate the
    // instruction's block.
    block.forEachInstruction((HInstruction instruction) {
      for (HInstruction input in instruction.inputs) {
        if (!input.block.dominates(block)) {
          markInvalid("Definition does not dominate use");
        }
      }
    });

    super.visitBasicBlock(block);
  }

  /** Returns how often [instruction] is contained in [instructions]. */
  static int countInstruction(List<HInstruction> instructions,
                              HInstruction instruction) {
    int result = 0;
    for (int i = 0; i < instructions.length; i++) {
      if (identical(instructions[i], instruction)) result++;
    }
    return result;
  }

  /**
   * Returns true if the predicate returns true for every instruction in the
   * list. The argument to [f] is an instruction with the count of how often
   * it appeared in the list [instructions].
   */
  static bool everyInstruction(List<HInstruction> instructions, Function f) {
    var copy = new List<HInstruction>.from(instructions);
    // TODO(floitsch): there is currently no way to sort HInstructions before
    // we have assigned an ID. The loop is therefore O(n^2) for now.
    for (int i = 0; i < copy.length; i++) {
      var current = copy[i];
      if (current == null) continue;
      int count = 1;
      for (int j = i + 1; j < copy.length; j++) {
        if (identical(copy[j], current)) {
          copy[j] = null;
          count++;
        }
      }
      if (!f(current, count)) return false;
    }
    return true;
  }

  void visitInstruction(HInstruction instruction) {
    // Verifies that we are in the use list of our inputs.
    bool hasCorrectInputs() {
      bool inBasicBlock = instruction.isInBasicBlock();
      return everyInstruction(instruction.inputs, (input, count) {
        if (inBasicBlock) {
          return input.isInBasicBlock()
              && countInstruction(input.usedBy, instruction) == count;
        } else {
          return countInstruction(input.usedBy, instruction) == 0;
        }
      });
    }

    // Verifies that all our uses have us in their inputs.
    bool hasCorrectUses() {
      if (!instruction.isInBasicBlock()) return true;
      return everyInstruction(instruction.usedBy, (use, count) {
        return use.isInBasicBlock()
            && countInstruction(use.inputs, instruction) == count;
      });
    }

    if (!identical(instruction.block, currentBlock)) {
      markInvalid("Instruction in wrong block");
    }
    if (!hasCorrectInputs()) {
      markInvalid("Incorrect inputs");
    }
    if (!hasCorrectUses()) {
      markInvalid("Incorrect uses");
    }
  }
}
