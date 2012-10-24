// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Hash map implementation with open addressing and quadratic probing.
class HashMapImplementation<K, V> implements HashMap<K, V> {

  // The [_keys] list contains the keys inserted in the map.
  // The [_keys] list must be a raw list because it
  // will contain both elements of type K, and the [_DELETED_KEY] of type
  // [_DeletedKeySentinel].
  // The alternative of declaring the [_keys] list as of type Object
  // does not work, because the HashSetIterator constructor would fail:
  //  HashSetIterator(HashSet<E> set)
  //    : _nextValidIndex = -1,
  //      _entries = set_._backingMap._keys {
  //    _advance();
  //  }
  // With K being type int, for example, it would fail because
  // List<Object> is not assignable to type List<int> of entries.
  List _keys;

  // The values inserted in the map. For a filled entry index in this
  // list, there is always the corresponding key in the [keys_] list
  // at the same entry index.
  List<V> _values;

  // The load limit is the number of entries we allow until we double
  // the size of the lists.
  int _loadLimit;

  // The current number of entries in the map. Will never be greater
  // than [_loadLimit].
  int _numberOfEntries;

  // The current number of deleted entries in the map.
  int _numberOfDeleted;

  // The sentinel when a key is deleted from the map.
  static const _DeletedKeySentinel _DELETED_KEY = const _DeletedKeySentinel();

  // The initial capacity of a hash map.
  static const int _INITIAL_CAPACITY = 8;  // must be power of 2

  HashMapImplementation() {
    _numberOfEntries = 0;
    _numberOfDeleted = 0;
    _loadLimit = _computeLoadLimit(_INITIAL_CAPACITY);
    _keys = new List(_INITIAL_CAPACITY);
    _values = new List<V>(_INITIAL_CAPACITY);
  }

  factory HashMapImplementation.from(Map<K, V> other) {
    Map<K, V> result = new HashMapImplementation<K, V>();
    other.forEach((K key, V value) { result[key] = value; });
    return result;
  }

  static int _computeLoadLimit(int capacity) {
    return (capacity * 3) ~/ 4;
  }

  static int _firstProbe(int hashCode, int length) {
    return hashCode & (length - 1);
  }

  static int _nextProbe(int currentProbe, int numberOfProbes, int length) {
    return (currentProbe + numberOfProbes) & (length - 1);
  }

  int _probeForAdding(K key) {
    if (key == null) throw const NullPointerException();
    int hash = _firstProbe(key.hashCode, _keys.length);
    int numberOfProbes = 1;
    int initialHash = hash;
    // insertionIndex points to a slot where a key was deleted.
    int insertionIndex = -1;
    while (true) {
      // [existingKey] can be either of type [K] or [_DeletedKeySentinel].
      Object existingKey = _keys[hash];
      if (existingKey === null) {
        // We are sure the key is not already in the set.
        // If the current slot is empty and we didn't find any
        // insertion slot before, return this slot.
        if (insertionIndex < 0) return hash;
        // If we did find an insertion slot before, return it.
        return insertionIndex;
      } else if (existingKey == key) {
        // The key is already in the map. Return its slot.
        return hash;
      } else if ((insertionIndex < 0) && (_DELETED_KEY === existingKey)) {
        // The slot contains a deleted element. Because previous calls to this
        // method may not have had this slot deleted, we must continue iterate
        // to find if there is a slot with the given key.
        insertionIndex = hash;
      }

      // We did not find an insertion slot. Look at the next one.
      hash = _nextProbe(hash, numberOfProbes++, _keys.length);
      // _ensureCapacity has guaranteed the following cannot happen.
      // assert(hash != initialHash);
    }
  }

  int _probeForLookup(K key) {
    if (key == null) throw const NullPointerException();
    int hash = _firstProbe(key.hashCode, _keys.length);
    int numberOfProbes = 1;
    int initialHash = hash;
    while (true) {
      // [existingKey] can be either of type [K] or [_DeletedKeySentinel].
      Object existingKey = _keys[hash];
      // If the slot does not contain anything (in particular, it does not
      // contain a deleted key), we know the key is not in the map.
      if (existingKey === null) return -1;
      // The key is in the map, return its index.
      if (existingKey == key) return hash;
      // Go to the next probe.
      hash = _nextProbe(hash, numberOfProbes++, _keys.length);
      // _ensureCapacity has guaranteed the following cannot happen.
      // assert(hash != initialHash);
    }
  }

  void _ensureCapacity() {
    int newNumberOfEntries = _numberOfEntries + 1;
    // Test if adding an element will reach the load limit.
    if (newNumberOfEntries >= _loadLimit) {
      _grow(_keys.length * 2);
      return;
    }

    // Make sure that we don't have poor performance when a map
    // contains lots of deleted entries: we _grow if
    // there are more deleted entried than free entries.
    int capacity = _keys.length;
    int numberOfFreeOrDeleted = capacity - newNumberOfEntries;
    int numberOfFree = numberOfFreeOrDeleted - _numberOfDeleted;
    // assert(numberOfFree > 0);
    if (_numberOfDeleted > numberOfFree) {
      _grow(_keys.length);
    }
  }

  static bool _isPowerOfTwo(int x) {
    return ((x & (x - 1)) == 0);
  }

  void _grow(int newCapacity) {
    assert(_isPowerOfTwo(newCapacity));
    int capacity = _keys.length;
    _loadLimit = _computeLoadLimit(newCapacity);
    List oldKeys = _keys;
    List<V> oldValues = _values;
    _keys = new List(newCapacity);
    _values = new List<V>(newCapacity);
    for (int i = 0; i < capacity; i++) {
      // [key] can be either of type [K] or [_DeletedKeySentinel].
      Object key = oldKeys[i];
      // If there is no key, we don't need to deal with the current slot.
      if (key === null || key === _DELETED_KEY) {
        continue;
      }
      V value = oldValues[i];
      // Insert the {key, value} pair in their new slot.
      int newIndex = _probeForAdding(key);
      _keys[newIndex] = key;
      _values[newIndex] = value;
    }
    _numberOfDeleted = 0;
  }

  void clear() {
    _numberOfEntries = 0;
    _numberOfDeleted = 0;
    int length = _keys.length;
    for (int i = 0; i < length; i++) {
      _keys[i] = null;
      _values[i] = null;
    }
  }

  void operator []=(K key, V value) {
    _ensureCapacity();
    int index = _probeForAdding(key);
    if ((_keys[index] === null) || (_keys[index] === _DELETED_KEY)) {
      _numberOfEntries++;
    }
    _keys[index] = key;
    _values[index] = value;
  }

  V operator [](K key) {
    int index = _probeForLookup(key);
    if (index < 0) return null;
    return _values[index];
  }

  V putIfAbsent(K key, V ifAbsent()) {
    int index = _probeForLookup(key);
    if (index >= 0) return _values[index];

    V value = ifAbsent();
    this[key] = value;
    return value;
  }

  V remove(K key) {
    int index = _probeForLookup(key);
    if (index >= 0) {
      _numberOfEntries--;
      V value = _values[index];
      _values[index] = null;
      // Set the key to the sentinel to not break the probing chain.
      _keys[index] = _DELETED_KEY;
      _numberOfDeleted++;
      return value;
    }
    return null;
  }

  bool isEmpty() {
    return _numberOfEntries == 0;
  }

  int get length {
    return _numberOfEntries;
  }

  void forEach(void f(K key, V value)) {
    int length = _keys.length;
    for (int i = 0; i < length; i++) {
      var key = _keys[i];
      if ((key !== null) && (key !== _DELETED_KEY)) {
        f(key, _values[i]);
      }
    }
  }


  Collection<K> getKeys() {
    List<K> list = new List<K>(length);
    int i = 0;
    forEach(void _(K key, V value) {
      list[i++] = key;
    });
    return list;
  }

  Collection<V> getValues() {
    List<V> list = new List<V>(length);
    int i = 0;
    forEach(void _(K key, V value) {
      list[i++] = value;
    });
    return list;
  }

  bool containsKey(K key) {
    return (_probeForLookup(key) != -1);
  }

  bool containsValue(V value) {
    int length = _values.length;
    for (int i = 0; i < length; i++) {
      var key = _keys[i];
      if ((key !== null) && (key !== _DELETED_KEY)) {
        if (_values[i] == value) return true;
      }
    }
    return false;
  }

  String toString() {
    return Maps.mapToString(this);
  }
}

class HashSetImplementation<E > implements HashSet<E> {

  HashSetImplementation() {
    _backingMap = new HashMapImplementation<E, E>();
  }

  factory HashSetImplementation.from(Iterable<E> other) {
    Set<E> set = new HashSetImplementation<E>();
    for (final e in other) {
      set.add(e);
    }
    return set;
  }

  void clear() {
    _backingMap.clear();
  }

  void add(E value) {
    _backingMap[value] = value;
  }

  bool contains(E value) {
    return _backingMap.containsKey(value);
  }

  bool remove(E value) {
    if (!_backingMap.containsKey(value)) return false;
    _backingMap.remove(value);
    return true;
  }

  void addAll(Collection<E> collection) {
    collection.forEach(void _(E value) {
      add(value);
    });
  }

  Set<E> intersection(Collection<E> collection) {
    Set<E> result = new Set<E>();
    collection.forEach(void _(E value) {
      if (contains(value)) result.add(value);
    });
    return result;
  }

  bool isSubsetOf(Collection<E> other) {
    return new Set<E>.from(other).containsAll(this);
  }

  void removeAll(Collection<E> collection) {
    collection.forEach(void _(E value) {
      remove(value);
    });
  }

  bool containsAll(Collection<E> collection) {
    return collection.every(bool _(E value) {
      return contains(value);
    });
  }

  void forEach(void f(E element)) {
    _backingMap.forEach(void _(E key, E value) {
      f(key);
    });
  }

  Set map(f(E element)) {
    Set result = new Set();
    _backingMap.forEach(void _(E key, E value) {
      result.add(f(key));
    });
    return result;
  }

  Dynamic reduce(Dynamic initialValue,
                 Dynamic combine(Dynamic previousValue, E element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  Set<E> filter(bool f(E element)) {
    Set<E> result = new Set<E>();
    _backingMap.forEach(void _(E key, E value) {
      if (f(key)) result.add(key);
    });
    return result;
  }

  bool every(bool f(E element)) {
    Collection<E> keys = _backingMap.getKeys();
    return keys.every(f);
  }

  bool some(bool f(E element)) {
    Collection<E> keys = _backingMap.getKeys();
    return keys.some(f);
  }

  bool isEmpty() {
    return _backingMap.isEmpty();
  }

  int get length {
    return _backingMap.length;
  }

  Iterator<E> iterator() {
    return new HashSetIterator<E>(this);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  // The map backing this set. The associations in this map are all
  // of the form element -> element. If a value is not in the map,
  // then it is not in the set.
  HashMapImplementation<E, E> _backingMap;
}

class HashSetIterator<E> implements Iterator<E> {

  // TODO(4504458): Replace set_ with set.
  HashSetIterator(HashSetImplementation<E> set_)
    : _nextValidIndex = -1,
      _entries = set_._backingMap._keys {
    _advance();
  }

  bool get hasNext {
    if (_nextValidIndex >= _entries.length) return false;
    if (_entries[_nextValidIndex] === HashMapImplementation._DELETED_KEY) {
      // This happens in case the set was modified in the meantime.
      // A modification on the set may make this iterator misbehave,
      // but we should never return the sentinel.
      _advance();
    }
    return _nextValidIndex < _entries.length;
  }

  E next() {
    if (!hasNext) {
      throw const NoMoreElementsException();
    }
    E res = _entries[_nextValidIndex];
    _advance();
    return res;
  }

  void _advance() {
    int length = _entries.length;
    var entry;
    final deletedKey = HashMapImplementation._DELETED_KEY;
    do {
      if (++_nextValidIndex >= length) break;
      entry = _entries[_nextValidIndex];
    } while ((entry === null) || (entry === deletedKey));
  }

  // The entries in the set. May contain null or the sentinel value.
  List<E> _entries;

  // The next valid index in [_entries] or the length of [entries_].
  // If it is the length of [_entries], calling [hasNext] on the
  // iterator will return false.
  int _nextValidIndex;
}

/**
 * A singleton sentinel used to represent when a key is deleted from the map.
 * We can't use [: const Object() :] as a sentinel because it would end up
 * canonicalized and then we cannot distinguish the deleted key from the
 * canonicalized [: Object() :].
 */
class _DeletedKeySentinel {
  const _DeletedKeySentinel();
}
