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
  static String mapToString(Map m) => ToString.mapToString(m);
}
