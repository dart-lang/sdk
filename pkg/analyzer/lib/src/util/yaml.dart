// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:yaml/src/event.dart';
import 'package:yaml/yaml.dart';

/// Given a [map], return the value associated with the key whose value matches
/// the given [key], or `null` if there is no matching key.
YamlNode getValue(YamlMap map, String key) {
  for (var k in map.nodes.keys) {
    if (k is YamlScalar && k.value == key) {
      return map.nodes[k];
    }
  }
  return null;
}

/// If all of the elements of [list] are strings, return a list of strings
/// containing the same elements. Otherwise, return `null`.
List<String> toStringList(List list) {
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

bool _contains(YamlList l1, YamlNode n2) {
  for (YamlNode n1 in l1.nodes) {
    if (n1.value == n2.value) {
      return true;
    }
  }
  return false;
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
  YamlNode merge(YamlNode o1, YamlNode o2) {
    // Handle promotion first.
    YamlMap listToMap(YamlList list) {
      Map<YamlNode, YamlNode> map = new HashMap<YamlNode,
          YamlNode>(); // equals: _equals, hashCode: _hashCode
      ScalarEvent event = new ScalarEvent(null, 'true', ScalarStyle.PLAIN);
      for (var element in list.nodes) {
        map[element] = new YamlScalar.internal(true, event);
      }
      return new YamlMap.internal(map, null, CollectionStyle.BLOCK);
    }

    if (isListOfString(o1) && isMapToBools(o2)) {
      o1 = listToMap(o1 as YamlList);
    } else if (isMapToBools(o1) && isListOfString(o2)) {
      o2 = listToMap(o2 as YamlList);
    }

    if (o1 is YamlMap && o2 is YamlMap) {
      return mergeMap(o1, o2);
    }
    if (o1 is YamlList && o2 is YamlList) {
      return mergeList(o1, o2);
    }
    // Default to override, unless the overriding value is `null`.
    return o2 ?? o1;
  }

  /// Merge lists, avoiding duplicates.
  YamlList mergeList(YamlList l1, YamlList l2) {
    List<YamlNode> list = <YamlNode>[];
    list.addAll(l1.nodes);
    for (YamlNode n2 in l2.nodes) {
      if (!_contains(l1, n2)) {
        list.add(n2);
      }
    }
    return new YamlList.internal(list, null, CollectionStyle.BLOCK);
  }

  /// Merge maps (recursively).
  YamlMap mergeMap(YamlMap m1, YamlMap m2) {
    Map<YamlNode, YamlNode> merged = new HashMap<YamlNode,
        YamlNode>(); // equals: _equals, hashCode: _hashCode
    m1.nodes.forEach((k, v) {
      merged[k] = v;
    });
    m2.nodes.forEach((k, v) {
      YamlScalar mergedKey = merged.keys
          .firstWhere((key) => key.value == k.value, orElse: () => k);
      merged[mergedKey] = merge(merged[mergedKey], v);
    });
    return new YamlMap.internal(merged, null, CollectionStyle.BLOCK);
  }

  static bool isListOfString(Object o) =>
      o is YamlList &&
      o.nodes.every((e) => e is YamlScalar && e.value is String);

  static bool isMapToBools(Object o) =>
      o is YamlMap &&
      o.nodes.values.every((v) => v is YamlScalar && v.value is bool);
}
