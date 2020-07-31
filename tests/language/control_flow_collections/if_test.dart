// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'utils.dart';

final list = [1, 2, 3];
final map = {1: 1, 2: 2, 3: 3};
final set = {1, 2, 3};

void main() {
  testList();
  testMap();
  testSet();
  testShortCircuit();
  testDuplicateKeys();
  testKeyOrder();
}

void testList() {
  // Then if true.
  Expect.listEquals(list, <int>[1, if (true) 2, 3]);

  // Nothing if false and no else.
  Expect.listEquals(list, <int>[1, if (false) 9, 2, 3]);

  // Else if false.
  Expect.listEquals(list, <int>[1, if (false) 9 else 2, 3]);

  // Only if.
  Expect.listEquals([1], <int>[if (true) 1]);

  // If at beginning.
  Expect.listEquals(list, <int>[if (true) 1, 2, 3]);

  // If in middle.
  Expect.listEquals(list, <int>[1, if (true) 2, 3]);

  // If at end.
  Expect.listEquals(list, <int>[1, 2, if (true) 3]);

  // Multiple ifs.
  Expect.listEquals(list,
      <int>[if (true) 1, if (false) 9, 2, if (true) 3]);

  // Cast condition.
  Expect.listEquals(<int>[1], <int>[if (true as dynamic) 1]);

  // Does not flatten nested collection literal.
  Expect.listEquals([1], [if (true) [1]].first);
  Expect.mapEquals({1: 1}, [if (true) {1: 1}].first);
  Expect.setEquals({1}, [if (true) {1}].first);

  // Nested spread.
  Expect.listEquals(list,
      <int>[if (true) ...<int>[1, 2], if (false) 9 else ...<int>[3]]);

  // Nested if in then.
  Expect.listEquals([1], <int>[if (true) if (true) 1, if (true) if (false) 9]);

  // Nested if in else.
  Expect.listEquals([1], <int>[if (false) 9 else if (true) 1]);

  // Nested for in then.
  Expect.listEquals(list, <int>[if (true) for (var i in list) i]);

  // Nested for in else.
  Expect.listEquals(list, <int>[if (false) 9 else for (var i in list) i]);
}

void testMap() {
  // Then if true.
  Expect.mapEquals(map, <int, int>{1: 1, if (true) 2: 2, 3: 3});

  // Nothing if false and no else.
  Expect.mapEquals(map, <int, int>{1: 1, if (false) 9: 9, 2: 2, 3: 3});

  // Else if false.
  Expect.mapEquals(map, <int, int>{1: 1, if (false) 9: 9 else 2: 2, 3: 3});

  // Only if.
  Expect.mapEquals(<int, int>{1: 1}, <int, int>{if (true) 1: 1});

  // If at beginning.
  Expect.mapEquals(map, <int, int>{if (true) 1: 1, 2: 2, 3: 3});

  // If in middle.
  Expect.mapEquals(map, <int, int>{1: 1, if (true) 2: 2, 3: 3});

  // If at end.
  Expect.mapEquals(map, <int, int>{1: 1, 2: 2, if (true) 3: 3});

  // Multiple ifs.
  Expect.mapEquals(map,
      <int, int>{if (true) 1: 1, if (false) 9: 9, 2: 2, if (true) 3: 3});

  // Cast condition.
  Expect.mapEquals(<int, int>{1: 1}, <int, int>{if (true as dynamic) 1: 1});

  // Nested spread.
  Expect.mapEquals(map, <int, int>{
    if (true) ...<int, int>{1: 1, 2: 2},
    if (false) 9: 9 else ...<int, int>{3: 3}
  });

  // Nested if in then.
  Expect.mapEquals({1: 1},
      <int, int>{if (true) if (true) 1: 1, if (true) if (false) 9: 9});

  // Nested if in else.
  Expect.mapEquals({1: 1},
      <int, int>{if (false) 9: 9 else if (true) 1: 1});

  // Nested for in then.
  Expect.mapEquals(map, <int, int>{if (true) for (var i in list) i: i});

  // Nested for in else.
  Expect.mapEquals(map, <int, int>{if (false) 9: 9 else for (var i in list) i: i});
}

void testSet() {
  // Then if true.
  Expect.setEquals(set, <int>{1, if (true) 2, 3});

  // Nothing if false and no else.
  Expect.setEquals(set, <int>{1, if (false) 9, 2, 3});

  // Else if false.
  Expect.setEquals(set, <int>{1, if (false) 9 else 2, 3});

  // Only if.
  Expect.setEquals({1}, <int>{if (true) 1});

  // If at beginning.
  Expect.setEquals(set, <int>{if (true) 1, 2, 3});

  // If in middle.
  Expect.setEquals(set, <int>{1, if (true) 2, 3});

  // If at end.
  Expect.setEquals(set, <int>{1, 2, if (true) 3});

  // Multiple ifs.
  Expect.setEquals(set,
      <int>{if (true) 1, if (false) 9, 2, if (true) 3});

  // Cast condition.
  Expect.setEquals({1}, <int>{if (true as dynamic) 1});

  // Does not flatten nested collection literal.
  Expect.listEquals([1], {if (true) [1]}.first);
  Expect.mapEquals({1: 1}, {if (true) {1: 1}}.first);
  Expect.setEquals({1}, {if (true) {1}}.first);

  // Nested spread.
  Expect.setEquals(set,
      <int>{if (true) ...<int>[1, 2], if (false) 9 else ...<int>[3]});

  // Nested if in then.
  Expect.setEquals({1}, <int>{if (true) if (true) 1, if (true) if (false) 9});

  // Nested if in else.
  Expect.setEquals({1}, <int>{if (false) 9 else if (true) 1});

  // Nested for in then.
  Expect.setEquals(set, <int>{if (true) for (var i in list) i});

  // Nested for in else.
  Expect.setEquals(set, <int>{if (false) 9 else for (var i in list) i});
}

void testShortCircuit() {
  var transcript = <String>[];
  T log<T>(T value) {
    transcript.add(value.toString());
    return value;
  }

  // With no else.
  Expect.listEquals([1], [if (true) log(1), if (false) log(2)]);
  Expect.equals("1", transcript.join(","));
  transcript.clear();

  // With else.
  Expect.listEquals([1, 4],
      [if (true) log(1) else log(2), if (false) log(3) else log(4)]);
  Expect.equals("1,4", transcript.join(","));
}

void testDuplicateKeys() {
  Expect.mapEquals(map, <int, int>{
    1: 1,
    if (true) 1: 1,
    if (false) 9: 9 else 2: 2,
    2: 2,
    3: 3
  });
  Expect.setEquals(set, <int>{1, if (true) 1, if (false) 9 else 2, 2, 3});
}

void testKeyOrder() {
  // First equal key wins.
  var e1a = Equality(1, "a");
  var e1b = Equality(1, "b");
  var e2a = Equality(2, "a");
  var e2b = Equality(2, "b");

  var map = <Equality, int>{
    e1a: 0,
    if (true) e1b: 0,
    if (true) e2a: 0,
    if (true) e2b: 0
  };
  Expect.equals("1:a,2:a", map.keys.join(","));

  var set = <Equality>{
    e1a,
    if (true) e1b,
    if (true) e2a,
    if (true) e2b
  };
  Expect.equals("1:a,2:a", set.join(","));
}
