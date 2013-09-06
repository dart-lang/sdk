// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class HashMap<K, V> {
  /* patch */ factory HashMap({ bool equals(K key1, K key2),
                                int hashCode(K key),
                                bool isValidKey(potentialKey) }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _HashMap<K, V>();
        }
        if (identical(identical, equals)) {
          return new _IdentityHashMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else if (equals == null) {
        equals = _defaultEquals;
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return new _CustomHashMap<K, V>(equals, hashCode, isValidKey);
  }
}

const int _MODIFICATION_COUNT_MASK = 0x3fffffff;

class _HashMap<K, V> implements HashMap<K, V> {
  static const int _INITIAL_CAPACITY = 8;

  int _elementCount = 0;
  List<_HashMapEntry> _buckets = new List(_INITIAL_CAPACITY);
  int _modificationCount = 0;

  int get length => _elementCount;
  bool get isEmpty => _elementCount == 0;
  bool get isNotEmpty => _elementCount != 0;

  Iterable<K> get keys => new _HashMapKeyIterable<K>(this);
  Iterable<V> get values => new _HashMapValueIterable<V>(this);

  bool containsKey(Object key) {
    int hashCode = key.hashCode;
    List buckets = _buckets;
    int index = hashCode & (buckets.length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.key == key) return true;
      entry = entry.next;
    }
    return false;
  }

  bool containsValue(Object value) {
    List buckets = _buckets;
    int length = buckets.length;
    for (int i = 0; i < length; i++) {
      _HashMapEntry entry = buckets[i];
      while (entry != null) {
        if (entry.value == value) return true;
        entry = entry.next;
      }
    }
    return false;
  }

  V operator[](Object key) {
    int hashCode = key.hashCode;
    List buckets = _buckets;
    int index = hashCode & (buckets.length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.key == key) {
        return entry.value;
      }
      entry = entry.next;
    }
    return null;
  }

  void operator []=(K key, V value) {
    int hashCode = key.hashCode;
    List buckets = _buckets;
    int length = buckets.length;
    int index = hashCode & (length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.key == key) {
        entry.value = value;
        return;
      }
      entry = entry.next;
    }
    _addEntry(buckets, index, length, key, value, hashCode);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int hashCode = key.hashCode;
    List buckets = _buckets;
    int length = buckets.length;
    int index = hashCode & (length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.key == key) {
        return entry.value;
      }
      entry = entry.next;
    }
    int stamp = _modificationCount;
    V value = ifAbsent();
    if (stamp == _modificationCount) {
      _addEntry(buckets, index, length, key, value, hashCode);
    } else {
      this[key] = value;
    }
    return value;
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  void forEach(void action(K key, V value)) {
    int stamp = _modificationCount;
    List buckets = _buckets;
    int length = buckets.length;
    for (int i = 0; i < length; i++) {
      _HashMapEntry entry = buckets[i];
      while (entry != null) {
        action(entry.key, entry.value);
        if (stamp != _modificationCount) {
          throw new ConcurrentModificationError(this);
        }
        entry = entry.next;
      }
    }
  }

  V remove(Object key) {
    int hashCode = key.hashCode;
    List buckets = _buckets;
    int index = hashCode & (buckets.length - 1);
    _HashMapEntry entry = buckets[index];
    _HashMapEntry previous = null;
    while (entry != null) {
      _HashMapEntry next = entry.next;
      if (hashCode == entry.hashCode && entry.key == key) {
        _removeEntry(entry, previous, index);
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return entry.value;
      }
      previous = entry;
      entry = next;
    }
    return null;
  }

  void clear() {
    _elementCount = 0;
    _buckets = new List(_INITIAL_CAPACITY);
    _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  }

  void _removeEntry(_HashMapEntry entry,
                    _HashMapEntry previousInBucket,
                    int bucketIndex) {
    if (previousInBucket == null) {
      _buckets[bucketIndex] = entry.next;
    } else {
      previousInBucket.next = entry.next;
    }
  }

  void _addEntry(List buckets, int index, int length,
                 K key, V value, int hashCode) {
    _HashMapEntry entry =
        new _HashMapEntry(key, value, hashCode, buckets[index]);
    buckets[index] = entry;
    int newElements = _elementCount + 1;
    _elementCount = newElements;
    // If we end up with more than 75% non-empty entries, we
    // resize the backing store.
    if ((newElements << 2) > ((length << 1) + length)) _resize();
    _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  }

  void _resize() {
    List oldBuckets = _buckets;
    int oldLength = oldBuckets.length;
    int newLength = oldLength << 1;
    List newBuckets = new List(newLength);
    for (int i = 0; i < oldLength; i++) {
      _HashMapEntry entry = oldBuckets[i];
      while (entry != null) {
        _HashMapEntry next = entry.next;
        int hashCode = entry.hashCode;
        int index = hashCode & (newLength - 1);
        entry.next = newBuckets[index];
        newBuckets[index] = entry;
        entry = next;
      }
    }
    _buckets = newBuckets;
  }

  String toString() => Maps.mapToString(this);
}

class _CustomHashMap<K, V> extends _HashMap<K, V> {
  final _Equality<K> _equals;
  final _Hasher<K> _hashCode;
  final _Predicate _validKey;
  _CustomHashMap(this._equals, this._hashCode, validKey)
      : _validKey = (validKey != null) ? validKey : new _TypeTest<K>().test;

  bool containsKey(Object key) {
    if (!_validKey(key)) return false;
    int hashCode = _hashCode(key);
    List buckets = _buckets;
    int index = hashCode & (buckets.length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && _equals(entry.key, key)) return true;
      entry = entry.next;
    }
    return false;
  }

  V operator[](Object key) {
    if (!_validKey(key)) return null;
    int hashCode = _hashCode(key);
    List buckets = _buckets;
    int index = hashCode & (buckets.length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && _equals(entry.key, key)) {
        return entry.value;
      }
      entry = entry.next;
    }
    return null;
  }

  void operator []=(K key, V value) {
    int hashCode = _hashCode(key);
    List buckets = _buckets;
    int length = buckets.length;
    int index = hashCode & (length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && _equals(entry.key, key)) {
        entry.value = value;
        return;
      }
      entry = entry.next;
    }
    _addEntry(buckets, index, length, key, value, hashCode);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int hashCode = _hashCode(key);
    List buckets = _buckets;
    int length = buckets.length;
    int index = hashCode & (length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && _equals(entry.key, key)) {
        return entry.value;
      }
      entry = entry.next;
    }
    int stamp = _modificationCount;
    V value = ifAbsent();
    if (stamp == _modificationCount) {
      _addEntry(buckets, index, length, key, value, hashCode);
    } else {
      this[key] = value;
    }
    return value;
  }

  V remove(Object key) {
    if (!_validKey(key)) return null;
    int hashCode = _hashCode(key);
    List buckets = _buckets;
    int index = hashCode & (buckets.length - 1);
    _HashMapEntry entry = buckets[index];
    _HashMapEntry previous = null;
    while (entry != null) {
      _HashMapEntry next = entry.next;
      if (hashCode == entry.hashCode && _equals(entry.key, key)) {
        _removeEntry(entry, previous, index);
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return entry.value;
      }
      previous = entry;
      entry = next;
    }
    return null;
  }

  String toString() => Maps.mapToString(this);
}

class _IdentityHashMap<K, V> extends _HashMap<K, V> {
  bool containsKey(Object key) {
    int hashCode = key.hashCode;
    List buckets = _buckets;
    int index = hashCode & (buckets.length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && identical(entry.key, key)) return true;
      entry = entry.next;
    }
    return false;
  }

  V operator[](Object key) {
    int hashCode = key.hashCode;
    List buckets = _buckets;
    int index = hashCode & (buckets.length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && identical(entry.key, key)) {
        return entry.value;
      }
      entry = entry.next;
    }
    return null;
  }

  void operator []=(K key, V value) {
    int hashCode = key.hashCode;
    List buckets = _buckets;
    int length = buckets.length;
    int index = hashCode & (length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && identical(entry.key, key)) {
        entry.value = value;
        return;
      }
      entry = entry.next;
    }
    _addEntry(buckets, index, length, key, value, hashCode);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int hashCode = key.hashCode;
    List buckets = _buckets;
    int length = buckets.length;
    int index = hashCode & (length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && identical(entry.key, key)) {
        return entry.value;
      }
      entry = entry.next;
    }
    int stamp = _modificationCount;
    V value = ifAbsent();
    if (stamp == _modificationCount) {
      _addEntry(buckets, index, length, key, value, hashCode);
    } else {
      this[key] = value;
    }
    return value;
  }

  V remove(Object key) {
    int hashCode = key.hashCode;
    List buckets = _buckets;
    int index = hashCode & (buckets.length - 1);
    _HashMapEntry entry = buckets[index];
    _HashMapEntry previous = null;
    while (entry != null) {
      _HashMapEntry next = entry.next;
      if (hashCode == entry.hashCode && identical(entry.key, key)) {
        _removeEntry(entry, previous, index);
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return entry.value;
      }
      previous = entry;
      entry = next;
    }
    return null;
  }

  String toString() => Maps.mapToString(this);
}


class _HashMapEntry {
  final key;
  var value;
  final int hashCode;
  _HashMapEntry next;
  _HashMapEntry(this.key, this.value, this.hashCode, this.next);
}

abstract class _HashMapIterable<E> extends IterableBase<E> {
  final HashMap _map;
  _HashMapIterable(this._map);
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
}

class _HashMapKeyIterable<K> extends _HashMapIterable<K> {
  _HashMapKeyIterable(HashMap map) : super(map);
  Iterator<K> get iterator => new _HashMapKeyIterator<K>(_map);
  bool contains(K key) => _map.containsKey(key);
  void forEach(void action(K key)) {
    _map.forEach((K key, _) {
      action(key);
    });
  }
}

class _HashMapValueIterable<V> extends _HashMapIterable<V> {
  _HashMapValueIterable(HashMap map) : super(map);
  Iterator<V> get iterator => new _HashMapValueIterator<V>(_map);
  bool contains(V value) => _map.containsValue(value);
  void forEach(void action(V value)) {
    _map.forEach((_, V value) {
      action(value);
    });
  }
}

abstract class _HashMapIterator<E> implements Iterator<E> {
  final HashMap _map;
  final int _stamp;

  int _index = 0;
  _HashMapEntry _entry;

  _HashMapIterator(HashMap map)
     : _map = map, _stamp = map._modificationCount;

  bool moveNext() {
    if (_stamp != _map._modificationCount) {
      throw new ConcurrentModificationError(_map);
    }
    _HashMapEntry entry = _entry;
    if (entry != null) {
      _HashMapEntry next = entry.next;
      if (next != null) {
        _entry = next;
        return true;
      }
      _entry = null;
    }
    List buckets = _map._buckets;
    int length = buckets.length;
    for (int i = _index; i < length; i++) {
      entry = buckets[i];
      if (entry != null) {
        _index = i + 1;
        _entry = entry;
        return true;
      }
    }
    _index = length;
    return false;
  }
}

class _HashMapKeyIterator<K> extends _HashMapIterator<K> {
  _HashMapKeyIterator(HashMap map) : super(map);
  K get current {
    _HashMapEntry entry = _entry;
    return (entry == null) ? null : entry.key;
  }
}

class _HashMapValueIterator<V> extends _HashMapIterator<V> {
  _HashMapValueIterator(HashMap map) : super(map);
  V get current {
    _HashMapEntry entry = _entry;
    return (entry == null) ? null : entry.value;
  }
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

  /* patch */ bool get isNotEmpty => !isEmpty;

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

  /* patch */ void removeAll(Iterable<Object> objectsToRemove) {
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

class _LinkedHashMapEntry extends _HashMapEntry {
  var _nextEntry;
  var _previousEntry;
  _LinkedHashMapEntry(key, value, int hashCode, _LinkedHashMapEntry next,
                      this._previousEntry, this._nextEntry)
      : super(key, value, hashCode, next) {
    _previousEntry._nextEntry = this;
    _nextEntry._previousEntry = this;
  }
}

class _LinkedHashMapKeyIterable<K> extends IterableBase<K> {
  LinkedHashMap<K, dynamic> _map;
  _LinkedHashMapKeyIterable(this._map);
  Iterator<K> get iterator => new _LinkedHashMapKeyIterator<K>(_map);
  bool contains(K key) => _map.containsKey(key);
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  int get length => _map.length;
}

class _LinkedHashMapValueIterable<V> extends IterableBase<V> {
  LinkedHashMap<dynamic, V> _map;
  _LinkedHashMapValueIterable(this._map);
  Iterator<K> get iterator => new _LinkedHashMapValueIterator<V>(_map);
  bool contains(V value) => _map.containsValue(value);
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  int get length => _map.length;
}

abstract class _LinkedHashMapIterator<T> implements Iterator<T> {
  final LinkedHashMap _map;
  var _next;
  T _current;
  int _modificationCount;
  _LinkedHashMapIterator(LinkedHashMap map)
      : _map = map,
        _current = null,
        _next = map._nextEntry,
        _modificationCount = map._modificationCount;

  bool moveNext() {
    if (_modificationCount != _map._modificationCount) {
      throw new ConcurrentModificationError(_map);
    }
    if (identical(_map, _next)) {
      _current = null;
      return false;
    }
    _LinkedHashMapEntry entry = _next;
    _next = entry._nextEntry;
    _current = _getValue(entry);
    return true;
  }

  T _getValue(_LinkedHashMapEntry entry);

  T get current => _current;
}

class _LinkedHashMapKeyIterator<K> extends _LinkedHashMapIterator<K> {
  _LinkedHashMapKeyIterator(LinkedHashMap map) : super(map);
  K _getValue(_LinkedHashMapEntry entry) => entry.key;
}

class _LinkedHashMapValueIterator<V> extends _LinkedHashMapIterator<V> {
  _LinkedHashMapValueIterator(LinkedHashMap map) : super(map);
  V _getValue(_LinkedHashMapEntry entry) => entry.value;
}


/**
 * A hash-based map that iterates keys and values in key insertion order.
 */
patch class LinkedHashMap<K, V> {
  var _nextEntry;
  var _previousEntry;

  /* patch */ factory LinkedHashMap({ bool equals(K key1, K key2),
                                      int hashCode(K key),
                                      bool isValidKey(potentialKey) }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _LinkedHashMap<K, V>();
        }
        if (identical(identical, equals)) {
          return new _LinkedIdentityHashMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else if (equals == null) {
        equals = _defaultEquals;
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return new _LinkedCustomHashMap<K, V>(equals, hashCode, isValidKey);
  }
}

// Methods that are exactly the same in all three linked hash map variants.
abstract class _LinkedHashMapMixin<K, V> implements LinkedHashMap<K, V> {
  var _nextEntry;
  var _previousEntry;

  bool containsValue(Object value) {
    int modificationCount = _modificationCount;
    var cursor = _nextEntry;
    while (!identical(cursor, this)) {
      _HashMapEntry entry = cursor;
      if (entry.value == value) return true;
      if (modificationCount != _modificationCount) {
        throw new ConcurrentModificationError(this);
      }
      cursor = cursor._nextEntry;
    }
    return false;
  }

  void forEach(void action(K key, V value)) {
    int modificationCount = _modificationCount;
    var cursor = _nextEntry;
    while (!identical(cursor, this)) {
      _HashMapEntry entry = cursor;
      action(entry.key, entry.value);
      if (modificationCount != _modificationCount) {
        throw new ConcurrentModificationError(this);
      }
      cursor = cursor._nextEntry;
    }
  }

  void clear() {
    _nextEntry = _previousEntry = this;
    _elementCount = 0;
    _buckets = new List(_HashMap._INITIAL_CAPACITY);
    _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  }

  void _addEntry(List buckets, int index, int length,
                 K key, V value, int hashCode) {
    _HashMapEntry entry =
        new _LinkedHashMapEntry(key, value, hashCode, buckets[index],
                                _previousEntry, this);
    buckets[index] = entry;
    int newElements = _elementCount + 1;
    _elementCount = newElements;
    // If we end up with more than 75% non-empty entries, we
    // resize the backing store.
    if ((newElements << 2) > ((length << 1) + length)) _resize();
    _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  }

  void _removeEntry(_LinkedHashMapEntry entry,
                    _HashMapEntry previousInBucket,
                    int bucketIndex) {
    var previousInChain = entry._previousEntry;
    var nextInChain = entry._nextEntry;
    previousInChain._nextEntry = nextInChain;
    nextInChain._previousEntry = previousInChain;
    if (previousInBucket == null) {
      _buckets[bucketIndex] = entry.next;
    } else {
      previousInBucket.next = entry.next;
    }
  }


  Iterable<K> get keys => new _LinkedHashMapKeyIterable<K>(this);
  Iterable<V> get values => new _LinkedHashMapValueIterable<V>(this);
}

class _LinkedHashMap<K, V> extends _HashMap<K, V>
                           with _LinkedHashMapMixin<K, V> {
  _LinkedHashMap() {
    _nextEntry = _previousEntry = this;
  }
}

class _LinkedIdentityHashMap<K, V> extends _IdentityHashMap<K, V>
                                   with _LinkedHashMapMixin<K, V> {
  _LinkedIdentityHashMap() {
    _nextEntry = _previousEntry = this;
  }
}

class _LinkedCustomHashMap<K, V> extends _CustomHashMap<K, V>
                                 with _LinkedHashMapMixin<K, V> {
  _LinkedCustomHashMap(bool equals(K key1, K key2),
                       int hashCode(K key),
                       bool isValidKey(potentialKey))
      : super(equals, hashCode, isValidKey) {
    _nextEntry = _previousEntry = this;
  }
}


patch class LinkedHashSet<E> extends _HashSetBase<E> {
  static const int _INITIAL_CAPACITY = 8;
  _LinkedHashTable<E> _table;

  /* patch */ LinkedHashSet() {
    _table = new _LinkedHashTable(_INITIAL_CAPACITY);
    _table._container = this;
  }

  // Iterable.
  /* patch */ Iterator<E> get iterator {
    return new _LinkedHashTableKeyIterator<E>(_table);
  }

  /* patch */ int get length => _table._elementCount;

  /* patch */ bool get isEmpty => _table._elementCount == 0;

  /* patch */ bool get isNotEmpty => !isEmpty;

  /* patch */ bool contains(Object object) => _table._get(object) >= 0;

  /* patch */ void forEach(void action(E element)) {
    int offset = _table._next(_LinkedHashTable._HEAD_OFFSET);
    int modificationCount = _table._modificationCount;
    while (offset != _LinkedHashTable._HEAD_OFFSET) {
      E key = _table._key(offset);
      action(key);
      _table._checkModification(modificationCount);
      offset = _table._next(offset);
    }
  }

  /* patch */ E get first {
    int firstOffset = _table._next(_LinkedHashTable._HEAD_OFFSET);
    if (firstOffset == _LinkedHashTable._HEAD_OFFSET) {
      throw new StateError("No elements");
    }
    return _table._key(firstOffset);
  }

  /* patch */ E get last {
    int lastOffset = _table._prev(_LinkedHashTable._HEAD_OFFSET);
    if (lastOffset == _LinkedHashTable._HEAD_OFFSET) {
      throw new StateError("No elements");
    }
    return _table._key(lastOffset);
  }

  // Collection.
  void _filterWhere(bool test(E element), bool removeMatching) {
    int entrySize = _table._entrySize;
    int length = _table._table.length;
    int offset = _table._next(_LinkedHashTable._HEAD_OFFSET);
    while (offset != _LinkedHashTable._HEAD_OFFSET) {
      E key = _table._key(offset);
      int nextOffset = _table._next(offset);
      int modificationCount = _table._modificationCount;
      bool shouldRemove = (removeMatching == test(key));
      _table._checkModification(modificationCount);
      if (shouldRemove) {
        _table._deleteEntry(offset);
      }
      offset = nextOffset;
    }
    _table._checkCapacity();
  }

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
    if (offset >= 0) {
      _table._checkCapacity();
      return true;
    }
    return false;
  }

  /* patch */ void removeAll(Iterable objectsToRemove) {
    for (Object object in objectsToRemove) {
      if (_table._remove(object) >= 0) {
        _table._checkCapacity();
      }
    }
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
  /** If set, used as the source object for [ConcurrentModificationError]s. */
  Object _container;

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
      throw new ConcurrentModificationError(_container);
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
    List table = new List(capacity * _entrySize);
    return table;
  }

  /** First table probe. */
  int _firstProbe(int hashCode, int capacity) {
    return hashCode & (capacity - 1);
  }

  /** Following table probes. */
  int _nextProbe(int previousIndex, int probeCount, int capacity) {
    // When capacity is a power of 2, this probing algorithm (the triangular
    // number sequence modulo capacity) is guaranteed to hit all indices exactly
    // once before repeating.
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
      } else if (!identical(_TOMBSTONE, entry)) {
        if (identical(_NULL, entry) ? _equals(null, object)
                                    : _equals(entry, object)) {
          return offset;
        }
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
  int _get(Object key) {
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
  int _remove(Object key) {
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
abstract class _HashTableIterable<E> extends IterableBase<E> {
  final _HashTable _hashTable;
  _HashTableIterable(this._hashTable);

  Iterator<E> get iterator;

  /**
   * Return the iterated value for a given entry.
   */
  E _valueAt(int offset, Object key);

  int get length => _hashTable._elementCount;

  bool get isEmpty => _hashTable._elementCount == 0;

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
    List result = new List(capacity * _entrySize);
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

class _LinkedHashTableKeyIterable<K> extends IterableBase<K> {
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

class _LinkedHashTableValueIterable<V> extends IterableBase<V> {
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
