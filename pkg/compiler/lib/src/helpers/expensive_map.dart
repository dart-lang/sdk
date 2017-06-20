// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The expensive map is a data structure useful for tracking down
 * excessive memory usage due to large maps. It acts as an ordinary
 * hash map, but it uses 10 times more memory (by default).
 */
class ExpensiveMap<K, V> implements Map<K, V> {
  final List _maps;

  ExpensiveMap([int copies = 10]) : _maps = new List(copies) {
    assert(copies > 0);
    for (int i = 0; i < _maps.length; i++) {
      _maps[i] = new Map<K, V>();
    }
  }

  int get length => _maps[0].length;
  bool get isEmpty => _maps[0].isEmpty;
  bool get isNotEmpty => _maps[0].isNotEmpty;

  Iterable<K> get keys => _maps[0].keys;
  Iterable<V> get values => _maps[0].values;

  bool containsKey(Object key) => _maps[0].containsKey(key);
  bool containsValue(Object value) => _maps[0].containsValue(value);

  V operator [](Object key) => _maps[0][key];

  void forEach(void action(K key, V value)) {
    _maps[0].forEach(action);
  }

  void operator []=(K key, V value) {
    for (int i = 0; i < _maps.length; i++) {
      _maps[i][key] = value;
    }
  }

  V putIfAbsent(K key, V ifAbsent()) {
    if (containsKey(key)) return this[key];
    V value = ifAbsent();
    this[key] = value;
    return value;
  }

  void addAll(Map<K, V> other) {
    for (int i = 0; i < _maps.length; i++) {
      _maps[i].addAll(other);
    }
  }

  V remove(Object key) {
    V result = _maps[0].remove(key);
    for (int i = 1; i < _maps.length; i++) {
      _maps[i].remove(key);
    }
    return result;
  }

  void clear() {
    for (int i = 0; i < _maps.length; i++) {
      _maps[i].clear();
    }
  }

  String toString() => "expensive(${_maps[0]}x${_maps.length})";
}
