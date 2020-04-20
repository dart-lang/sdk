// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:collection';
import 'dart:convert' show json;

Map<String, dynamic> newJsonMap() => json.decode('{}');
Map<String, dynamic> newJsonMapCustomReviver() =>
    json.decode('{}', reviver: (key, value) => value);

void main() {
  test({});
  test(new LinkedHashMap());
  test(new HashMap());
  test(new LinkedHashMap.identity());
  test(new HashMap.identity());
  test(new MapView(new HashMap()));
  test(new MapBaseMap());
  test(new MapMixinMap());
  test(newJsonMap());
  test(newJsonMapCustomReviver());
  testNonNull(new SplayTreeMap());
  testNonNull(new SplayTreeMap(Comparable.compare));
  testNonNull(new MapView(new SplayTreeMap()));
}

void test(Map<Comparable, Object> map) {
  testNonNull(map);

  // Also works with null keys and values (omitted for splay-tree based maps)
  map.clear();
  map.update(null, unreachable, ifAbsent: () => null);
  Expect.mapEquals({null: null}, map);
  map.update(null, (v) => "$v", ifAbsent: unreachable);
  Expect.mapEquals({null: "null"}, map);
  map.update(null, (v) => null, ifAbsent: unreachable);
  Expect.mapEquals({null: null}, map);
}

void testNonNull(Map<Comparable, Object> map) {
  // Only use literal String keys since JSON maps only accept strings,
  // and literals works with identity-maps, and it's comparable for SplayTreeMap
  // maps.
  Expect.mapEquals({}, map);
  map.update("key1", unreachable, ifAbsent: () => 42);
  Expect.mapEquals({"key1": 42}, map);
  map.clear();
  map["key1"] = 42;
  map.update("key1", (v) => 1 + v, ifAbsent: unreachable);
  Expect.mapEquals({"key1": 43}, map);
  map.clear();

  // Operations on maps with multiple elements.
  var multi = {
    "k1": 1,
    "k2": 2,
    "k3": 3,
    "k4": 4,
    "k5": 5,
    "k6": 6,
    "k7": 7,
    "k8": 8,
    "k9": 9,
    "k10": 10,
  };
  map.addAll(multi);
  Expect.mapEquals(multi, map);
  map.update("k3", (v) => 13);
  map.update("k6", (v) => 16);
  map.update("k11", unreachable, ifAbsent: () => 21);
  Expect.mapEquals({
    "k1": 1,
    "k2": 2,
    "k3": 13,
    "k4": 4,
    "k5": 5,
    "k6": 16,
    "k7": 7,
    "k8": 8,
    "k9": 9,
    "k10": 10,
    "k11": 21,
  }, map);

  map.clear();
  map.updateAll((k, v) => throw "unreachable");
  Expect.mapEquals({}, map);

  map.addAll(multi);
  map.updateAll((k, v) => "$k:$v");
  Expect.mapEquals({
    "k1": "k1:1",
    "k2": "k2:2",
    "k3": "k3:3",
    "k4": "k4:4",
    "k5": "k5:5",
    "k6": "k6:6",
    "k7": "k7:7",
    "k8": "k8:8",
    "k9": "k9:9",
    "k10": "k10:10",
  }, map);

  map.clear();
  Expect.throws(
      () => map.update("key1", unreachable, ifAbsent: () => throw "expected"),
      (t) => t == "expected");

  map["key1"] = 42;
  Expect.throws(() => map.update("key1", (_) => throw "expected"),
      (t) => t == "expected");

  // No ifAbsent means throw if key not there.
  Expect.throws(() => map.update("key-not", unreachable), (e) => e is Error);

  Expect.throws(() => map.update("key1", null), (e) => e is Error);

  // Works with null values.
  map.clear();
  map.update("key1", unreachable, ifAbsent: () => null);
  Expect.mapEquals({"key1": null}, map);
  map.update("key1", (v) => "$v", ifAbsent: unreachable);
  Expect.mapEquals({"key1": "null"}, map);
  map.update("key1", (v) => null, ifAbsent: unreachable);
  Expect.mapEquals({"key1": null}, map);
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

Null unreachable([_, __]) => throw "unreachable";
