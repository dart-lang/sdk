// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A [Map] is an associative container, mapping a key to a value.
 * Null values are supported, but null keys are not.
 */
abstract class Map<K, V> {
  /**
   * Creates a map with the default implementation.
   */
  factory Map() => new _HashMapImpl<K, V>();

  /**
   * Creates a [Map] that contains all key value pairs of [other].
   */
  factory Map.from(Map<K, V> other) => new _HashMapImpl<K, V>.from(other);


  /**
   * Returns whether this map contains the given [value].
   */
  bool containsValue(V value);

  /**
   * Returns whether this map contains the given [key].
   */
  bool containsKey(K key);

  /**
   * Returns the value for the given [key] or null if [key] is not
   * in the map. Because null values are supported, one should either
   * use containsKey to distinguish between an absent key and a null
   * value, or use the [putIfAbsent] method.
   */
  V operator [](K key);

  /**
   * Associates the [key] with the given [value].
   */
  void operator []=(K key, V value);

  /**
   * If [key] is not associated to a value, calls [ifAbsent] and
   * updates the map by mapping [key] to the value returned by
   * [ifAbsent]. Returns the value in the map.
   */
  V putIfAbsent(K key, V ifAbsent());

  /**
   * Removes the association for the given [key]. Returns the value for
   * [key] in the map or null if [key] is not in the map. Note that values
   * can be null and a returned null value does not always imply that the
   * key is absent.
   */
  V remove(K key);

  /**
   * Removes all pairs from the map.
   */
  void clear();

  /**
   * Applies [f] to each {key, value} pair of the map.
   */
  void forEach(void f(K key, V value));

  /**
   * Returns a collection containing all the keys in the map.
   */
  Collection<K> get keys;

  /**
   * Returns a collection containing all the values in the map.
   */
  Collection<V> get values;

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length;

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool get isEmpty;
}

/**
 * Hash map version of the [Map] interface. A [HashMap] does not
 * provide any guarantees on the order of keys and values in [keys]
 * and [values].
 */
abstract class HashMap<K, V> extends Map<K, V> {
  /**
   * Creates a map with the default implementation.
   */
  factory HashMap() => new _HashMapImpl<K, V>();

  /**
   * Creates a [HashMap] that contains all key value pairs of [other].
   */
  factory HashMap.from(Map<K, V> other) => new _HashMapImpl<K, V>.from(other);
}

/**
 * Hash map version of the [Map] interface that preserves insertion
 * order.
 */
abstract class LinkedHashMap<K, V> extends HashMap<K, V> {
  /**
   * Creates a map with the default implementation.
   */
  factory LinkedHashMap() => new _LinkedHashMapImpl<K, V>();

  /**
   * Creates a [LinkedHashMap] that contains all key value pairs of [other].
   */
  factory LinkedHashMap.from(Map<K, V> other)
    => new _LinkedHashMapImpl<K, V>.from(other);
}


// Hash map implementation with open addressing and quadratic probing.
class _HashMapImpl<K, V> implements HashMap<K, V> {

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

  _HashMapImpl() {
    _numberOfEntries = 0;
    _numberOfDeleted = 0;
    _loadLimit = _computeLoadLimit(_INITIAL_CAPACITY);
    _keys = new List(_INITIAL_CAPACITY);
    _values = new List<V>(_INITIAL_CAPACITY);
  }

  factory _HashMapImpl.from(Map<K, V> other) {
    Map<K, V> result = new _HashMapImpl<K, V>();
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

  bool get isEmpty {
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


  Collection<K> get keys {
    List<K> list = new List<K>(length);
    int i = 0;
    forEach(void _(K key, V value) {
      list[i++] = key;
    });
    return list;
  }

  Collection<V> get values {
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


/**
 * A singleton sentinel used to represent when a key is deleted from the map.
 * We can't use [: const Object() :] as a sentinel because it would end up
 * canonicalized and then we cannot distinguish the deleted key from the
 * canonicalized [: Object() :].
 */
class _DeletedKeySentinel {
  const _DeletedKeySentinel();
}


/**
 * This class represents a pair of two objects, used by LinkedHashMap
 * to store a {key, value} in a list.
 */
class _KeyValuePair<K, V> {
  _KeyValuePair(this.key, this.value) {}

  final K key;
  V value;
}

/**
 * A LinkedHashMap is a hash map that preserves the insertion order
 * when iterating over the keys or the values. Updating the value of a
 * key does not change the order.
 */
class _LinkedHashMapImpl<K, V> implements LinkedHashMap<K, V> {
  DoubleLinkedQueue<_KeyValuePair<K, V>> _list;
  HashMap<K, DoubleLinkedQueueEntry<_KeyValuePair<K, V>>> _map;

  _LinkedHashMapImpl() {
    _map = new HashMap<K, DoubleLinkedQueueEntry<_KeyValuePair<K, V>>>();
    _list = new DoubleLinkedQueue<_KeyValuePair<K, V>>();
  }

  factory _LinkedHashMapImpl.from(Map<K, V> other) {
    Map<K, V> result = new _LinkedHashMapImpl<K, V>();
    other.forEach((K key, V value) { result[key] = value; });
    return result;
  }

  void operator []=(K key, V value) {
    if (_map.containsKey(key)) {
      _map[key].element.value = value;
    } else {
      _list.addLast(new _KeyValuePair<K, V>(key, value));
      _map[key] = _list.lastEntry();
    }
  }

  V operator [](K key) {
    DoubleLinkedQueueEntry<_KeyValuePair<K, V>> entry = _map[key];
    if (entry === null) return null;
    return entry.element.value;
  }

  V remove(K key) {
    DoubleLinkedQueueEntry<_KeyValuePair<K, V>> entry = _map.remove(key);
    if (entry === null) return null;
    entry.remove();
    return entry.element.value;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    V value = this[key];
    if ((this[key] === null) && !(containsKey(key))) {
      value = ifAbsent();
      this[key] = value;
    }
    return value;
  }

  Collection<K> get keys {
    List<K> list = new List<K>(length);
    int index = 0;
    _list.forEach(void _(_KeyValuePair<K, V> entry) {
      list[index++] = entry.key;
    });
    assert(index == length);
    return list;
  }


  Collection<V> get values {
    List<V> list = new List<V>(length);
    int index = 0;
    _list.forEach(void _(_KeyValuePair<K, V> entry) {
      list[index++] = entry.value;
    });
    assert(index == length);
    return list;
  }

  void forEach(void f(K key, V value)) {
    _list.forEach(void _(_KeyValuePair<K, V> entry) {
      f(entry.key, entry.value);
    });
  }

  bool containsKey(K key) {
    return _map.containsKey(key);
  }

  bool containsValue(V value) {
    return _list.some(bool _(_KeyValuePair<K, V> entry) {
      return (entry.value == value);
    });
  }

  int get length {
    return _map.length;
  }

  bool get isEmpty {
    return length == 0;
  }

  void clear() {
    _map.clear();
    _list.clear();
  }

  String toString() {
    return Maps.mapToString(this);
  }
}
