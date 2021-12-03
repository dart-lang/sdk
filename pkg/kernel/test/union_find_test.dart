// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/src/union_find.dart';

void testSame<T>(UnionFind<T> unionFind, T a, T b, bool expected) {
  expect(expected, unionFind.nodesInSameSet(unionFind[a], unionFind[b]));
}

void testSets<T>(UnionFind<T> unionFind, Set<Set<T>> sets) {
  for (Set<T> set in sets) {
    UnionFindNode<T> root = unionFind.findNode(unionFind[set.first]);
    for (T value in unionFind.values) {
      testSame(unionFind, value, root.value, set.contains(value));
    }
  }
}

void testFind<T>(UnionFind<T> unionFind, T value, T expected) {
  expect(expected, unionFind.findNode(unionFind[value]).value);
}

void testUnion<T>(UnionFind<T> unionFind, T a, T b, T expected) {
  expect(expected, unionFind.unionOfNodes(unionFind[a], unionFind[b]).value);
}

void main() {
  UnionFind<int> unionFind = new UnionFind();
  // {0}
  testFind(unionFind, 0, 0);
  testSame(unionFind, 0, 0, true);
  testSets(unionFind, {
    {0}
  });

  // {0}, {1}
  testFind(unionFind, 1, 1);
  testSame(unionFind, 0, 1, false);
  testSame(unionFind, 1, 0, false);
  testSame(unionFind, 1, 1, true);
  testSets(unionFind, {
    {0},
    {1}
  });

  // {0}, {1}, {2}
  testFind(unionFind, 2, 2);
  testSame(unionFind, 0, 2, false);
  testSame(unionFind, 1, 2, false);
  testSame(unionFind, 2, 2, true);
  testSets(unionFind, {
    {0},
    {1},
    {2}
  });

  // {0}, {1}, {2}
  testUnion(unionFind, 0, 0, 0);
  testSame(unionFind, 0, 0, true);
  testSame(unionFind, 0, 1, false);
  testSame(unionFind, 0, 2, false);
  testSets(unionFind, {
    {0},
    {1},
    {2}
  });

  // {0, 1}, {2}
  testUnion(unionFind, 0, 1, 0);
  testSame(unionFind, 0, 0, true);
  testSame(unionFind, 0, 1, true);
  testSame(unionFind, 1, 0, true);
  testSame(unionFind, 0, 2, false);
  testFind(unionFind, 0, 0);
  testFind(unionFind, 1, 0);
  testSets(unionFind, {
    {0, 1},
    {2}
  });

  // {0, 1}, {2, 3}
  testUnion(unionFind, 2, 3, 2);
  testSame(unionFind, 0, 0, true);
  testSame(unionFind, 0, 1, true);
  testSame(unionFind, 0, 2, false);
  testSame(unionFind, 0, 3, false);
  testSame(unionFind, 0, 0, true);
  testSame(unionFind, 0, 1, true);
  testSame(unionFind, 0, 2, false);
  testSame(unionFind, 0, 3, false);
  testFind(unionFind, 2, 2);
  testFind(unionFind, 3, 2);
  testSets(unionFind, {
    {0, 1},
    {2, 3}
  });

  // {0, 1, 2, 3}
  testUnion(unionFind, 1, 2, 0);
  testSets(unionFind, {
    {0, 1, 2, 3}
  });
}

void expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
