// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/*
 * Helper class which implements complex [Map] operations
 * in term of basic ones ([Map.keys], [Map.operator []],
 * [Map.operator []=] and [Map.remove].)  Not all methods are
 * necessary to implement each particular operation.
 */
class Maps {
  static bool containsValue(Map map, value) {
    for (final v in map.values) {
      if (value == v) {
        return true;
      }
    }
    return false;
  }

  static bool containsKey(Map map, key) {
    for (final k in map.keys) {
      if (key == k) {
        return true;
      }
    }
    return false;
  }

  static putIfAbsent(Map map, key, ifAbsent()) {
    if (map.containsKey(key)) {
      return map[key];
    }
    final v = ifAbsent();
    map[key] = v;
    return v;
  }

  static clear(Map map) {
    for (final k in map.keys.toList()) {
      map.remove(k);
    }
  }

  static forEach(Map map, void f(key, value)) {
    for (final k in map.keys) {
      f(k, map[k]);
    }
  }

  static Iterable getValues(Map map) {
    return map.keys.map((key) => map[key]);
  }

  static int length(Map map) => map.keys.length;

  static bool isEmpty(Map map) => map.keys.isEmpty;

  static bool isNotEmpty(Map map) => map.keys.isNotEmpty;

  // A list to identify cyclic maps during toString() calls.
  static List _toStringList = new List();

  /**
   * Returns a string representing the specified map. The returned string
   * looks like this: [:'{key0: value0, key1: value1, ... keyN: valueN}':].
   * The value returned by its [toString] method is used to represent each
   * key or value.
   *
   * If the map collection contains a reference to itself, either
   * directly as a key or value, or indirectly through other collections
   * or maps, the contained reference is rendered as [:'{...}':]. This
   * prevents the infinite regress that would otherwise occur. So, for example,
   * calling this method on a map whose sole entry maps the string key 'me'
   * to a reference to the map would return [:'{me: {...}}':].
   *
   * A typical implementation of a map's [toString] method will
   * simply return the results of this method applied to the collection.
   */
  static String mapToString(Map m) {
    for (int i = 0; i < _toStringList.length; i++) {
      if (identical(_toStringList[i], m)) { return '{...}'; }
    }

    var result = new StringBuffer();
    try {
      _toStringList.add(m);
      result.write('{');
      bool first = true;
      m.forEach((k, v) {
        if(!first) {
          result.write(', ');
        }
        first = false;
        result.write(k);
        result.write(': ');
        result.write(v);
      });
      result.write('}');
    } finally {
      assert(identical(_toStringList.last, m));
      _toStringList.removeLast();
    }

    return result.toString();
  }

  static _id(x) => x;

  /**
   * Fills a map with key/value pairs computed from [iterable].
   *
   * This method is used by Map classes in the named constructor fromIterable.
   */
  static void _fillMapWithMappedIterable(Map map, Iterable iterable,
                                         key(element), value(element)) {
    if (key == null) key = _id;
    if (value == null) value = _id;

    for (var element in iterable) {
      map[key(element)] = value(element);
    }
  }

  /**
   * Fills a map by associating the [keys] to [values].
   *
   * This method is used by Map classes in the named constructor fromIterables.
   */
  static void _fillMapWithIterables(Map map, Iterable keys,
                                    Iterable values) {
    Iterator keyIterator = keys.iterator;
    Iterator valueIterator = values.iterator;

    bool hasNextKey = keyIterator.moveNext();
    bool hasNextValue = valueIterator.moveNext();

    while (hasNextKey && hasNextValue) {
      map[keyIterator.current] = valueIterator.current;
      hasNextKey = keyIterator.moveNext();
      hasNextValue = valueIterator.moveNext();
    }

    if (hasNextKey || hasNextValue) {
      throw new ArgumentError("Iterables do not have same length.");
    }
  }
}
