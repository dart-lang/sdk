// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";

/// The expensive map is a data structure useful for tracking down
/// excessive memory usage due to large maps. It acts as an ordinary
/// hash map, but it uses 10 times more memory (by default).
class ExpensiveMap<K, V> extends MapBase<K, V> {
  final List _maps;

  ExpensiveMap([int copies = 10]) : _maps = new List.filled(copies, null) {
    assert(copies > 0);
    for (int i = 0; i < _maps.length; i++) {
      _maps[i] = new Map<K, V>();
    }
  }

  @override
  int get length => _maps[0].length;
  @override
  bool get isEmpty => _maps[0].isEmpty;
  @override
  bool get isNotEmpty => _maps[0].isNotEmpty;

  @override
  Iterable<K> get keys => _maps[0].keys;
  @override
  Iterable<V> get values => _maps[0].values;

  @override
  bool containsKey(Object key) => _maps[0].containsKey(key);
  @override
  bool containsValue(Object value) => _maps[0].containsValue(value);

  @override
  V operator [](Object key) => _maps[0][key];

  @override
  void forEach(void action(K key, V value)) {
    _maps[0].forEach(action);
  }

  @override
  void operator []=(K key, V value) {
    for (int i = 0; i < _maps.length; i++) {
      _maps[i][key] = value;
    }
  }

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    if (containsKey(key)) return this[key];
    V value = ifAbsent();
    this[key] = value;
    return value;
  }

  @override
  void addAll(Map<K, V> other) {
    for (int i = 0; i < _maps.length; i++) {
      _maps[i].addAll(other);
    }
  }

  @override
  V remove(Object key) {
    V result = _maps[0].remove(key);
    for (int i = 1; i < _maps.length; i++) {
      _maps[i].remove(key);
    }
    return result;
  }

  @override
  void clear() {
    for (int i = 0; i < _maps.length; i++) {
      _maps[i].clear();
    }
  }

  @override
  Map<KR, VR> cast<KR, VR>() => Map.castFrom<K, V, KR, VR>(this);
  @override
  Iterable<MapEntry<K, V>> get entries => _maps[0].entries;

  @override
  void addEntries(Iterable<MapEntry<K, V>> entries) {
    for (int i = 0; i < _maps.length; i++) {
      _maps[i].addEntries(entries);
    }
  }

  @override
  Map<KR, VR> map<KR, VR>(MapEntry<KR, VR> transform(K key, V value)) =>
      _maps[0].map(transform);

  @override
  V update(K key, V update(V value), {V ifAbsent()}) {
    V result;
    for (int i = 0; i < _maps.length; i++) {
      result = _maps[i].update(key, update, ifAbsent: ifAbsent);
    }
    return result;
  }

  @override
  void updateAll(V update(K key, V value)) {
    for (int i = 0; i < _maps.length; i++) {
      _maps[i].updateAll(update);
    }
  }

  @override
  void removeWhere(bool test(K key, V value)) {
    for (int i = 0; i < _maps.length; i++) {
      _maps[i].removeWhere(test);
    }
  }

  @override
  String toString() => "expensive(${_maps[0]}x${_maps.length})";
}
