// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

class LinkedHashMap<K, V> extends _LinkedHashTable<K> implements HashMap<K, V> {
  static const int _INITIAL_CAPACITY = 8;
  static const int _VALUE_INDEX = 3;
  // ALias for easy access.
  static const int _HEAD_OFFSET = _LinkedHashTable._HEAD_OFFSET;

  int get _entrySize => 4;

  LinkedHashMap() : super(_INITIAL_CAPACITY);

  factory LinkedHashMap.from(Map<K, V> other) {
    return new LinkedHashMap<K, V>()..addAll(other);
  }

  V _value(int offset) => _table[offset + _VALUE_INDEX];
  void _setValue(int offset, V value) { _table[offset + _VALUE_INDEX] = value; }

  _copyEntry(List oldTable, int fromOffset, int toOffset) {
    _table[toOffset + _VALUE_INDEX] = oldTable[fromOffset + _VALUE_INDEX];
  }

  bool containsKey(K key) {
    return _get(key) >= 0;
  }

  bool containsValue(V value) {
    int modificationCount = _modificationCount;
    for (int offset = _next(_HEAD_OFFSET);
         offset != _HEAD_OFFSET;
         offset = _next(offset)) {
      if (_value(offset) == value) {
        return true;
      }
      // The == call may modify the table.
      _checkModification(modificationCount);
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
    if (entry == null) {
      _entryCount++;
      _checkCapacity();
    } else {
      assert(identical(entry, _TOMBSTONE));
      _deletedCount--;
    }
    _setKey(offset, key);
    _setValue(offset, value);
    _linkLast(offset);
    _recordModification();
    return value;
  }

  V remove(K key) {
    int offset = _remove(key);
    if (offset < 0) return null;
    Object oldValue = _value(offset);
    _setValue(offset, null);
    _checkCapacity();
    return oldValue;
  }

  void clear() {
    _clear();
  }

  void forEach(void action (K key, V value)) {
    int modificationCount = _modificationCount;
    for (int offset = _next(_HEAD_OFFSET);
         offset != _HEAD_OFFSET;
         offset = _next(offset)) {
      action(_key(offset), _value(offset));
      _checkModification(modificationCount);
    }
  }

  Iterable<K> get keys => new _LinkedHashTableKeyIterable<K>(this);
  Iterable<V> get values =>
      new _LinkedHashTableValueIterable<V>(this, _VALUE_INDEX);

  int get length => _elementCount;

  bool get isEmpty => _elementCount == 0;

  String toString() => Maps.mapToString(this);
}
