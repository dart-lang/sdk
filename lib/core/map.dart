// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A [Map] is an associative container, mapping a key to a value.
 * Null values are supported, but null keys are not.
 */
interface Map<K, V> default HashMapImplementation<K, V> {
  /**
   * Creates a map with the default implementation.
   */
  Map();

  /**
   * Creates a [Map] that contains all key value pairs of [other].
   */
  Map.from(Map<K, V> other);


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
  Collection<K> getKeys();

  /**
   * Returns a collection containing all the values in the map.
   */
  Collection<V> getValues();

  /**
   * The number of {key, value} pairs in the map.
   */
  int get length;

  /**
   * Returns true if there is no {key, value} pair in the map.
   */
  bool isEmpty();
}

/**
 * Hash map version of the [Map] interface. A [HashMap] does not
 * provide any guarantees on the order of keys and values in [getKeys]
 * and [getValues].
 */
interface HashMap<K, V> extends Map<K, V>
    default HashMapImplementation<K, V> {
  /**
   * Creates a map with the default implementation.
   */
  HashMap();

  /**
   * Creates a [HashMap] that contains all key value pairs of [other].
   */
  HashMap.from(Map<K, V> other);
}

/**
 * Hash map version of the [Map] interface that preserves insertion
 * order.
 */
interface LinkedHashMap<K, V> extends HashMap<K, V>
    default LinkedHashMapImplementation<K, V> {
  /**
   * Creates a map with the default implementation.
   */
  LinkedHashMap();

  /**
   * Creates a [LinkedHashMap] that contains all key value pairs of [other].
   */
  LinkedHashMap.from(Map<K, V> other);
}
