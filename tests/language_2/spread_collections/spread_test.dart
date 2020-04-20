// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'helper_classes.dart';

// Typed as dynamic to also test spreading a value of type dynamic.
final dynamic list = [1, 2, 3, 4];
final dynamic map = {1: 1, 2: 2, 3: 3, 4: 4};
final dynamic set = {1, 2, 3, 4};

void main() {
  testList();
  testMap();
  testSet();
  testDuplicateKeys();
  testKeyOrder();
}

void testList() {
  // Only spread.
  Expect.listEquals(list, <int>[...list]);

  // Spread at beginning.
  Expect.listEquals(list, <int>[...<int>[1, 2], 3, 4]);

  // Spread in middle.
  Expect.listEquals(list, <int>[1, ...<int>[2, 3], 4]);

  // Spread at end.
  Expect.listEquals(list, <int>[1, 2, ...<int>[3, 4]]);

  // Empty spreads.
  Expect.listEquals(list,
      <int>[...<int>[], 1, 2, ...<int>[], 3, 4, ...<int>[]]);

  // Multiple spreads.
  Expect.listEquals(list, <int>[...<int>[1], 2, ...<int>[3, 4]]);

  // Nested spreads.
  Expect.listEquals(list, <int>[...<int>[...<int>[1, 2], ...<int>[3, 4]]]);

  // Null-aware.
  Expect.listEquals(list, <int>[1, ...?<int>[2, 3], ...?(null), ...?<int>[4]]);

  // Does not deep flatten.
  var innerList = <int>[3];
  Expect.listEquals(
      <Object>[1, 2, innerList, 4],
      <Object>[1, ...<Object>[2, innerList, 4]]);

  // Downcast element.
  Expect.listEquals(list, <int>[...<num>[1, 2, 3, 4]]);
}

void testMap() {
  // Only spread.
  Expect.mapEquals(map, <int, int>{...map});

  // Spread at beginning.
  Expect.mapEquals(map, <int, int>{...<int, int>{1: 1, 2: 2}, 3: 3, 4: 4});

  // Spread in middle.
  Expect.mapEquals(map, <int, int>{1: 1, ...<int, int>{2: 2, 3: 3}, 4: 4});

  // Spread at end.
  Expect.mapEquals(map, <int, int>{1: 1, 2: 2, ...<int, int>{3: 3, 4: 4}});

  // Empty spreads.
  Expect.mapEquals(map, <int, int>{
    ...<int, int>{},
    1: 1,
    2: 2,
    ...<int, int>{},
    3: 3,
    4: 4,
    ...<int, int>{}
  });

  // Multiple spreads.
  Expect.mapEquals(map,
      <int, int>{...<int, int>{1: 1}, 2: 2, ...<int, int>{3: 3, 4: 4}});

  // Nested spreads.
  Expect.mapEquals(map, <int, int>{
    ...<int, int>{
      ...<int, int>{1: 1, 2: 2},
      ...<int, int>{3: 3, 4: 4}
    }
  });

  // Null-aware.
  Expect.mapEquals(map, <int, int>{
    1: 1,
    ...?<int, int>{2: 2, 3: 3},
    ...?(null),
    ...?<int, int>{4: 4}
  });

  // Does not deep flatten.
  var innerMap = <int, int>{3: 3};
  Expect.mapEquals(<int, Object>{
    1: 1,
    2: 2,
    3: innerMap,
    4: 4
  }, <int, Object>{
    1: 1,
    ...<int, Object>{
      2: 2,
      3: innerMap,
      4: 4
    }
  });

  // Downcast element.
  Expect.mapEquals(map, <int, int>{...<num, num>{1: 1, 2: 2, 3: 3, 4: 4}});
}

void testSet() {
  // Only spread.
  Expect.setEquals(set, <int>{...set});

  // Spread at beginning.
  Expect.setEquals(set, <int>{...<int>[1, 2], 3, 4});

  // Spread in middle.
  Expect.setEquals(set, <int>{1, ...<int>[2, 3], 4});

  // Spread at end.
  Expect.setEquals(set, <int>{1, 2, ...<int>[3, 4]});

  // Empty spreads.
  Expect.setEquals(set, <int>{...<int>[], 1, 2, ...<int>[], 3, 4, ...<int>[]});

  // Multiple spreads.
  Expect.setEquals(set, <int>{...<int>[1], 2, ...<int>[3, 4]});

  // Nested spreads.
  Expect.setEquals(set, <int>{...<int>{...<int>[1, 2], ...<int>[3, 4]}});

  // Null-aware.
  Expect.setEquals(set, <int>{1, ...?<int>[2, 3], ...?(null), ...?<int>[4]});

  // Does not deep flatten.
  var innerSet = <int>{3};
  Expect.setEquals(<Object>{1, 2, innerSet, 4},
      <Object>{1, ...<Object>[2, innerSet, 4]});

  // Downcast element.
  Expect.setEquals(set, <int>{...<num>[1, 2, 3, 4]});
}

void testDuplicateKeys() {
  Expect.mapEquals(map, <int, int>{
    1: 1,
    2: 2,
    ...<int, int>{2: 2, 3: 3, 4: 4},
    ...<int, int>{3: 3},
    4: 4
  });
  Expect.setEquals(set, <int>{1, 2, ...<int>[1, 2, 3, 4], ...<int>[2, 3], 4});
}

void testKeyOrder() {
  // First equal key wins.
  var e1a = Equality(1, "a");
  var e1b = Equality(1, "b");
  var e2a = Equality(2, "a");
  var e2b = Equality(2, "b");

  var map = <Equality, int>{e1a: 1, ...<Equality, int>{e1b: 2, e2a: 3, e2b: 4}};
  Expect.equals("1:a,2:a", map.keys.join(","));

  var set = <Equality>{e1a, ...<Equality>[e1b, e2a, e2b]};
  Expect.equals("1:a,2:a", set.join(","));

  // All elements are evaluated, left to right.
  var transcript = <String>[];
  T log<T>(T value) {
    transcript.add(value.toString());
    return value;
  }

  map = <Equality, int>{
    log(e1a): log(1),
    ...<Equality, int>{log(e1b): log(2), log(e2a): log(3), log(e2b): log(4)}
  };
  Expect.equals("1:a,1,1:b,2,2:a,3,2:b,4", transcript.join(","));

  transcript.clear();
  set = <Equality>{log(e1a), ...<Equality>[log(e1b), log(e2a), log(e2b)]};
  Expect.equals("1:a,1:b,2:a,2:b", transcript.join(","));
}
