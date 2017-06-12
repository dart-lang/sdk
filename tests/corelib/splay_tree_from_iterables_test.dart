// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:collection';

main() {
  positiveTest();
  emptyMapTest();
  fewerKeysIterableTest();
  fewerValuesIterableTest();
  equalElementsTest();
  genericTypeTest();
}

void positiveTest() {
  var map = new SplayTreeMap.fromIterables([1, 2, 3], ["one", "two", "three"]);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is SplayTreeMap);
  Expect.isFalse(map is HashMap);

  Expect.equals(3, map.length);
  Expect.equals(3, map.keys.length);
  Expect.equals(3, map.values.length);

  Expect.equals("one", map[1]);
  Expect.equals("two", map[2]);
  Expect.equals("three", map[3]);
}

void emptyMapTest() {
  var map = new SplayTreeMap.fromIterables([], []);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is SplayTreeMap);
  Expect.isFalse(map is HashMap);

  Expect.equals(0, map.length);
  Expect.equals(0, map.keys.length);
  Expect.equals(0, map.values.length);
}

void fewerValuesIterableTest() {
  Expect.throws(() => new SplayTreeMap.fromIterables([1, 2], [0]));
}

void fewerKeysIterableTest() {
  Expect.throws(() => new SplayTreeMap.fromIterables([1], [0, 2]));
}

void equalElementsTest() {
  var map = new SplayTreeMap.fromIterables([1, 2, 2], ["one", "two", "three"]);

  Expect.isTrue(map is Map);
  Expect.isTrue(map is SplayTreeMap);
  Expect.isFalse(map is HashMap);

  Expect.equals(2, map.length);
  Expect.equals(2, map.keys.length);
  Expect.equals(2, map.values.length);

  Expect.equals("one", map[1]);
  Expect.equals("three", map[2]);
}

void genericTypeTest() {
  var map = new SplayTreeMap<int, String>.fromIterables(
      [1, 2, 3], ["one", "two", "three"]);
  Expect.isTrue(map is Map<int, String>);
  Expect.isTrue(map is SplayTreeMap<int, String>);

  // Make sure it is not just SplayTreeMap<dynamic, dynamic>.
  Expect.isFalse(map is SplayTreeMap<String, dynamic>);
  Expect.isFalse(map is SplayTreeMap<dynamic, int>);

  Expect.equals(3, map.length);
  Expect.equals(3, map.keys.length);
  Expect.equals(3, map.values.length);

  Expect.equals("one", map[1]);
  Expect.equals("two", map[2]);
  Expect.equals("three", map[3]);
}
