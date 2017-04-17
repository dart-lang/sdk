// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for linked hash-maps.
library linkedHashMap.test;

import "package:expect/expect.dart";
import 'dart:collection' show LinkedHashMap;

class LinkedHashMapTest {
  static void testMain() {
    Map map = new LinkedHashMap();
    map["a"] = 1;
    map["b"] = 2;
    map["c"] = 3;
    map["d"] = 4;
    map["e"] = 5;

    List<String> keys = new List<String>(5);
    List<int> values = new List<int>(5);

    int index;

    clear() {
      index = 0;
      for (int i = 0; i < keys.length; i++) {
        keys[i] = null;
        values[i] = null;
      }
    }

    verifyKeys(List<String> correctKeys) {
      for (int i = 0; i < correctKeys.length; i++) {
        Expect.equals(correctKeys[i], keys[i]);
      }
    }

    verifyValues(List<int> correctValues) {
      for (int i = 0; i < correctValues.length; i++) {
        Expect.equals(correctValues[i], values[i]);
      }
    }

    testForEachMap(Object key, Object value) {
      Expect.equals(map[key], value);
      keys[index] = key;
      values[index] = value;
      index++;
    }

    testForEachValue(Object v) {
      values[index++] = v;
    }

    testForEachKey(Object v) {
      keys[index++] = v;
    }

    final keysInOrder = const ["a", "b", "c", "d", "e"];
    final valuesInOrder = const [1, 2, 3, 4, 5];

    clear();
    map.forEach(testForEachMap);
    verifyKeys(keysInOrder);
    verifyValues(valuesInOrder);

    clear();
    map.keys.forEach(testForEachKey);
    verifyKeys(keysInOrder);

    clear();
    map.values.forEach(testForEachValue);
    verifyValues(valuesInOrder);

    // Remove and then insert.
    map.remove("b");
    map["b"] = 6;
    final keysAfterBMove = const ["a", "c", "d", "e", "b"];
    final valuesAfterBMove = const [1, 3, 4, 5, 6];

    clear();
    map.forEach(testForEachMap);
    verifyKeys(keysAfterBMove);
    verifyValues(valuesAfterBMove);

    clear();
    map.keys.forEach(testForEachKey);
    verifyKeys(keysAfterBMove);

    clear();
    map.values.forEach(testForEachValue);
    verifyValues(valuesAfterBMove);

    // Update.
    map["a"] = 0;
    final valuesAfterAUpdate = const [0, 3, 4, 5, 6];

    clear();
    map.forEach(testForEachMap);
    verifyKeys(keysAfterBMove);
    verifyValues(valuesAfterAUpdate);

    clear();
    map.keys.forEach(testForEachKey);
    verifyKeys(keysAfterBMove);

    clear();
    map.values.forEach(testForEachValue);
    verifyValues(valuesAfterAUpdate);
  }
}

main() {
  LinkedHashMapTest.testMain();
}
