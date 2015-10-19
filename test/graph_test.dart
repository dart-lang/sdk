// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2js_info/src/graph.dart';
import 'package:test/test.dart';

main() {
  var graph = makeTestGraph();

  test('preorder traversal', () {
    expect(graph.preOrder('A').toList(), equals(['A', 'E', 'D', 'C', 'B']));
  });

  test('postorder traversal', () {
    expect(graph.postOrder('A').toList(), equals(['C', 'E', 'D', 'B', 'A']));
  });

  test('topological sort', () {
    expect(
        graph.computeTopologicalSort(),
        equals([
          ['C'],
          ['E'],
          ['D', 'B', 'A']
        ]));
  });

  test('contains path', () {
    expect(graph.containsPath('A', 'C'), isTrue);
    expect(graph.containsPath('B', 'E'), isTrue);
    expect(graph.containsPath('C', 'A'), isFalse);
    expect(graph.containsPath('E', 'B'), isFalse);
  });

  test('dominator tree', () {
    // A dominates all other nodes in the graph, the resulting tree looks like
    //       A
    //    / / | |
    //    B C D E
    var dom = graph.dominatorTree('A');
    expect(dom.targetsOf('A').length, equals(4));
  });

  test('cycle finding', () {
    expect(graph.findCycleContaining('B'), equals(['A', 'D', 'B']));
    expect(graph.findCycleContaining('C'), equals(['C']));
  });
}

/// Creates a simple test graph with the following structure:
/// ```
///      A -> E
///     / ^   ^
///    /  \  /
///   v   v /
///  B -> D
///  \  /
///  v v
///   C
/// ```
Graph<String> makeTestGraph() {
  var graph = new EdgeListGraph<String>();
  graph.addEdge('A', 'B');
  graph.addEdge('A', 'D');
  graph.addEdge('A', 'E');
  graph.addEdge('B', 'C');
  graph.addEdge('B', 'D');
  graph.addEdge('D', 'A');
  graph.addEdge('D', 'C');
  graph.addEdge('D', 'E');
  return graph;
}
