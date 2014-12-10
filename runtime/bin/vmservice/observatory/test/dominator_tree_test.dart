// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/dominator_tree.dart';
import 'package:unittest/unittest.dart';

void main() {
  test('small example from [Lenguaer & Tarjan 1979]', smallTest);
  test('non-flowgraph', nonFlowgraph);
}

void smallTest() {
  var g = {
    'R': ['A', 'B', 'C'],
    'A': ['D'],
    'B': ['A', 'D', 'E'],
    'C': ['F', 'G'],
    'D': ['L'],
    'E': ['H'],
    'F': ['I'],
    'G': ['I', 'J'],
    'H': ['E', 'K'],
    'I': ['K'],
    'J': ['I'],
    'K': ['I', 'R'],
    'L': ['H'],
  };
  var d = new Dominator();
  for (String u in g.keys) {
    d.addEdges(u, g[u]);
  }
  d.computeDominatorTree('R');
  expect(d.dominator('I'), equals('R'));
  expect(d.dominator('K'), equals('R'));
  expect(d.dominator('C'), equals('R'));
  expect(d.dominator('H'), equals('R'));
  expect(d.dominator('E'), equals('R'));
  expect(d.dominator('A'), equals('R'));
  expect(d.dominator('D'), equals('R'));
  expect(d.dominator('B'), equals('R'));
  
  expect(d.dominator('F'), equals('C'));
  expect(d.dominator('G'), equals('C'));
  expect(d.dominator('J'), equals('G'));
  expect(d.dominator('L'), equals('D'));
  expect(d.dominator('R'), isNull);
}

void nonFlowgraph() {
  var d = new Dominator();
  d.addEdges('A', ['B']);
  expect(() => d.computeDominatorTree('B'), throwsStateError);
}