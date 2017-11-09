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

Iterable id(Iterable x) => x;

main() {
  // Test functionality.
  for (var iterable in [
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
      [3]  //# 01: ok
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
    var result = iterable.reduce((x, y) { //# 01: ok
      callCount++; //# 01: ok
      return x + y; //# 01: ok
    }); //# 01: ok
    Expect.equals(6, result, "${iterable.runtimeType}"); //# 01: ok
    Expect.equals(2, callCount); //# 01: ok
  }

  // Empty iterables not allowed.
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
    Expect.throwsStateError(
        () => iterable.reduce((x, y) => throw "Unreachable"));
  }

  // Singleton iterables not calling reduce function.
  for (var iterable in [
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
    (new HashMap()..[0] = 1).values,
    (new SplayTreeMap()..[1] = 0).keys,
    (new SplayTreeMap()..[0] = 1).values,
    new HashSet()..add(1),
    new LinkedHashSet()..add(1),
    new SplayTreeSet()..add(1),
    "\x01".codeUnits,
    "\x01".runes,
    new MyList([1]),
  ]) {
    Expect.equals(1, iterable.reduce((x, y) => throw "Unreachable")); //# 01: ok
  }

  // Concurrent modifications not allowed.
  testModification(base, modify, transform) {
    var iterable = transform(base);
    Expect.throws(() {
      iterable.reduce((x, y) {
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

  testModification([1, 2, 3], add4, id);
  testModification(new HashSet()..add(1)..add(2)..add(3), add4, id);
  testModification(new LinkedHashSet()..add(1)..add(2)..add(3), add4, id);
  testModification(new SplayTreeSet()..add(1)..add(2)..add(3), add4, id);
  testModification(new MyList([1, 2, 3]), add4, id);

  testModification([0, 1, 2, 3], add4, (x) => x.where((x) => x > 0));
  testModification([0, 1, 2], add4, (x) => x.map((x) => x + 1));
  testModification([
    [1, 2],
    [3]
  ], add4, (x) => x.expand((x) => x));
  testModification([3, 2, 1], add4, (x) => x.reversed);
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
