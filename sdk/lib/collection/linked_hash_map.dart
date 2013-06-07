// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/**
 * A hash-table based implementation of [Map].
 *
 * Keys insertion order is remembered, and keys are iterated in insertion order.
 * Values are iterated in their corresponding key's order.
 *
 * The keys of a `HashMap` must have consistent [Object.operator==]
 * and [Object.hashCode] implementations. This means that the `==` operator
 * must define a stable equivalence relation on the keys (reflexive,
 * anti-symmetric, transitive, and consistent over time), and that `hashCode`
 * must be the same for objects that are considered equal by `==`.
 *
 * The map allows `null` as a key.
 */
class LinkedHashMap<K, V> implements Map<K, V> {
  external LinkedHashMap();

  factory LinkedHashMap.from(Map<K, V> other) {
    return new LinkedHashMap<K, V>()..addAll(other);
  }

  external bool containsKey(K key);

  external bool containsValue(V value);

  external void addAll(Map<K, V> other);

  external V operator [](K key);

  external void operator []=(K key, V value);

  external V putIfAbsent(K key, V ifAbsent());

  external V remove(K key);

  external void clear();

  external void forEach(void action (K key, V value));

  /** The keys of the map, in insertion order. */
  external Iterable<K> get keys;
  /** The values of the map, in the order of their corresponding [keys].*/
  external Iterable<V> get values;

  external int get length;

  external bool get isEmpty;

  external bool get isNotEmpty;

  String toString() => Maps.mapToString(this);
}
