// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/src/async_dependency_walker.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsyncDependencyWalkerTest);
  });
}

@reflectiveTest
class AsyncDependencyWalkerTest {
  final nodes = <String, TestNode>{};

  Future<Null> checkGraph(
      Map<String, List<String>> graph,
      String startingNodeName,
      List<List<String>> expectedEvaluations,
      List<bool> expectedSccFlags) async {
    makeGraph(graph);
    var walker = await walk(startingNodeName);
    expect(walker._evaluations, expectedEvaluations.map((x) => x.toSet()));
    expect(walker._sccFlags, expectedSccFlags);
  }

  TestNode getNode(String name) =>
      nodes.putIfAbsent(name, () => new TestNode(name));

  void makeGraph(Map<String, List<String>> graph) {
    graph.forEach((name, deps) {
      var node = getNode(name);
      for (var dep in deps) {
        node._dependencies.add(getNode(dep));
      }
    });
  }

  test_complex_graph() async {
    await checkGraph(
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
  }

  test_diamond() async {
    await checkGraph(
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
  }

  test_singleNode() async {
    await checkGraph(
        {'a': []},
        'a',
        [
          ['a']
        ],
        [false]);
  }

  test_singleNodeWithTrivialCycle() async {
    await checkGraph(
        {
          'a': ['a']
        },
        'a',
        [
          ['a']
        ],
        [true]);
  }

  test_threeNodesWithCircularDependency() async {
    await checkGraph(
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
  }

  test_twoBacklinksEarlierFirst() async {
    // Test a graph A->B->C->D, where D points back to B and then C.
    await checkGraph(
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
  }

  test_twoBacklinksLaterFirst() async {
    // Test a graph A->B->C->D, where D points back to C and then B.
    await checkGraph(
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
  }

  test_twoNodesWithCircularDependency() async {
    await checkGraph(
        {
          'a': ['b'],
          'b': ['a']
        },
        'a',
        [
          ['a', 'b']
        ],
        [true]);
  }

  test_twoNodesWithSimpleDependency() async {
    await checkGraph(
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

  Future<TestWalker> walk(String startingNodeName) async {
    var testWalker = new TestWalker();
    await testWalker.walk(getNode(startingNodeName));
    return testWalker;
  }
}

class TestNode extends Node<TestNode> {
  final String _name;

  bool _computeDependenciesCalled = false;

  final _dependencies = <TestNode>[];

  TestNode(this._name);

  @override
  Future<List<TestNode>> computeDependencies() async {
    expect(_computeDependenciesCalled, false);
    _computeDependenciesCalled = true;
    return _dependencies;
  }
}

class TestWalker extends AsyncDependencyWalker<TestNode> {
  final _evaluations = <Set<String>>[];
  final _sccFlags = <bool>[];

  @override
  Future<Null> evaluate(TestNode v) async {
    _evaluations.add([v._name].toSet());
    _sccFlags.add(false);
  }

  @override
  Future<Null> evaluateScc(List<TestNode> scc) async {
    var sccNames = scc.map((node) => node._name).toSet();
    // Make sure there were no duplicates
    expect(sccNames.length, scc.length);
    _evaluations.add(sccNames);
    _sccFlags.add(true);
  }
}
