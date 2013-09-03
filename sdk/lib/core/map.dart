// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An unordered collection of key-value pairs,
 * from which you retrieve a value by using its associated key.
 *
 * Each key must be unique.
 * Null values are supported, but null keys are not.
 */
abstract class Map<K, V> {
  /**
   * Creates a Map instance with the default implementation.
   */
  factory Map() = LinkedHashMap<K, V>;

  /**
   * Creates a Map instance that contains all key-value pairs of [other].
   */
  factory Map.from(Map<K, V> other) = LinkedHashMap<K, V>.from;

  /**
   * Creates a Map instance
   * where the keys and values are computed from the [iterable].
   *
   * For each element of the [iterable] this constructor computes a key-value
   * pair, by applying [key] and [value] respectively.
   *
   * The keys computed by the source [iterable]
   * do not need to be unique. The last
   * occurrence of a key will simply overwrite any previous value.
   *
   * If no values are specified for [key] and [value] the default is the
   * identity function.
   */
  factory Map.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) = LinkedHashMap<K, V>.fromIterable;

  /**
   * Creates a Map instance associating the given [keys] to [values].
   *
   * This constructor iterates over [keys] and [values] and maps each element of
   * [keys] to the corresponding element of [values].
   *
   * If [keys] contains the same object multiple times, the last occurrence
   * overwrites the previous value.
   *
   * It is an error if the two [Iterable]s don't have the same length.
   */
  factory Map.fromIterables(Iterable<K> keys, Iterable<V> values)
      = LinkedHashMap<K, V>.fromIterables;

  /**
   * Returns true if this map contains the given value.
   */
  bool containsValue(Object value);

  /**
   * Returns true if this map contains the given key.
   */
  bool containsKey(Object key);

  /**
   * Returns the value for the given [key] or null if [key] is not
   * in the map. Because null values are supported, one should either
   * use [containsKey] to distinguish between an absent key and a null
   * value, or use the [putIfAbsent] method.
   */
  V operator [](Object key);

  /**
   * Associates the [key] with the given [value].
   */
  void operator []=(K key, V value);

  /**
   * If [key] is not associated to a value, calls [ifAbsent] and
   * updates the map by mapping [key] to the value returned by
   * [ifAbsent]. Returns the value in the map.
   *
   * It is an error to add or remove keys from the map during the call to
   * [ifAbsent].
   */
  V putIfAbsent(K key, V ifAbsent());

  /**
   * Adds all key-value pairs of [other] to this map.
   *
   * If a key of [other] is already in this map, its value is overwritten.
   *
   * The operation is equivalent to doing `this[key] = value` for each key
   * and associated value in other. It iterates over [other], which must
   * therefore not change during the iteration.
   */
  void addAll(Map<K, V> other);

  /**
   * Removes the association for the given [key]. Returns the value for
   * [key] in the map or null if [key] is not in the map. Note that values
   * can be null and a returned null value does not always imply that the
   * key is absent.
   */
  V remove(Object key);

  /**
   * Removes all pairs from the map.
   */
  void clear();

  /**
   * Applies [f] to each {key, value} pair of the map.
   *
   * It is an error to add or remove keys from the map during iteration.
   */
  void forEach(void f(K key, V value));

  /**
   * The keys of [this].
   */
  Iterable<K> get keys;

  /**
   * The values of [this].
   */
  Iterable<V> get values;

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length;

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool get isEmpty;

  /**
   * Returns true if there is at least one {key, value} pair in the map.
   */
  bool get isNotEmpty;
}
