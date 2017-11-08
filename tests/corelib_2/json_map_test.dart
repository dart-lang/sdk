// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_map_test;

import "package:expect/expect.dart";
import 'dart:convert' show JSON;
import 'dart:collection' show LinkedHashMap, HashMap;

bool useReviver = false;
Map jsonify(Map map) {
  String encoded = JSON.encode(map);
  return useReviver
      ? JSON.decode(encoded, reviver: (key, value) => value)
      : JSON.decode(encoded);
}

List listEach(Map map) {
  var result = [];
  map.forEach((key, value) {
    result.add(key);
    result.add(value);
  });
  return result;
}

void main() {
  test(false);
  test(true);
}

void test(bool revive) {
  useReviver = revive;
  testEmpty(jsonify({}));
  testAtoB(jsonify({'a': 'b'}));

  Map map = jsonify({});
  map['a'] = 'b';
  testAtoB(map);

  map = jsonify({});
  Expect.equals('b', map.putIfAbsent('a', () => 'b'));
  testAtoB(map);

  map = jsonify({});
  map.addAll({'a': 'b'});
  testAtoB(map);

  testOrder(['a', 'b', 'c', 'd', 'e', 'f']);

  testProto();
  testToString();
  testConcurrentModifications();
  testType();
  testClear();

  testListEntry();
  testMutation();
}

void testEmpty(Map map) {
  for (int i = 0; i < 2; i++) {
    Expect.equals(0, map.length);
    Expect.isTrue(map.isEmpty);
    Expect.isFalse(map.isNotEmpty);
    Expect.listEquals([], map.keys.toList());
    Expect.listEquals([], map.values.toList());
    Expect.isNull(map['a']);
    Expect.listEquals([], listEach(map));
    Expect.isFalse(map.containsKey('a'));
    Expect.isFalse(map.containsValue('a'));
    Expect.isNull(map.remove('a'));
    testLookupNonExistingKeys(map);
    testLookupNonExistingValues(map);
    map.clear();
  }
}

void testAtoB(Map map) {
  Expect.equals(1, map.length);
  Expect.isFalse(map.isEmpty);
  Expect.isTrue(map.isNotEmpty);
  Expect.listEquals(['a'], map.keys.toList());
  Expect.listEquals(['b'], map.values.toList());
  Expect.equals('b', map['a']);
  Expect.listEquals(['a', 'b'], listEach(map));
  Expect.isTrue(map.containsKey('a'));
  Expect.isFalse(map.containsKey('b'));
  Expect.isTrue(map.containsValue('b'));
  Expect.isFalse(map.containsValue('a'));

  testLookupNonExistingKeys(map);
  testLookupNonExistingValues(map);
  Expect.equals('b', map.remove('a'));
  Expect.isNull(map.remove('b'));
  testLookupNonExistingKeys(map);
  testLookupNonExistingValues(map);

  map.clear();
  testEmpty(map);
}

void testLookupNonExistingKeys(Map map) {
  for (String key in ['__proto__', 'null', null]) {
    Expect.isNull(map[key]);
    Expect.isFalse(map.containsKey(key));
  }
}

void testLookupNonExistingValues(Map map) {
  for (var value in ['__proto__', 'null', null]) {
    Expect.isFalse(map.containsValue(value));
  }
}

void testOrder(List list) {
  if (list.isEmpty)
    return;
  else
    testOrder(list.skip(1).toList());

  Map original = {};
  for (int i = 0; i < list.length; i++) {
    original[list[i]] = i;
  }

  Map map = jsonify(original);
  Expect.equals(list.length, map.length);
  Expect.listEquals(list, map.keys.toList());

  for (int i = 0; i < 10; i++) {
    map["$i"] = i;
    Expect.equals(list.length + i + 1, map.length);
    Expect.listEquals(list, map.keys.take(list.length).toList());
  }
}

void testProto() {
  Map map = jsonify({'__proto__': 0});
  Expect.equals(1, map.length);
  Expect.isTrue(map.containsKey('__proto__'));
  Expect.listEquals(['__proto__'], map.keys.toList());
  Expect.equals(0, map['__proto__']);
  Expect.equals(0, map.remove('__proto__'));
  testEmpty(map);

  map = jsonify({'__proto__': null});
  Expect.equals(1, map.length);
  Expect.isTrue(map.containsKey('__proto__'));
  Expect.listEquals(['__proto__'], map.keys.toList());
  Expect.isNull(map['__proto__']);
  Expect.isNull(map.remove('__proto__'));
  testEmpty(map);
}

void testToString() {
  Expect.equals("{}", jsonify({}).toString());
  Expect.equals("{a: 0}", jsonify({'a': 0}).toString());
}

void testConcurrentModifications() {
  void testIterate(Map map, Iterable iterable, Function f) {
    Iterator iterator = iterable.iterator;
    f(map);
    iterator.moveNext();
  }

  void testKeys(Map map, Function f) => testIterate(map, map.keys, f);
  void testValues(Map map, Function f) => testIterate(map, map.values, f);

  void testForEach(Map map, Function f) {
    map.forEach((key, value) {
      f(map);
    });
  }

  bool throwsCME(Function f) {
    try {
      f();
    } on ConcurrentModificationError catch (e) {
      return true;
    } catch (e) {
      return false;
    }
    return false;
  }

  Map map = {};
  Expect.isTrue(throwsCME(() => testKeys(jsonify(map), (map) => map['a'] = 0)));
  Expect
      .isTrue(throwsCME(() => testValues(jsonify(map), (map) => map['a'] = 0)));
  Expect.isFalse(
      throwsCME(() => testForEach(jsonify(map), (map) => map['a'] = 0)));

  Expect.isFalse(throwsCME(() => testKeys(jsonify(map), (map) => map.clear())));
  Expect
      .isFalse(throwsCME(() => testValues(jsonify(map), (map) => map.clear())));
  Expect.isFalse(
      throwsCME(() => testForEach(jsonify(map), (map) => map.clear())));

  Expect.isFalse(
      throwsCME(() => testKeys(jsonify(map), (map) => map.remove('a'))));
  Expect.isFalse(
      throwsCME(() => testValues(jsonify(map), (map) => map.remove('a'))));
  Expect.isFalse(
      throwsCME(() => testForEach(jsonify(map), (map) => map.remove('a'))));

  Expect.isTrue(throwsCME(
      () => testKeys(jsonify(map), (map) => map.putIfAbsent('a', () => 0))));
  Expect.isTrue(throwsCME(
      () => testValues(jsonify(map), (map) => map.putIfAbsent('a', () => 0))));
  Expect.isFalse(throwsCME(
      () => testForEach(jsonify(map), (map) => map.putIfAbsent('a', () => 0))));

  Expect.isFalse(
      throwsCME(() => testKeys(jsonify(map), (map) => map.addAll({}))));
  Expect.isFalse(
      throwsCME(() => testValues(jsonify(map), (map) => map.addAll({}))));
  Expect.isFalse(
      throwsCME(() => testForEach(jsonify(map), (map) => map.addAll({}))));

  Expect.isTrue(
      throwsCME(() => testKeys(jsonify(map), (map) => map.addAll({'a': 0}))));
  Expect.isTrue(
      throwsCME(() => testValues(jsonify(map), (map) => map.addAll({'a': 0}))));
  Expect.isFalse(throwsCME(
      () => testForEach(jsonify(map), (map) => map.addAll({'a': 0}))));

  map = {'a': 1};
  Expect
      .isFalse(throwsCME(() => testKeys(jsonify(map), (map) => map['a'] = 0)));
  Expect.isFalse(
      throwsCME(() => testValues(jsonify(map), (map) => map['a'] = 0)));
  Expect.isFalse(
      throwsCME(() => testForEach(jsonify(map), (map) => map['a'] = 0)));

  Expect.isTrue(throwsCME(() => testKeys(jsonify(map), (map) => map['b'] = 0)));
  Expect
      .isTrue(throwsCME(() => testValues(jsonify(map), (map) => map['b'] = 0)));
  Expect.isTrue(
      throwsCME(() => testForEach(jsonify(map), (map) => map['b'] = 0)));

  Expect.isTrue(throwsCME(() => testKeys(jsonify(map), (map) => map.clear())));
  Expect
      .isTrue(throwsCME(() => testValues(jsonify(map), (map) => map.clear())));
  Expect
      .isTrue(throwsCME(() => testForEach(jsonify(map), (map) => map.clear())));

  Expect.isTrue(
      throwsCME(() => testKeys(jsonify(map), (map) => map.remove('a'))));
  Expect.isTrue(
      throwsCME(() => testValues(jsonify(map), (map) => map.remove('a'))));
  Expect.isTrue(
      throwsCME(() => testForEach(jsonify(map), (map) => map.remove('a'))));

  Expect.isFalse(
      throwsCME(() => testKeys(jsonify(map), (map) => map.remove('b'))));
  Expect.isFalse(
      throwsCME(() => testValues(jsonify(map), (map) => map.remove('b'))));
  Expect.isFalse(
      throwsCME(() => testForEach(jsonify(map), (map) => map.remove('b'))));

  Expect.isFalse(throwsCME(
      () => testKeys(jsonify(map), (map) => map.putIfAbsent('a', () => 0))));
  Expect.isFalse(throwsCME(
      () => testValues(jsonify(map), (map) => map.putIfAbsent('a', () => 0))));
  Expect.isFalse(throwsCME(
      () => testForEach(jsonify(map), (map) => map.putIfAbsent('a', () => 0))));

  Expect.isTrue(throwsCME(
      () => testKeys(jsonify(map), (map) => map.putIfAbsent('b', () => 0))));
  Expect.isTrue(throwsCME(
      () => testValues(jsonify(map), (map) => map.putIfAbsent('b', () => 0))));
  Expect.isTrue(throwsCME(
      () => testForEach(jsonify(map), (map) => map.putIfAbsent('b', () => 0))));

  Expect.isFalse(
      throwsCME(() => testKeys(jsonify(map), (map) => map.addAll({}))));
  Expect.isFalse(
      throwsCME(() => testValues(jsonify(map), (map) => map.addAll({}))));
  Expect.isFalse(
      throwsCME(() => testForEach(jsonify(map), (map) => map.addAll({}))));

  Expect.isFalse(
      throwsCME(() => testKeys(jsonify(map), (map) => map.addAll({'a': 0}))));
  Expect.isFalse(
      throwsCME(() => testValues(jsonify(map), (map) => map.addAll({'a': 0}))));
  Expect.isFalse(throwsCME(
      () => testForEach(jsonify(map), (map) => map.addAll({'a': 0}))));

  Expect.isTrue(
      throwsCME(() => testKeys(jsonify(map), (map) => map.addAll({'b': 0}))));
  Expect.isTrue(
      throwsCME(() => testValues(jsonify(map), (map) => map.addAll({'b': 0}))));
  Expect.isTrue(throwsCME(
      () => testForEach(jsonify(map), (map) => map.addAll({'b': 0}))));
}

void testType() {
  Expect.isTrue(jsonify({}) is Map);
  Expect.isTrue(jsonify({}) is HashMap);
  Expect.isTrue(jsonify({}) is LinkedHashMap);

  Expect.isTrue(jsonify({}) is Map<String, dynamic>);
  Expect.isTrue(jsonify({}) is HashMap<String, dynamic>);
  Expect.isTrue(jsonify({}) is LinkedHashMap<String, dynamic>);

  Expect.isFalse(jsonify({}) is Map<int, dynamic>);
  Expect.isFalse(jsonify({}) is HashMap<int, dynamic>);
  Expect.isFalse(jsonify({}) is LinkedHashMap<int, dynamic>);
}

void testClear() {
  Map map = jsonify({'a': 0});
  map.clear();
  Expect.equals(0, map.length);
}

void testListEntry() {
  Map map = jsonify({
    'a': [
      7,
      8,
      {'b': 9}
    ]
  });
  List list = map['a'];
  Expect.equals(3, list.length);
  Expect.equals(7, list[0]);
  Expect.equals(8, list[1]);
  Expect.equals(9, list[2]['b']);
}

void testMutation() {
  Map map = jsonify({'a': 0});
  Expect.listEquals(['a', 0], listEach(map));
  map['a'] = 1;
  Expect.listEquals(['a', 1], listEach(map));
  map['a']++;
  Expect.listEquals(['a', 2], listEach(map));
}
