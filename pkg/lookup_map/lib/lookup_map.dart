// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines [LookupMap], a simple map that can be optimized by dart2js.
library lookup_map;

/// [LookupMap] is a simple, but very restricted map.  The map can only hold
/// constant keys and the only way to use the map is to retrieve values with a
/// key you already have.  Except for lookup, any other operation in [Map] (like
/// forEach, keys, values, length, etc) is not available.
///
/// Constant [LookupMap]s are understood by dart2js and can be tree-shaken
/// internally: if a key is not used elsewhere in the program, its entry can be
/// deleted from the map during compilation without changing the program's
/// behavior. Currently dart2js supports tree-shaking keys that are `Type`
/// literals, and any const expression that can only be created with a const
/// constructor. This means that primitives, Strings, and constant objects that
/// override the `==` operator cannot be tree-shaken.
///
/// Note: [LookupMap] is unlikely going to be useful for individual developers
/// writing code by hand. It is mainly intended as a helper utility for
/// frameworks that need to autogenerate data and associate it with a type in
/// the program. For example, this can be used by a dependency injection system
/// to record how to create instances of a given type. A dependency injection
/// framework can store in a [LookupMap] all the information it needs for every
/// injectable type in every library and package.  When compiling a specific
/// application, dart2js can tree-shake the data of types that are not used by
/// the application. Similarly, this can also be used by
/// serialization/deserialization packages that can store in a [LookupMap] the
/// deserialization logic for a given type.
class LookupMap<K, V> {
  /// The key for [LookupMap]s with a single key/value pair.
  final K _key;

  /// The value for [LookupMap]s with a single key/value pair.
  final V _value;

  /// List of alternating key-value pairs in the map.
  final List _entries;

  /// Other maps to which this map delegates lookup operations if the key is not
  /// found on [entries]. See [LookupMap]'s constructor for details.
  final List<LookupMap<K, V>> _nestedMaps;

  /// Creates a lookup-map given a list of key-value pair [entries], and
  /// optionally additional entries from other [LookupMap]s.
  ///
  /// When doing a lookup, if the key is not found on [entries]. The lookup will
  /// be performed in reverse order of the list of [nestedMaps], so a later
  /// entry for a key shadows previous entries.  For example, in:
  ///
  ///     const map = const LookupMap(const [A, 1],
  ///         const [const LookupMap(const [A, 2, B, 4]),
  ///                const LookupMap(const [A, 3, B, 5]));
  ///
  /// `map[A]` returns `1` and `map[B]` returns `5`.
  ///
  /// Note: in the future we expect to change [entries] to be a const map
  /// instead of a list of key-value pairs.
  // TODO(sigmund): make entries a map once we fix TypeImpl.== (issue #17207).
  const LookupMap(List entries, [List<LookupMap<K, V>> nestedMaps = const []])
    : _key = null, _value = null, _entries = entries, _nestedMaps = nestedMaps;

  /// Creates a lookup map with a single key-value pair.
  const LookupMap.pair(K key, V value)
    : _key = key, _value = value, _entries = const [], _nestedMaps = const [];

  /// Return the data corresponding to [key].
  V operator[](K key) {
    var map = _flatMap[this];
    if (map == null) {
      map = {};
      _addEntriesTo(map);
      _flatMap[this] = map;
    }
    return map[key];
  }

  /// Add to [map] entries from [nestedMaps] and from [entries] according to the
  /// precedense order described in [nestedMaps].
  _addEntriesTo(Map map) {
    _nestedMaps.forEach((m) => m._addEntriesTo(map));
    for (var i = 0; i < _entries.length; i += 2) {
      map[_entries[i]] = _entries[i + 1];
    }
    if (_key != null) map[_key] = _value;
  }
}

/// An expando that stores a flatten version of a [LookupMap], this is
/// computed and stored the first time the map is accessed.
final _flatMap = new Expando('_flat_map');

/// Internal constant that matches the version in the pubspec. This is used by
/// dart2js to ensure that optimizations are only enabled on known versions of
/// this code.
// Note: this needs to be kept in sync with the pubspec, otherwise
// test/version_check_test would fail.
final _version = '0.0.1+1';
