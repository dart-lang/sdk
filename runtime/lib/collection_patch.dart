// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:collection" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:_internal" as internal;

import "dart:_internal" show patch;

import "dart:typed_data" show Uint32List;

/// These are the additional parts of this patch library:
// part "compact_hash.dart";

@patch
class HashMap<K, V> {
  @patch
  factory HashMap(
      {bool equals(K key1, K key2),
      int hashCode(K key),
      bool isValidKey(potentialKey)}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _HashMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return new _IdentityHashMap<K, V>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
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

  @patch
  factory HashMap.identity() = _IdentityHashMap<K, V>;

  Set<K> _newKeySet();
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

  V operator [](Object key) {
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
    _buckets = new List(_INITIAL_CAPACITY);
    if (_elementCount > 0) {
      _elementCount = 0;
      _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
    }
  }

  void _removeEntry(
      _HashMapEntry entry, _HashMapEntry previousInBucket, int bucketIndex) {
    if (previousInBucket == null) {
      _buckets[bucketIndex] = entry.next;
    } else {
      previousInBucket.next = entry.next;
    }
  }

  void _addEntry(
      List buckets, int index, int length, K key, V value, int hashCode) {
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

  Set<K> _newKeySet() => new _HashSet<K>();
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

  V operator [](Object key) {
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

  Set<K> _newKeySet() => new _CustomHashSet<K>(_equals, _hashCode, _validKey);
}

class _IdentityHashMap<K, V> extends _HashMap<K, V> {
  bool containsKey(Object key) {
    int hashCode = identityHashCode(key);
    List buckets = _buckets;
    int index = hashCode & (buckets.length - 1);
    _HashMapEntry entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && identical(entry.key, key)) return true;
      entry = entry.next;
    }
    return false;
  }

  V operator [](Object key) {
    int hashCode = identityHashCode(key);
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
    int hashCode = identityHashCode(key);
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
    int hashCode = identityHashCode(key);
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
    int hashCode = identityHashCode(key);
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

  Set<K> _newKeySet() => new _IdentityHashSet<K>();
}

class _HashMapEntry {
  final key;
  var value;
  final int hashCode;
  _HashMapEntry next;
  _HashMapEntry(this.key, this.value, this.hashCode, this.next);
}

abstract class _HashMapIterable<E> extends internal.EfficientLengthIterable<E> {
  final HashMap _map;
  _HashMapIterable(this._map);
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
}

class _HashMapKeyIterable<K> extends _HashMapIterable<K> {
  _HashMapKeyIterable(HashMap map) : super(map);
  Iterator<K> get iterator => new _HashMapKeyIterator<K>(_map);
  bool contains(Object key) => _map.containsKey(key);
  void forEach(void action(K key)) {
    _map.forEach((K key, _) {
      action(key);
    });
  }

  Set<K> toSet() => _map._newKeySet()..addAll(this);
}

class _HashMapValueIterable<V> extends _HashMapIterable<V> {
  _HashMapValueIterable(HashMap map) : super(map);
  Iterator<V> get iterator => new _HashMapValueIterator<V>(_map);
  bool contains(Object value) => _map.containsValue(value);
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
      : _map = map,
        _stamp = map._modificationCount;

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

@patch
class HashSet<E> {
  @patch
  factory HashSet(
      {bool equals(E e1, E e2),
      int hashCode(E e),
      bool isValidKey(potentialKey)}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _HashSet<E>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return new _IdentityHashSet<E>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return new _CustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @patch
  factory HashSet.identity() = _IdentityHashSet<E>;
}

class _HashSet<E> extends _HashSetBase<E> implements HashSet<E> {
  static const int _INITIAL_CAPACITY = 8;

  List<_HashSetEntry> _buckets = new List(_INITIAL_CAPACITY);
  int _elementCount = 0;
  int _modificationCount = 0;

  bool _equals(e1, e2) => e1 == e2;
  int _hashCode(e) => e.hashCode;

  // Iterable.

  Iterator<E> get iterator => new _HashSetIterator<E>(this);

  int get length => _elementCount;

  bool get isEmpty => _elementCount == 0;

  bool get isNotEmpty => _elementCount != 0;

  bool contains(Object object) {
    int index = _hashCode(object) & (_buckets.length - 1);
    _HashSetEntry entry = _buckets[index];
    while (entry != null) {
      if (_equals(entry.key, object)) return true;
      entry = entry.next;
    }
    return false;
  }

  E lookup(Object object) {
    int index = _hashCode(object) & (_buckets.length - 1);
    _HashSetEntry entry = _buckets[index];
    while (entry != null) {
      var key = entry.key;
      if (_equals(key, object)) return key;
      entry = entry.next;
    }
    return null;
  }

  // Set.

  bool add(E element) {
    int hashCode = _hashCode(element);
    int index = hashCode & (_buckets.length - 1);
    _HashSetEntry entry = _buckets[index];
    while (entry != null) {
      if (_equals(entry.key, element)) return false;
      entry = entry.next;
    }
    _addEntry(element, hashCode, index);
    return true;
  }

  void addAll(Iterable<E> objects) {
    int ctr = 0;
    for (E object in objects) {
      ctr++;
      add(object);
    }
  }

  bool _remove(Object object, int hashCode) {
    int index = hashCode & (_buckets.length - 1);
    _HashSetEntry entry = _buckets[index];
    _HashSetEntry previous = null;
    while (entry != null) {
      if (_equals(entry.key, object)) {
        _HashSetEntry next = entry.remove();
        if (previous == null) {
          _buckets[index] = next;
        } else {
          previous.next = next;
        }
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return true;
      }
      previous = entry;
      entry = entry.next;
    }
    return false;
  }

  bool remove(Object object) => _remove(object, _hashCode(object));

  void removeAll(Iterable<Object> objectsToRemove) {
    for (Object object in objectsToRemove) {
      _remove(object, _hashCode(object));
    }
  }

  void _filterWhere(bool test(E element), bool removeMatching) {
    int length = _buckets.length;
    for (int index = 0; index < length; index++) {
      _HashSetEntry entry = _buckets[index];
      _HashSetEntry previous = null;
      while (entry != null) {
        int modificationCount = _modificationCount;
        bool testResult = test(entry.key);
        if (modificationCount != _modificationCount) {
          throw new ConcurrentModificationError(this);
        }
        if (testResult == removeMatching) {
          _HashSetEntry next = entry.remove();
          if (previous == null) {
            _buckets[index] = next;
          } else {
            previous.next = next;
          }
          _elementCount--;
          _modificationCount =
              (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
          entry = next;
        } else {
          previous = entry;
          entry = entry.next;
        }
      }
    }
  }

  void removeWhere(bool test(E element)) {
    _filterWhere(test, true);
  }

  void retainWhere(bool test(E element)) {
    _filterWhere(test, false);
  }

  void clear() {
    _buckets = new List(_INITIAL_CAPACITY);
    if (_elementCount > 0) {
      _elementCount = 0;
      _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
    }
  }

  void _addEntry(E key, int hashCode, int index) {
    _buckets[index] = new _HashSetEntry(key, hashCode, _buckets[index]);
    int newElements = _elementCount + 1;
    _elementCount = newElements;
    int length = _buckets.length;
    // If we end up with more than 75% non-empty entries, we
    // resize the backing store.
    if ((newElements << 2) > ((length << 1) + length)) _resize();
    _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  }

  void _resize() {
    int oldLength = _buckets.length;
    int newLength = oldLength << 1;
    List oldBuckets = _buckets;
    List newBuckets = new List(newLength);
    for (int i = 0; i < oldLength; i++) {
      _HashSetEntry entry = oldBuckets[i];
      while (entry != null) {
        _HashSetEntry next = entry.next;
        int newIndex = entry.hashCode & (newLength - 1);
        entry.next = newBuckets[newIndex];
        newBuckets[newIndex] = entry;
        entry = next;
      }
    }
    _buckets = newBuckets;
  }

  HashSet<E> _newSet() => new _HashSet<E>();
}

class _IdentityHashSet<E> extends _HashSet<E> {
  int _hashCode(e) => identityHashCode(e);
  bool _equals(e1, e2) => identical(e1, e2);
  HashSet<E> _newSet() => new _IdentityHashSet<E>();
}

class _CustomHashSet<E> extends _HashSet<E> {
  final _Equality<E> _equality;
  final _Hasher<E> _hasher;
  final _Predicate _validKey;
  _CustomHashSet(this._equality, this._hasher, bool validKey(Object o))
      : _validKey = (validKey != null) ? validKey : new _TypeTest<E>().test;

  bool remove(Object element) {
    if (!_validKey(element)) return false;
    return super.remove(element);
  }

  bool contains(Object element) {
    if (!_validKey(element)) return false;
    return super.contains(element);
  }

  E lookup(Object element) {
    if (!_validKey(element)) return null;
    return super.lookup(element);
  }

  bool containsAll(Iterable<Object> elements) {
    for (Object element in elements) {
      if (!_validKey(element) || !this.contains(element)) return false;
    }
    return true;
  }

  void removeAll(Iterable<Object> elements) {
    for (Object element in elements) {
      if (_validKey(element)) {
        super._remove(element, _hasher(element));
      }
    }
  }

  bool _equals(e1, e2) => _equality(e1, e2);
  int _hashCode(e) => _hasher(e);

  HashSet<E> _newSet() => new _CustomHashSet<E>(_equality, _hasher, _validKey);
}

class _HashSetEntry {
  final key;
  final int hashCode;
  _HashSetEntry next;
  _HashSetEntry(this.key, this.hashCode, this.next);

  _HashSetEntry remove() {
    _HashSetEntry result = next;
    next = null;
    return result;
  }
}

class _HashSetIterator<E> implements Iterator<E> {
  final _HashSet _set;
  final int _modificationCount;
  int _index = 0;
  _HashSetEntry _next;
  E _current;

  _HashSetIterator(_HashSet hashSet)
      : _set = hashSet,
        _modificationCount = hashSet._modificationCount;

  bool moveNext() {
    if (_modificationCount != _set._modificationCount) {
      throw new ConcurrentModificationError(_set);
    }
    if (_next != null) {
      _current = _next.key;
      _next = _next.next;
      return true;
    }
    List<_HashSetEntry> buckets = _set._buckets;
    while (_index < buckets.length) {
      _next = buckets[_index];
      _index = _index + 1;
      if (_next != null) {
        _current = _next.key;
        _next = _next.next;
        return true;
      }
    }
    _current = null;
    return false;
  }

  E get current => _current;
}

/**
 * A hash-based map that iterates keys and values in key insertion order.
 * This is never actually instantiated any more - the constructor always
 * returns an instance of _CompactLinkedHashMap or _InternalLinkedHashMap,
 * which despite the names do not use links (but are insertion-ordered as if
 * they did).
 */
@patch
class LinkedHashMap<K, V> {
  @patch
  factory LinkedHashMap(
      {bool equals(K key1, K key2),
      int hashCode(K key),
      bool isValidKey(potentialKey)}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _InternalLinkedHashMap<K, V>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return new _CompactLinkedIdentityHashMap<K, V>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return new _CompactLinkedCustomHashMap<K, V>(equals, hashCode, isValidKey);
  }

  @patch
  factory LinkedHashMap.identity() = _CompactLinkedIdentityHashMap<K, V>;
}

@patch
class LinkedHashSet<E> {
  @patch
  factory LinkedHashSet(
      {bool equals(E e1, E e2),
      int hashCode(E e),
      bool isValidKey(potentialKey)}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _CompactLinkedHashSet<E>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return new _CompactLinkedIdentityHashSet<E>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return new _CompactLinkedCustomHashSet<E>(equals, hashCode, isValidKey);
  }

  @patch
  factory LinkedHashSet.identity() = _CompactLinkedIdentityHashSet<E>;
}
