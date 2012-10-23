// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("deep_equals");

/**
 * Returns whether two objects are structurally equivalent. This considers NaN
 * values to be equivalent. It also handles self-referential structures.
 */
bool deepEquals(obj1, obj2, [List parents1, List parents2]) {
  if (obj1 === obj2) return true;
  if (parents1 == null) {
    parents1 = [];
    parents2 = [];
  }

  // parents1 and parents2 are guaranteed to be the same size.
  for (var i = 0; i < parents1.length; i++) {
    var loop1 = obj1 === parents1[i];
    var loop2 = obj2 === parents2[i];
    // If both structures loop in the same place, they're equal at that point in
    // the structure. If one loops and the other doesn't, they're not equal.
    if (loop1 && loop2) return true;
    if (loop1 || loop2) return false;
  }

  parents1.add(obj1);
  parents2.add(obj2);
  try {
    if (obj1 is List && obj2 is List) {
      return _listEquals(obj1, obj2, parents1, parents2);
    } else if (obj1 is Map && obj2 is Map) {
      return _mapEquals(obj1, obj2, parents1, parents2);
    } else if (obj1 is double && obj2 is double) {
      return _doubleEquals(obj1, obj2);
    } else {
      return obj1 == obj2;
    }
  } finally {
    parents1.removeLast();
    parents2.removeLast();
  }
}

/** Returns whether [list1] and [list2] are structurally equal. */
bool _listEquals(List list1, List list2, List parents1, List parents2) {
  if (list1.length != list2.length) return false;

  for (var i = 0; i < list1.length; i++) {
    if (!deepEquals(list1[i], list2[i], parents1, parents2)) return false;
  }

  return true;
}

/** Returns whether [map1] and [map2] are structurally equal. */
bool _mapEquals(Map map1, Map map2, List parents1, List parents2) {
  if (map1.length != map2.length) return false;

  for (var key in map1.getKeys()) {
    if (!map2.containsKey(key)) return false;
    if (!deepEquals(map1[key], map2[key], parents1, parents2)) return false;
  }

  return true;
}

/**
 * Returns whether two doubles are equivalent. This differs from `d1 == d2` in
 * that it considers NaN to be equal to itself.
 */
bool _doubleEquals(double d1, double d2) {
  if (d1.isNaN && d2.isNaN) return true;
  return d1 == d2;
}
