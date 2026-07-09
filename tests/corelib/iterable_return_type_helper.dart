// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

testIntIterable(iterable) {
  Expect.isTrue(iterable is Iterable<int>, "${iterable.runtimeType}");
  Expect.isFalse(iterable is Iterable<String>, "${iterable.runtimeType}");
}

void testIterable(Iterable<int> iterable, [int depth = 3]) {
  testIntIterable(iterable);
  if (depth > 0) {
    testIterable(iterable.where((x) => true), depth - 1);
    testIterable(iterable.skip(1), depth - 1);
    testIterable(iterable.take(1), depth - 1);
    testIterable(iterable.skipWhile((x) => false), depth - 1);
    testIterable(iterable.takeWhile((x) => true), depth - 1);
    testList(iterable.toList(growable: true), depth - 1);
    testList(iterable.toList(growable: false), depth - 1);
    testIterable(iterable.toSet(), depth - 1);
  }
}

void testList(List<int> list, [int depth = 3]) {
  testIterable(list, depth);
  if (depth > 0) {
    testIterable(list.getRange(0, list.length), depth - 1);
    testIterable(list.reversed, depth - 1);
    testMap(list.asMap(), depth - 1);
  }
}

void testMap(Map<int, int> map, [int depth = 3]) {
  Expect.isTrue(map is Map<int, int>);
  Expect.isFalse(map is Map<int, String>);
  Expect.isFalse(map is Map<String, int>);
  if (depth > 0) {
    testIterable(map.keys, depth - 1);
    testIterable(map.values, depth - 1);
  }
}
