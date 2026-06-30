// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:collection";

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
/// Do not modify a map (add or remove keys) while an operation
/// is being performed on that map, for example in functions
/// called during a [forEach] or [putIfAbsent] call,
/// or while iterating the map ([keys], [values] or [entries]).
/// Changing the value of an existing key, for example using
/// [operator[]=] or [update], does not affect the map's structure
/// and will not break iteration.
///
/// Do not modify keys in any way which changes their equality (and thus their
/// hash code) while they are in the map. If a map key's [Object.hashCode]
/// changes, it may cause future lookups for that key to fail.
///
/// Example:
/// ```dart
/// final Map<int, String> planets = HashMap(); // Is a HashMap
/// ```
/// To add data to a map, use [operator[]=], [addAll] or [addEntries].
/// ```dart continued
/// planets[3] = 'Earth';
/// planets.addAll({4: 'Mars'});
/// final gasGiants = {6: 'Jupiter', 5: 'Saturn'};
/// planets.addEntries(gasGiants.entries);
/// print(planets); // fx {5: Saturn, 6: Jupiter, 3: Earth, 4: Mars}
/// ```
/// To check if the map is empty, use [isEmpty] or [isNotEmpty].
/// To find the number of map entries, use [length].
/// ```dart continued
/// final isEmpty = planets.isEmpty; // false
/// final length = planets.length; // 4
/// ```
/// The [forEach] iterates through all entries of a map.
/// ```dart continued
/// planets.forEach((key, value) {
///   print('$key \t $value');
///   // 5        Saturn
///   // 4        Mars
///   // 3        Earth
///   // 6        Jupiter
/// });
/// ```
/// To check whether the map has an entry with a specific key, use [containsKey].
/// ```dart continued
/// final keyOneExists = planets.containsKey(4); // true
/// final keyFiveExists = planets.containsKey(1); // false
/// ```
/// To check whether the map has an entry with a specific value,
/// use [containsValue].
/// ```dart continued
/// final marsExists = planets.containsValue('Mars'); // true
/// final venusExists = planets.containsValue('Venus'); // false
/// ```
/// To remove an entry with a specific key, use [remove].
/// ```dart continued
/// final removeValue = planets.remove(6);
/// print(removeValue); // Jupiter
/// print(planets); // fx {4: Mars, 3: Earth, 5: Saturn}
/// ```
/// To remove multiple entries at the same time, based on their keys and values,
/// use [removeWhere].
/// ```dart continued
/// planets.removeWhere((key, value) => key == 5);
/// print(planets); // fx {3: Earth, 4: Mars}
/// ```
/// To conditionally add or modify a value for a specific key, depending on
/// whether there already is an entry with that key,
/// use [putIfAbsent] or [update].
/// ```dart continued
/// planets.update(4, (v) => 'Saturn');
/// planets.update(8, (v) => '', ifAbsent: () => 'Neptune');
/// planets.putIfAbsent(4, () => 'Another Saturn');
/// print(planets); // fx {4: Saturn, 8: Neptune, 3: Earth}
/// ```
/// To update the values of all keys, based on the existing key and value,
/// use [updateAll].
/// ```dart continued
/// planets.updateAll((key, value) => 'X');
/// print(planets); // fx {8: X, 3: X, 4: X}
/// ```
/// To remove all entries and empty the map, use [clear].
/// ```dart continued
/// planets.clear();
/// print(planets); // {}
/// print(planets.isEmpty); // true
/// ```
///
/// **See also:**
/// * [Map], the general interface of key/value pair collections.
/// * [LinkedHashMap] iterates in key insertion order.
/// * [SplayTreeMap] iterates the keys in sorted order.
@Deprecated("Use LinkedHashMap instead")
typedef HashMap<K, V> = LinkedHashMap<K, V>;
