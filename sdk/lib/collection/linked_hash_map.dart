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
 * The keys of a `LinkedHashMap` must have consistent [Object.operator==]
 * and [Object.hashCode] implementations. This means that the `==` operator
 * must define a stable equivalence relation on the keys (reflexive,
 * anti-symmetric, transitive, and consistent over time), and that `hashCode`
 * must be the same for objects that are considered equal by `==`.
 *
 * The map allows `null` as a key.
 */
class LinkedHashMap<K, V> implements HashMap<K, V> {
  external LinkedHashMap();

  /**
   * Creates a [LinkedHashMap] that contains all key value pairs of [other].
   */
  factory LinkedHashMap.from(Map<K, V> other) {
    return new LinkedHashMap<K, V>()..addAll(other);
  }

  /**
   * Creates a [LinkedHashMap] where the keys and values are computed from the
   * [iterable].
   *
   * For each element of the [iterable] this constructor computes a key/value
   * pair, by applying [key] and [value] respectively.
   *
   * The keys of the key/value pairs do not need to be unique. The last
   * occurrence of a key will simply overwrite any previous value.
   *
   * If no values are specified for [key] and [value] the default is the
   * identity function.
   */
  factory LinkedHashMap.fromIterable(Iterable<K> iterable,
      {K key(element), V value(element)}) {
    LinkedHashMap<K, V> map = new LinkedHashMap<K, V>();
    Maps._fillMapWithMappedIterable(map, iterable, key, value);
    return map;
  }

  /**
   * Creates a [LinkedHashMap] associating the given [keys] to [values].
   *
   * This constructor iterates over [keys] and [values] and maps each element of
   * [keys] to the corresponding element of [values].
   *
   * If [keys] contains the same object multiple times, the last occurrence
   * overwrites the previous value.
   *
   * It is an error if the two [Iterable]s don't have the same length.
   */
  factory LinkedHashMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    LinkedHashMap<K, V> map = new LinkedHashMap<K, V>();
    Maps._fillMapWithIterables(map, keys, values);
    return map;
  }

  external bool containsKey(Object key);

  external bool containsValue(Object value);

  external void addAll(Map<K, V> other);

  external V operator [](Object key);

  external void operator []=(K key, V value);

  external V putIfAbsent(K key, V ifAbsent());

  external V remove(Object key);

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
