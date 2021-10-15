// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// Default function for equality comparison in customized HashMaps.
bool _defaultEquals(Object? a, Object? b) => a == b;

/// Default function for hash-code computation in customized HashMaps.
int _defaultHashCode(Object? a) => a.hashCode;

/// Type of custom equality function.
typedef _Equality<K> = bool Function(K a, K b);

/// Type of custom hash code function.
typedef _Hasher<K> = int Function(K object);

/// A hash-table based implementation of [Map].
///
/// The keys of a `HashMap` must have consistent [Object.==]
/// and [Object.hashCode] implementations. This means that the `==` operator
/// must define a stable equivalence relation on the keys (reflexive,
/// symmetric, transitive, and consistent over time), and that `hashCode`
/// must be the same for objects that are considered equal by `==`.
///
/// Iterating the map's keys, values or entries (through [forEach])
/// may happen in any order.
/// The iteration order only changes when the map is modified.
/// Values are iterated in the same order as their associated keys,
/// so iterating the [keys] and [values] in parallel
/// will give matching key and value pairs.
///
/// Example:
/// ```dart
/// final HashMap<int, String> hashMap = HashMap();
/// hashMap.addAll({10: 'A', 20: 'B', 30: 'C', 1: 'aa', 2: 'bb'});
/// print(hashMap.isEmpty); // false
/// print(hashMap.length); // 5
/// print(hashMap); // {1: aa, 2: bb, 10: A, 20: B, 30: C}
/// // Iterating items using [forEach]:
/// hashMap.forEach((key, value) {
///   print('key: $key ' ' value: $value');
/// });
/// // Check if key defined on map
/// print(hashMap.containsKey(1)); // true
/// print(hashMap.containsKey(3)); // false
/// // Check if value defined on map
/// print(hashMap.containsValue('b')); // false
/// print(hashMap.containsValue('bb')); // true
/// // Remove one item using key value
/// hashMap.remove(1); // { 2: bb, 10: A, 20: B, 30: C}
/// // Remove all items with provided statement
/// hashMap.removeWhere((key, value) => key == 2); // {10: A, 20: B, 30: C}
/// hashMap.removeWhere((key, value) => value == 'B'); // {10: A, 30: C}
/// // Update existing key value on map
/// final retVal1 = hashMap.update(10, (v) => 'ABC', ifAbsent: () => 'D');
/// print(hashMap); // {10: ABC, 30: C}
/// // Update / insert value to map if key not exists
/// final retVal2 = hashMap.update(4, (v) => 'abc', ifAbsent: () => 'D');
/// print(hashMap); // {10: ABC, 4: D, 30: C}
/// // Update all items
/// hashMap.updateAll((int key, String value) => 'E');
/// print(hashMap); // {10: E, 4: E, 30: E}
/// // Remove all items
/// hashMap.clear(); // {}
/// ```
///
/// [HashMap.from] example:
/// ```dart
/// final Map baseMap = {1: 'A', 2: 'B', 3: 'C'};
/// final HashMap<int, String> fromBaseMap = HashMap.from(baseMap);
/// ```
///
/// [HashMap.fromEntries] example:
/// ```dart
/// final Map baseMap = {3: 'A', 2: 'B', 1: 'C'};
/// final HashMap mapFromEntries = HashMap.fromEntries(baseMap.entries);
/// ```
///
/// [HashMap.fromIterable] example:
/// ```dart
/// final List<int> keyList = [11, 12, 13, 14];
/// final HashMap mapFromIterable =
///   HashMap.fromIterable(keyList, key: (i) => i, value: (i) => i * i);
/// ```
///
/// [HashMap.fromIterables] example:
/// ```dart
/// final List<String> keys = ['1', '2', '3', '4'];
/// final List<String> values = ['A', 'B', 'C', 'D'];
/// final HashMap mapFromIterables = HashMap.fromIterables(keys, values);
/// ```
///
/// [HashMap.of] example:
/// ```dart
/// final Map mapIntString = {3: 'A', 2: 'B', 1: 'C', 4: 'D'};
/// final HashMap mapOf = HashMap.of(mapIntString);
/// ```
abstract class HashMap<K, V> implements Map<K, V> {
  /// Creates an unordered hash-table based [Map].
  ///
  /// The created map is not ordered in any way. When iterating the keys or
  /// values, the iteration order is unspecified except that it will stay the
  /// same as long as the map isn't changed.
  ///
  /// If [equals] is provided, it is used to compare the keys in the table with
  /// new keys. If [equals] is omitted, the key's own [Object.==] is used
  /// instead.
  ///
  /// Similar, if [hashCode] is provided, it is used to produce a hash value
  /// for keys in order to place them in the hash table. If it is omitted, the
  /// key's own [Object.hashCode] is used.
  ///
  /// If using methods like [operator []], [remove] and [containsKey] together
  /// with a custom equality and hashcode, an extra `isValidKey` function
  /// can be supplied. This function is called before calling [equals] or
  /// [hashCode] with an argument that may not be a [K] instance, and if the
  /// call returns false, the key is assumed to not be in the set.
  /// The [isValidKey] function defaults to just testing if the object is a
  /// [K] instance.
  ///
  /// Example:
  /// ```dart
  /// HashMap<int,int>(equals: (int a, int b) => (b - a) % 5 == 0,
  ///                  hashCode: (int e) => e % 5)
  /// ```
  /// This example map does not need an `isValidKey` function to be passed.
  /// The default function accepts only `int` values, which can safely be
  /// passed to both the `equals` and `hashCode` functions.
  ///
  /// If neither `equals`, `hashCode`, nor `isValidKey` is provided,
  /// the default `isValidKey` instead accepts all keys.
  /// The default equality and hashcode operations are assumed to work on all
  /// objects.
  ///
  /// Likewise, if `equals` is [identical], `hashCode` is [identityHashCode]
  /// and `isValidKey` is omitted, the resulting map is identity based,
  /// and the `isValidKey` defaults to accepting all keys.
  /// Such a map can be created directly using [HashMap.identity].
  ///
  /// The used `equals` and `hashCode` method should always be consistent,
  /// so that if `equals(a, b)` then `hashCode(a) == hashCode(b)`. The hash
  /// of an object, or what it compares equal to, should not change while the
  /// object is a key in the map. If it does change, the result is
  /// unpredictable.
  ///
  /// If you supply one of [equals] and [hashCode],
  /// you should generally also to supply the other.
  external factory HashMap(
      {bool Function(K, K)? equals,
      int Function(K)? hashCode,
      bool Function(dynamic)? isValidKey});

  /// Creates an unordered identity-based map.
  ///
  /// Effectively a shorthand for:
  /// ```dart
  /// HashMap<K, V>(equals: identical,
  ///               hashCode: identityHashCode)
  /// ```
  external factory HashMap.identity();

  /// Creates a [HashMap] that contains all key/value pairs of [other].
  ///
  /// The keys must all be instances of [K] and the values of [V].
  /// The [other] map itself can have any type.
  factory HashMap.from(Map<dynamic, dynamic> other) {
    HashMap<K, V> result = HashMap<K, V>();
    other.forEach((dynamic k, dynamic v) {
      result[k as K] = v as V;
    });
    return result;
  }

  /// Creates a [HashMap] that contains all key/value pairs of [other].
  factory HashMap.of(Map<K, V> other) => HashMap<K, V>()..addAll(other);

  /// Creates a [HashMap] where the keys and values are computed from the
  /// [iterable].
  ///
  /// For each element of the [iterable] this constructor computes a key/value
  /// pair, by applying [key] and [value] respectively.
  ///
  /// The keys of the key/value pairs do not need to be unique. The last
  /// occurrence of a key will simply overwrite any previous value.
  ///
  /// If no values are specified for [key] and [value] the default is the
  /// identity function.
  factory HashMap.fromIterable(Iterable iterable,
      {K Function(dynamic element)? key, V Function(dynamic element)? value}) {
    HashMap<K, V> map = HashMap<K, V>();
    MapBase._fillMapWithMappedIterable(map, iterable, key, value);
    return map;
  }

  /// Creates a [HashMap] associating the given [keys] to [values].
  ///
  /// This constructor iterates over [keys] and [values] and maps each element
  /// of [keys] to the corresponding element of [values].
  ///
  /// If [keys] contains the same object multiple times, the last occurrence
  /// overwrites the previous value.
  ///
  /// It is an error if the two [Iterable]s don't have the same length.
  factory HashMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    HashMap<K, V> map = HashMap<K, V>();
    MapBase._fillMapWithIterables(map, keys, values);
    return map;
  }

  /// Creates a [HashMap] containing the entries of [entries].
  ///
  /// Returns a new `HashMap<K, V>` where all entries of [entries]
  /// have been added in iteration order.
  ///
  /// If multiple [entries] have the same key,
  /// later occurrences overwrite the earlier ones.
  @Since("2.1")
  factory HashMap.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      HashMap<K, V>()..addEntries(entries);
}
