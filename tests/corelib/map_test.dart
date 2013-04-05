// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library map_test;
import "package:expect/expect.dart";
import 'dart:collection';

void main() {
  test(new HashMap());
  test(new LinkedHashMap());
  test(new SplayTreeMap());
  test(new SplayTreeMap(Comparable.compare));
  testLinkedHashMap();
  testMapLiteral();
  testNullValue();
  testTypes();

  testWeirdStringKeys(new Map());
  testWeirdStringKeys(new Map<String, String>());
  testWeirdStringKeys(new HashMap());
  testWeirdStringKeys(new HashMap<String, String>());
  testWeirdStringKeys(new LinkedHashMap());
  testWeirdStringKeys(new LinkedHashMap<String, String>());
  testWeirdStringKeys(new SplayTreeMap());
  testWeirdStringKeys(new SplayTreeMap<String, String>());

  testNumericKeys(new Map());
  testNumericKeys(new Map<num, String>());
  testNumericKeys(new HashMap());
  testNumericKeys(new HashMap<num, String>());
  testNumericKeys(new LinkedHashMap());
  testNumericKeys(new LinkedHashMap<num, String>());
}


void test(Map map) {
  testDeletedElement(map);
  testMap(map, 1, 2, 3, 4, 5, 6, 7, 8);
  map.clear();
  testMap(map, "value1", "value2", "value3", "value4", "value5",
          "value6", "value7", "value8");
}

void testLinkedHashMap() {
  LinkedHashMap map = new LinkedHashMap();
  Expect.equals(false, map.containsKey(1));
  map[1] = 1;
  map[1] = 2;
  Expect.equals(1, map.length);
}

void testMap(Map map, key1, key2, key3, key4, key5, key6, key7, key8) {
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
  Map otherMap = new Map();
  void testForEachMap(key, value) {
    otherMap[key] = value;
  }
  map.forEach(testForEachMap);
  Expect.equals(true, otherMap.containsKey(key1));
  Expect.equals(true, otherMap.containsKey(key2));
  Expect.equals(true, otherMap.containsValue(value1));
  Expect.equals(true, otherMap.containsValue(value2));
  Expect.equals(2, otherMap.length);

  otherMap.clear();
  Expect.equals(0, otherMap.length);

  // Test Collection.keys.
  void testForEachCollection(value) {
    otherMap[value] = value;
  }
  Iterable keys = map.keys;
  keys.forEach(testForEachCollection);
  Expect.equals(true, otherMap.containsKey(key1));
  Expect.equals(true, otherMap.containsKey(key2));
  Expect.equals(true, otherMap.containsValue(key1));
  Expect.equals(true, otherMap.containsValue(key2));
  Expect.equals(true, !otherMap.containsKey(value1));
  Expect.equals(true, !otherMap.containsKey(value2));
  Expect.equals(true, !otherMap.containsValue(value1));
  Expect.equals(true, !otherMap.containsValue(value2));
  Expect.equals(2, otherMap.length);
  otherMap.clear();
  Expect.equals(0, otherMap.length);

  // Test Collection.values.
  Iterable values = map.values;
  values.forEach(testForEachCollection);
  Expect.equals(true, !otherMap.containsKey(key1));
  Expect.equals(true, !otherMap.containsKey(key2));
  Expect.equals(true, !otherMap.containsValue(key1));
  Expect.equals(true, !otherMap.containsValue(key2));
  Expect.equals(true, otherMap.containsKey(value1));
  Expect.equals(true, otherMap.containsKey(value2));
  Expect.equals(true, otherMap.containsValue(value1));
  Expect.equals(true, otherMap.containsValue(value2));
  Expect.equals(2, otherMap.length);
  otherMap.clear();
  Expect.equals(0, otherMap.length);

  // Test Map.putIfAbsent.
  map.clear();
  Expect.equals(false, map.containsKey(key1));
  map.putIfAbsent(key1, () => 10);
  Expect.equals(true, map.containsKey(key1));
  Expect.equals(10, map[key1]);
  Expect.equals(10,
      map.putIfAbsent(key1, () => 11));
}

void testDeletedElement(Map map) {
  map.clear();
  for (int i = 0; i < 100; i++) {
    map[1] = 2;
    Expect.equals(1, map.length);
    map.remove(1);
    Expect.equals(0, map.length);
  }
  Expect.equals(0, map.length);
}

void testMapLiteral() {
  Map m = {"a": 1, "b" : 2, "c": 3 };
  Expect.equals(3, m.length);
  int sum = 0;
  m.forEach((a, b) {
    sum += b;
  });
  Expect.equals(6, sum);

  List values = m.keys.toList();
  Expect.equals(3, values.length);
  String first = values[0];
  String second = values[1];
  String third = values[2];
  String all = "${first}${second}${third}";
  Expect.equals(3, all.length);
  Expect.equals(true, all.contains("a", 0));
  Expect.equals(true, all.contains("b", 0));
  Expect.equals(true, all.contains("c", 0));
}

void testNullValue() {
  Map m = {"a": 1, "b" : null, "c": 3 };

  Expect.equals(null, m["b"]);
  Expect.equals(true, m.containsKey("b"));
  Expect.equals(3, m.length);

  m["a"] = null;
  m["c"] = null;
  Expect.equals(null, m["a"]);
  Expect.equals(true, m.containsKey("a"));
  Expect.equals(null, m["c"]);
  Expect.equals(true, m.containsKey("c"));
  Expect.equals(3, m.length);

  m.remove("a");
  Expect.equals(2, m.length);
  Expect.equals(null, m["a"]);
  Expect.equals(false, m.containsKey("a"));
}

void testTypes() {
  Map<int, dynamic> map;
  testMap(Map map) {
    map[42] = "text";
    map[43] = "text";
    map[42] = "text";
    map.remove(42);
    map[42] = "text";
  }
  testMap(new HashMap<int, String>());
  testMap(new LinkedHashMap<int, String>());
  testMap(new SplayTreeMap<int, String>());
  testMap(new SplayTreeMap<int, String>(Comparable.compare));
  testMap(new SplayTreeMap<int, String>((int a, int b) => a.compareTo(b)));
  testMap(new HashMap<num, String>());
  testMap(new LinkedHashMap<num, String>());
  testMap(new SplayTreeMap<num, String>());
  testMap(new SplayTreeMap<num, String>(Comparable.compare));
  testMap(new SplayTreeMap<num, String>((num a, num b) => a.compareTo(b)));
}

void testWeirdStringKeys(Map map) {
  // Test weird keys.
  var weirdKeys = const [
      'hasOwnProperty',
      'constructor',
      'toLocaleString',
      'propertyIsEnumerable',
      '__defineGetter__',
      '__defineSetter__',
      '__lookupGetter__',
      '__lookupSetter__',
      'isPrototypeOf',
      'toString',
      'valueOf',
      '__proto__',
      '__count__',
      '__parent__',
      ''];
  Expect.isTrue(map.isEmpty);
  for (var key in weirdKeys) {
    Expect.isFalse(map.containsKey(key));
    Expect.equals(null, map[key]);
    var value = 'value:$key';
    map[key] = value;
    Expect.isTrue(map.containsKey(key));
    Expect.equals(value, map[key]);
    Expect.equals(value, map.remove(key));
    Expect.isFalse(map.containsKey(key));
    Expect.equals(null, map[key]);
  }
  Expect.isTrue(map.isEmpty);

}

void testNumericKeys(Map map) {
  var numericKeys = const [
      double.INFINITY,
      double.NEGATIVE_INFINITY,
      0,
      0.0,
      -0.0 ];

  Expect.isTrue(map.isEmpty);
  for (var key in numericKeys) {
    Expect.isFalse(map.containsKey(key));
    Expect.equals(null, map[key]);
    var value = 'value:$key';
    map[key] = value;
    Expect.isTrue(map.containsKey(key));
    Expect.equals(value, map[key]);
    Expect.equals(value, map.remove(key));
    Expect.isFalse(map.containsKey(key));
    Expect.equals(null, map[key]);
  }
  Expect.isTrue(map.isEmpty);

  // Test NaN.
  var nan = double.NAN;
  Expect.isFalse(map.containsKey(nan));
  Expect.equals(null, map[nan]);

  map[nan] = 'value:0';
  Expect.isFalse(map.containsKey(nan));
  Expect.equals(null, map[nan]);
  Expect.equals(1, map.length);

  map[nan] = 'value:1';
  Expect.isFalse(map.containsKey(nan));
  Expect.equals(null, map[nan]);
  Expect.equals(2, map.length);

  Expect.equals(null, map.remove(nan));
  Expect.equals(2, map.length);

  var count = 0;
  map.forEach((key, value) {
    if (key.isNaN) count++;
  });
  Expect.equals(2, count);

  map.clear();
  Expect.isTrue(map.isEmpty);
}
