// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:collection';
import 'dart:convert' show json;

var baseMap = const {"x": 0, "y": 1};

void main() {
  var entry = new MapEntry<int, int>(1, 2);
  Expect.isTrue(entry is MapEntry<int, int>);
  Expect.isTrue(entry is! MapEntry<String, String>);
  Expect.isTrue(entry is! MapEntry<Null, Null>);
  Expect.equals(1, entry.key);
  Expect.equals(2, entry.value);
  Expect.equals("MapEntry(1: 2)", "$entry");
  dynamic dynEntry = entry;
  Expect.throwsNoSuchMethodError(() {
    dynEntry.key = 0;
  }, "key not settable");
  Expect.throwsNoSuchMethodError(() {
    dynEntry.value = 0;
  }, "value not settable");

  checkEntries(baseMap, baseMap);
  checkEntries(baseMap, new Map<String, Object>.unmodifiable(baseMap));
  checkMap({"x": 0, "y": 1});
  checkMap(new Map<String, dynamic>.from(baseMap));
  checkMap(new HashMap<String, dynamic>.from(baseMap));
  checkMap(new LinkedHashMap<String, dynamic>.from(baseMap));
  checkMap(new SplayTreeMap<String, dynamic>.from(baseMap));
  checkMap(json.decode('{"x":0,"y":1}'));
}

void checkMap(Map<String, dynamic> map) {
  checkEntries(baseMap, map);
  map.addEntries([new MapEntry<String, dynamic>("z", 2)]);
  checkEntries({"x": 0, "y": 1, "z": 2}, map);
  map.addEntries(<MapEntry<String, dynamic>>[
    new MapEntry("y", 11),
    new MapEntry("v", 3),
    new MapEntry("w", 4)
  ]);
  checkEntries({"v": 3, "w": 4, "x": 0, "y": 11, "z": 2}, map);

  var valueMap = map.map<int, String>((key, value) => new MapEntry(value, key));
  checkEntries({0: "x", 2: "z", 3: "v", 4: "w", 11: "y"}, valueMap);
}

void checkEntries(Map expected, Map map) {
  int byKey(MapEntry e1, MapEntry e2) => e1.key.compareTo(e2.key);
  Expect.equals(expected.length, map.entries.length);
  var sorted = map.entries.toList()..sort(byKey);
  Expect.equals(expected.length, sorted.length);
  var expectedEntries = expected.entries.toList();
  for (int i = 0; i < sorted.length; i++) {
    Expect.equals(expectedEntries[i].key, sorted[i].key);
    Expect.equals(expectedEntries[i].value, sorted[i].value);
  }
}
