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
/// The [HashMap] is unordered (the order of iteration is not guaranteed).
///
/// The keys of a `HashMap` must have consistent [Object.==]
/// and [Object.hashCode] implementations. This means that the `==` operator
/// must define a stable equivalence relation on the keys (reflexive,
/// symmetric, transitive, and consistent over time), and that `hashCode`
/// must be the same for objects that are considered equal by `==`.
///
/// Iterating the map's keys, values or entries (through [forEach])
/// may happen in any order. The iteration order only changes when the map is
/// modified. Values are iterated in the same order as their associated keys,
/// so iterating the [keys] and [values] in parallel
/// will give matching key and value pairs.
///
/// **Notice:**
/// It is generally not allowed to modify the map (add or remove keys) while
/// an operation is being performed on the map, for example, in functions called
/// during a [forEach] or [putIfAbsent] call.
/// Modifying the map while iterating the keys or values
/// may also break the iteration.
///
/// Example:
/// ```dart
/// final hashMap = HashMap();
/// // To add data to map, call addAll or addEntries.
/// hashMap.addAll({3: 'Earth', 4: 'Mars'});
/// print(hashMap.runtimeType); // HashMap<dynamic, dynamic>
///
/// final gasGiants = {1: 'Jupiter', 2: 'Saturn'};
/// hashMap.addEntries(gasGiants.entries);
/// print(hashMap); // {1: Jupiter, 2: Saturn, 3: Earth, 4: Mars}
///
/// // To check if the map is empty, use isEmpty or isNotEmpty
/// // To check length of map data, use length
/// final isEmpty = hashMap.isEmpty; // false
/// final length = hashMap.length; // 4
///
/// // The forEach iterates through all entries of a map.
/// hashMap.forEach((key, value) {
///   print('key: $key value: $value');
///   // key: 1 value: Jupiter
///   // key: 2 value: Saturn
///   // key: 3 value: Earth
///   // key: 4 value: Mars
/// });
///
/// // To check is there a defined key, call containsKey
/// final keyOneExists = hashMap.containsKey(1); // true
/// final keyFiveExists = hashMap.containsKey(5); // false
///
/// // To check is there a value item on map, call containsValue
/// final marsExists = hashMap.containsValue('Mars'); // true
/// final venusExists = hashMap.containsValue('Venus'); // false
///
/// // To remove specific key-pair using key, call remove
/// final removeValue = hashMap.remove(1);
/// print(removeValue); // Jupiter
/// print(hashMap); // {2: Saturn, 3: Earth, 4: Mars}
///
/// // To remove item(s) with a statement, call the removeWhere
/// hashMap.removeWhere((key, value) => key == 2);
/// print(hashMap); // {3: Earth, 4: Mars}
///
/// // Update known key values
/// hashMap.update(4, (v) => 'Sun');
/// print(hashMap); // {3: Earth, 4: Sun}
/// // Key 8 missing from hashmap, adds Neptune via ifAbsent
/// hashMap.update(8, (v) => '', ifAbsent: () => 'Neptune');
/// print(hashMap); // {8: Neptune, 3: Earth, 4: Sun}
///
/// // To update all items, call updateAll
/// hashMap.updateAll((key, value) => null);
/// print(hashMap); // {8: null, 3: null, 4: null}
///
/// // To clean up data, call the clear
/// hashMap.clear();
/// print(hashMap); // {}
/// ```
///
/// **See also:**
/// * [Map] a base-class for key/value pair collection.
/// * [LinkedHashMap] iterates in key insertion order.
/// * [SplayTreeMap] iterates the keys in sorted order.
abstract class HashMap<K, V> implements Map<K, V> {
  /// Creates an unordered hash-table based [Map].
  ///
  /// The created map is not ordered in any way. When iterating the keys or
  /// values, the iteration order is unspecified except that it will stay the
  /// same as long as the map isn't changed.
  ///
  /// If [equals] is provided, it is used to compare the keys in the map with
  /// new keys. If [equals] is omitted, the key's own [Object.==] is used
  /// instead.
  ///
  /// Similarly, if [hashCode] is provided, it is used to produce a hash value
  /// for keys in order to place them in the map. If [hashCode] is omitted,
  /// the key's own [Object.hashCode] is used.
  ///
  /// The used `equals` and `hashCode` method should always be consistent,
  /// so that if `equals(a, b)`, then `hashCode(a) == hashCode(b)`. The hash
  /// of an object, or what it compares equal to, should not change while the
  /// object is a key in the map. If it does change, the result is
  /// unpredictable.
  ///
  /// If you supply one of [equals] and [hashCode],
  /// you should generally also supply the other.
  ///
  /// Some [equals] or [hashCode] functions might not work for all objects.
  /// If [isValidKey] is supplied, it's used to check a potential key
  /// which is not necessarily an instance of [K], like the arguments to
  /// [operator []], [remove] and [containsKey], which are typed as `Object?`.
  /// If [isValidKey] returns `false`, for an object, the [equals] and
  /// [hashCode] functions are not called, and no key equal to that object
  /// is assumed to be in the map.
  /// The [isValidKey] function defaults to just testing if the object is an
  /// instance of [K].
  ///
  /// Example:
  /// ```dart template:expression
  /// HashMap<int,int>(equals: (int a, int b) => (b - a) % 5 == 0,
  ///                  hashCode: (int e) => e % 5);
  /// ```
  /// This example map does not need an `isValidKey` function to be passed.
  /// The default function accepts precisely `int` values, which can safely be
  /// passed to both the `equals` and `hashCode` functions.
  ///
  /// If neither `equals`, `hashCode`, nor `isValidKey` is provided,
  /// the default `isValidKey` instead accepts all keys.
  /// The default equality and hashcode operations are known to work on all
  /// objects.
  ///
  /// Likewise, if `equals` is [identical], `hashCode` is [identityHashCode]
  /// and `isValidKey` is omitted, the resulting map is identity based,
  /// and the `isValidKey` defaults to accepting all keys.
  /// Such a map can be created directly using [HashMap.identity].
  external factory HashMap(
      {bool Function(K, K)? equals,
      int Function(K)? hashCode,
      bool Function(dynamic)? isValidKey});

  /// Creates an unordered identity-based map.
  ///
  /// Keys of this map are considered equal only to the same object,
  /// and do not use [Object.==] at all.
  ///
  /// Effectively shorthand for:
  /// ```dart
  /// HashMap<K, V>(equals: identical, hashCode: identityHashCode)
  /// ```
  external factory HashMap.identity();

  /// Creates a [HashMap] that contains all key/value pairs of [other].
  ///
  /// The keys must all be instances of [K] and the values of [V].
  /// The [other] map itself can have any type.
  /// ```dart
  /// final baseMap = {1: 'A', 2: 'B', 3: 'C'};
  /// final fromBaseMap = HashMap.from(baseMap);
  /// print(fromBaseMap); // {1: A, 2: B, 3: C}
  /// ```
  factory HashMap.from(Map<dynamic, dynamic> other) {
    HashMap<K, V> result = HashMap<K, V>();
    other.forEach((dynamic k, dynamic v) {
      result[k as K] = v as V;
    });
    return result;
  }

  /// Creates a [HashMap] that contains all key/value pairs of [other].
  /// Example:
  /// ```dart
  /// final baseMap = {1: 'A', 2: 'B', 3: 'C'};
  /// final mapOf = HashMap.of(baseMap);
  /// print(mapOf); // {1: A, 2: B, 3: C}
  /// ```
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
  /// If no values are specified for [key] and [value], the default is the
  /// identity function.
  /// Example:
  /// ```dart
  /// final keyList = [11, 12, 13, 14];
  /// final mapFromIterable =
  ///   HashMap.fromIterable(keyList, key: (i) => i, value: (i) => i * i);
  /// print(mapFromIterable); // {11: 121, 12: 144, 13: 169, 14: 196}
  /// ```
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
  /// Example:
  /// ```dart
  /// final keys = ['Mercury', 'Venus', 'Earth', 'Mars'];
  /// final values = [0.06, 0.81, 1, 0.11];
  /// final mapFromIterables = HashMap.fromIterables(keys, values);
  /// print(mapFromIterables);
  /// // {Earth: 1, Mercury: 0.06, Mars: 0.11, Venus: 0.81}
  /// ```
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
  ///
  /// Example:
  /// ```dart
  /// final data = {'Earth': 1, 'Mercury': 0.06, 'Mars': 0.11 };
  /// final mapFromEntries = HashMap.fromEntries(data.entries);
  /// print(mapFromEntries); // {Mercury: 0.06, Earth: 1, Mars: 0.11}
  /// ```
  @Since("2.1")
  factory HashMap.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      HashMap<K, V>()..addEntries(entries);
}
