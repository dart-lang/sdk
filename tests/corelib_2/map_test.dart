// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library map_test;

import "package:expect/expect.dart";
import 'dart:collection';
import 'dart:convert' show JSON;

Map<String, dynamic> newJsonMap() => JSON.decode('{}');
Map<String, dynamic> newJsonMapCustomReviver() =>
    JSON.decode('{}', reviver: (key, value) => value);

void main() {
  test(new HashMap());
  test(new LinkedHashMap());
  test(new SplayTreeMap());
  test(new SplayTreeMap(Comparable.compare));
  test(new MapView(new HashMap()));
  test(new MapView(new SplayTreeMap()));
  test(new MapBaseMap());
  test(new MapMixinMap());
  test(newJsonMap());
  test(newJsonMapCustomReviver());
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
  testWeirdStringKeys(new MapBaseMap<String, String>());
  testWeirdStringKeys(new MapMixinMap<String, String>());
  testWeirdStringKeys(newJsonMap());
  testWeirdStringKeys(newJsonMapCustomReviver());

  testNumericKeys(new Map());
  testNumericKeys(new Map<num, String>());
  testNumericKeys(new HashMap());
  testNumericKeys(new HashMap<num, String>());
  testNumericKeys(new HashMap.identity());
  testNumericKeys(new HashMap<num, String>.identity());
  testNumericKeys(new LinkedHashMap());
  testNumericKeys(new LinkedHashMap<num, String>());
  testNumericKeys(new LinkedHashMap.identity());
  testNumericKeys(new LinkedHashMap<num, String>.identity());
  testNumericKeys(new MapBaseMap<num, String>());
  testNumericKeys(new MapMixinMap<num, String>());

  testNaNKeys(new Map());
  testNaNKeys(new Map<num, String>());
  testNaNKeys(new HashMap());
  testNaNKeys(new HashMap<num, String>());
  testNaNKeys(new LinkedHashMap());
  testNaNKeys(new LinkedHashMap<num, String>());
  testNaNKeys(new MapBaseMap<num, String>());
  testNaNKeys(new MapMixinMap<num, String>());
  // Identity maps fail the NaN-keys tests because the test assumes that
  // NaN is not equal to NaN.

  testIdentityMap(new Map.identity());
  testIdentityMap(new HashMap.identity());
  testIdentityMap(new LinkedHashMap.identity());
  testIdentityMap(new HashMap(equals: identical, hashCode: identityHashCode));
  testIdentityMap(
      new LinkedHashMap(equals: identical, hashCode: identityHashCode));
  testIdentityMap(new HashMap(
      equals: (x, y) => identical(x, y), hashCode: (x) => identityHashCode(x)));
  testIdentityMap(new LinkedHashMap(
      equals: (x, y) => identical(x, y), hashCode: (x) => identityHashCode(x)));

  testCustomMap(new HashMap(
      equals: myEquals,
      hashCode: myHashCode,
      isValidKey: (v) => v is Customer));
  testCustomMap(new LinkedHashMap(
      equals: myEquals,
      hashCode: myHashCode,
      isValidKey: (v) => v is Customer));
  testCustomMap(
      new HashMap<Customer, dynamic>(equals: myEquals, hashCode: myHashCode));

  testCustomMap(new LinkedHashMap<Customer, dynamic>(
      equals: myEquals, hashCode: myHashCode));

  testIterationOrder(new LinkedHashMap());
  testIterationOrder(new LinkedHashMap.identity());
  testIterationOrder(newJsonMap());
  testIterationOrder(newJsonMapCustomReviver());

  testOtherKeys(new SplayTreeMap<int, int>());
  testOtherKeys(
      new SplayTreeMap<int, int>((int a, int b) => a - b, (v) => v is int));
  testOtherKeys(new SplayTreeMap((int a, int b) => a - b, (v) => v is int));
  testOtherKeys(new HashMap<int, int>());
  testOtherKeys(new HashMap<int, int>.identity());
  testOtherKeys(new HashMap<int, int>(
      hashCode: (v) => v.hashCode, isValidKey: (v) => v is int));
  testOtherKeys(new HashMap(
      equals: (int x, int y) => x == y,
      hashCode: (int v) => v.hashCode,
      isValidKey: (v) => v is int));
  testOtherKeys(new LinkedHashMap<int, int>());
  testOtherKeys(new LinkedHashMap<int, int>.identity());
  testOtherKeys(new LinkedHashMap<int, int>(
      hashCode: (v) => v.hashCode, isValidKey: (v) => v is int));
  testOtherKeys(new LinkedHashMap(
      equals: (int x, int y) => x == y,
      hashCode: (int v) => v.hashCode,
      isValidKey: (v) => v is int));
  testOtherKeys(new MapBaseMap<int, int>());
  testOtherKeys(new MapMixinMap<int, int>());

  testUnmodifiableMap(const {1: 37});
  testUnmodifiableMap(new UnmodifiableMapView({1: 37}));
  testUnmodifiableMap(new UnmodifiableMapBaseMap([1, 37]));

  testFrom();
}

void test<K, V>(Map<K, V> map) {
  testDeletedElement(map);
  if (map is Map<int, dynamic>) {
    testMap(map, 1, 2, 3, 4, 5, 6, 7, 8);
  } else {
    map.clear();
    testMap(map, "value1", "value2", "value3", "value4", "value5", "value6",
        "value7", "value8");
  }
}

void testLinkedHashMap() {
  LinkedHashMap map = new LinkedHashMap();
  Expect.isFalse(map.containsKey(1));
  map[1] = 1;
  map[1] = 2;
  testLength(1, map);
}

void testMap<K, V>(
    Map<K, V> typedMap, key1, key2, key3, key4, key5, key6, key7, key8) {
  Map map = typedMap;
  int value1 = 10;
  int value2 = 20;
  int value3 = 30;
  int value4 = 40;
  int value5 = 50;
  int value6 = 60;
  int value7 = 70;
  int value8 = 80;

  testLength(0, map);

  map[key1] = value1;
  Expect.equals(value1, map[key1]);
  map[key1] = value2;
  Expect.isFalse(map.containsKey(key2));
  testLength(1, map);

  map[key1] = value1;
  Expect.equals(value1, map[key1]);
  // Add enough entries to make sure the table grows.
  map[key2] = value2;
  Expect.equals(value2, map[key2]);
  testLength(2, map);
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
  testLength(8, map);

  map.remove(key4);
  Expect.isFalse(map.containsKey(key4));
  testLength(7, map);

  // Test clearing the table.
  map.clear();
  testLength(0, map);
  Expect.isFalse(map.containsKey(key1));
  Expect.isFalse(map.containsKey(key2));
  Expect.isFalse(map.containsKey(key3));
  Expect.isFalse(map.containsKey(key4));
  Expect.isFalse(map.containsKey(key5));
  Expect.isFalse(map.containsKey(key6));
  Expect.isFalse(map.containsKey(key7));
  Expect.isFalse(map.containsKey(key8));

  // Test adding and removing again.
  map[key1] = value1;
  Expect.equals(value1, map[key1]);
  testLength(1, map);
  map[key2] = value2;
  Expect.equals(value2, map[key2]);
  testLength(2, map);
  map[key3] = value3;
  Expect.equals(value3, map[key3]);
  map.remove(key3);
  testLength(2, map);
  map[key4] = value4;
  Expect.equals(value4, map[key4]);
  map.remove(key4);
  testLength(2, map);
  map[key5] = value5;
  Expect.equals(value5, map[key5]);
  map.remove(key5);
  testLength(2, map);
  map[key6] = value6;
  Expect.equals(value6, map[key6]);
  map.remove(key6);
  testLength(2, map);
  map[key7] = value7;
  Expect.equals(value7, map[key7]);
  map.remove(key7);
  testLength(2, map);
  map[key8] = value8;
  Expect.equals(value8, map[key8]);
  map.remove(key8);
  testLength(2, map);

  Expect.isTrue(map.containsKey(key1));
  Expect.isTrue(map.containsValue(value1));

  // Test Map.forEach.
  Map otherMap = new Map<K, V>();
  void testForEachMap(key, value) {
    otherMap[key] = value;
  }

  map.forEach(testForEachMap);
  Expect.isTrue(otherMap.containsKey(key1));
  Expect.isTrue(otherMap.containsKey(key2));
  Expect.isTrue(otherMap.containsValue(value1));
  Expect.isTrue(otherMap.containsValue(value2));
  Expect.equals(2, otherMap.length);

  otherMap.clear();
  Expect.equals(0, otherMap.length);

  // Test Collection.keys.
  void testForEachKey(key) {
    otherMap[key] = null;
  }

  Iterable keys = map.keys;
  keys.forEach(testForEachKey);
  Expect.isTrue(otherMap.containsKey(key1));
  Expect.isTrue(otherMap.containsKey(key2));
  Expect.isFalse(otherMap.containsKey(value1));
  Expect.isFalse(otherMap.containsKey(value2));

  Expect.isTrue(otherMap.containsValue(null));
  Expect.isFalse(otherMap.containsValue(value1));
  Expect.isFalse(otherMap.containsValue(value2));
  Expect.equals(2, otherMap.length);
  otherMap.clear();
  Expect.equals(0, otherMap.length);

  // Test Collection.values.
  void testForEachValue(value) {
    if (value == value1) {
      otherMap[key1] = value;
    } else if (value == value2) {
      otherMap[key2] = value;
    } else {
      otherMap[key3] = null;
    }
  }

  Iterable values = map.values;
  values.forEach(testForEachValue);
  Expect.isTrue(otherMap.containsKey(key1));
  Expect.isTrue(otherMap.containsKey(key2));
  Expect.isFalse(otherMap.containsKey(value1));
  Expect.isFalse(otherMap.containsKey(value2));

  Expect.isTrue(otherMap.containsValue(value1));
  Expect.isTrue(otherMap.containsValue(value2));
  Expect.isFalse(otherMap.containsValue(value3));
  Expect.isFalse(otherMap.containsValue(key1));
  Expect.isFalse(otherMap.containsValue(null));
  Expect.equals(2, otherMap.length);
  otherMap.clear();
  Expect.equals(0, otherMap.length);

  // Test Map.putIfAbsent.
  map.clear();
  Expect.isFalse(map.containsKey(key1));
  map.putIfAbsent(key1, () => 10);
  Expect.isTrue(map.containsKey(key1));
  Expect.equals(10, map[key1]);
  Expect.equals(10, map.putIfAbsent(key1, () => 11));

  // Test Map.addAll.
  map.clear();
  otherMap.clear();
  otherMap['99'] = 1;
  otherMap['50'] = 50;
  otherMap['1'] = 99;
  map.addAll(otherMap);
  Expect.equals(3, map.length);
  Expect.equals(1, map['99']);
  Expect.equals(50, map['50']);
  Expect.equals(99, map['1']);
  otherMap['50'] = 42;
  map.addAll(new HashMap<K, V>.from(otherMap));
  Expect.equals(3, map.length);
  Expect.equals(1, map['99']);
  Expect.equals(42, map['50']);
  Expect.equals(99, map['1']);
  otherMap['99'] = 7;
  map.addAll(new SplayTreeMap<K, V>.from(otherMap));
  Expect.equals(3, map.length);
  Expect.equals(7, map['99']);
  Expect.equals(42, map['50']);
  Expect.equals(99, map['1']);
  otherMap.remove('99');
  map['99'] = 0;
  map.addAll(otherMap);
  Expect.equals(3, map.length);
  Expect.equals(0, map['99']);
  Expect.equals(42, map['50']);
  Expect.equals(99, map['1']);
  map.clear();
  otherMap.clear();
  map.addAll(otherMap);
  Expect.equals(0, map.length);
}

void testDeletedElement(Map map) {
  map.clear();
  for (int i = 0; i < 100; i++) {
    map['1'] = 2;
    testLength(1, map);
    map.remove('1');
    testLength(0, map);
  }
  testLength(0, map);
}

void testMapLiteral() {
  Map m = {"a": 1, "b": 2, "c": 3};
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
  Expect.isTrue(all.contains("a", 0));
  Expect.isTrue(all.contains("b", 0));
  Expect.isTrue(all.contains("c", 0));
}

void testNullValue() {
  Map m = {"a": 1, "b": null, "c": 3};

  Expect.equals(null, m["b"]);
  Expect.isTrue(m.containsKey("b"));
  Expect.equals(3, m.length);

  m["a"] = null;
  m["c"] = null;
  Expect.equals(null, m["a"]);
  Expect.isTrue(m.containsKey("a"));
  Expect.equals(null, m["c"]);
  Expect.isTrue(m.containsKey("c"));
  Expect.equals(3, m.length);

  m.remove("a");
  Expect.equals(2, m.length);
  Expect.equals(null, m["a"]);
  Expect.isFalse(m.containsKey("a"));
}

void testTypes() {
  testMap(Map<num, String> map) {
    Expect.isTrue(map is Map<num, String>);
    Expect.isTrue(map is! Map<String, dynamic>);
    Expect.isTrue(map is! Map<dynamic, int>);

    // Use with properly typed keys and values.
    map[42] = "text1";
    map[43] = "text2";
    map[42] = "text3";
    Expect.equals("text3", map.remove(42));
    Expect.equals(null, map[42]);
    map[42] = "text4";

    // Ensure that "containsKey", "containsValue" and "remove"
    // accepts any object.
    for (var object in [true, null, new Object()]) {
      Expect.isFalse(map.containsKey(object));
      Expect.isFalse(map.containsValue(object));
      Expect.isNull(map.remove(object));
      Expect.isNull(map[object]);
    }
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
    ''
  ];
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
    -0.0
  ];

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
}

void testNaNKeys(Map map) {
  Expect.isTrue(map.isEmpty);
  // Test NaN.
  var nan = double.NAN;
  Expect.isFalse(map.containsKey(nan));
  Expect.equals(null, map[nan]);

  map[nan] = 'value:0';
  Expect.isFalse(map.containsKey(nan));
  Expect.equals(null, map[nan]);
  testLength(1, map);

  map[nan] = 'value:1';
  Expect.isFalse(map.containsKey(nan));
  Expect.equals(null, map[nan]);
  testLength(2, map);

  Expect.equals(null, map.remove(nan));
  testLength(2, map);

  var count = 0;
  map.forEach((key, value) {
    if (key.isNaN) count++;
  });
  Expect.equals(2, count);

  map.clear();
  Expect.isTrue(map.isEmpty);
}

void testLength(int length, Map map) {
  Expect.equals(length, map.length);
  Expect.equals(length, map.keys.length);
  Expect.equals(length, map.values.length);
  // Check being-empty.
  var ifEmpty = (length == 0) ? Expect.isTrue : Expect.isFalse;
  var ifNotEmpty = (length != 0) ? Expect.isTrue : Expect.isFalse;
  ifEmpty(map.isEmpty);
  ifNotEmpty(map.isNotEmpty);
  ifEmpty(map.keys.isEmpty);
  ifNotEmpty(map.keys.isNotEmpty);
  ifEmpty(map.values.isEmpty);
  ifNotEmpty(map.values.isNotEmpty);
  // Test key/value iterators match their isEmpty/isNotEmpty.
  ifNotEmpty(map.keys.iterator.moveNext());
  ifNotEmpty(map.values.iterator.moveNext());
  if (length == 0) {
    for (var k in map.keys) Expect.fail("contains key when iterating: $k");
    for (var v in map.values) Expect.fail("contains values when iterating: $v");
  }
}

testIdentityMap<K, V>(Map<K, V> typedMap) {
  Map map = typedMap;
  Expect.isTrue(map.isEmpty);

  var nan = double.NAN;
  // TODO(11551): Remove guard when dart2js makes identical(NaN, NaN) true.
  if (identical(nan, nan)) {
    map[nan] = 42;
    testLength(1, map);
    Expect.isTrue(map.containsKey(nan));
    Expect.equals(42, map[nan]);
    map[nan] = 37;
    testLength(1, map);
    Expect.equals(37, map[nan]);
    Expect.equals(37, map.remove(nan));
    testLength(0, map);
  }

  Vampire v1 = const Vampire(1);
  Vampire v2 = const Vampire(2);
  Expect.isFalse(v1 == v1);
  Expect.isFalse(v2 == v2);
  Expect.isTrue(v2 == v1); // Snob!

  map[v1] = 1;
  map[v2] = 2;
  testLength(2, map);

  Expect.isTrue(map.containsKey(v1));
  Expect.isTrue(map.containsKey(v2));

  Expect.equals(1, map[v1]);
  Expect.equals(2, map[v2]);

  Expect.equals(1, map.remove(v1));
  testLength(1, map);
  Expect.isFalse(map.containsKey(v1));
  Expect.isTrue(map.containsKey(v2));

  Expect.isNull(map.remove(v1));
  Expect.equals(2, map.remove(v2));
  testLength(0, map);

  var eq01 = new Equalizer(0);
  var eq02 = new Equalizer(0);
  var eq11 = new Equalizer(1);
  var eq12 = new Equalizer(1);
  // Sanity.
  Expect.equals(eq01, eq02);
  Expect.equals(eq02, eq01);
  Expect.equals(eq11, eq12);
  Expect.equals(eq12, eq11);
  Expect.notEquals(eq01, eq11);
  Expect.notEquals(eq01, eq12);
  Expect.notEquals(eq02, eq11);
  Expect.notEquals(eq02, eq12);
  Expect.notEquals(eq11, eq01);
  Expect.notEquals(eq11, eq02);
  Expect.notEquals(eq12, eq01);
  Expect.notEquals(eq12, eq02);

  map[eq01] = 0;
  map[eq02] = 1;
  map[eq11] = 2;
  map[eq12] = 3;
  testLength(4, map);

  Expect.equals(0, map[eq01]);
  Expect.equals(1, map[eq02]);
  Expect.equals(2, map[eq11]);
  Expect.equals(3, map[eq12]);

  Expect.isTrue(map.containsKey(eq01));
  Expect.isTrue(map.containsKey(eq02));
  Expect.isTrue(map.containsKey(eq11));
  Expect.isTrue(map.containsKey(eq12));

  Expect.equals(1, map.remove(eq02));
  Expect.equals(3, map.remove(eq12));
  testLength(2, map);
  Expect.isTrue(map.containsKey(eq01));
  Expect.isFalse(map.containsKey(eq02));
  Expect.isTrue(map.containsKey(eq11));
  Expect.isFalse(map.containsKey(eq12));

  Expect.equals(0, map[eq01]);
  Expect.equals(null, map[eq02]);
  Expect.equals(2, map[eq11]);
  Expect.equals(null, map[eq12]);

  Expect.equals(0, map.remove(eq01));
  Expect.equals(2, map.remove(eq11));
  testLength(0, map);

  map[eq01] = 0;
  map[eq02] = 1;
  map[eq11] = 2;
  map[eq12] = 3;
  testLength(4, map);

  // Transfer to equality-based map will collapse elements.
  Map eqMap = new HashMap<K, V>();
  eqMap.addAll(map);
  testLength(2, eqMap);
  Expect.isTrue(eqMap.containsKey(eq01));
  Expect.isTrue(eqMap.containsKey(eq02));
  Expect.isTrue(eqMap.containsKey(eq11));
  Expect.isTrue(eqMap.containsKey(eq12));

  // Changing objects will not affect identity map.
  map.clear();
  var m1 = new Mutable(1);
  var m2 = new Mutable(2);
  var m3 = new Mutable(3);
  map[m1] = 1;
  map[m2] = 2;
  map[m3] = 3;
  Expect.equals(3, map.length);
  Expect.isTrue(map.containsKey(m1));
  Expect.isTrue(map.containsKey(m2));
  Expect.isTrue(map.containsKey(m3));
  Expect.notEquals(m1, m3);
  m3.id = 1;
  Expect.equals(m1, m3);
  // Even if keys are equal, they are still not identical.
  // Even if hashcode of m3 changed, it can still be found.
  Expect.equals(1, map[m1]);
  Expect.equals(3, map[m3]);
}

/** Class of objects that are equal if they hold the same id. */
class Equalizer {
  int id;
  Equalizer(this.id);
  int get hashCode => id;
  bool operator ==(Object other) =>
      other is Equalizer && id == (other as Equalizer).id;
}

/**
 * Objects that are not reflexive.
 *
 * They think they are better than their equals.
 */
class Vampire {
  final int generation;
  const Vampire(this.generation);

  int get hashCode => generation;

  // The double-fang operator falsely claims that a vampire is equal to
  // any of its sire's generation.
  bool operator ==(Object other) =>
      other is Vampire && generation - 1 == (other as Vampire).generation;
}

void testCustomMap<K, V>(Map<K, V> typedMap) {
  Map map = typedMap;
  testLength(0, map);
  var c11 = const Customer(1, 1);
  var c12 = const Customer(1, 2);
  var c21 = const Customer(2, 1);
  var c22 = const Customer(2, 2);
  // Sanity.
  Expect.equals(c11, c12);
  Expect.notEquals(c11, c21);
  Expect.notEquals(c11, c22);
  Expect.equals(c21, c22);
  Expect.notEquals(c21, c11);
  Expect.notEquals(c21, c12);

  Expect.isTrue(myEquals(c11, c21));
  Expect.isFalse(myEquals(c11, c12));
  Expect.isFalse(myEquals(c11, c22));
  Expect.isTrue(myEquals(c12, c22));
  Expect.isFalse(myEquals(c12, c11));
  Expect.isFalse(myEquals(c12, c21));

  map[c11] = 42;
  testLength(1, map);
  Expect.isTrue(map.containsKey(c11));
  Expect.isTrue(map.containsKey(c21));
  Expect.isFalse(map.containsKey(c12));
  Expect.isFalse(map.containsKey(c22));
  Expect.equals(42, map[c11]);
  Expect.equals(42, map[c21]);

  map[c21] = 37;
  testLength(1, map);
  Expect.isTrue(map.containsKey(c11));
  Expect.isTrue(map.containsKey(c21));
  Expect.isFalse(map.containsKey(c12));
  Expect.isFalse(map.containsKey(c22));
  Expect.equals(37, map[c11]);
  Expect.equals(37, map[c21]);

  map[c22] = 42;
  testLength(2, map);
  Expect.isTrue(map.containsKey(c11));
  Expect.isTrue(map.containsKey(c21));
  Expect.isTrue(map.containsKey(c12));
  Expect.isTrue(map.containsKey(c22));
  Expect.equals(37, map[c11]);
  Expect.equals(37, map[c21]);
  Expect.equals(42, map[c12]);
  Expect.equals(42, map[c22]);

  Expect.equals(42, map.remove(c12));
  testLength(1, map);
  Expect.isTrue(map.containsKey(c11));
  Expect.isTrue(map.containsKey(c21));
  Expect.isFalse(map.containsKey(c12));
  Expect.isFalse(map.containsKey(c22));
  Expect.equals(37, map[c11]);
  Expect.equals(37, map[c21]);

  Expect.equals(37, map.remove(c11));
  testLength(0, map);
}

void testUnmodifiableMap(Map map) {
  Expect.isTrue(map.containsKey(1));
  testLength(1, map);
  Expect.equals(1, map.keys.first);
  Expect.equals(37, map.values.first);

  Expect.throws(map.clear);
  Expect.throws(() {
    map.remove(1);
  });
  Expect.throws(() {
    map[2] = 42;
  });
  Expect.throws(() {
    map.addAll({2: 42});
  });
}

class Customer {
  final int id;
  final int secondId;
  const Customer(this.id, this.secondId);
  int get hashCode => id;
  bool operator ==(Object other) {
    if (other is! Customer) return false;
    Customer otherCustomer = other;
    return id == otherCustomer.id;
  }
}

int myHashCode(Customer c) => c.secondId;
bool myEquals(Customer a, Customer b) => a.secondId == b.secondId;

void testIterationOrder(Map map) {
  var order = ['0', '6', '4', '2', '7', '9', '7', '1', '2', '5', '3'];
  for (int i = 0; i < order.length; i++) map[order[i]] = i;
  Expect.listEquals(
      map.keys.toList(), ['0', '6', '4', '2', '7', '9', '1', '5', '3']);
  Expect.listEquals(map.values.toList(), [0, 1, 2, 8, 6, 5, 7, 9, 10]);
}

void testOtherKeys(Map<int, int> map) {
  // Test that non-int keys are allowed in containsKey/remove/lookup.
  // Custom hash sets and tree sets must be constructed so they don't
  // use the equality/comparator on incompatible objects.

  // This should not throw in either checked or unchecked mode.
  Expect.isFalse(map.containsKey("not an int"));
  Expect.isFalse(map.containsKey(1.5));
  Expect.isNull(map.remove("not an int"));
  Expect.isNull(map.remove(1.5));
  Expect.isNull(map["not an int"]);
  Expect.isNull(map[1.5]);
}

class Mutable {
  int id;
  Mutable(this.id);
  int get hashCode => id;
  bool operator ==(other) => other is Mutable && other.id == id;
}

// Slow implementation of Map based on MapBase.
abstract class MapBaseOperations<K, V> {
  final List _keys = <K>[];
  final List _values = <V>[];
  int _modCount = 0;

  V operator [](Object key) {
    int index = _keys.indexOf(key);
    if (index < 0) return null;
    return _values[index];
  }

  Iterable<K> get keys => new TestKeyIterable<K>(this);

  void operator []=(K key, V value) {
    int index = _keys.indexOf(key);
    if (index >= 0) {
      _values[index] = value;
    } else {
      _modCount++;
      _keys.add(key);
      _values.add(value);
    }
  }

  V remove(Object key) {
    int index = _keys.indexOf(key);
    if (index >= 0) {
      var result = _values[index];
      key = _keys.removeLast();
      var value = _values.removeLast();
      if (index != _keys.length) {
        _keys[index] = key;
        _values[index] = value;
      }
      _modCount++;
      return result;
    }
    return null;
  }

  void clear() {
    // Clear cannot be based on remove, since remove won't remove keys that
    // are not equal to themselves. It will fail the testNaNKeys test.
    _keys.clear();
    _values.clear();
    _modCount++;
  }
}

class MapBaseMap<K, V> = MapBase<K, V> with MapBaseOperations<K, V>;
class MapMixinMap<K, V> = MapBaseOperations<K, V> with MapMixin<K, V>;

class TestKeyIterable<K> extends IterableBase<K> {
  final _map;
  TestKeyIterable(this._map);
  int get length => _map._keys.length;
  Iterator<K> get iterator => new TestKeyIterator<K>(_map);
}

class TestKeyIterator<K> implements Iterator<K> {
  final _map;
  final int _modCount;
  int _index = 0;
  var _current;
  TestKeyIterator(map)
      : _map = map,
        _modCount = map._modCount;
  bool moveNext() {
    if (_modCount != _map._modCount) {
      throw new ConcurrentModificationError(_map);
    }
    if (_index == _map._keys.length) {
      _current = null;
      return false;
    }
    _current = _map._keys[_index++];
    return true;
  }

  K get current => _current;
}

// Slow implementation of Map based on MapBase.
class UnmodifiableMapBaseMap<K, V> extends UnmodifiableMapBase<K, V> {
  final List _keys = <K>[];
  final List _values = <V>[];
  UnmodifiableMapBaseMap(List pairs) {
    for (int i = 0; i < pairs.length; i += 2) {
      _keys.add(pairs[i]);
      _values.add(pairs[i + 1]);
    }
  }

  int get _modCount => 0;

  V operator [](Object key) {
    int index = _keys.indexOf(key);
    if (index < 0) return null;
    return _values[index];
  }

  Iterable<K> get keys => _keys.skip(0);
}

abstract class Super implements Comparable {}

abstract class Interface implements Comparable {}

class Sub extends Super implements Interface, Comparable {
  int compareTo(dynamic other) => 0;
  int get hashCode => 0;
  bool operator ==(other) => other is Sub;
}

expectMap(Map expect, Map actual) {
  Expect.equals(expect.length, actual.length, "length");
  for (var key in expect.keys) {
    Expect.isTrue(actual.containsKey(key), "containsKey $key");
    Expect.equals(expect[key], actual[key]);
  }
}

void testFrom() {
  // Check contents.
  for (var map in [
    {},
    {1: 1},
    {1: 2, 3: 4, 5: 6, 7: 8}
  ]) {
    expectMap(map, new Map.from(map));
    expectMap(map, new HashMap.from(map));
    expectMap(map, new LinkedHashMap.from(map));
    expectMap(map, new SplayTreeMap.from(map));
  }
  // Test type combinations allowed.
  Map<int, int> intMap = <int, int>{1: 2, 3: 4};
  Map<num, num> numMap = <num, num>{1: 2, 3: 4};
  expectMap(intMap, new Map<int, int>.from(numMap));
  expectMap(intMap, new Map<num, num>.from(intMap));
  expectMap(intMap, new HashMap<int, int>.from(numMap));
  expectMap(intMap, new HashMap<num, num>.from(intMap));
  expectMap(intMap, new LinkedHashMap<int, int>.from(numMap));
  expectMap(intMap, new LinkedHashMap<num, num>.from(intMap));
  expectMap(intMap, new SplayTreeMap<int, int>.from(numMap));
  expectMap(intMap, new SplayTreeMap<num, num>.from(intMap));

  var sub = new Sub();
  Map<Super, Super> superMap = <Super, Super>{sub: sub};
  Map<Interface, Interface> interfaceMap = <Interface, Interface>{sub: sub};
  expectMap(superMap, new Map<Super, Super>.from(interfaceMap));
  expectMap(superMap, new Map<Interface, Interface>.from(superMap));
  expectMap(superMap, new HashMap<Super, Super>.from(interfaceMap));
  expectMap(superMap, new HashMap<Interface, Interface>.from(superMap));
  expectMap(superMap, new LinkedHashMap<Super, Super>.from(interfaceMap));
  expectMap(superMap, new LinkedHashMap<Interface, Interface>.from(superMap));
  expectMap(superMap, new SplayTreeMap<Super, Super>.from(interfaceMap));
  expectMap(superMap, new SplayTreeMap<Interface, Interface>.from(superMap));
}
