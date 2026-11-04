// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math show min;
import 'dart:typed_data';

import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/bit_vector.dart';

/// Returns a list of non-trivial loops (SCCs) in [blocks].
///
/// Uses an iterative version of Tarjan's algorithm [0].
///
/// [0] https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
List<List<Block>> findNonTrivialSccs(List<Block> blocks) {
  if (blocks.isEmpty) return const [];

  final numBlocks = blocks.first.graph.preorder.length;
  final inSubgraph = BitVector(numBlocks);
  final onSccStack = BitVector(numBlocks);
  final dfsIndex = Int32List(numBlocks);
  final lowLink = Int32List(numBlocks);
  final nextSuccessor = Int32List(numBlocks);
  final sccStack = <Block>[];
  final dfsStack = <Block>[];

  for (final block in blocks) {
    final num = block.preorderNumber;
    inSubgraph.add(num);
    dfsIndex[num] = -1;
  }

  final result = <List<Block>>[];
  int nextIndex = 0;

  void push(Block block) {
    final blockNum = block.preorderNumber;
    dfsIndex[blockNum] = lowLink[blockNum] = nextIndex++;
    nextSuccessor[blockNum] = 0;
    sccStack.add(block);
    onSccStack.add(blockNum);
    dfsStack.add(block);
  }

  for (final root in blocks) {
    if (dfsIndex[root.preorderNumber] >= 0) continue;
    push(root);
    while (dfsStack.isNotEmpty) {
      final block = dfsStack.last;
      final blockNum = block.preorderNumber;
      final successors = block.successors;
      // Since this is an iterative DFS, `nextSuccessor[blockNum]` tracks the
      // loop index over `block.successors` so we can resume scanning remaining
      // successors after returning from a child and run post-order updates once
      // all successors have been visited.
      final succIndex = nextSuccessor[blockNum];
      if (succIndex < successors.length) {
        nextSuccessor[blockNum] = succIndex + 1;
        final successor = successors[succIndex];
        final succNum = successor.preorderNumber;
        if (!inSubgraph[succNum]) continue;
        if (dfsIndex[succNum] < 0) {
          push(successor);
        } else if (onSccStack[succNum]) {
          lowLink[blockNum] = math.min(lowLink[blockNum], dfsIndex[succNum]);
        }
        continue;
      }

      dfsStack.removeLast();
      if (dfsStack.isNotEmpty) {
        final parentNum = dfsStack.last.preorderNumber;
        lowLink[parentNum] = math.min(lowLink[parentNum], lowLink[blockNum]);
      }

      if (lowLink[blockNum] == dfsIndex[blockNum]) {
        // Filter out trivial SCCs, where a trivial SCC is a single block that
        // doesn't jump back to itself.
        if (sccStack.last == block && !successors.contains(block)) {
          sccStack.removeLast();
          onSccStack.remove(blockNum);
        } else {
          final scc = <Block>[];
          Block member;
          do {
            member = sccStack.removeLast();
            onSccStack.remove(member.preorderNumber);
            scc.add(member);
          } while (member != block);
          // Reverse so blocks (and loop entries) are ordered by DFS discovery
          // order rather than Tarjan stack pop order.
          _reverse(scc);
          result.add(scc);
        }
      }
    }
  }

  assert(sccStack.isEmpty && dfsStack.isEmpty);
  return result;
}

void _reverse(List<Block> list) {
  for (int i = 0, j = list.length - 1; i < j; ++i, --j) {
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
}
