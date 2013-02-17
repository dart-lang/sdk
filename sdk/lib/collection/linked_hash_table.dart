// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/** Unique marker object for the head of a linked list of entries. */
class _LinkedHashTableHeadMarker {
  const _LinkedHashTableHeadMarker();
}

const _LinkedHashTableHeadMarker _HEAD_MARKER =
    const _LinkedHashTableHeadMarker();

class _LinkedHashTable<K> extends _HashTable<K> {
  static const _NEXT_INDEX = 1;
  static const _PREV_INDEX = 2;
  static const _HEAD_OFFSET = 0;

  _LinkedHashTable(int initialCapacity) : super(initialCapacity);

  int get _entrySize => 3;

  List _createTable(int capacity) {
    List result = new List.fixedLength(capacity * _entrySize);
    result[_HEAD_OFFSET] = _HEAD_MARKER;
    result[_HEAD_OFFSET + _NEXT_INDEX] = _HEAD_OFFSET;
    result[_HEAD_OFFSET + _PREV_INDEX] = _HEAD_OFFSET;
    return result;
  }

  int _next(int offset) => _table[offset + _NEXT_INDEX];
  void _setNext(int offset, int to) { _table[offset + _NEXT_INDEX] = to; }

  int _prev(int offset) => _table[offset + _PREV_INDEX];
  void _setPrev(int offset, int to) { _table[offset + _PREV_INDEX] = to; }

  void _linkLast(int offset) {
    // Add entry at offset at end of double-linked list.
    int last = _prev(_HEAD_OFFSET);
    _setNext(offset, _HEAD_OFFSET);
    _setPrev(offset, last);
    _setNext(last, offset);
    _setPrev(_HEAD_OFFSET, offset);
  }

  void _unlink(int offset) {
    assert(offset != _HEAD_OFFSET);
    int next = _next(offset);
    int prev = _prev(offset);
    _setNext(offset, null);
    _setPrev(offset, null);
    _setNext(prev, next);
    _setPrev(next, prev);
  }

  /**
   * Copies all non-free entries from the old table to the new empty table.
   */
  void _addAllEntries(List oldTable) {
    int offset = oldTable[_HEAD_OFFSET + _NEXT_INDEX];
    while (offset != _HEAD_OFFSET) {
      Object object = oldTable[offset];
      int nextOffset = oldTable[offset + _NEXT_INDEX];
      int toOffset = _put(object);
      _copyEntry(oldTable, offset, toOffset);
      offset = nextOffset;
    }
  }

  void _clear() {
    if (_elementCount == 0) return;
    _setNext(_HEAD_OFFSET, _HEAD_OFFSET);
    _setPrev(_HEAD_OFFSET, _HEAD_OFFSET);
    for (int i = _entrySize; i < _table.length; i++) {
      _table[i] = null;
    }
    _entryCount = _deletedCount = 0;
    _recordModification();
  }

  int _put(K key) {
    int offset = _probeForAdd(_hashCodeOf(key), key);
    Object oldEntry = _table[offset];
    if (identical(oldEntry, _TOMBSTONE)) {
      _deletedCount--;
    } else if (oldEntry == null) {
      _entryCount++;
    } else {
      return offset;
    }
    _recordModification();
    _setKey(offset, key);
    _linkLast(offset);
    return offset;
  }

  void _deleteEntry(int offset) {
    _unlink(offset);
    _setKey(offset, _TOMBSTONE);
    _deletedCount++;
    _recordModification();
  }
}

class _LinkedHashTableKeyIterable<K> extends Iterable<K> {
  final _LinkedHashTable<K> _table;
  _LinkedHashTableKeyIterable(this._table);
  Iterator<K> get iterator => new _LinkedHashTableKeyIterator<K>(_table);

  bool contains(Object value) => _table._get(value) >= 0;

  int get length => _table._elementCount;
}

class _LinkedHashTableKeyIterator<K> extends _LinkedHashTableIterator<K> {
  _LinkedHashTableKeyIterator(_LinkedHashTable<K> hashTable): super(hashTable);

  K _getCurrent(int offset) => _hashTable._key(offset);
}

class _LinkedHashTableValueIterable<V> extends Iterable<V> {
  final _LinkedHashTable _hashTable;
  final int _valueIndex;
  _LinkedHashTableValueIterable(this._hashTable, this._valueIndex);
  Iterator<V> get iterator =>
      new _LinkedHashTableValueIterator<V>(_hashTable, _valueIndex);
  int get length => _hashTable._elementCount;
}

class _LinkedHashTableValueIterator<V> extends _LinkedHashTableIterator<V> {
  final int _valueIndex;

  _LinkedHashTableValueIterator(_LinkedHashTable hashTable, this._valueIndex)
      : super(hashTable);

  V _getCurrent(int offset) => _hashTable._table[offset + _valueIndex];
}

abstract class _LinkedHashTableIterator<T> implements Iterator<T> {
  final _LinkedHashTable _hashTable;
  final int _modificationCount;
  int _offset;
  T _current;

  _LinkedHashTableIterator(_LinkedHashTable table)
      : _hashTable = table,
        _modificationCount = table._modificationCount,
        _offset = table._next(_LinkedHashTable._HEAD_OFFSET);

  bool moveNext() {
    _hashTable._checkModification(_modificationCount);
    if (_offset == _LinkedHashTable._HEAD_OFFSET) {
      _current = null;
      return false;
    }
    _current = _getCurrent(_offset);
    _offset = _hashTable._next(_offset);
    return true;
  }

  T _getCurrent(int offset);

  T get current => _current;
}
