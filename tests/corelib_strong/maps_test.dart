// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library maps_test;

import "package:expect/expect.dart";
import 'dart:collection';

main() {
  final key1 = "key1";
  final key2 = "key2";
  final key3 = "key3";
  final key4 = "key4";
  final key5 = "key5";
  final key6 = "key6";
  final key7 = "key7";
  final key8 = "key8";

  final value1 = 10;
  final value2 = 20;
  final value3 = 30;
  final value4 = 40;
  final value5 = 50;
  final value6 = 60;
  final value7 = 70;
  final value8 = 80;

  Map map = new Map();

  map[key1] = value1;
  map[key1] = value2;
  Expect.equals(false, Maps.containsKey(map, key2));
  Expect.equals(1, Maps.length(map));

  map[key1] = value1;
  // Add enough entries to make sure the table grows.
  map[key2] = value2;
  Expect.equals(2, Maps.length(map));
  map[key3] = value3;
  map[key4] = value4;
  map[key5] = value5;
  map[key6] = value6;
  map[key7] = value7;
  map[key8] = value8;
  Expect.equals(8, Maps.length(map));

  map.remove(key4);
  Expect.equals(false, Maps.containsKey(map, key4));
  Expect.equals(7, Maps.length(map));

  // Test clearing the table.
  Maps.clear(map);
  Expect.equals(0, Maps.length(map));
  Expect.equals(false, Maps.containsKey(map, key1));
  Expect.equals(false, map.containsKey(key1));
  Expect.equals(false, Maps.containsKey(map, key2));
  Expect.equals(false, map.containsKey(key2));
  Expect.equals(false, Maps.containsKey(map, key3));
  Expect.equals(false, map.containsKey(key3));
  Expect.equals(false, Maps.containsKey(map, key4));
  Expect.equals(false, map.containsKey(key4));
  Expect.equals(false, Maps.containsKey(map, key5));
  Expect.equals(false, map.containsKey(key5));
  Expect.equals(false, Maps.containsKey(map, key6));
  Expect.equals(false, map.containsKey(key6));
  Expect.equals(false, Maps.containsKey(map, key7));
  Expect.equals(false, map.containsKey(key7));
  Expect.equals(false, Maps.containsKey(map, key8));
  Expect.equals(false, map.containsKey(key8));

  // Test adding and removing again.
  map[key1] = value1;
  Expect.equals(1, Maps.length(map));
  map[key2] = value2;
  Expect.equals(2, Maps.length(map));
  map[key3] = value3;
  map.remove(key3);
  Expect.equals(2, Maps.length(map));
  map[key4] = value4;
  map.remove(key4);
  Expect.equals(2, Maps.length(map));
  map[key5] = value5;
  map.remove(key5);
  Expect.equals(2, Maps.length(map));
  map[key6] = value6;
  map.remove(key6);
  Expect.equals(2, Maps.length(map));
  map[key7] = value7;
  map.remove(key7);
  Expect.equals(2, Maps.length(map));
  map[key8] = value8;
  map.remove(key8);
  Expect.equals(2, Maps.length(map));

  Expect.equals(true, Maps.containsKey(map, key1));
  Expect.equals(true, Maps.containsValue(map, value1));

  // Test Map.forEach.
  Map other_map = new Map();
  void testForEachMap(key, value) {
    other_map[key] = value;
  }

  Maps.forEach(map, testForEachMap);
  Expect.equals(true, other_map.containsKey(key1));
  Expect.equals(true, other_map.containsKey(key2));
  Expect.equals(true, other_map.containsValue(value1));
  Expect.equals(true, other_map.containsValue(value2));
  Expect.equals(2, Maps.length(other_map));

  // Test Collection.values.
  void testForEachCollection(value) {
    other_map[value] = value;
  }

  Iterable values = Maps.getValues(map);
  other_map = new Map();
  values.forEach(testForEachCollection);
  Expect.equals(true, !other_map.containsKey(key1));
  Expect.equals(true, !other_map.containsKey(key2));
  Expect.equals(true, !other_map.containsValue(key1));
  Expect.equals(true, !other_map.containsValue(key2));
  Expect.equals(true, other_map.containsKey(value1));
  Expect.equals(true, other_map.containsKey(value2));
  Expect.equals(true, other_map.containsValue(value1));
  Expect.equals(true, other_map.containsValue(value2));
  Expect.equals(2, other_map.length);
  other_map.clear();

  // Test Map.putIfAbsent.
  map.clear();
  Expect.equals(false, Maps.containsKey(map, key1));
  Maps.putIfAbsent(map, key1, () => 10);
  Expect.equals(true, map.containsKey(key1));
  Expect.equals(10, map[key1]);
  Expect.equals(10, Maps.putIfAbsent(map, key1, () => 11));
}
