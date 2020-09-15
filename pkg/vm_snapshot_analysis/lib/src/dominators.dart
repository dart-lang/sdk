// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility methods for computing dominators of an arbitrary graph.
library vm_snapshot_analysis.src.dominators;

import 'dart:math' as math;

/// Compute dominator tree of the graph.
///
/// The code for dominator tree computation is taken verbatim from the
/// native compiler (see runtime/vm/compiler/backend/flow_graph.cc).
@pragma('vm:prefer-inline')
List<int> computeDominators({
  int size,
  int root,
  Iterable<int> succ(int n),
  Iterable<int> predOf(int n),
  void handleEdge(int from, int to),
}) {
  // Compute preorder numbering for the graph using DFS.
  final parent = List<int>.filled(size, -1);
  final preorder = List<int>.filled(size, null);
  final preorderNumber = List<int>.filled(size, null);

  var N = 0;
  void dfs() {
    final stack = [_DfsState(p: -1, n: root)];
    while (stack.isNotEmpty) {
      final s = stack.removeLast();
      final p = s.p;
      final n = s.n;
      handleEdge(s.n, s.p);
      if (preorderNumber[n] == null) {
        preorderNumber[n] = N;
        preorder[preorderNumber[n]] = n;
        parent[preorderNumber[n]] = p;

        for (var w in succ(n)) {
          stack.add(_DfsState(p: preorderNumber[n], n: w));
        }

        N++;
      }
    }
  }

  dfs();

  // Use the SEMI-NCA algorithm to compute dominators.  This is a two-pass
  // version of the Lengauer-Tarjan algorithm (LT is normally three passes)
  // that eliminates a pass by using nearest-common ancestor (NCA) to
  // compute immediate dominators from semidominators.  It also removes a
  // level of indirection in the link-eval forest data structure.
  //
  // The algorithm is described in Georgiadis, Tarjan, and Werneck's
  // "Finding Dominators in Practice".

  // All arrays are maps between preorder basic-block numbers.
  final idom = parent.toList(); // Immediate dominator.
  final semi = List<int>.generate(size, (i) => i); // Semidominator.
  final label =
      List<int>.generate(size, (i) => i); // Label for link-eval forest.

  void compressPath(int start, int current) {
    final next = parent[current];
    if (next > start) {
      compressPath(start, next);
      label[current] = math.min(label[current], label[next]);
      parent[current] = parent[next];
    }
  }

  // 1. First pass: compute semidominators as in Lengauer-Tarjan.
  // Semidominators are computed from a depth-first spanning tree and are an
  // approximation of immediate dominators.

  // Use a link-eval data structure with path compression.  Implement path
  // compression in place by mutating the parent array.  Each block has a
  // label, which is the minimum block number on the compressed path.

  // Loop over the blocks in reverse preorder (not including the graph
  // entry).
  for (var block_index = size - 1; block_index >= 1; --block_index) {
    // Loop over the predecessors.
    final block = preorder[block_index];
    // Clear the immediately dominated blocks in case ComputeDominators is
    // used to recompute them.
    for (final pred in predOf(block)) {
      // Look for the semidominator by ascending the semidominator path
      // starting from pred.
      final pred_index = preorderNumber[pred];
      var best = pred_index;
      if (pred_index > block_index) {
        compressPath(block_index, pred_index);
        best = label[pred_index];
      }

      // Update the semidominator if we've found a better one.
      semi[block_index] = math.min(semi[block_index], semi[best]);
    }

    // Now use label for the semidominator.
    label[block_index] = semi[block_index];
  }

  // 2. Compute the immediate dominators as the nearest common ancestor of
  // spanning tree parent and semidominator, for all blocks except the entry.
  final result = List<int>.filled(size, -1);
  for (var block_index = 1; block_index < size; ++block_index) {
    var dom_index = idom[block_index];
    while (dom_index > semi[block_index]) {
      dom_index = idom[dom_index];
    }
    idom[block_index] = dom_index;
    result[preorder[block_index]] = preorder[dom_index];
  }
  return result;
}

class _DfsState {
  final int p;
  final int n;
  _DfsState({this.p, this.n});
}
