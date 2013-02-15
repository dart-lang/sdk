// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A [Map] is an associative container, mapping a key to a value.
 * Null values are supported, but null keys are not.
 */
abstract class Map<K, V> {
  /**
   * Creates a map with the default implementation.
   */
  factory Map() => new HashMap<K, V>();

  /**
   * Creates a [Map] that contains all key value pairs of [other].
   */
  factory Map.from(Map<K, V> other) => new HashMap<K, V>.from(other);


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
   *
   * It is an error to add or remove keys from map during the call to
   * [ifAbsent].
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
   *
   * It is an error to add or remove keys from the map during iteration.
   */
  void forEach(void f(K key, V value));

  /**
   * The keys of [this].
   */
  // TODO(floitsch): this should return a [Set].
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
}
