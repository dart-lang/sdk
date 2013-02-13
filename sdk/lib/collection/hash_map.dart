// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

class HashMap<K, V> extends _HashTable<K> implements Map<K, V> {
  static const int _INITIAL_CAPACITY = 8;
  static const int _VALUE_INDEX = 1;

  HashMap() : super(_INITIAL_CAPACITY);

  factory HashMap.from(Map<K, V> other) {
    return new HashMap<K, V>()..addAll(other);
  }

  int get _entrySize => 2;

  V _value(int offset) => _table[offset + _VALUE_INDEX];
  void _setValue(int offset, V value) { _table[offset + _VALUE_INDEX] = value; }

  _copyEntry(List fromTable, int fromOffset, int toOffset) {
    _table[toOffset + _VALUE_INDEX] = fromTable[fromOffset + _VALUE_INDEX];
  }

  bool containsKey(K key) {
    return _get(key) >= 0;
  }

  bool containsValue(V value) {
    for (int offset = 0; offset < _table.length; offset += _entrySize) {
      if (!_isFree(_table[offset]) && _value(offset) == value) {
        return true;
      }
    }
    return false;
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      int offset = _put(key);
      _setValue(offset, value);
      _checkCapacity();
    });
  }

  V operator [](K key) {
    int offset = _get(key);
    if (offset >= 0) return _value(offset);
    return null;
  }

  void operator []=(K key, V value) {
    int offset = _put(key);
    _setValue(offset, value);
    _checkCapacity();
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int offset = _probeForAdd(_hashCodeOf(key), key);
    Object entry = _table[offset];
    if (!_isFree(entry)) {
      return _value(offset);
    }
    int modificationCount = _modificationCount;
    V value = ifAbsent();
    _checkModification(modificationCount);
    _setKey(offset, key);
    _setValue(offset, value);
    if (entry == null) {
      _entryCount++;
      _checkCapacity();
    } else {
      assert(identical(entry, _TOMBSTONE));
      _deletedCount--;
    }
    _recordModification();
    return value;
  }

  V remove(K key) {
    int offset = _remove(key);
    if (offset < 0) return null;
    V oldValue = _value(offset);
    _setValue(offset, null);
    _checkCapacity();
    return oldValue;
  }

  void clear() {
    _clear();
  }

  void forEach(void action (K key, V value)) {
    int modificationCount = _modificationCount;
    for (int offset = 0; offset < _table.length; offset += _entrySize) {
      Object entry = _table[offset];
      if (!_isFree(entry)) {
        K key = entry;
        V value = _value(offset);
        action(key, value);
        _checkModification(modificationCount);
      }
    }
  }

  Iterable<K> get keys => new _HashTableKeyIterable<K>(this);
  Iterable<V> get values =>
      new _HashTableValueIterable<V>(this, _VALUE_INDEX);

  int get length => _elementCount;

  bool get isEmpty => _elementCount == 0;

  String toString() => Maps.mapToString(this);
}
