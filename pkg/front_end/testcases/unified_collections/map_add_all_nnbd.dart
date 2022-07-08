// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void useAddAll() {
  dynamic dynamicMap1 = <int, int>{0: 100, 1: 101, 2: 102};
  dynamic dynamicMap2 = <num, num>{3: 103, 4: 104, 5: 105};
  dynamic dynamicMap3 = <int?, int?>{6: 106, 7: 107, 8: 108};
  Map<int, int> intMap = <int, int>{9: 109, 10: 110, 11: 111};

  var map1 = <int, int>{
    ...dynamicMap1,
    ...dynamicMap2,
    ...dynamicMap3,
    ...intMap,
  };

  expect(
      new Map<int, int>.fromIterables(new List<int>.generate(12, (int i) => i),
          new List<int>.generate(12, (int i) => 100 + i)),
      map1);

  var map2 = <num, num>{
    ...dynamicMap1,
    ...dynamicMap2,
    ...dynamicMap3,
    ...intMap,
  };

  expect(
      new Map<num, num>.fromIterables(new List<num>.generate(12, (int i) => i),
          new List<num>.generate(12, (int i) => 100 + i)),
      map2);

  Map<int, int> map3 = {
    ...dynamicMap1,
    ...dynamicMap2,
    ...dynamicMap3,
    ...intMap,
  };

  expect(
      new Map<int, int>.fromIterables(new List<int>.generate(12, (int i) => i),
          new List<int>.generate(12, (int i) => 100 + i)),
      map3);

  var map4 = {
    ...dynamicMap1,
    ...dynamicMap2,
    ...dynamicMap3,
    ...intMap,
  };

  expect(
      new Map<dynamic, dynamic>.fromIterables(
          new List<int>.generate(12, (int i) => i),
          new List<int>.generate(12, (int i) => 100 + i)),
      map4);

  {
    Map<int, int> intMap1 = {0: 100, 1: 101, 2: 102};
    Map<int, int> intMap2 = {3: 103, 4: 104, 5: 105};
    var map = {...intMap1, ...intMap2};
    expect(
        new Map<int, int>.fromIterables(new List<int>.generate(6, (int i) => i),
            new List<int>.generate(6, (int i) => 100 + i)),
        map);
  }
}

void useAddAllNullable() {
  dynamic dynamicMap1 = <int, int>{0: 100, 1: 101, 2: 102};
  dynamic dynamicMap2 = <num, num>{3: 103, 4: 104, 5: 105};
  dynamic dynamicMap3 = <int?, int?>{6: 106, 7: 107, 8: 108};
  Map<int, int>? intMap = true ? <int, int>{9: 109, 10: 110, 11: 111} : null;

  var map1 = <int, int>{
    ...?dynamicMap1,
    ...?dynamicMap2,
    ...?dynamicMap3,
    ...?intMap,
  };

  expect(
      new Map<int, int>.fromIterables(new List<int>.generate(12, (int i) => i),
          new List<int>.generate(12, (int i) => 100 + i)),
      map1);

  var map2 = <num, num>{
    ...?dynamicMap1,
    ...?dynamicMap2,
    ...?dynamicMap3,
    ...?intMap,
  };

  expect(
      new Map<num, num>.fromIterables(new List<num>.generate(12, (int i) => i),
          new List<num>.generate(12, (int i) => 100 + i)),
      map2);

  Map<int, int> map3 = {
    ...?dynamicMap1,
    ...?dynamicMap2,
    ...?dynamicMap3,
    ...?intMap,
  };

  expect(
      new Map<int, int>.fromIterables(new List<int>.generate(12, (int i) => i),
          new List<int>.generate(12, (int i) => 100 + i)),
      map3);

  var map4 = {
    ...?dynamicMap1,
    ...?dynamicMap2,
    ...?dynamicMap3,
    ...?intMap,
  };

  expect(
      new Map<dynamic, dynamic>.fromIterables(
          new List<int>.generate(12, (int i) => i),
          new List<int>.generate(12, (int i) => 100 + i)),
      map4);
}

main() {
  useAddAll();
  useAddAllNullable();
}

void expect(Map map1, Map map2) {
  if (map1.length != map2.length) {
    throw 'Unexpected length. Expected ${map1.length}, actual ${map2.length}.';
  }
  for (MapEntry entry in map1.entries) {
    if (!map2.containsKey(entry.key)) {
      throw 'Key ${entry.key} not found. Expected $map1, actual $map2.';
    }
    if (map2[entry.key] != entry.value) {
      throw 'Found value ${map2[entry.key]} expected ${entry.value} for key ${entry.key}.';
    }
  }
  if (map1.runtimeType.toString() != map2.runtimeType.toString()) {
    throw "Runtime time difference: "
        "${map1.runtimeType.toString()} vs ${map2.runtimeType.toString()}";
  }
}
