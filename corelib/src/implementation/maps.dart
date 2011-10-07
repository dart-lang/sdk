// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
 * Helper class which implements complex [Map] operations
 * in term of basic ones ([Map.getKeys], [Map.operator []],
 * [Map.operator []=] and [Map.remove].)  Not all methods are
 * necessary to implement each particular operation.
 */
class Maps {
  static bool containsValue(Map map, value) {
    for (final v in map.getValues()) {
      if (value == v) {
        return true;
      }
    }
    return false;
  }

  static bool containsKey(Map map, key) {
    for (final k in map.getKeys()) {
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
    for (final k in map.getKeys()) {
      map.remove(k);
    }
  }

  static forEach(Map map, void f(key, value)) {
    for (final k in map.getKeys()) {
      f(k, map[k]);
    }
  }

  static Collection getValues(Map map) {
    final result = [];
    for (final k in map.getKeys()) {
      result.add(map[k]);
    }
    return result;
  }

  static int length(Map map) => map.getKeys().length;

  static bool isEmpty(Map map) => length(map) == 0;
}
