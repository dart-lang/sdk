// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// A hash-table based implementation of [Map].
///
/// __The insertion order of keys is remembered__,
/// and keys are iterated in the order they were inserted into the map.
/// Values are iterated in their corresponding key's order.
/// Changing a key's value, when the key is already in the map,
/// does not change the iteration order,
/// but removing the key and adding it again
/// will make it be last in the iteration order.
///
/// **Notice:** Manipulating item count in [forEach] is prohibited. Adding or
/// deleting items during iteration causes an exception:
/// [ConcurrentModificationError].
///
/// The keys of a `LinkedHashMap` must have consistent [Object.==]
/// and [Object.hashCode] implementations. This means that the `==` operator
/// must define a stable equivalence relation on the keys (reflexive,
/// symmetric, transitive, and consistent over time), and that `hashCode`
/// must be the same for objects that are considered equal by `==`.
///
/// Example:
///
/// ```dart
/// final LinkedHashMap<int, String> linkedHashMap =
///   LinkedHashMap<int, String>();
///
/// // To add data to map, call addAll or addEntries
/// linkedHashMap.addAll({1: 'A', 4: 'D', 2: 'B', 3: 'C'});
///
/// // To check is the map empty, use isEmpty or isNotEmpty.
/// // To check length of map data, use length
/// linkedHashMap.isEmpty; // false
/// linkedHashMap.length; // 4
/// print(linkedHashMap); // {1: A, 4: D, 2: B, 3: C}
///
/// // The forEach iterates through all entries of a map.
/// linkedHashMap.forEach((key, value) {
///   print('key: $key value: $value');
///   // key: 1 value: A
///   // key: 4 value: D
///   // key: 2 value: B
///   // key: 3 value: C
/// });
///
/// // To check is there a defined key, call containsKey
/// final keyOneExists = linkedHashMap.containsKey(1); // true
/// final keyFiveExists = linkedHashMap.containsKey(5); // false
///
/// // To check is there a value item on map, call containsValue
/// final bExists = linkedHashMap.containsValue('B'); // true
/// final gExists =  linkedHashMap.containsValue('G'); // false
///
/// // To remove specific key-pair using key, call remove
/// final removedValue = linkedHashMap.remove(1);
/// print(removedValue); // A
/// print(linkedHashMap); // {4: D, 2: B, 3: C}
///
/// // To remove item(s) with a statement, call removeWhere
/// linkedHashMap.removeWhere((key, value) => key == 2);
/// linkedHashMap.removeWhere((key, value) => value == 'C');
/// print(linkedHashMap); // {4: D}
///
/// // To update or insert (adding new key-value pair if not exists) value,
/// // call update with ifAbsent statement or call putIfAbsent:
/// linkedHashMap.update(10, (v) => 'ABC', ifAbsent: () => 'E');
/// print(linkedHashMap); // {4: D, 10: E}
/// linkedHashMap.update(4, (v) => 'abc', ifAbsent: () => 'F');
/// print(linkedHashMap); // {4: abc, 10: E}
///
/// // To update all items, call updateAll
/// linkedHashMap.updateAll((int key, String value) => 'X');
/// print(linkedHashMap); // {4: X, 1: X}
///
/// // To clean up data, call clear
/// linkedHashMap.clear();
/// print(linkedHashMap); // {}
/// ```
abstract class LinkedHashMap<K, V> implements Map<K, V> {
  /// Creates an insertion-ordered hash-table based [Map].
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
  /// ```dart template:expression
  /// LinkedHashMap<int,int>(equals: (int a, int b) => (b - a) % 5 == 0,
  ///                        hashCode: (int e) => e % 5);
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
  /// Such a map can be created directly using [LinkedHashMap.identity].
  ///
  /// The used `equals` and `hashCode` method should always be consistent,
  /// so that if `equals(a, b)` then `hashCode(a) == hashCode(b)`. The hash
  /// of an object, or what it compares equal to, should not change while the
  /// object is in the table. If it does change, the result is unpredictable.
  ///
  /// If you supply one of [equals] and [hashCode],
  /// you should generally also to supply the other.
  external factory LinkedHashMap(
      {bool Function(K, K)? equals,
      int Function(K)? hashCode,
      bool Function(dynamic)? isValidKey});

  /// Creates an insertion-ordered identity-based map.
  ///
  /// Effectively a shorthand for:
  /// ```dart template:expression
  /// LinkedHashMap<K, V>(equals: identical,
  ///                     hashCode: identityHashCode)
  /// ```
  external factory LinkedHashMap.identity();

  /// Creates a [LinkedHashMap] that contains all key value pairs of [other].
  ///
  /// The keys must all be instances of [K] and the values to [V].
  /// The [other] map itself can have any type.
  /// Example:
  /// ```dart
  /// final baseMap = {1: 'A', 2: 'B', 3: 'C'};
  /// final fromBaseMap = LinkedHashMap.from(baseMap);
  /// print(fromBaseMap); // {1: A, 2: B, 3: C}
  /// ```
  factory LinkedHashMap.from(Map<dynamic, dynamic> other) {
    LinkedHashMap<K, V> result = LinkedHashMap<K, V>();
    other.forEach((dynamic k, dynamic v) {
      result[k as K] = v as V;
    });
    return result;
  }

  /// Creates a [LinkedHashMap] that contains all key value pairs of [other].
  /// Example:
  /// ```dart
  /// final dataMap = {3: 'A', 2: 'B', 1: 'C', 4: 'D'};
  /// final mapOf = LinkedHashMap.of(dataMap);
  /// print(mapOf); // {3: A, 2: B, 1: C, 4: D}
  /// ```
  factory LinkedHashMap.of(Map<K, V> other) =>
      LinkedHashMap<K, V>()..addAll(other);

  /// Creates a [LinkedHashMap] where the keys and values are computed from the
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
  /// Example:
  /// ```dart
  /// final keyList = [11, 12, 13, 14];
  /// final mapFromIterable =
  ///   LinkedHashMap.fromIterable(keyList, key: (i) => i, value: (i) => i * i);
  /// print(mapFromIterable); // {11: 121, 12: 144, 13: 169, 14: 196}
  /// ```
  factory LinkedHashMap.fromIterable(Iterable iterable,
      {K Function(dynamic element)? key, V Function(dynamic element)? value}) {
    LinkedHashMap<K, V> map = LinkedHashMap<K, V>();
    MapBase._fillMapWithMappedIterable(map, iterable, key, value);
    return map;
  }

  /// Creates a [LinkedHashMap] associating the given [keys] to [values].
  ///
  /// This constructor iterates over [keys] and [values] and maps each element of
  /// [keys] to the corresponding element of [values].
  ///
  /// If [keys] contains the same object multiple times, the last occurrence
  /// overwrites the previous value.
  ///
  /// It is an error if the two [Iterable]s don't have the same length.
  /// Example:
  /// ```dart
  /// final keys = ['1', '2', '3', '4'];
  /// final values = ['A', 'B', 'C', 'D'];
  /// final mapFromIterables = LinkedHashMap.fromIterables(keys, values);
  /// print(mapFromIterables); // {1: A, 2: B, 3: C, 4: D}
  /// ```
  factory LinkedHashMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    LinkedHashMap<K, V> map = LinkedHashMap<K, V>();
    MapBase._fillMapWithIterables(map, keys, values);
    return map;
  }

  /// Creates a [LinkedHashMap] containing the entries of [entries].
  ///
  /// Returns a new `LinkedHashMap<K, V>` where all entries of [entries]
  /// have been added in iteration order.
  ///
  /// If multiple [entries] have the same key,
  /// later occurrences overwrite the earlier ones.
  /// Example:
  /// ```dart
  /// final dataMap = {3: 'A', 2: 'B', 1: 'C'};
  /// final mapFromEntries = LinkedHashMap.fromEntries(dataMap.entries);
  /// print(mapFromEntries); // {3: A, 2: B, 1: C}
  /// ```
  @Since("2.1")
  factory LinkedHashMap.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      LinkedHashMap<K, V>()..addEntries(entries);
}
