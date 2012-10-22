// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This class represents a pair of two objects, used by LinkedHashMap
 * to store a {key, value} in a list.
 */
class KeyValuePair<K, V> {
  KeyValuePair(this.key, this.value) {}

  final K key;
  V value;
}

/**
 * A LinkedHashMap is a hash map that preserves the insertion order
 * when iterating over the keys or the values. Updating the value of a
 * key does not change the order.
 */
class LinkedHashMapImplementation<K, V>
    implements LinkedHashMap<K, V> {
  DoubleLinkedQueue<KeyValuePair<K, V>> _list;
  HashMap<K, DoubleLinkedQueueEntry<KeyValuePair<K, V>>> _map;

  LinkedHashMapImplementation() {
    _map = new HashMap<K, DoubleLinkedQueueEntry<KeyValuePair<K, V>>>();
    _list = new DoubleLinkedQueue<KeyValuePair<K, V>>();
  }

  factory LinkedHashMapImplementation.from(Map<K, V> other) {
    Map<K, V> result = new LinkedHashMapImplementation<K, V>();
    other.forEach((K key, V value) { result[key] = value; });
    return result;
  }

  void operator []=(K key, V value) {
    if (_map.containsKey(key)) {
      _map[key].element.value = value;
    } else {
      _list.addLast(new KeyValuePair<K, V>(key, value));
      _map[key] = _list.lastEntry();
    }
  }

  V operator [](K key) {
    DoubleLinkedQueueEntry<KeyValuePair<K, V>> entry = _map[key];
    if (entry == null) return null;
    return entry.element.value;
  }

  V remove(K key) {
    DoubleLinkedQueueEntry<KeyValuePair<K, V>> entry = _map.remove(key);
    if (entry == null) return null;
    entry.remove();
    return entry.element.value;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    V value = this[key];
    if ((this[key] == null) && !(containsKey(key))) {
      value = ifAbsent();
      this[key] = value;
    }
    return value;
  }

  Collection<K> getKeys() {
    List<K> list = new List<K>(length);
    int index = 0;
    _list.forEach(void _(KeyValuePair<K, V> entry) {
      list[index++] = entry.key;
    });
    assert(index == length);
    return list;
  }


  Collection<V> getValues() {
    List<V> list = new List<V>(length);
    int index = 0;
    _list.forEach(void _(KeyValuePair<K, V> entry) {
      list[index++] = entry.value;
    });
    assert(index == length);
    return list;
  }

  void forEach(void f(K key, V value)) {
    _list.forEach(void _(KeyValuePair<K, V> entry) {
      f(entry.key, entry.value);
    });
  }

  bool containsKey(K key) {
    return _map.containsKey(key);
  }

  bool containsValue(V value) {
    return _list.some(bool _(KeyValuePair<K, V> entry) {
      return (entry.value == value);
    });
  }

  int get length {
    return _map.length;
  }

  bool isEmpty() {
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
