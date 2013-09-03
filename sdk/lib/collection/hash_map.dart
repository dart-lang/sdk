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

  /**
   * Creates a [HashMap] that contains all key value pairs of [other].
   */
  factory HashMap.from(Map<K, V> other) {
    return new HashMap<K, V>()..addAll(other);
  }

  /**
   * Creates a [HashMap] where the keys and values are computed from the
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
  factory HashMap.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) {
    HashMap<K, V> map = new HashMap<K, V>();
    Maps._fillMapWithMappedIterable(map, iterable, key, value);
    return map;
  }

  /**
   * Creates a [HashMap] associating the given [keys] to [values].
   *
   * This constructor iterates over [keys] and [values] and maps each element of
   * [keys] to the corresponding element of [values].
   *
   * If [keys] contains the same object multiple times, the last occurrence
   * overwrites the previous value.
   *
   * It is an error if the two [Iterable]s don't have the same length.
   */
  factory HashMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    HashMap<K, V> map = new HashMap<K, V>();
    Maps._fillMapWithIterables(map, keys, values);
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
