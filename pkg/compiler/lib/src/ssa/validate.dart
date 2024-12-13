// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'nodes.dart';

class HValidator extends HInstructionVisitor {
  bool isValid = true;
  late final HGraph graph;

  void visitGraph(HGraph visitee) {
    graph = visitee;
    visitDominatorTree(visitee);
  }

  void markInvalid(String reason) {
    print('Invalid: $reason');
    isValid = false;
  }

  // Note that during construction of the Ssa graph the basic blocks are
  // not required to be valid yet.
  @override
  void visitBasicBlock(HBasicBlock node) {
    currentBlock = node;
    if (!isValid) return; // Don't need to continue if we are already invalid.

    // Test that the last instruction is a branching instruction and that the
    // basic block contains the branch-target.
    if (node.first == null || node.last == null) {
      markInvalid("empty block");
    }
    if (node.last is! HControlFlow) {
      markInvalid("block ends with non-tail node.");
    }
    if (node.last is HIf && node.successors.length != 2) {
      markInvalid("If node without two successors");
    }
    if (node.last is HConditionalBranch && node.successors.length != 2) {
      markInvalid("Conditional node without two successors");
    }
    if (node.last is HLoopBranch) {
      // Assert that the block we inserted to avoid critical edges satisfies
      // our assumptions. That is, it must not contain any instructions
      // (although it may contain phi-updates).
      HBasicBlock avoidCriticalEdgeBlock = node.successors.last;
      if (avoidCriticalEdgeBlock.first is! HGoto) {
        markInvalid("Critical edge block contains instructions");
      }
    }
    if (node.last is HGoto && node.successors.length != 1) {
      markInvalid("Goto node with not exactly one successor");
    }
    if (node.last is HJump && node.successors.length != 1) {
      markInvalid("Break or continue node without one successor");
    }
    if ((node.last is HReturn || node.last is HThrow) &&
        (node.successors.length != 1 || !node.successors[0].isExitBlock())) {
      markInvalid(
        "Return or throw node with > 1 successor "
        "or not going to exit-block",
      );
    }
    if (node.last is HExit && node.successors.isNotEmpty) {
      markInvalid("Exit block with successor");
    }

    if (node.successors.isEmpty && !node.isExitBlock()) {
      markInvalid("Non-exit block without successor");
    }

    // Check that successors ids are always higher than the current one.
    // TODO(floitsch): this is, of course, not true for back-branches.
    if (node.id < 0) markInvalid("block without id");
    for (HBasicBlock successor in node.successors) {
      if (!isValid) break;
      if (successor.id < 0) markInvalid("successor without id");
      if (successor.id <= node.id && !successor.isLoopHeader()) {
        markInvalid("successor with lower id, but not a loop-header");
      }
    }
    // Make sure we don't have a critical edge.
    if (isValid &&
        node.successors.length > 1 &&
        node.last is! HTry &&
        node.last is! HExitTry &&
        node.last is! HSwitch) {
      for (HBasicBlock successor in node.successors) {
        if (!isValid) break;
        if (successor.predecessors.length >= 2) {
          markInvalid("SSA graph contains critical edge.");
        }
      }
    }

    // Check that the entries in the dominated-list are sorted.
    int lastId = 0;
    for (HBasicBlock dominated in node.dominatedBlocks) {
      if (!isValid) break;
      if (!identical(dominated.dominator, node)) {
        markInvalid("dominated block not pointing back");
      }
      if (dominated.id == -1 || dominated.id <= lastId) {
        markInvalid("dominated.id == -1 or dominated has <= id");
      }
      lastId = dominated.id;
    }

    if (!isValid) return;
    node.forEachPhi(visitInstruction);

    // Check that the blocks of the parameters of a phi are dominating the
    // corresponding predecessor block. Note that a block dominates
    // itself.
    node.forEachPhi((HPhi phi) {
      assert(phi.inputs.length <= node.predecessors.length);
      for (int i = 0; i < phi.inputs.length; i++) {
        HInstruction input = phi.inputs[i];
        if (!input.block!.dominates(node.predecessors[i])) {
          markInvalid("Definition does not dominate use");
        }
      }
    });

    // Check that the blocks of the inputs of an instruction dominate the
    // instruction's block.
    node.forEachInstruction((HInstruction instruction) {
      for (HInstruction input in instruction.inputs) {
        if (!input.block!.dominates(node)) {
          markInvalid("Definition does not dominate use");
        }
      }
    });

    super.visitBasicBlock(node);
  }

  // Limit for the size of `inputs` and `usedBy` lists. We assume lists longer
  // than this are OK in order to avoid the O(N^2) validation getting out of
  // hand.
  //
  // Poster child: corelib/regexp/pcre_test.dart, which has a 7KLOC main().
  static const int kMaxValidatedInstructionListLength = 1000;

  /// Verifies [instruction] is contained in [instructions] [count] times.
  static bool checkInstructionCount(
    List<HInstruction> instructions,
    HInstruction instruction,
    int count,
  ) {
    if (instructions.length > kMaxValidatedInstructionListLength) return true;
    int result = 0;
    for (int i = 0; i < instructions.length; i++) {
      if (identical(instructions[i], instruction)) result++;
    }
    return result == count;
  }

  /// Returns true if the predicate returns true for every instruction in the
  /// list. The argument to [f] is an instruction with the count of how often
  /// it appeared in the list [instructions].
  static bool everyInstruction(
    List<HInstruction> instructions,
    bool Function(HInstruction, int) f,
  ) {
    if (instructions.length > kMaxValidatedInstructionListLength) return true;
    var copy = List<HInstruction?>.from(instructions);
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

  @override
  void visitInstruction(HInstruction instruction) {
    // Verifies that we are in the use list of our inputs.
    bool hasCorrectInputs() {
      bool inBasicBlock = instruction.isInBasicBlock();
      return everyInstruction(instruction.inputs, (input, count) {
        if (inBasicBlock) {
          return input.isInBasicBlock() &&
              checkInstructionCount(input.usedBy, instruction, count);
        } else {
          return checkInstructionCount(input.usedBy, instruction, 0);
        }
      });
    }

    // Verifies that all our uses have us in their inputs.
    bool hasCorrectUses() {
      if (!instruction.isInBasicBlock()) return true;
      return everyInstruction(instruction.usedBy, (use, count) {
        return use.isInBasicBlock() &&
            checkInstructionCount(use.inputs, instruction, count);
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

    if (instruction is HLocalGet) {
      if (instruction.inputs.length != 1) {
        markInvalid('HLocalGet has one input');
      }
      HInstruction input = instruction.inputs.first;
      if (input is! HLocalValue) {
        markInvalid('Incorrect input ${input.runtimeType} to HLocalGet');
      }
    }
  }
}

/// Validate that the graph contains no unused phi nodes.
///
///     assert(NoUnusedPhiValidator.containsNoUnusedPhis(graph));
class NoUnusedPhiValidator extends HGraphVisitor {
  bool isValid = true;

  static bool containsNoUnusedPhis(HGraph graph) {
    final validator = NoUnusedPhiValidator();
    validator.visitDominatorTree(graph);
    return validator.isValid;
  }

  @override
  void visitBasicBlock(HBasicBlock block) {
    block.forEachPhi(visitPhi);
  }

  void visitPhi(HPhi phi) {
    if (phi.usedBy.isEmpty) {
      print('Unused $phi in B${phi.block!.id}');
      isValid = false;
    }
  }
}
