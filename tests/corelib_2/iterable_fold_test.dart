// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:collection';
import 'dart:typed_data';

class MyList extends ListBase {
  List list;
  MyList(this.list);

  get length => list.length;
  set length(val) {
    list.length = val;
  }

  operator [](index) => list[index];
  operator []=(index, val) => list[index] = val;
}

id (x) => x;

main() {
  for (dynamic iterable in [
    const [1, 2, 3],
    [1, 2, 3],
    new List(3)
      ..[0] = 1
      ..[1] = 2
      ..[2] = 3,
    {1: 1, 2: 2, 3: 3}.keys,
    {1: 1, 2: 2, 3: 3}.values,
    new Iterable.generate(3, (x) => x + 1),
    new List.generate(3, (x) => x + 1),
    [0, 1, 2, 3].where((x) => x > 0),
    [0, 1, 2].map((x) => x + 1),
    [ //# 01: ok
      [1, 2], //# 01: ok
      [3] //# 01: ok
    ].expand(id), //# 01: ok
    [3, 2, 1].reversed,
    [0, 1, 2, 3].skip(1),
    [1, 2, 3, 4].take(3),
    new Uint8List(3)
      ..[0] = 1
      ..[1] = 2
      ..[2] = 3,
    (new HashMap()
          ..[1] = 1
          ..[2] = 2
          ..[3] = 3)
        .keys,
    (new HashMap()
          ..[1] = 1
          ..[2] = 2
          ..[3] = 3)
        .values,
    (new SplayTreeMap()
          ..[1] = 0
          ..[2] = 0
          ..[3] = 0)
        .keys,
    (new SplayTreeMap()
          ..[0] = 1
          ..[1] = 2
          ..[2] = 3)
        .values,
    new HashSet()..add(1)..add(2)..add(3),
    new LinkedHashSet()..add(1)..add(2)..add(3),
    new SplayTreeSet()..add(1)..add(2)..add(3),
    "\x01\x02\x03".codeUnits,
    "\x01\x02\x03".runes,
    new MyList([1, 2, 3]),
  ]) {
    int callCount = 0;
    var result = iterable.fold(0, (x, y) {
      callCount++;
      return x + y;
    });
    Expect.equals(6, result, "${iterable.runtimeType}");
    Expect.equals(3, callCount);
  }

  // Empty iterables are allowed.
  for (var iterable in [
    const [],
    [],
    new List(0),
    {}.keys,
    {}.values,
    new Iterable.generate(0, (x) => x + 1),
    new List.generate(0, (x) => x + 1),
    [0, 1, 2, 3].where((x) => false),
    [].map((x) => x + 1),
    [[], []].expand(id), //# 01: ok
    [].reversed,
    [0, 1, 2, 3].skip(4),
    [1, 2, 3, 4].take(0),
    new Uint8List(0),
    (new HashMap()).keys,
    (new HashMap()).values,
    (new SplayTreeMap()).keys,
    (new SplayTreeMap()).values,
    new HashSet(),
    new LinkedHashSet(),
    new SplayTreeSet(),
    "".codeUnits,
    "".runes,
    new MyList([]),
  ]) {
    Expect.equals(42, iterable.fold(42, (x, y) => throw "Unreachable"));
  }

  // Singleton iterables are calling reduce function.
  for (dynamic iterable in [
    const [1],
    [1],
    new List(1)..[0] = 1,
    {1: 1}.keys,
    {1: 1}.values,
    new Iterable.generate(1, (x) => x + 1),
    new List.generate(1, (x) => x + 1),
    [0, 1, 2, 3].where((x) => x == 1),
    [0].map((x) => x + 1),
    [ //# 01: ok
      [], //# 01: ok
      [1] //# 01: ok
    ].expand(id), //# 01: ok
    [1].reversed,
    [0, 1].skip(1),
    [1, 2, 3, 4].take(1),
    new Uint8List(1)..[0] = 1,
    (new HashMap()..[1] = 0).keys,
    (new HashMap()..[0] = 1).values, //# 02: ok
    (new SplayTreeMap()..[1] = 0).keys,
    (new SplayTreeMap()..[0] = 1).values, //# 02: ok
    new HashSet()..add(1),
    new LinkedHashSet()..add(1),
    new SplayTreeSet()..add(1),
    "\x01".codeUnits,
    "\x01".runes,
    new MyList([1]),
  ]) {
    Expect.equals(43, iterable.fold(42, (x, y) => x + y));
  }

  // Concurrent modifications not allowed.
  testModification(base, modify, transform) {
    var iterable = transform(base);
    Expect.throws(() {
      iterable.fold(0, (x, y) {
        modify(base);
        return x + y;
      });
    }, (e) => e is ConcurrentModificationError);
  }

  void add4(collection) {
    collection.add(4);
  }

  void put4(map) {
    map[4] = 4;
  }

  testModification([1, 2, 3], add4, id); //# 02: ok
  testModification(new HashSet()..add(1)..add(2)..add(3), add4, id); //# 02: ok
  testModification(new LinkedHashSet()..add(1)..add(2)..add(3), add4, id); //# 02: ok
  testModification(new SplayTreeSet()..add(1)..add(2)..add(3), add4, id); //# 02: ok
  testModification(new MyList([1, 2, 3]), add4, id); //# 02: ok

  testModification([0, 1, 2, 3], add4, (x) => x.where((x) => x > 0)); //# 02: ok
  testModification([0, 1, 2], add4, (x) => x.map((x) => x + 1)); //# 02: ok
  testModification([ //# 02: ok
    [1, 2], //# 02: ok
    [3] //# 02: ok
  ], add4, (x) => x.expand((x) => x)); //# 02: ok
  testModification([3, 2, 1], add4, (x) => x.reversed); //# 02: ok
  testModification({1: 1, 2: 2, 3: 3}, put4, (x) => x.keys);
  testModification({1: 1, 2: 2, 3: 3}, put4, (x) => x.values);
  var hashMap = new HashMap()
    ..[1] = 1
    ..[2] = 2
    ..[3] = 3;
  testModification(hashMap, put4, (x) => x.keys);
  hashMap = new HashMap()
    ..[1] = 1
    ..[2] = 2
    ..[3] = 3;
  testModification(hashMap, put4, (x) => x.values);
  var splayMap = new SplayTreeMap()
    ..[1] = 1
    ..[2] = 2
    ..[3] = 3;
  testModification(splayMap, put4, (x) => x.keys);
  splayMap = new SplayTreeMap()
    ..[1] = 1
    ..[2] = 2
    ..[3] = 3;
  testModification(splayMap, put4, (x) => x.values);
}
