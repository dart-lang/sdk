// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.graph_test;

import 'package:expect/expect.dart' show Expect;

import 'package:front_end/src/fasta/graph/graph.dart';

class TestGraph implements Graph<String> {
  final Map<String, List<String>> graph;

  TestGraph(this.graph);

  Iterable<String> get vertices => graph.keys;

  Iterable<String> neighborsOf(String vertex) => graph[vertex];
}

test(String expected, Map<String, List<String>> graph) {
  List<List<String>> result = computeStrongComponents(new TestGraph(graph));
  Expect.stringEquals(expected, "$result");
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
}
