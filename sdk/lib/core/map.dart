// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core.dart";

/**
 * An collection of key-value pairs, from which you retrieve a value
 * using its associated key.
 *
 * There is a finite number of keys in the map,
 * and each key has exactly one value associated with it.
 *
 * Maps, and their keys and values, can be iterated.
 * The order of iteration is defined by the individual type of map.
 * Examples:
 *
 * * The plain [HashMap] is unordered (no order is guaranteed),
 * * the [LinkedHashMap] iterates in key insertion order,
 * * and a sorted map like [SplayTreeMap] iterates the keys in sorted order.
 *
 * It is generally not allowed to modify the map (add or remove keys) while
 * an operation is being performed on the map, for example in functions called
 * during a [forEach] or [putIfAbsent] call.
 * Modifying the map while iterating the keys or values
 * may also break the iteration.
 */
abstract class Map<K, V> {
  /**
   * Creates a Map instance with the default implementation, [LinkedHashMap].
   *
   * This constructor is equivalent to the non-const map literal `<K,V>{}`.
   *
   * A `LinkedHashMap` requires the keys to implement compatible
   * `operator==` and `hashCode`, and it allows null as a key.
   * It iterates in key insertion order.
   */
  external factory Map();

  /**
   * Creates a [LinkedHashMap] instance that contains all key-value pairs of
   * [other].
   *
   * The keys must all be assignable to [K] and the values to [V].
   * The [other] map itself can have any type.
   *
   * A `LinkedHashMap` requires the keys to implement compatible
   * `operator==` and `hashCode`, and it allows `null` as a key.
   * It iterates in key insertion order.
   */
  factory Map.from(Map other) = LinkedHashMap<K, V>.from;

  /**
   * Creates an unmodifiable hash based map containing the entries of [other].
   *
   * The keys must all be assignable to [K] and the values to [V].
   * The [other] map itself can have any type.
   *
   * The map requires the keys to implement compatible
   * `operator==` and `hashCode`, and it allows `null` as a key.
   * The created map iterates keys in a fixed order,
   * preserving the order provided by [other].
   *
   * The resulting map behaves like the result of [Map.from],
   * except that the map returned by this constructor is not modifiable.
   */
  external factory Map.unmodifiable(Map other);

  /**
   * Creates an identity map with the default implementation, [LinkedHashMap].
   *
   * The returned map allows `null` as a key.
   * It iterates in key insertion order.
   */
  factory Map.identity() = LinkedHashMap<K, V>.identity;

  /**
   * Creates a Map instance in which the keys and values are computed from the
   * [iterable].
   *
   * The created map is a [LinkedHashMap].
   * A `LinkedHashMap` requires the keys to implement compatible
   * `operator==` and `hashCode`, and it allows null as a key.
   * It iterates in key insertion order.
   *
   * For each element of the [iterable] this constructor computes a key-value
   * pair, by applying [key] and [value] respectively.
   *
   * The example below creates a new Map from a List. The keys of `map` are
   * `list` values converted to strings, and the values of the `map` are the
   * squares of the `list` values:
   *
   *     List<int> list = [1, 2, 3];
   *     Map<String, int> map = new Map.fromIterable(list,
   *         key: (item) => item.toString(),
   *         value: (item) => item * item));
   *
   *     map['1'] + map['2']; // 1 + 4
   *     map['3'] - map['2']; // 9 - 4
   *
   * If no values are specified for [key] and [value] the default is the
   * identity function.
   *
   * In the following example, the keys and corresponding values of `map`
   * are `list` values:
   *
   *     map = new Map.fromIterable(list);
   *     map[1] + map[2]; // 1 + 2
   *     map[3] - map[2]; // 3 - 2
   *
   * The keys computed by the source [iterable] do not need to be unique. The
   * last occurrence of a key will simply overwrite any previous value.
   */
  factory Map.fromIterable(Iterable iterable,
      {K key(element), V value(element)}) = LinkedHashMap<K, V>.fromIterable;

  /**
   * Creates a Map instance associating the given [keys] to [values].
   *
   * The created map is a [LinkedHashMap].
   * A `LinkedHashMap` requires the keys to implement compatible
   * `operator==` and `hashCode`, and it allows null as a key.
   * It iterates in key insertion order.
   *
   * This constructor iterates over [keys] and [values] and maps each element of
   * [keys] to the corresponding element of [values].
   *
   *     List<String> letters = ['b', 'c'];
   *     List<String> words = ['bad', 'cat'];
   *     Map<String, String> map = new Map.fromIterables(letters, words);
   *     map['b'] + map['c'];  // badcat
   *
   * If [keys] contains the same object multiple times, the last occurrence
   * overwrites the previous value.
   *
   * The two [Iterable]s must have the same length.
   */
  factory Map.fromIterables(Iterable<K> keys, Iterable<V> values) =
      LinkedHashMap<K, V>.fromIterables;

  /**
   * Returns true if this map contains the given [value].
   *
   * Returns true if any of the values in the map are equal to `value`
   * according to the `==` operator.
   */
  bool containsValue(Object value);

  /**
   * Returns true if this map contains the given [key].
   *
   * Returns true if any of the keys in the map are equal to `key`
   * according to the equality used by the map.
   */
  bool containsKey(Object key);

  /**
   * Returns the value for the given [key] or null if [key] is not in the map.
   *
   * Some maps allows keys to have `null` as a value,
   * For those maps, a lookup using this operator does cannot be used to
   * distinguish between a key not being in the map, and the key having a null
   * value.
   * Methods like [containsKey] or [putIfAbsent] can be use if the distinction
   * is important.
   */
  V operator [](Object key);

  /**
   * Associates the [key] with the given [value].
   *
   * If the key was already in the map, its associated value is changed.
   * Otherwise the key-value pair is added to the map.
   */
  void operator []=(K key, V value);

  /**
   * Look up the value of [key], or add a new value if it isn't there.
   *
   * Returns the value associated to [key], if there is one.
   * Otherwise calls [ifAbsent] to get a new value, associates [key] to
   * that value, and then returns the new value.
   *
   *     Map<String, int> scores = {'Bob': 36};
   *     for (var key in ['Bob', 'Rohan', 'Sophena']) {
   *       scores.putIfAbsent(key, () => key.length);
   *     }
   *     scores['Bob'];      // 36
   *     scores['Rohan'];    //  5
   *     scores['Sophena'];  //  7
   *
   * Calling [ifAbsent] must not add or remove keys from the map.
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
   * Removes [key] and its associated value, if present, from the map.
   *
   * Returns the value associated with `key` before it was removed.
   * Returns `null` if `key` was not in the map.
   *
   * Note that values can be `null` and a returned `null` value doesn't
   * always mean that the key was absent.
   */
  V remove(Object key);

  /**
   * Removes all pairs from the map.
   *
   * After this, the map is empty.
   */
  void clear();

  /**
   * Applies [f] to each key-value pair of the map.
   *
   * Calling `f` must not add or remove keys from the map.
   */
  void forEach(void f(K key, V value));

  /**
   * The keys of [this].
   *
   * The returned iterable has efficient `length` and `contains` operations,
   * based on [length] and [containsKey] of the map.
   *
   * The order of iteration is defined by the individual `Map` implementation,
   * but must be consistent between changes to the map.
   *
   * Modifying the map while iterating the keys
   * may break the iteration.
   */
  Iterable<K> get keys;

  /**
   * The values of [this].
   *
   * The values are iterated in the order of their corresponding keys.
   * This means that iterating [keys] and [values] in parallel will
   * provided matching pairs of keys and values.
   *
   * The returned iterable has an efficient `length` method based on the
   * [length] of the map. Its [Iterable.contains] method is based on
   * `==` comparison.
   *
   * Modifying the map while iterating the
   * values may break the iteration.
   */
  Iterable<V> get values;

  /**
   * The number of key-value pairs in the map.
   */
  int get length;

  /**
   * Returns true if there is no key-value pair in the map.
   */
  bool get isEmpty;

  /**
   * Returns true if there is at least one key-value pair in the map.
   */
  bool get isNotEmpty;
}
