// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// A subtest of the larger MapTest. Will eliminate once the full
// test is running.

import "package:expect/expect.dart";

class MapTest {
  static void testDeletedElement(Map map) {
    map.clear();
    for (int i = 0; i < 100; i++) {
      map[1] = 2;
      Expect.equals(1, map.length);
      int x = map.remove(1);
      Expect.equals(2, x);
      Expect.equals(0, map.length);
    }
    Expect.equals(0, map.length);
    for (int i = 0; i < 100; i++) {
      map[i] = 2;
      Expect.equals(1, map.length);
      int x = map.remove(105);
      Expect.equals(null, x);
      Expect.equals(1, map.length);
      x = map.remove(i);
      Expect.equals(2, x);
      Expect.equals(0, map.length);
    }
    Expect.equals(0, map.length);
    map.remove(105);
  }

  static void test(Map map) {
    testDeletedElement(map);
    testMap(map, 1, 2, 3, 4, 5, 6, 7, 8);
    map.clear();
    testMap(map, "value1", "value2", "value3", "value4", "value5", "value6",
        "value7", "value8");
  }

  static void testMap(Map map, key1, key2, key3, key4, key5, key6, key7, key8) {
    int value1 = 10;
    int value2 = 20;
    int value3 = 30;
    int value4 = 40;
    int value5 = 50;
    int value6 = 60;
    int value7 = 70;
    int value8 = 80;

    Expect.equals(0, map.length);

    map[key1] = value1;
    Expect.equals(value1, map[key1]);
    map[key1] = value2;
    Expect.equals(false, map.containsKey(key2));
    Expect.equals(1, map.length);

    map[key1] = value1;
    Expect.equals(value1, map[key1]);
    // Add enough entries to make sure the table grows.
    map[key2] = value2;
    Expect.equals(value2, map[key2]);
    Expect.equals(2, map.length);
    map[key3] = value3;
    Expect.equals(value2, map[key2]);
    Expect.equals(value3, map[key3]);
    map[key4] = value4;
    Expect.equals(value3, map[key3]);
    Expect.equals(value4, map[key4]);
    map[key5] = value5;
    Expect.equals(value4, map[key4]);
    Expect.equals(value5, map[key5]);
    map[key6] = value6;
    Expect.equals(value5, map[key5]);
    Expect.equals(value6, map[key6]);
    map[key7] = value7;
    Expect.equals(value6, map[key6]);
    Expect.equals(value7, map[key7]);
    map[key8] = value8;
    Expect.equals(value1, map[key1]);
    Expect.equals(value2, map[key2]);
    Expect.equals(value3, map[key3]);
    Expect.equals(value4, map[key4]);
    Expect.equals(value5, map[key5]);
    Expect.equals(value6, map[key6]);
    Expect.equals(value7, map[key7]);
    Expect.equals(value8, map[key8]);
    Expect.equals(8, map.length);

    map.remove(key4);
    Expect.equals(false, map.containsKey(key4));
    Expect.equals(7, map.length);

    // Test clearing the table.
    map.clear();
    Expect.equals(0, map.length);
    Expect.equals(false, map.containsKey(key1));
    Expect.equals(false, map.containsKey(key2));
    Expect.equals(false, map.containsKey(key3));
    Expect.equals(false, map.containsKey(key4));
    Expect.equals(false, map.containsKey(key5));
    Expect.equals(false, map.containsKey(key6));
    Expect.equals(false, map.containsKey(key7));
    Expect.equals(false, map.containsKey(key8));

    // Test adding and removing again.
    map[key1] = value1;
    Expect.equals(value1, map[key1]);
    Expect.equals(1, map.length);
    map[key2] = value2;
    Expect.equals(value2, map[key2]);
    Expect.equals(2, map.length);
    map[key3] = value3;
    Expect.equals(value3, map[key3]);
    map.remove(key3);
    Expect.equals(2, map.length);
    map[key4] = value4;
    Expect.equals(value4, map[key4]);
    map.remove(key4);
    Expect.equals(2, map.length);
    map[key5] = value5;
    Expect.equals(value5, map[key5]);
    map.remove(key5);
    Expect.equals(2, map.length);
    map[key6] = value6;
    Expect.equals(value6, map[key6]);
    map.remove(key6);
    Expect.equals(2, map.length);
    map[key7] = value7;
    Expect.equals(value7, map[key7]);
    map.remove(key7);
    Expect.equals(2, map.length);
    map[key8] = value8;
    Expect.equals(value8, map[key8]);
    map.remove(key8);
    Expect.equals(2, map.length);

    Expect.equals(true, map.containsKey(key1));
    Expect.equals(true, map.containsValue(value1));

    // Test Map.forEach.
    Map other_map = new Map();
    void testForEachMap(key, value) {
      other_map[key] = value;
    }

    map.forEach(testForEachMap);
    Expect.equals(true, other_map.containsKey(key1));
    Expect.equals(true, other_map.containsKey(key2));
    Expect.equals(true, other_map.containsValue(value1));
    Expect.equals(true, other_map.containsValue(value2));
    Expect.equals(2, other_map.length);

    other_map.clear();
    Expect.equals(0, other_map.length);

    // Test Collection.keys.
    void testForEachCollection(value) {
      other_map[value] = value;
    }

    Iterable keys = map.keys;
    keys.forEach(testForEachCollection);
    Expect.equals(true, other_map.containsKey(key1));
    Expect.equals(true, other_map.containsKey(key2));
    Expect.equals(true, other_map.containsValue(key1));
    Expect.equals(true, other_map.containsValue(key2));
    Expect.equals(true, !other_map.containsKey(value1));
    Expect.equals(true, !other_map.containsKey(value2));
    Expect.equals(true, !other_map.containsValue(value1));
    Expect.equals(true, !other_map.containsValue(value2));
    Expect.equals(2, other_map.length);
    other_map.clear();
    Expect.equals(0, other_map.length);

    // Test Collection.values.
    Iterable values = map.values;
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
    Expect.equals(0, other_map.length);

    // Test Map.putIfAbsent.
    map.clear();
    Expect.equals(false, map.containsKey(key1));
    map.putIfAbsent(key1, () => 10);
    Expect.equals(true, map.containsKey(key1));
    Expect.equals(10, map[key1]);
    Expect.equals(10, map.putIfAbsent(key1, () => 11));
  }

  static testKeys(Map map) {
    map[1] = 101;
    map[2] = 102;
    Iterable k = map.keys;
    Expect.equals(2, k.length);
    Iterable v = map.values;
    Expect.equals(2, v.length);
    Expect.equals(true, map.containsValue(101));
    Expect.equals(true, map.containsValue(102));
    Expect.equals(false, map.containsValue(103));
  }

  static testMain() {
    test(new Map());
    testKeys(new Map());
  }
}

main() {
  MapTest.testMain();
}
