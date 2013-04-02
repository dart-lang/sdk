// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

class _HashMapTable<K, V> extends _HashTable<K> {
  static const int _INITIAL_CAPACITY = 8;
  static const int _VALUE_INDEX = 1;

  _HashMapTable() : super(_INITIAL_CAPACITY);

  int get _entrySize => 2;

  V _value(int offset) => _table[offset + _VALUE_INDEX];
  void _setValue(int offset, V value) { _table[offset + _VALUE_INDEX] = value; }

  _copyEntry(List fromTable, int fromOffset, int toOffset) {
    _table[toOffset + _VALUE_INDEX] = fromTable[fromOffset + _VALUE_INDEX];
  }
}

class HashMap<K, V> implements Map<K, V> {
  external HashMap();

  factory HashMap.from(Map<K, V> other) {
    return new HashMap<K, V>()..addAll(other);
  }

  external int get length;
  external bool get isEmpty;

  external Iterable<K> get keys;
  external Iterable<V> get values;

  external bool containsKey(K key);
  external bool containsValue(V value);

  external void addAll(Map<K, V> other);

  external V operator [](K key);
  external void operator []=(K key, V value);

  external V putIfAbsent(K key, V ifAbsent());

  external V remove(K key);
  external void clear();

  external void forEach(void action(K key, V value));

  String toString() => Maps.mapToString(this);
}
