// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'utils.dart';

final list = [1, 2, 3, 4];
final map = {1: 1, 2: 2, 3: 3, 4: 4};
final set = {1, 2, 3, 4};

void main() {
  testList();
  testMap();
  testSet();
  testDuplicateKeys();
  testKeyOrder();
}

void testList() {
  // Only for.
  Expect.listEquals(list, <int>[for (var i in list) i]);

  // For at beginning.
  Expect.listEquals(list, <int>[for (var i in <int>[1, 2]) i, 3, 4]);

  // For in middle.
  Expect.listEquals(list, <int>[1, for (var i in <int>[2, 3]) i, 4]);

  // For at end.
  Expect.listEquals(list, <int>[1, 2, for (var i in <int>[3, 4]) i]);

  // Empty for.
  Expect.listEquals(list,
      <int>[1, for (var i in <int>[]) i, 2, 3, for (; false;) 9, 4]);

  // Multiple fors.
  Expect.listEquals(list,
      <int>[for (var i in <int>[1]) i, 2, for (var i = 3; i <= 4; i++) i]);

  // Spread inside for.
  Expect.listEquals(list,
      <int>[for (var i in <int>[0, 2]) ...<int>[1 + i, 2 + i]]);

  // If inside for.
  Expect.listEquals(list,
      <int>[for (var i in <int>[1, 9, 2, 3, 9, 4]) if (i != 9) i]);

  // Else inside for.
  Expect.listEquals(list,
      <int>[for (var i in <int>[1, -2, 3, -4]) if (i < 0) -i else i]);

  // For inside for.
  Expect.listEquals(list,
      <int>[for (var i in <int>[0, 2]) for (var j = 1; j <= 2; j++) i + j]);

  // Does not flatten nested collection literal.
  Expect.listEquals([1], [for (var i = 1; i < 2; i++) [i]].first);
  Expect.mapEquals({1: 1}, [for (var i = 1; i < 2; i++) {i: i}].first);
  Expect.setEquals({1}, [for (var i = 1; i < 2; i++) {i}].first);

  // Downcast condition.
  Expect.listEquals([1], <int>[for (var i = 1; (i < 2) as dynamic; i++) i]);
}

void testMap() {
  // Only for.
  Expect.mapEquals(map, <int, int>{for (var i in list) i: i});

  // For at beginning.
  Expect.mapEquals(map,
      <int, int>{for (var i in <int>[1, 2]) i: i, 3: 3, 4: 4});

  // For in middle.
  Expect.mapEquals(map,
      <int, int>{1: 1, for (var i in <int>[2, 3]) i: i, 4: 4});

  // For at end.
  Expect.mapEquals(map,
      <int, int>{1: 1, 2: 2, for (var i in <int>[3, 4]) i: i});

  // Empty for.
  Expect.mapEquals(map, <int, int>{
    1: 1,
    for (var i in <int>[]) i: i,
    2: 2,
    3: 3,
    for (; false;) 9: 9,
    4: 4
  });

  // Multiple fors.
  Expect.mapEquals(map, <int, int>{
    for (var i in <int>[1]) i: i,
    2: 2,
    for (var i = 3; i <= 4; i++) i: i
  });

  // Spread inside for.
  Expect.mapEquals(map, <int, int>{
    for (var i in <int>[0, 2]) ...<int, int>{1 + i: 1 + i, 2 + i: 2 + i}
  });

  // If inside for.
  Expect.mapEquals(map,
      <int, int>{for (var i in <int>[1, 9, 2, 3, 9, 4]) if (i != 9) i: i});

  // Else inside for.
  Expect.mapEquals(map,
      <int, int>{for (var i in <int>[1, -2, 3, -4]) if (i < 0) -i: -i else i: i});

  // For inside for.
  Expect.mapEquals(map, <int, int>{
    for (var i in <int>[0, 2]) for (var j = 1; j <= 2; j++) i + j: i + j
  });

  // Downcast condition.
  Expect.mapEquals({1 : 1},
      <int, int>{for (var i = 1; (i < 2) as dynamic; i++) i: i});
}

void testSet() {
  // Only for.
  Expect.setEquals(set, <int>{for (var i in list) i});

  // For at beginning.
  Expect.setEquals(set, <int>{for (var i in <int>[1, 2]) i, 3, 4});

  // For in middle.
  Expect.setEquals(set, <int>{1, for (var i in <int>[2, 3]) i, 4});

  // For at end.
  Expect.setEquals(set, <int>{1, 2, for (var i in <int>[3, 4]) i});

  // Empty for.
  Expect.setEquals(set,
      <int>{1, for (var i in <int>[]) i, 2, 3, for (; false;) 9, 4});

  // Multiple fors.
  Expect.setEquals(set,
      <int>{for (var i in <int>[1]) i, 2, for (var i = 3; i <= 4; i++) i});

  // Spread inside for.
  Expect.setEquals(set,
      <int>{for (var i in <int>[0, 2]) ...<int>[1 + i, 2 + i]});

  // If inside for.
  Expect.setEquals(set,
      <int>{for (var i in <int>[1, 9, 2, 3, 9, 4]) if (i != 9) i});

  // Else inside for.
  Expect.setEquals(set,
      <int>{for (var i in <int>[1, -2, 3, -4]) if (i < 0) -i else i});

  // For inside for.
  Expect.setEquals(set,
      <int>{for (var i in <int>[0, 2]) for (var j = 1; j <= 2; j++) i + j});

  // Does not flatten nested collection literal.
  Expect.listEquals([1], {for (var i = 1; i < 2; i++) [i]}.first);
  Expect.mapEquals({1: 1}, {for (var i = 1; i < 2; i++) {i: i}}.first);
  Expect.setEquals({1}, {for (var i = 1; i < 2; i++) {i}}.first);

  // Downcast condition.
  Expect.setEquals({1}, <int>{for (var i = 1; (i < 2) as dynamic; i++) i});
}

void testDuplicateKeys() {
  Expect.mapEquals(map, <int, int>{
    1: 1,
    for (var i in <int>[1, 2, 3]) i: i,
    for (var i = 2; i <= 3; i++) i: i,
    3: 3,
    4: 4
  });
  Expect.setEquals(set, <int>{
    1,
    for (var i in <int>[1, 2, 3]) i,
    for (var i = 2; i <= 3; i++) i,
    3,
    4
  });
}

void testKeyOrder() {
  // First equal key wins.
  var e1a = Equality(1, "a");
  var e1b = Equality(1, "b");
  var e2a = Equality(2, "a");
  var e2b = Equality(2, "b");
  var keys = [e1b, e2a, e2b];
  var values = [2, 3, 4];

  var map = <Equality, int>{
    e1a: 1,
    for (var i = 0; i < keys.length; i++) keys[i]: values[i]
  };
  Expect.equals("1:a,2:a", map.keys.join(","));
  Expect.equals("2,4", map.values.join(","));

  var set = <Equality>{e1a, for (var i = 0; i < keys.length; i++) keys[i]};
  Expect.equals("1:a,2:a", set.join(","));
}
