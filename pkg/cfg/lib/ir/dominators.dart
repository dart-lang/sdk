// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math show min;
import 'dart:typed_data';

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/bit_vector.dart';

class Dominators {
  final FlowGraph graph;

  /// Immediate dominator (preorder block number -> preorder block number).
  final Int32List idom;

  /// List of blocks immediately dominated by a block,
  /// indexed by preorder block number.
  final List<List<Block>> dominated;

  /// (preorder, postorder) numbers for a block in a dominators tree.
  /// Note that they are different from preorder/postorder numbers of
  /// a block in the control flow graph.
  late Int32List _blockNums = _numberBlocks();

  /// Instruction number in its block, initialized lazily.
  Int32List? _instructionNums;

  Dominators._(this.graph, int numBlocks)
    : idom = Int32List(numBlocks),
      dominated = List<List<Block>>.generate(numBlocks, (_) => <Block>[]);

  /// Return true if [b] dominates [a], i.e. every path from
  /// graph entry to [a] goes through [b].
  bool isDominatedBy(Instruction a, Instruction b) {
    if (a == b) {
      return false;
    }
    final blockA = a.block!;
    final blockB = b.block!;
    if (blockA != blockB) {
      return _getDomPreorderNumber(blockB) < _getDomPreorderNumber(blockA) &&
          _getDomPostorderNumber(blockA) < _getDomPostorderNumber(blockB);
    }
    _numberInstructionsInBlock(blockA);
    return _instructionNums![b.id] < _instructionNums![a.id];
  }

  void invalidateInstructionNumbering() {
    _instructionNums = null;
  }

  /// Calculate a list of (preorder, postorder) numbers in a dominators tree.
  Int32List _numberBlocks() {
    final blockNums = Int32List(graph.preorder.length * 2);
    final workList = <(Block, int)>[];
    workList.add((graph.entryBlock, 0));
    var preorderNumber = 0;
    var postorderNumber = 0;
    while (workList.isNotEmpty) {
      final (block, index) = workList.removeLast();
      if (index == 0) {
        blockNums[(block.preorderNumber << 1) + 0] = preorderNumber++;
      }
      if (index < block.dominatedBlocks.length) {
        workList.add((block, index + 1));
        final child = block.dominatedBlocks[index];
        workList.add((child, 0));
      } else {
        blockNums[(block.preorderNumber << 1) + 1] = postorderNumber++;
      }
    }
    assert(preorderNumber == graph.preorder.length);
    assert(postorderNumber == graph.preorder.length);
    return blockNums;
  }

  /// Returns preorder number of [block] in the dominators tree.
  /// This is different from [block.preorderNumber] which gives preorder
  /// number of a block in the CFG.
  int _getDomPreorderNumber(Block block) =>
      _blockNums[(block.preorderNumber << 1) + 0];

  /// Returns postorder number of [block] in the dominators tree.
  /// This is different from [block.postorderNumber] which gives postorder
  /// number of a block in the CFG.
  int _getDomPostorderNumber(Block block) =>
      _blockNums[(block.preorderNumber << 1) + 1];

  /// Calculates and caches ordinal numbers of instructions in [block].
  void _numberInstructionsInBlock(Block block) {
    final instructionNums = (_instructionNums ??= Int32List(
      graph.instructions.length,
    ));
    if (instructionNums[block.id] == 0) {
      var instrNumber = 1;
      instructionNums[block.id] = instrNumber++;
      for (final instr in block) {
        assert(instructionNums[instr.id] == 0);
        instructionNums[instr.id] = instrNumber++;
      }
    }
  }
}

/// Compute immediate dominator and dominated blocks for each basic block.
Dominators computeDominators(FlowGraph graph) {
  // Use the SEMI-NCA algorithm to compute dominators. This is a two-pass
  // version of the Lengauer-Tarjan algorithm (LT is normally three passes)
  // that eliminates a pass by using nearest-common ancestor (NCA) to
  // compute immediate dominators from semidominators. It also removes a
  // level of indirection in the link-eval forest data structure.
  //
  // The algorithm is described in Georgiadis, Tarjan, and Werneck's
  // "Finding Dominators in Practice".
  // https://renatowerneck.files.wordpress.com/2016/06/gtw06-dominators.pdf

  // All lists are indexed by preorder block numbers.
  final preorder = graph.preorder;
  final int size = preorder.length;
  final dominators = Dominators._(graph, size);
  // Parent in the spanning tree.
  final parent = Int32List(size);
  // Immediate dominator.
  final idom = dominators.idom;
  // Semidominator.
  final semi = Int32List(size);
  // Label for link-eval forest.
  final label = Int32List(size);

  for (var i = 0; i < size; ++i) {
    parent[i] = (i == 0) ? -1 : preorder[i].predecessors.first.preorderNumber;
    idom[i] = parent[i];
    semi[i] = i;
    label[i] = i;
  }

  // 1. First pass: compute semidominators as in Lengauer-Tarjan.
  // Semidominators are computed from a depth-first spanning tree and are an
  // approximation of immediate dominators.

  // Use a link-eval data structure with path compression.  Implement path
  // compression in place by mutating [parent].  Each block has a
  // label, which is the minimum block number on the compressed path.
  void compressPath(int startIndex, int currentIndex) {
    int nextIndex = parent[currentIndex];
    if (nextIndex > startIndex) {
      compressPath(startIndex, nextIndex);
      label[currentIndex] = math.min(label[currentIndex], label[nextIndex]);
      parent[currentIndex] = parent[nextIndex];
    }
  }

  // Loop over the blocks in reverse preorder (not including the graph entry).
  for (int blockIndex = size - 1; blockIndex >= 1; --blockIndex) {
    final block = preorder[blockIndex];
    for (final pred in block.predecessors) {
      // Look for the semidominator by ascending the semidominator path
      // starting from pred.
      int predIndex = pred.preorderNumber;
      var best = predIndex;
      if (predIndex > blockIndex) {
        compressPath(blockIndex, predIndex);
        best = label[predIndex];
      }

      // Update the semidominator if we've found a better one.
      semi[blockIndex] = math.min(semi[blockIndex], semi[best]);
    }

    // Now use label for the semidominator.
    label[blockIndex] = semi[blockIndex];
  }

  // 2. Compute the immediate dominators as the nearest common ancestor of
  // spanning tree parent and semidominator, for all blocks except the entry.
  for (var blockIndex = 1; blockIndex < size; ++blockIndex) {
    int domIndex = idom[blockIndex];
    while (domIndex > semi[blockIndex]) {
      domIndex = idom[domIndex];
    }
    idom[blockIndex] = domIndex;
    dominators.dominated[domIndex].add(preorder[blockIndex]);
  }

  return dominators;
}

/// Compute the dominance frontier for each basic block.
///
/// Returns a list that maps the preorder block number
/// to a set of blocks in the dominance frontier.
///
/// If [includeExceptionHandlers], also include exception handler
/// to a dominance frontier of the block. This is needed in order to
/// account for implicit control flow from the exceptions.
/// (In the implicit control flow, block is a predecessor of its exception
/// handler but block doesn't dominate its exception handler, so exception
/// handler always belongs to a block's dominance frontier.)
List<BitVector> computeDominanceFrontier(
  FlowGraph graph, {
  bool includeExceptionHandlers = false,
}) {
  // This is algorithm in "A Simple, Fast Dominance Algorithm" (Figure 5),
  // which is attributed to a paper by Ferrante et al.
  //
  // There is no bookkeeping required to avoid adding a block twice to
  // the same block's dominance frontier because we use a set to represent
  // the dominance frontier.
  final preorder = graph.preorder;
  final int size = preorder.length;
  final dominanceFrontier = List<BitVector>.generate(
    size,
    (i) => BitVector(size),
    growable: false,
  );
  for (var blockIndex = 0; blockIndex < size; ++blockIndex) {
    final block = preorder[blockIndex];
    if (includeExceptionHandlers) {
      final exceptionHandler = block.exceptionHandler;
      if (exceptionHandler != null) {
        dominanceFrontier[blockIndex].add(exceptionHandler.preorderNumber);
      }
    }
    final count = block.predecessors.length;
    if (count <= 1) continue;
    for (var i = 0; i < count; ++i) {
      Block? runner = block.predecessors[i];
      while (runner != block.dominator) {
        dominanceFrontier[runner!.preorderNumber].add(blockIndex);
        runner = runner.dominator;
      }
    }
  }
  return dominanceFrontier;
}
