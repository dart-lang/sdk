// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    for (final k in map.keys) {
      map.remove(k);
    }
  }

  static forEach(Map map, void f(key, value)) {
    for (final k in map.keys) {
      f(k, map[k]);
    }
  }

  static Collection getValues(Map map) {
    final result = [];
    for (final k in map.keys) {
      result.add(map[k]);
    }
    return result;
  }

  static int length(Map map) => map.keys.length;

  static bool isEmpty(Map map) => length(map) == 0;

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
    var result = new StringBuffer();
    _emitMap(m, result, new List());
    return result.toString();
  }

  /**
   * Appends a string representing the specified map to the specified
   * string buffer. The string is formatted as per [mapToString].
   * The [:visiting:] list contains references to all of the enclosing
   * collections and maps (which are currently in the process of being
   * emitted into [:result:]). The [:visiting:] parameter allows this method
   * to generate a [:'[...]':] or [:'{...}':] where required. In other words,
   * it allows this method and [_emitCollection] to identify recursive maps
   * and collections.
   */
  static void _emitMap(Map m, StringBuffer result, List visiting) {
    visiting.add(m);
    result.add('{');

    bool first = true;
    m.forEach((k, v) {
      if (!first) {
        result.add(', ');
      }
      first = false;
      Collections._emitObject(k, result, visiting);
      result.add(': ');
      Collections._emitObject(v, result, visiting);
    });

    result.add('}');
    visiting.removeLast();
  }
}
