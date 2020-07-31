// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'utils.dart';

final list = [1, 2, 3, 4];
final map = {1: 1, 2: 2, 3: 3, 4: 4};
final set = {1, 2, 3, 4};

Stream<int> stream(List<int> values) => Stream.fromIterable(values);
Stream<num> numStream(List<num> values) => Stream.fromIterable(values);

void main() {
  asyncTest(() async {
    await testList();
    await testMap();
    await testSet();
    await testDuplicateKeys();
    await testKeyOrder();
    await testRuntimeErrors();
  });
}

Future<void> testList() async {
  // Only await for.
  Expect.listEquals(list, <int>[await for (var i in stream(list)) i]);

  // Await for at beginning.
  Expect.listEquals(list, <int>[await for (var i in stream([1, 2])) i, 3, 4]);

  // Await for in middle.
  Expect.listEquals(list, <int>[1, await for (var i in stream([2, 3])) i, 4]);

  // Await for at end.
  Expect.listEquals(list, <int>[1, 2, await for (var i in stream([3, 4])) i]);

  // Empty await for.
  Expect.listEquals(list,
      <int>[1, 2, await for (var i in stream([])) i, 3, 4]);

  // Multiple await fors.
  Expect.listEquals(list, <int>[
    await for (var i in stream([1])) i,
    2,
    await for (var i in stream([3, 4])) i
  ]);

  // Spread inside await for.
  Expect.listEquals(list,
      <int>[await for (var i in stream([0, 2])) ...<int>[1 + i, 2 + i]]);

  // If inside await for.
  Expect.listEquals(list,
      <int>[await for (var i in stream([1, 9, 2, 3, 9, 4])) if (i != 9) i]);

  // Else inside await for.
  Expect.listEquals(list,
      <int>[await for (var i in stream([1, -2, 3, -4])) if (i < 0) -i else i]);

  // For inside await for.
  Expect.listEquals(list, <int>[
    await for (var i in stream([0, 2])) for (var j = 1; j <= 2; j++) i + j
  ]);

  // Does not flatten nested collection literal.
  Expect.listEquals([1], [await for (var i in stream([1])) [i]].first);
  Expect.mapEquals({1: 1}, [await for (var i in stream([1])) {i: i}].first);
  Expect.setEquals({1}, [await for (var i in stream([1])) {i}].first);
}

Future<void> testMap() async {
  // Only for.
  Expect.mapEquals(map, <int, int>{await for (var i in stream(list)) i: i});

  // Await for at beginning.
  Expect.mapEquals(map,
      <int, int>{await for (var i in stream([1, 2])) i: i, 3: 3, 4: 4});

  // Await for in middle.
  Expect.mapEquals(map,
      <int, int>{1: 1, await for (var i in stream([2, 3])) i: i, 4: 4});

  // Await for at end.
  Expect.mapEquals(map,
      <int, int>{1: 1, 2: 2, await for (var i in stream([3, 4])) i: i});

  // Empty await for.
  Expect.mapEquals(map, <int, int>{
    1: 1,
    await for (var i in stream([])) i: i,
    2: 2,
    3: 3,
    4: 4
  });

  // Multiple await fors.
  Expect.mapEquals(map, <int, int>{
    await for (var i in stream([1])) i: i,
    2: 2,
    await for (var i in stream([3, 4])) i: i
  });

  // Spread inside await for.
  Expect.mapEquals(map, <int, int>{
    await for (var i in stream([0, 2]))
      ...<int, int>{1 + i: 1 + i, 2 + i: 2 + i}
  });

  // If inside await for.
  Expect.mapEquals(map, <int, int>{
    await for (var i in stream([1, 9, 2, 3, 9, 4])) if (i != 9) i: i
  });

  // Else inside await for.
  Expect.mapEquals(map, <int, int>{
    await for (var i in stream([1, -2, 3, -4])) if (i < 0) -i: -i else i: i
  });

  // For inside await for.
  Expect.mapEquals(map, <int, int>{
    await for (var i in stream([0, 2]))
      for (var j = 1; j <= 2; j++) i + j: i + j
  });
}

Future<void> testSet() async {
  // Only await for.
  Expect.setEquals(set, <int>{await for (var i in stream(list)) i});

  // Await for at beginning.
  Expect.setEquals(set, <int>{await for (var i in stream([1, 2])) i, 3, 4});

  // Await for in middle.
  Expect.setEquals(set, <int>{1, await for (var i in stream([2, 3])) i, 4});

  // Await for at end.
  Expect.setEquals(set, <int>{1, 2, await for (var i in stream([3, 4])) i});

  // Empty await for.
  Expect.setEquals(set,
      <int>{1, await for (var i in stream([])) i, 2, 3, 4});

  // Multiple await fors.
  Expect.setEquals(set, <int>{
    await for (var i in stream([1])) i,
    2,
    await for (var i in stream([3, 4])) i
  });

  // Spread inside await for.
  Expect.setEquals(set,
      <int>{await for (var i in stream([0, 2])) ...<int>[1 + i, 2 + i]});

  // If inside await for.
  Expect.setEquals(set,
      <int>{await for (var i in stream([1, 9, 2, 3, 9, 4])) if (i != 9) i});

  // Else inside await for.
  Expect.setEquals(set,
      <int>{await for (var i in stream([1, -2, 3, -4])) if (i < 0) -i else i});

  // For inside await for.
  Expect.setEquals(set, <int>{
    await for (var i in stream([0, 2])) for (var j = 1; j <= 2; j++) i + j
  });

  // Does not flatten nested collection literal.
  Expect.listEquals([1], {await for (var i in stream([1])) [i]}.first);
  Expect.mapEquals({1: 1}, {await for (var i in stream([1])) {i: i}}.first);
  Expect.setEquals({1}, {await for (var i in stream([1])) {i}}.first);
}

Future<void> testDuplicateKeys() async {
  Expect.mapEquals(map, <int, int>{
    1: 1,
    await for (var i in stream([1, 2, 3])) i: i,
    await for (var i in stream([2, 3])) i: i,
    3: 3,
    4: 4
  });
  Expect.setEquals(set, <int>{
    1,
    await for (var i in stream([1, 2, 3])) i,
    await for (var i in stream([2, 3])) i,
    3,
    4
  });
}

Future<void> testKeyOrder() async {
  // First equal key wins.
  var e1a = Equality(1, "a");
  var e1b = Equality(1, "b");
  var e2a = Equality(2, "a");
  var e2b = Equality(2, "b");
  var keys = [e1b, e2a, e2b];
  var values = [2, 3, 4];

  var map = <Equality, int>{
    e1a: 1,
    await for (var i in stream([0, 1, 2])) keys[i]: values[i]
  };
  Expect.equals("1:a,2:a", map.keys.join(","));
  Expect.equals("2,4", map.values.join(","));

  var set = <Equality>{e1a, await for (var i in stream([0, 1, 2])) keys[i]};
  Expect.equals("1:a,2:a", set.join(","));
}

Future<void> testRuntimeErrors() async {
  // Cast variable.
  dynamic nonStream = 3;
  asyncExpectThrows<TypeError>(
      () async => <int>[await for (int i in nonStream) 1]);
  asyncExpectThrows<TypeError>(
      () async => <int, int>{await for (int i in nonStream) 1: 1});
  asyncExpectThrows<TypeError>(
      () async => <int>{await for (int i in nonStream) 1});

  // Wrong element type.
  dynamic nonInt = "string";
  asyncExpectThrows<TypeError>(
      () async => <int>[await for (var i in stream([1])) nonInt]);
  asyncExpectThrows<TypeError>(
      () async => <int, int>{await for (var i in stream([1])) nonInt: 1});
  asyncExpectThrows<TypeError>(
      () async => <int, int>{await for (var i in stream([1])) 1: nonInt});
  asyncExpectThrows<TypeError>(
      () async => <int>{await for (var i in stream([1])) nonInt});
}
