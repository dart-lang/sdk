// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.test.graph_test;

import 'package:expect/expect.dart' show Expect;

import 'package:kernel/util/graph.dart';

const String A = 'A';
const String B = 'B';
const String C = 'C';
const String D = 'D';
const String E = 'E';
const String F = 'F';

class TestGraph implements Graph<String> {
  final Map<String, List<String>> graph;

  TestGraph(this.graph);

  @override
  Iterable<String> get vertices => graph.keys;

  @override
  Iterable<String> neighborsOf(String vertex) => graph[vertex]!;
}

void test(
    {required List<List<String>> expectedStrongComponents,
    List<String> expectedSortedVertices = const [],
    List<String> expectedCyclicVertices = const [],
    List<List<String>> expectedLayers = const [],
    List<List<List<String>>> expectedStrongLayers = const [],
    required Map<String, List<String>> graphData}) {
  Graph<String> graph = new TestGraph(graphData);

  List<List<String>> strongComponentResult = computeStrongComponents(graph);
  Expect.equals(
      expectedStrongComponents.length,
      strongComponentResult.length,
      "Unexpected strongly connected components count. "
      "Expected ${expectedStrongComponents}, "
      "actual ${strongComponentResult}");
  for (int index = 0; index < expectedStrongComponents.length; index++) {
    Expect.listEquals(
        expectedStrongComponents[index],
        strongComponentResult[index],
        "Unexpected strongly connected components. "
        "Expected $expectedStrongComponents, actual $strongComponentResult.");
  }

  TopologicalSortResult<String> topologicalResult = topologicalSort(graph);
  Set<String> sortedAndCyclicVertices = topologicalResult.sortedVertices
      .toSet()
      .intersection(topologicalResult.cyclicVertices.toSet());
  Expect.isTrue(sortedAndCyclicVertices.isEmpty,
      "Found vertices both sorted and cyclic: $sortedAndCyclicVertices");
  List<String> sortedOrCyclicVertices = [
    ...topologicalResult.sortedVertices,
    ...topologicalResult.cyclicVertices
  ];
  Expect.equals(
      graphData.length,
      sortedOrCyclicVertices.length,
      "Unexpected vertex count. Expected ${graphData.length}, "
      "found ${sortedOrCyclicVertices.length}.");
  Expect.listEquals(
      expectedSortedVertices,
      topologicalResult.sortedVertices,
      "Unexpected sorted vertices. "
      "Expected $expectedSortedVertices, "
      "actual ${topologicalResult.sortedVertices}.");
  Expect.listEquals(
      expectedCyclicVertices,
      topologicalResult.cyclicVertices,
      "Unexpected cyclic vertices. "
      "Expected $expectedCyclicVertices, "
      "actual ${topologicalResult.cyclicVertices}.");
  Expect.equals(
      expectedLayers.length,
      topologicalResult.layers.length,
      "Unexpected topological layer count. "
      "Expected ${expectedLayers}, "
      "actual ${topologicalResult.layers}");
  for (int index = 0; index < expectedLayers.length; index++) {
    Expect.listEquals(
        expectedLayers[index],
        topologicalResult.layers[index],
        "Unexpected topological layers. "
        "Expected $expectedLayers, "
        "actual ${topologicalResult.layers}.");
    for (String vertex in topologicalResult.layers[index]) {
      int actualIndex = topologicalResult.indexMap[vertex]!;
      Expect.equals(
          index,
          actualIndex,
          "Unexpected topological index for $vertex. "
          "Expected $index, found $actualIndex.");
    }
  }

  StrongComponentGraph<String> strongComponentGraph =
      new StrongComponentGraph(graph, strongComponentResult);
  TopologicalSortResult<List<String>> strongTopologicalResult =
      topologicalSort(strongComponentGraph);
  Expect.equals(
      expectedStrongLayers.length,
      strongTopologicalResult.layers.length,
      "Unexpected strong topological layer count. "
      "Expected ${expectedStrongLayers}, "
      "actual ${strongTopologicalResult.layers}");
  for (int index = 0; index < expectedStrongLayers.length; index++) {
    List<List<String>> expectedStrongLayer = expectedStrongLayers[index];
    List<List<String>> strongLayer = strongTopologicalResult.layers[index];
    Expect.equals(
        expectedStrongLayer.length,
        strongLayer.length,
        "Unexpected strong topological layer $index count. "
        "Expected ${expectedStrongLayers}, "
        "actual ${strongTopologicalResult.layers}");

    for (int subIndex = 0; subIndex < expectedStrongLayer.length; subIndex++) {
      Expect.listEquals(
          expectedStrongLayer[subIndex],
          strongLayer[subIndex],
          "Unexpected strong topological layer $index. "
          "Expected $expectedStrongLayer, "
          "actual $strongLayer.");
    }
    for (List<String> vertex in strongTopologicalResult.layers[index]) {
      int actualIndex = strongTopologicalResult.indexMap[vertex]!;
      Expect.equals(
          index,
          actualIndex,
          "Unexpected strong topological index for $vertex. "
          "Expected $index, found $actualIndex.");
    }
  }
}

void main() {
  test(graphData: {
    A: [B],
    B: [A],
    C: [A],
    D: [C],
  }, expectedStrongComponents: [
    [B, A],
    [C],
    [D]
  ], expectedCyclicVertices: [
    B,
    A,
    C,
    D
  ], expectedStrongLayers: [
    [
      [B, A]
    ],
    [
      [C]
    ],
    [
      [D]
    ]
  ]);

  test(graphData: {}, expectedStrongComponents: []);

  test(graphData: {
    A: [],
    B: [],
    C: [],
    D: [],
  }, expectedStrongComponents: [
    [A],
    [B],
    [C],
    [D]
  ], expectedSortedVertices: [
    A,
    B,
    C,
    D
  ], expectedLayers: [
    [A, B, C, D]
  ], expectedStrongLayers: [
    [
      [A],
      [B],
      [C],
      [D]
    ]
  ]);

  test(graphData: {
    D: [C],
    C: [A],
    B: [A],
    A: [B],
  }, expectedStrongComponents: [
    [B, A],
    [C],
    [D]
  ], expectedCyclicVertices: [
    B,
    A,
    C,
    D
  ], expectedStrongLayers: [
    [
      [B, A]
    ],
    [
      [C]
    ],
    [
      [D]
    ]
  ]);

  test(graphData: {
    A: [B],
    B: [C],
    C: [D],
    D: [],
  }, expectedStrongComponents: [
    [D],
    [C],
    [B],
    [A]
  ], expectedSortedVertices: [
    D,
    C,
    B,
    A
  ], expectedLayers: [
    [D],
    [C],
    [B],
    [A]
  ], expectedStrongLayers: [
    [
      [D]
    ],
    [
      [C]
    ],
    [
      [B]
    ],
    [
      [A]
    ]
  ]);

  test(graphData: {
    D: [],
    C: [D],
    B: [C],
    A: [B],
  }, expectedStrongComponents: [
    [D],
    [C],
    [B],
    [A]
  ], expectedSortedVertices: [
    D,
    C,
    B,
    A
  ], expectedLayers: [
    [D],
    [C],
    [B],
    [A]
  ], expectedStrongLayers: [
    [
      [D]
    ],
    [
      [C]
    ],
    [
      [B]
    ],
    [
      [A]
    ]
  ]);

  test(graphData: {
    A: [],
    B: [A],
    C: [A],
    D: [B, C],
  }, expectedStrongComponents: [
    [A],
    [B],
    [C],
    [D]
  ], expectedSortedVertices: [
    A,
    B,
    C,
    D
  ], expectedLayers: [
    [A],
    [B, C],
    [D]
  ], expectedStrongLayers: [
    [
      [A]
    ],
    [
      [B],
      [C]
    ],
    [
      [D]
    ]
  ]);

  // Test a complex graph.
  test(graphData: {
    A: [B, C],
    B: [C, D],
    C: [],
    D: [C, E],
    E: [B, F],
    F: [C, D]
  }, expectedStrongComponents: [
    [C],
    [F, E, D, B],
    [A],
  ], expectedSortedVertices: [
    C
  ], expectedCyclicVertices: [
    E,
    D,
    B,
    A,
    F
  ], expectedLayers: [
    [C]
  ], expectedStrongLayers: [
    [
      [C]
    ],
    [
      [F, E, D, B]
    ],
    [
      [A]
    ]
  ]);

  // Test a diamond-shaped graph.
  test(graphData: {
    A: [B, C],
    B: [D],
    C: [D],
    D: []
  }, expectedStrongComponents: [
    [D],
    [B],
    [C],
    [A],
  ], expectedSortedVertices: [
    D,
    B,
    C,
    A
  ], expectedLayers: [
    [D],
    [B, C],
    [A]
  ], expectedStrongLayers: [
    [
      [D]
    ],
    [
      [B],
      [C]
    ],
    [
      [A]
    ]
  ]);

  // Test a graph with a single node.
  test(graphData: {
    A: []
  }, expectedStrongComponents: [
    [A]
  ], expectedSortedVertices: [
    A
  ], expectedLayers: [
    [A]
  ], expectedStrongLayers: [
    [
      [A]
    ]
  ]);

  // Test a graph with a single node and a trivial cycle.
  test(graphData: {
    A: [A]
  }, expectedStrongComponents: [
    [A]
  ], expectedCyclicVertices: [
    A
  ], expectedStrongLayers: [
    [
      [A]
    ]
  ]);

  // Test a graph with three nodes with circular dependencies.
  test(graphData: {
    A: [B],
    B: [C],
    C: [A],
  }, expectedStrongComponents: [
    [C, B, A]
  ], expectedCyclicVertices: [
    C,
    B,
    A
  ], expectedStrongLayers: [
    [
      [C, B, A]
    ]
  ]);

  // Test a graph A->B->C->D, where D points back to B and then C.
  test(graphData: {
    A: [B],
    B: [C],
    C: [D],
    D: [B, C]
  }, expectedStrongComponents: [
    [D, C, B],
    [A]
  ], expectedCyclicVertices: [
    D,
    C,
    B,
    A
  ], expectedStrongLayers: [
    [
      [D, C, B]
    ],
    [
      [A]
    ]
  ]);

  // Test a graph A->B->C->D, where D points back to C and then B.
  test(graphData: {
    A: [B],
    B: [C],
    C: [D],
    D: [C, B]
  }, expectedStrongComponents: [
    [D, C, B],
    [A]
  ], expectedCyclicVertices: [
    D,
    C,
    B,
    A
  ], expectedStrongLayers: [
    [
      [D, C, B]
    ],
    [
      [A]
    ]
  ]);

  // Test a graph with two nodes with circular dependencies.
  test(graphData: {
    A: [B],
    B: [A]
  }, expectedStrongComponents: [
    [B, A]
  ], expectedCyclicVertices: [
    B,
    A
  ], expectedStrongLayers: [
    [
      [B, A]
    ]
  ]);

  // Test a graph with two nodes and a single dependency.
  test(graphData: {
    A: [B],
    B: []
  }, expectedStrongComponents: [
    [B],
    [A]
  ], expectedSortedVertices: [
    B,
    A
  ], expectedLayers: [
    [B],
    [A]
  ], expectedStrongLayers: [
    [
      [B]
    ],
    [
      [A]
    ]
  ]);

  test(graphData: {
    A: [],
    B: [A],
    C: [B, D],
    D: [C],
    E: [A],
    F: [B],
  }, expectedStrongComponents: [
    [A],
    [B],
    [D, C],
    [E],
    [F],
  ], expectedSortedVertices: [
    A,
    B,
    E,
    F,
  ], expectedCyclicVertices: [
    D,
    C,
  ], expectedLayers: [
    [A],
    [B, E],
    [F],
  ], expectedStrongLayers: [
    [
      [A]
    ],
    [
      [B],
      [E]
    ],
    [
      [D, C],
      [F]
    ]
  ]);

  testTransitiveDependencies(graphData: {
    A: [B],
    B: [A],
  }, of: {
    A
  }, expected: {
    A,
    B,
  });

  testTransitiveDependencies(graphData: {}, of: {
    A,
    B,
    C,
    D,
    E,
    F,
  }, expected: {});

  {
    String MAIN = "MAIN";
    String DARTFFI = "DARTFFI";
    testTransitiveDependencies(graphData: {
      MAIN: [DARTFFI],
    }, of: {
      DARTFFI
    }, expected: {
      MAIN,
    });
  }

  testTransitiveDependencies(graphData: {
    A: [B],
    B: [C],
    C: [B, D],
    D: [C],
    E: [A],
    F: [B],
  }, of: {
    A
  }, expected: {
    A,
    E
  });

  {
    String MAIN = "MAIN";
    String TARGET = "TARGET";

    testTransitiveDependencies(graphData: {
      MAIN: [A, E],
      A: [B],
      B: [A, C],
      C: [TARGET],
      D: [],
      E: [D],
    }, of: {
      TARGET,
    }, expected: {
      C,
      B,
      A,
      MAIN,
    });

    testTransitiveDependencies(graphData: {
      MAIN: [A, E],
      A: [B],
      B: [A, C],
      C: [],
      D: [],
      E: [D],
    }, of: {
      TARGET,
    }, expected: {});

    testTransitiveDependencies(graphData: {
      MAIN: [A, C, E, TARGET],
      A: [B],
      B: [A, C],
      C: [],
      D: [],
      E: [D],
    }, of: {
      TARGET,
    }, expected: {
      MAIN,
    });
  }
}

void testTransitiveDependencies(
    {required Set<String> of,
    required Set<String> expected,
    required Map<String, List<String>> graphData}) {
  Graph<String> graph = new TestGraph(graphData);
  Set<String> actual = calculateTransitiveDependenciesOf(graph, of);
  Expect.setEquals(expected, actual);
}
