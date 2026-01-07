// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/instructions.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/utils/bit_vector.dart';

/// Control flow simplifications and optimizations.
final class ControlFlowOptimizations extends Pass {
  late final BitVector _removedBlocks = BitVector(graph.preorder.length);
  bool _changed = false;

  ControlFlowOptimizations() : super('ControlFlowOptimizations');

  void run() {
    for (final block in graph.reversePostorder) {
      if (!_removedBlocks[block.preorderNumber]) {
        currentBlock = block;
        _optimizeBlock(block);
      }
    }
    currentBlock = null;
    if (_changed) {
      graph.discoverBlocks();
    }
  }

  void _optimizeBlock(Block block) {
    for (;;) {
      final lastInstruction = block.lastInstruction;
      switch (lastInstruction) {
        case Goto():
          if (!_removeRedundantGoto(block, lastInstruction)) {
            return;
          }
        case Branch():
          if (!_removeRedundantBranch(block, lastInstruction)) {
            return;
          }
        default:
          return;
      }
    }
  }

  bool _removeRedundantGoto(Block block, Goto goto) {
    final successor = goto.target;
    if (successor.predecessors.length > 1) {
      return false;
    }
    if (successor.exceptionHandler != block.exceptionHandler &&
        successor.next != successor.lastInstruction) {
      // Do not merge a non-empty block with different exception handler.
      return false;
    }
    assert(successor != block);
    if (successor is JoinBlock) {
      for (final phi in successor.phis) {
        phi.replaceUsesWith(phi.inputDefAt(0));
        phi.removeFromGraph();
      }
    }
    _mergeBlocks(block, successor);
    return true;
  }

  void _mergeBlocks(Block block, Block successor) {
    for (final instr in successor) {
      assert(instr is! Phi);
      instr.block = block;
    }
    block.lastInstruction.removeFromGraph();
    block.lastInstruction.linkTo(successor.next!);
    block.lastInstruction = successor.lastInstruction;
    successor.next = null;
    successor.lastInstruction = successor;
    block.successors.clear();
    for (final newSuccessor in successor.successors) {
      block.successors.add(newSuccessor);
      newSuccessor.replacePredecessor(successor, block);
    }
    _removedBlocks[successor.preorderNumber] = true;
    _changed = true;
  }

  bool _removeRedundantBranch(Block block, Branch branch) {
    final successor = _skipEmptyBlocks(branch.trueSuccessor);
    if (successor != _skipEmptyBlocks(branch.falseSuccessor)) {
      return false;
    }
    if (successor is JoinBlock && successor.hasPhis) {
      return false;
    }
    _clearEmptyBlocks(branch.trueSuccessor, successor);
    _clearEmptyBlocks(branch.falseSuccessor, successor);
    branch.removeFromGraph();
    block.lastInstruction.appendInstruction(Goto(graph, branch.sourcePosition));
    block.successors.clear();
    block.successors.add(successor);
    successor.predecessors.add(block);
    _changed = true;
    return true;
  }

  Block _skipEmptyBlocks(Block block) {
    for (;;) {
      if (block.next != block.lastInstruction) {
        return block;
      }
      if (block.predecessors.length > 1) {
        return block;
      }
      if (block.lastInstruction is! Goto) {
        return block;
      }
      block = block.successors.single;
    }
  }

  void _clearEmptyBlocks(Block block, Block end) {
    while (block != end) {
      assert(block.next == block.lastInstruction);
      block.lastInstruction.removeFromGraph();
      _removedBlocks[block.preorderNumber] = true;
      _changed = true;
      final next = block.successors.single;
      next.predecessors.remove(block);
      block = next;
    }
  }
}
