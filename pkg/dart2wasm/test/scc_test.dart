// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/flow_graph.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/ir/source_position.dart';
import 'package:dart2wasm/cfg/scc.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ast;

void main() {
  // Empty query and single acyclic block: 0
  checkSccs(edges: {0: []}, subgraph: [], expected: []);
  checkSccs(edges: {0: []}, subgraph: null, expected: []);

  // Diamond DAG: 0 -> {1, 2} -> 3
  checkSccs(
    edges: {
      0: [1, 2],
      1: [3],
      2: [3],
      3: [],
    },
    subgraph: null,
    expected: [],
  );

  // Single-block self-loop: 0 -> (1 <-> 1) -> 2
  final selfLoop = {
    0: [1],
    1: [1, 2],
    2: <int>[],
  };
  checkSccs(
    edges: selfLoop,
    subgraph: null,
    expected: [
      [1],
    ],
  );
  checkSccs(edges: selfLoop, subgraph: [0, 2], expected: []);

  // Branching SCC ordered by DFS discovery order: 1 <-> 0 <-> 2 (visiting 2 first)
  checkSccs(
    edges: {
      0: [2, 1],
      1: [0],
      2: [0],
    },
    subgraph: null,
    expected: [
      [0, 2, 1],
    ],
  );

  // Two SCCs in reverse topological order: 0 -> (1 <-> 2) -> (3 <-> 4)
  checkSccs(
    edges: {
      0: [3, 1],
      1: [2],
      2: [1, 3],
      3: [4],
      4: [3],
    },
    subgraph: null,
    expected: [
      [3, 4],
      [1, 2],
    ],
  );

  // Outer loop 0 <-> (1 <-> 2) -> (3 <-> 4) <-> 0:
  // - Full graph is a single SCC [0, 1, 2, 3, 4].
  // - Removing header 0 exposes inner SCCs [3, 4] and [1, 2].
  final nested = {
    0: [1, 4],
    1: [2],
    2: [1, 3, 0],
    3: [4],
    4: [3, 0],
  };
  checkSccs(
    edges: nested,
    subgraph: null,
    expected: [
      [0, 1, 2, 3, 4],
    ],
  );
  checkSccs(
    edges: nested,
    subgraph: [1, 2, 3, 4],
    expected: [
      [3, 4],
      [1, 2],
    ],
  );
}

void checkSccs({
  required Map<int, List<int>> edges,
  required List<int>? subgraph,
  required List<List<int>> expected,
}) {
  final proc = ast.Procedure(
    ast.Name('test'),
    ast.ProcedureKind.Method,
    ast.FunctionNode(null),
    fileUri: Uri.parse('test:///scc_test.dart'),
  );
  final graph = FlowGraph(FunctionRegistry().getFunction(proc));
  final blocks = <Block>[
    graph.entryBlock..preorderNumber = 0,
    for (int i = 1; i < edges.length; i++)
      JoinBlock(graph, noPosition)..preorderNumber = i,
  ];
  graph.preorder.addAll(blocks);
  edges.forEach((from, targets) {
    for (final to in targets) {
      blocks[from].successors.add(blocks[to]);
    }
  });

  final query = subgraph != null
      ? [for (final i in subgraph) blocks[i]]
      : blocks;
  final actual = [
    for (final scc in findNonTrivialSccs(query))
      [for (final b in scc) b.preorderNumber],
  ];
  Expect.deepEquals(expected, actual);
}
