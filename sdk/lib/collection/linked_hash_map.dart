// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

class _LinkedHashMapTable<K, V> extends _LinkedHashTable<K> {
  static const int _INITIAL_CAPACITY = 8;
  static const int _VALUE_INDEX = 3;

  int get _entrySize => 4;

  _LinkedHashMapTable() : super(_INITIAL_CAPACITY);

  V _value(int offset) => _table[offset + _VALUE_INDEX];
  void _setValue(int offset, V value) { _table[offset + _VALUE_INDEX] = value; }

  _copyEntry(List oldTable, int fromOffset, int toOffset) {
    _table[toOffset + _VALUE_INDEX] = oldTable[fromOffset + _VALUE_INDEX];
  }
}

/**
 * A hash-based map that iterates keys and values in key insertion order.
 */
class LinkedHashMap<K, V> implements Map<K, V> {
  final _LinkedHashMapTable _hashTable;

  LinkedHashMap() : _hashTable = new _LinkedHashMapTable<K, V>() {
    _hashTable._container = this;
  }

  factory LinkedHashMap.from(Map<K, V> other) {
    return new LinkedHashMap<K, V>()..addAll(other);
  }

  bool containsKey(K key) {
    return _hashTable._get(key) >= 0;
  }

  bool containsValue(V value) {
    int modificationCount = _hashTable._modificationCount;
    for (int offset = _hashTable._next(_LinkedHashTable._HEAD_OFFSET);
         offset != _LinkedHashTable._HEAD_OFFSET;
         offset = _hashTable._next(offset)) {
      if (_hashTable._value(offset) == value) {
        return true;
      }
      // The == call may modify the table.
      _hashTable._checkModification(modificationCount);
    }
    return false;
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      int offset = _hashTable._put(key);
      _hashTable._setValue(offset, value);
      _hashTable._checkCapacity();
    });
  }

  V operator [](K key) {
    int offset = _hashTable._get(key);
    if (offset >= 0) return _hashTable._value(offset);
    return null;
  }

  void operator []=(K key, V value) {
    int offset = _hashTable._put(key);
    _hashTable._setValue(offset, value);
    _hashTable._checkCapacity();
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int offset = _hashTable._probeForAdd(_hashTable._hashCodeOf(key), key);
    Object entry = _hashTable._table[offset];
    if (!_hashTable._isFree(entry)) {
      return _hashTable._value(offset);
    }
    int modificationCount = _hashTable._modificationCount;
    V value = ifAbsent();
    if (modificationCount == _hashTable._modificationCount) {
      _hashTable._setKey(offset, key);
      _hashTable._setValue(offset, value);
      _hashTable._linkLast(offset);
      if (entry == null) {
        _hashTable._entryCount++;
        _hashTable._checkCapacity();
      } else {
        assert(identical(entry, _TOMBSTONE));
        _hashTable._deletedCount--;
      }
      _hashTable._recordModification();
    } else {
      // The table might have changed, so we can't trust [offset] any more.
      // Do another lookup before setting the value.
      offset = _hashTable._put(key);
      _hashTable._setValue(offset, value);
      _hashTable._checkCapacity();
    }
    return value;
  }

  V remove(K key) {
    int offset = _hashTable._remove(key);
    if (offset < 0) return null;
    Object oldValue = _hashTable._value(offset);
    _hashTable._setValue(offset, null);
    _hashTable._checkCapacity();
    return oldValue;
  }

  void clear() {
    _hashTable._clear();
  }

  void forEach(void action (K key, V value)) {
    int modificationCount = _hashTable._modificationCount;
    for (int offset = _hashTable._next(_LinkedHashTable._HEAD_OFFSET);
         offset != _LinkedHashTable._HEAD_OFFSET;
         offset = _hashTable._next(offset)) {
      action(_hashTable._key(offset), _hashTable._value(offset));
      _hashTable._checkModification(modificationCount);
    }
  }

  Iterable<K> get keys => new _LinkedHashTableKeyIterable<K>(_hashTable);
  Iterable<V> get values =>
      new _LinkedHashTableValueIterable<V>(_hashTable,
                                           _LinkedHashMapTable._VALUE_INDEX);

  int get length => _hashTable._elementCount;

  bool get isEmpty => _hashTable._elementCount == 0;

  String toString() => Maps.mapToString(this);
}
