// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * A hash-table based implementation of [Map].
 *
 * The keys of a `HashMap` must have consistent [Object.operator==]
 * and [Object.hashCode] implementations. This means that the `==` operator
 * must define a stable equivalence relation on the keys (reflexive,
 * anti-symmetric, transitive, and consistent over time), and that `hashCode`
 * must be the same for objects that are considered equal by `==`.
 *
 * The map allows `null` as a key.
 */
class HashMap<K, V> implements Map<K, V> {
  external HashMap();

  static _id(x) => x;

  factory HashMap.from(Map<K, V> other) {
    return new HashMap<K, V>()..addAll(other);
  }

  factory HashMap.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) {
    HashMap<K, V> map = new HashMap<K, V>();

    if (key == null) key = _id;
    if (value == null) value = _id;

    for (var element in iterable) {
      map[key(element)] = value(element);
    }

    return map;
  }

  factory HashMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    HashMap<K, V> map = new HashMap<K, V>();

    Iterator<K> keyIterator = keys.iterator;
    Iterator<V> valueIterator = values.iterator;

    bool hasNextKey = keyIterator.moveNext();
    bool hasNextValue = valueIterator.moveNext();

    while (hasNextKey && hasNextValue) {
      map[keyIterator.current] = valueIterator.current;
      hasNextKey = keyIterator.moveNext();
      hasNextValue = valueIterator.moveNext();
    }

    if (hasNextKey || hasNextValue) {
      throw new ArgumentError("Iterables do not have same length.");
    }

    return map;
  }

  external int get length;
  external bool get isEmpty;
  external bool get isNotEmpty;

  external Iterable<K> get keys;
  external Iterable<V> get values;

  external bool containsKey(Object key);
  external bool containsValue(Object value);

  external void addAll(Map<K, V> other);

  external V operator [](Object key);
  external void operator []=(K key, V value);

  external V putIfAbsent(K key, V ifAbsent());

  external V remove(Object key);
  external void clear();

  external void forEach(void action(K key, V value));

  String toString() => Maps.mapToString(this);
}
