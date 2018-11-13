// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library kernel.test.graph_test;

import 'package:expect/expect.dart' show Expect;

import 'package:kernel/util/graph.dart';

class TestGraph implements Graph<String> {
  final Map<String, List<String>> graph;

  TestGraph(this.graph);

  Iterable<String> get vertices => graph.keys;

  Iterable<String> neighborsOf(String vertex) => graph[vertex];
}

void test(String expected, Map<String, List<String>> graph) {
  List<List<String>> result = computeStrongComponents(new TestGraph(graph));
  Expect.stringEquals(expected, "$result");
}

void checkGraph(Map<String, List<String>> graph, String startingNodeName,
    List<List<String>> expectedEvaluations, List<bool> expectedSccFlags) {
  List<List<String>> result = computeStrongComponents(new TestGraph(graph));
  List<List<String>> expectedReversed = <List<String>>[];
  for (List<String> list in expectedEvaluations) {
    expectedReversed.add(list.reversed.toList());
  }
  Expect.stringEquals(expectedReversed.join(", "), result.join(", "));
}

main() {
  test("[[B, A], [C], [D]]", {
    "A": ["B"],
    "B": ["A"],
    "C": ["A"],
    "D": ["C"],
  });

  test("[]", {});

  test("[[A], [B], [C], [D]]", {
    "A": [],
    "B": [],
    "C": [],
    "D": [],
  });

  test("[[B, A], [C], [D]]", {
    "D": ["C"],
    "C": ["A"],
    "B": ["A"],
    "A": ["B"],
  });

  test("[[D], [C], [B], [A]]", {
    "A": ["B"],
    "B": ["C"],
    "C": ["D"],
    "D": [],
  });

  test("[[D], [C], [B], [A]]", {
    "D": [],
    "C": ["D"],
    "B": ["C"],
    "A": ["B"],
  });

  test("[[A], [B], [C], [D]]", {
    "A": [],
    "B": ["A"],
    "C": ["A"],
    "D": ["B", "C"],
  });

  // Test a complex graph.
  checkGraph(
      {
        'a': ['b', 'c'],
        'b': ['c', 'd'],
        'c': [],
        'd': ['c', 'e'],
        'e': ['b', 'f'],
        'f': ['c', 'd']
      },
      'a',
      [
        ['c'],
        ['b', 'd', 'e', 'f'],
        ['a']
      ],
      [false, true, false]);

  // Test a diamond-shaped graph.
  checkGraph(
      {
        'a': ['b', 'c'],
        'b': ['d'],
        'c': ['d'],
        'd': []
      },
      'a',
      [
        ['d'],
        ['b'],
        ['c'],
        ['a']
      ],
      [false, false, false, false]);

  // Test a graph with a single node.
  checkGraph(
      {'a': []},
      'a',
      [
        ['a']
      ],
      [false]);

  // Test a graph with a single node and a trivial cycle.
  checkGraph(
      {
        'a': ['a']
      },
      'a',
      [
        ['a']
      ],
      [true]);

  // Test a graph with three nodes with circular dependencies.
  checkGraph(
      {
        'a': ['b'],
        'b': ['c'],
        'c': ['a'],
      },
      'a',
      [
        ['a', 'b', 'c']
      ],
      [true]);
  // Test a graph A->B->C->D, where D points back to B and then C.
  checkGraph(
      {
        'a': ['b'],
        'b': ['c'],
        'c': ['d'],
        'd': ['b', 'c']
      },
      'a',
      [
        ['b', 'c', 'd'],
        ['a']
      ],
      [true, false]);

  // Test a graph A->B->C->D, where D points back to C and then B.
  checkGraph(
      {
        'a': ['b'],
        'b': ['c'],
        'c': ['d'],
        'd': ['c', 'b']
      },
      'a',
      [
        ['b', 'c', 'd'],
        ['a']
      ],
      [true, false]);

  // Test a graph with two nodes with circular dependencies.
  checkGraph(
      {
        'a': ['b'],
        'b': ['a']
      },
      'a',
      [
        ['a', 'b']
      ],
      [true]);

  // Test a graph with two nodes and a single dependency.
  checkGraph(
      {
        'a': ['b'],
        'b': []
      },
      'a',
      [
        ['b'],
        ['a']
      ],
      [false, false]);
}
