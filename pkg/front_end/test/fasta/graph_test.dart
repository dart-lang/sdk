// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.graph_test;

import 'package:expect/expect.dart' show Expect;

import 'package:test_reflective_loader/test_reflective_loader.dart'
    show defineReflectiveSuite, defineReflectiveTests, reflectiveTest;

import 'package:kernel/util/graph.dart';

import '../src/dependency_walker_test.dart' show DependencyWalkerTest;

class TestGraph implements Graph<String> {
  final Map<String, List<String>> graph;

  TestGraph(this.graph);

  Iterable<String> get vertices => graph.keys;

  Iterable<String> neighborsOf(String vertex) => graph[vertex];
}

main() {
  // TODO(ahe): Delete this file and move DependencyWalkerTest to
  // pkg/kernel/test/graph_test.dart.
  defineReflectiveSuite(() {
    defineReflectiveTests(GraphTest);
  });
}

@reflectiveTest
class GraphTest extends DependencyWalkerTest {
  void checkGraph(Map<String, List<String>> graph, String startingNodeName,
      List<List<String>> expectedEvaluations, List<bool> expectedSccFlags) {
    List<List<String>> result = computeStrongComponents(new TestGraph(graph));
    List<List<String>> expectedReversed = <List<String>>[];
    for (List<String> list in expectedEvaluations) {
      expectedReversed.add(list.reversed.toList());
    }
    Expect.stringEquals(expectedReversed.join(", "), result.join(", "));
  }
}
