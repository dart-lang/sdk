// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void testListMapCorrespondence(List list, Map map) {
  Expect.equals(list.length, map.length);
  for (int i = 0; i < list.length; i++) {
    Expect.equals(list[i], map[i]);
  }
  Expect.isNull(map[list.length]);
  Expect.isNull(map[-1]);

  Iterable keys = map.keys;
  Iterable values = map.values;
  Expect.isFalse(keys is List);
  Expect.isFalse(values is List);
  Expect.equals(list.length, keys.length);
  Expect.equals(list.length, values.length);
  for (int i = 0; i < list.length; i++) {
    Expect.equals(i, keys.elementAt(i));
    Expect.equals(list[i], values.elementAt(i));
  }

  int forEachCount = 0;
  map.forEach((key, value) {
    Expect.equals(forEachCount, key);
    Expect.equals(list[key], value);
    forEachCount++;
  });

  for (int i = 0; i < list.length; i++) {
    Expect.isTrue(map.containsKey(i));
    Expect.isTrue(map.containsValue(list[i]));
  }
  Expect.isFalse(map.containsKey(-1));
  Expect.isFalse(map.containsKey(list.length));

  Expect.equals(list.length, forEachCount);

  Expect.equals(list.isEmpty, map.isEmpty);
}

void testConstAsMap(List list) {
  Map<int, dynamic> map = list.asMap();

  testListMapCorrespondence(list, map);

  Expect.throws(() => map[0] = 499, (e) => e is UnsupportedError);
  Expect.throws(
      () => map.putIfAbsent(0, () => 499), (e) => e is UnsupportedError);
  Expect.throws(() => map.clear(), (e) => e is UnsupportedError);
}

void testFixedAsMap(List list) {
  testConstAsMap(list);

  Map<int, dynamic> map = list.asMap();

  if (!list.isEmpty) {
    list[0] = 499;
    // Check again to make sure the map is backed by the list.
    testListMapCorrespondence(list, map);
  }
}

void testAsMap(List list) {
  testFixedAsMap(list);

  Map<int, dynamic> map = list.asMap();

  Iterable keys = map.keys;
  Iterable values = map.values;

  list.add(42);
  // Check again to make sure the map is backed by the list and that the
  // length is not cached.
  testListMapCorrespondence(list, map);
  // Also check that the keys and values iterable from the map are backed by
  // the list.
  Expect.equals(list.length, keys.length);
  Expect.equals(values.length, values.length);
}

main() {
  testConstAsMap(const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  testAsMap([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  List list = new List(10);
  for (int i = 0; i < 10; i++) list[i] = i + 1;
  testFixedAsMap(list);

  testConstAsMap(const []);
  testAsMap([]);
  testFixedAsMap(new List(0));
}
