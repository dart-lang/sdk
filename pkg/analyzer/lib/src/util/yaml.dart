// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.util.yaml;

import 'dart:collection';

import 'package:yaml/yaml.dart';

/// If all of the elements of [list] are strings, return a list of strings
/// containing the same elements. Otherwise, return `null`.
List<String> toStringList(YamlList list) {
  if (list == null) {
    return null;
  }
  List<String> stringList = <String>[];
  for (var element in list) {
    if (element is String) {
      stringList.add(element);
    } else {
      return null;
    }
  }
  return stringList;
}

/// Merges two maps (of yaml) with simple override semantics, suitable for
/// merging two maps where one map defines default values that are added to
/// (and possibly overridden) by an overriding map.
class Merger {
  /// Merges a default [o1] with an overriding object [o2].
  ///
  ///   * lists are merged (without duplicates).
  ///   * lists of scalar values can be promoted to simple maps when merged with
  ///     maps of strings to booleans (e.g., ['opt1', 'opt2'] becomes
  ///     {'opt1': true, 'opt2': true}.
  ///   * maps are merged recursively.
  ///   * if map values cannot be merged, the overriding value is taken.
  ///
  Object merge(Object o1, Object o2) {
    // Handle promotion first.
    if (o1 is List && isMapToBools(o2)) {
      o1 = new Map.fromIterable(o1, key: (item) => item, value: (item) => true);
    } else if (isMapToBools(o1) && o2 is List) {
      o2 = new Map.fromIterable(o2, key: (item) => item, value: (item) => true);
    }

    if (o1 is Map && o2 is Map) {
      return mergeMap(o1, o2);
    }
    if (o1 is List && o2 is List) {
      return mergeList(o1, o2);
    }
    // Default to override.
    return o2;
  }

  /// Merge lists, avoiding duplicates.
  List mergeList(List l1, List l2) =>
      new List()..addAll(l1)..addAll(l2.where((item) => !l1.contains(item)));

  /// Merge maps (recursively).
  Map mergeMap(Map m1, Map m2) {
    Map merged = new HashMap()..addAll(m1);
    m2.forEach((k, v) {
      merged[k] = merge(merged[k], v);
    });
    return merged;
  }

  static bool isMapToBools(Object o) =>
      o is Map && o.values.every((v) => v is bool);
}
