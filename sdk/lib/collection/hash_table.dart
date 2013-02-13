// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

class _DeadEntry {
  const _DeadEntry();
}

class _NullKey {
  const _NullKey();
  int get hashCode => null.hashCode;
}

const _TOMBSTONE = const _DeadEntry();
const _NULL = const _NullKey();

class _HashTable<K> {
  /**
   * Table of entries with [_entrySize] slots per entry.
   *
   * Capacity in entries must be factor of two.
   */
  List _table;
  /** Current capacity. Always equal to [:_table.length ~/ _entrySize:]. */
  int _capacity;
  /** Count of occupied entries, including deleted ones. */
  int _entryCount = 0;
  /** Count of deleted entries. */
  int _deletedCount = 0;
  /** Counter incremented when table is modified. */
  int _modificationCount = 0;

  _HashTable(int initialCapacity) : _capacity = initialCapacity {
    _table = _createTable(initialCapacity);
  }

  /** Reads key from table. Converts _NULL marker to null. */
  Object _key(offset) {
    assert(!_isFree(_table[offset]));
    Object key = _table[offset];
    if (!identical(key, _NULL)) return key;
    return null;
  }

  /** Writes key to table. Converts null to _NULL marker. */
  void _setKey(int offset, Object key) {
    if (key == null) key = _NULL;
    _table[offset] = key;
  }

  int get _elementCount => _entryCount - _deletedCount;

  /** Size of each entry. */
  int get _entrySize => 1;

  void _checkModification(int expectedModificationCount) {
    if (_modificationCount != expectedModificationCount) {
      throw new ConcurrentModificationError(this);
    }
  }

  void _recordModification() {
    // Value cycles after 2^30 modifications. If you keep hold of an
    // iterator for that long, you might miss a modification detection,
    // and iteration can go sour. Don't do that.
    _modificationCount = (_modificationCount + 1) & (0x3FFFFFFF);
  }

  /**
   * Create an empty table.
   */
  List _createTable(int capacity) {
    List table = new List.fixedLength(capacity * _entrySize);
    return table;
  }

  /** First table probe. */
  int _firstProbe(int hashCode, int capacity) {
    return hashCode & (capacity - 1);
  }

  /** Following table probes. */
  int _nextProbe(int previousIndex, int probeCount, int capacity) {
    return (previousIndex + probeCount) & (capacity - 1);
  }

  /** Whether an object is a free-marker (either tombstone or free). */
  bool _isFree(Object marker) =>
      marker == null || identical(marker, _TOMBSTONE);

  /**
   * Look up the offset for an object in the table.
   *
   * Finds the offset of the object in the table, if it is there,
   * or the first free offset for its hashCode.
   */
  int _probeForAdd(int hashCode, Object object) {
    int entrySize = _entrySize;
    int index = _firstProbe(hashCode, _capacity);
    int firstTombstone = -1;
    int probeCount = 0;
    while (true) {
      int offset = index * entrySize;
      Object entry = _table[offset];
      if (identical(entry, _TOMBSTONE)) {
        if (firstTombstone < 0) firstTombstone = offset;
      } else if (entry == null) {
        if (firstTombstone < 0) return offset;
        return firstTombstone;
      } else if (identical(_NULL, entry) ? _equals(null, object)
                                         : _equals(entry, object)) {
        return offset;
      }
      // The _nextProbe is designed so that it hits
      // every index eventually.
      index = _nextProbe(index, ++probeCount, _capacity);
    }
  }

  /**
   * Look up the offset for an object in the table.
   *
   * If the object is in the table, its offset is returned.
   *
   * If the object is not in the table, Otherwise a negative value is returned.
   */
  int _probeForLookup(int hashCode, Object object) {
    int entrySize = _entrySize;
    int index = _firstProbe(hashCode, _capacity);
    int probeCount = 0;
    while (true) {
      int offset = index * entrySize;
      Object entry = _table[offset];
      if (entry == null) {
        return -1;
      } else if (identical(_NULL, entry) ? _equals(null, object)
                                         : _equals(entry, object)) {
        // If entry is _TOMBSTONE, it matches nothing.
        // Consider special casing it to make 'equals' calls monomorphic.
        return offset;
      }
      // The _nextProbe is designed so that it hits
      // every index eventually.
      index = _nextProbe(index, ++probeCount, _capacity);
    }
  }

  // Override the following two to change equality/hashCode computations

  /**
   * Compare two object for equality.
   *
   * The first object is the one already in the table,
   * and the second is the one being searched for.
   */
  bool _equals(Object element, Object other) {
    return element == other;
  }

  /**
   * Compute hash-code for an object.
   */
  int _hashCodeOf(Object object) => object.hashCode;

  /**
   * Ensure that the table isn't too full for its own good.
   *
   * Call this after adding an element.
   */
  int _checkCapacity() {
    // Compute everything in multiples of entrySize to avoid division.
    int freeCount = _capacity - _entryCount;
    if (freeCount * 4 < _capacity ||
        freeCount < _deletedCount) {
      // Less than 25% free or more deleted entries than free entries.
      _grow(_entryCount - _deletedCount);
    }
  }

  void _grow(int contentCount) {
    int capacity = _capacity;
    // Don't grow to less than twice the needed capacity.
    int minCapacity = contentCount * 2;
    while (capacity < minCapacity) {
      capacity *= 2;
    }
    // Reset to another table and add all existing elements.
    List oldTable = _table;
    _table = _createTable(capacity);
    _capacity = capacity;
    _entryCount = 0;
    _deletedCount = 0;
    _addAllEntries(oldTable);
    _recordModification();
  }

  /**
   * Copies all non-free entries from the old table to the new empty table.
   */
  void _addAllEntries(List oldTable) {
    for (int i = 0; i < oldTable.length; i += _entrySize) {
      Object object = oldTable[i];
      if (!_isFree(object)) {
        int toOffset = _put(object);
        _copyEntry(oldTable, i, toOffset);
      }
    }
  }

  /**
   * Copies everything but the key element from one entry to another.
   *
   * Called while growing the base array.
   *
   * Override this if any non-key fields need copying.
   */
  void _copyEntry(List fromTable, int fromOffset, int toOffset) {}

  // The following three methods are for simple get/set/remove operations.
  // They only affect the key of an entry. The remaining fields must be
  // filled by the caller.

  /**
   * Returns the offset of a key in [_table], or negative if it's not there.
   */
  int _get(K key) {
    return _probeForLookup(_hashCodeOf(key), key);
  }

  /**
   * Puts the key into the table and returns its offset into [_table].
   *
   * If [_entrySize] is greater than 1, the caller should fill the
   * remaining fields.
   *
   * Remember to call [_checkCapacity] after using this method.
   */
  int _put(K key) {
    int offset = _probeForAdd(_hashCodeOf(key), key);
    Object oldEntry = _table[offset];
    if (oldEntry == null) {
      _entryCount++;
    } else if (identical(oldEntry, _TOMBSTONE)) {
      _deletedCount--;
    } else {
      return offset;
    }
    _setKey(offset, key);
    _recordModification();
    return offset;
  }

  /**
   * Removes a key from the table and returns its offset into [_table].
   *
   * Returns null if the key was not in the table.
   * If [_entrySize] is greater than 1, the caller should clean up the
   * remaining fields.
   */
  int _remove(K key) {
    int offset = _probeForLookup(_hashCodeOf(key), key);
    if (offset >= 0) {
      _deleteEntry(offset);
    }
    return offset;
  }

  /** Clears the table completely, leaving it empty. */
  void _clear() {
    if (_elementCount == 0) return;
    for (int i = 0; i < _table.length; i++) {
      _table[i] = null;
    }
    _entryCount = _deletedCount = 0;
    _recordModification();
  }

  /** Clears an entry in the table. */
  void _deleteEntry(int offset) {
    assert(!_isFree(_table[offset]));
    _setKey(offset, _TOMBSTONE);
    _deletedCount++;
    _recordModification();
  }
}

/**
 * Generic iterable based on a [_HashTable].
 */
abstract class _HashTableIterable<E> extends Iterable<E> {
  final _HashTable _hashTable;
  _HashTableIterable(this._hashTable);

  Iterator<E> get iterator;

  /**
   * Return the iterated value for a given entry.
   */
  E _valueAt(int offset, Object key);

  int get length => _hashTable._elementCount;

  /**
   * Iterates over non-free entries of the table.
   *
   * I
   */
  void forEach(void action(E element)) {
    int entrySize = _hashTable._entrySize;
    List table = _hashTable._table;
    int modificationCount = _hashTable._modificationCount;
    for (int offset = 0; offset < table.length; offset += entrySize) {
      Object entry = table[offset];
      if (!_hashTable._isFree(entry)) {
        E value = _valueAt(offset, entry);
        action(value);
      }
      _hashTable._checkModification(modificationCount);
    }
  }

  bool get isEmpty => _hashTable._elementCount == 0;

  E get single {
    if (_hashTable._elementCount > 1) {
      throw new StateError("More than one element");
    }
    return first;
  }
}

abstract class _HashTableIterator<E> implements Iterator<E> {
  final _HashTable _hashTable;
  final int _modificationCount;
  /** Location right after last found element. */
  int _offset = 0;
  E _current = null;

  _HashTableIterator(_HashTable hashTable)
      : _hashTable = hashTable,
        _modificationCount = hashTable._modificationCount;

  bool moveNext() {
    _hashTable._checkModification(_modificationCount);

    List table = _hashTable._table;
    int entrySize = _hashTable._entrySize;

    while (_offset < table.length) {
      int currentOffset = _offset;
      Object entry = table[currentOffset];
      _offset = currentOffset + entrySize;
      if (!_hashTable._isFree(entry)) {
        _current = _valueAt(currentOffset, entry);
        return true;
      }
    }
    _current = null;
    return false;
  }

  E get current => _current;

  E _valueAt(int offset, Object key);
}

class _HashTableKeyIterable<K> extends _HashTableIterable<K> {
  _HashTableKeyIterable(_HashTable<K> hashTable) : super(hashTable);

  Iterator<K> get iterator => new _HashTableKeyIterator<K>(_hashTable);

  K _valueAt(int offset, Object key) {
    if (identical(key, _NULL)) return null;
    return key;
  }

  bool contains(Object value) => _hashTable._get(value) >= 0;
}

class _HashTableKeyIterator<K> extends _HashTableIterator<K> {
  _HashTableKeyIterator(_HashTable hashTable) : super(hashTable);

  K _valueAt(int offset, Object key) {
    if (identical(key, _NULL)) return null;
    return key;
  }
}

class _HashTableValueIterable<V> extends _HashTableIterable<V> {
  final int _entryIndex;

  _HashTableValueIterable(_HashTable hashTable, this._entryIndex)
      : super(hashTable);

  Iterator<V> get iterator {
    return new _HashTableValueIterator<V>(_hashTable, _entryIndex);
  }

  V _valueAt(int offset, Object key) => _hashTable._table[offset + _entryIndex];
}

class _HashTableValueIterator<V> extends _HashTableIterator<V> {
  final int _entryIndex;

  _HashTableValueIterator(_HashTable hashTable, this._entryIndex)
      : super(hashTable);

  V _valueAt(int offset, Object key) => _hashTable._table[offset + _entryIndex];
}
