// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class HashMap<K, V> {
  final _HashMapTable<K, V> _hashTable = new _HashMapTable<K, V>();

  /* patch */ HashMap() {
    _hashTable._container = this;
  }


  /* patch */ bool containsKey(K key) {
    return _hashTable._get(key) >= 0;
  }

  /* patch */ bool containsValue(V value) {
    List table = _hashTable._table;
    int entrySize = _hashTable._entrySize;
    for (int offset = 0; offset < table.length; offset += entrySize) {
      if (!_hashTable._isFree(table[offset]) &&
          _hashTable._value(offset) == value) {
        return true;
      }
    }
    return false;
  }

  /* patch */ void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      int offset = _hashTable._put(key);
      _hashTable._setValue(offset, value);
      _hashTable._checkCapacity();
    });
  }

  /* patch */ V operator [](K key) {
    int offset = _hashTable._get(key);
    if (offset >= 0) return _hashTable._value(offset);
    return null;
  }

  /* patch */ void operator []=(K key, V value) {
    int offset = _hashTable._put(key);
    _hashTable._setValue(offset, value);
    _hashTable._checkCapacity();
  }

  /* patch */ V putIfAbsent(K key, V ifAbsent()) {
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

  /* patch */ V remove(K key) {
    int offset = _hashTable._remove(key);
    if (offset < 0) return null;
    V oldValue = _hashTable._value(offset);
    _hashTable._setValue(offset, null);
    _hashTable._checkCapacity();
    return oldValue;
  }

  /* patch */ void clear() {
    _hashTable._clear();
  }

  /* patch */ void forEach(void action(K key, V value)) {
    int modificationCount = _hashTable._modificationCount;
    List table = _hashTable._table;
    int entrySize = _hashTable._entrySize;
    for (int offset = 0; offset < table.length; offset += entrySize) {
      Object entry = table[offset];
      if (!_hashTable._isFree(entry)) {
        K key = entry;
        V value = _hashTable._value(offset);
        action(key, value);
        _hashTable._checkModification(modificationCount);
      }
    }
  }

  /* patch */ Iterable<K> get keys => new _HashTableKeyIterable<K>(_hashTable);
  /* patch */ Iterable<V> get values =>
      new _HashTableValueIterable<V>(_hashTable, _HashMapTable._VALUE_INDEX);

  /* patch */ int get length => _hashTable._elementCount;

  /* patch */ bool get isEmpty => _hashTable._elementCount == 0;
}

patch class HashSet<E> {
  static const int _INITIAL_CAPACITY = 8;
  final _HashTable<E> _table;

  /* patch */ HashSet() : _table = new _HashTable(_INITIAL_CAPACITY) {
    _table._container = this;
  }

  factory HashSet.from(Iterable<E> iterable) {
    return new HashSet<E>()..addAll(iterable);
  }

  // Iterable.
  /* patch */ Iterator<E> get iterator => new _HashTableKeyIterator<E>(_table);

  /* patch */ int get length => _table._elementCount;

  /* patch */ bool get isEmpty => _table._elementCount == 0;

  /* patch */ bool contains(Object object) => _table._get(object) >= 0;

  // Collection.
  /* patch */ void add(E element) {
    _table._put(element);
    _table._checkCapacity();
  }

  /* patch */ void addAll(Iterable<E> objects) {
    for (E object in objects) {
      _table._put(object);
      _table._checkCapacity();
    }
  }

  /* patch */ bool remove(Object object) {
    int offset = _table._remove(object);
    _table._checkCapacity();
    return offset >= 0;
  }

  /* patch */ void removeAll(Iterable objectsToRemove) {
    for (Object object in objectsToRemove) {
      _table._remove(object);
      _table._checkCapacity();
    }
  }

  void _filterWhere(bool test(E element), bool removeMatching) {
    int entrySize = _table._entrySize;
    int length = _table._table.length;
    for (int offset =  0; offset < length; offset += entrySize) {
      Object entry = _table._table[offset];
      if (!_table._isFree(entry)) {
        E key = identical(entry, _NULL) ? null : entry;
        int modificationCount = _table._modificationCount;
        bool shouldRemove = (removeMatching == test(key));
        _table._checkModification(modificationCount);
        if (shouldRemove) {
          _table._deleteEntry(offset);
        }
      }
    }
    _table._checkCapacity();
  }

  /* patch */ void removeWhere(bool test(E element)) {
    _filterWhere(test, true);
  }

  /* patch */ void retainWhere(bool test(E element)) {
    _filterWhere(test, false);
  }

  /* patch */ void clear() {
    _table._clear();
  }
}
