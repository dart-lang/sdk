// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection" show Queue;
import "dart:typed_data" show Int32List;

import "package:expect/expect.dart";

// Tests behavior of result of an operation on a followedBy iterable.
test(List expects, Iterable iterable, [String name]) {
  try {
    Expect.isFalse(iterable is List, "$name is! List");
    Expect.isFalse(iterable is Set, "$name is! Set");
    Expect.isFalse(iterable is Queue, "$name is! Queue");
    if (expects.isNotEmpty) {
      Expect.equals(expects.first, iterable.first, "$name: first");
      Expect.equals(expects.last, iterable.last, "$name: last");
    } else {
      Expect.throwsStateError(() => iterable.first, "$name: first");
      Expect.throwsStateError(() => iterable.last, "$name: last");
    }
    var it = iterable.iterator;
    for (int index = 0; index < expects.length; index++) {
      Expect.isTrue(it.moveNext(), "$name: has element $index");
      var expect = expects[index];
      Expect.equals(expect, it.current, "$name at $index");
      Expect.equals(
          expect, iterable.elementAt(index), "$name: elementAt($index)");
      Expect.isTrue(iterable.contains(expect), "$name:contains $index");
    }
    Expect.isFalse(it.moveNext(),
        "$name: extra element at ${expects.length}: ${it.current}");
  } on Error {
    print("Failed during: $name");
    rethrow;
  }
}

// Tests various operations on the a followedBy iterable.
tests(List<int> expects, Iterable<int> follow, [String name]) {
  int length = expects.length;
  test(expects, follow, name);
  for (int i = 0; i <= length; i++) {
    test(expects.sublist(i), follow.skip(i), "$name.skip($i)");
  }
  for (int i = 0; i <= length; i++) {
    test(expects.sublist(0, i), follow.take(i), "$name.take($i)");
  }
  for (int i = 0; i <= length; i++) {
    for (int j = 0; j <= length - i; j++) {
      test(expects.sublist(i, i + j), follow.skip(i).take(j),
          "$name.skiptake($i,${i+j})");
      test(expects.sublist(i, i + j), follow.take(i + j).skip(i),
          "$name.takeskip($i,${i+j})");
    }
  }
}

// Tests various different types of iterables as first and second operand.
types(List expects, List<int> first, List<int> second, [String name]) {
  var conversions = <String, Iterable<int> Function(List<int>)>{
    "const": toConst,
    "list": toList,
    "unmod": toUnmodifiable,
    "set": toSet,
    "queue": toQueue,
    "eff-len-iter": toELIter,
    "non-eff-iter": toNEIter,
    "typed": toTyped,
    "keys": toKeys,
    "values": toValues,
  };
  conversions.forEach((n1, c1) {
    conversions.forEach((n2, c2) {
      tests(expects, c1(first).followedBy(c2(second)), "$name:$n1/$n2");
    });
  });
}

List<int> toConst(List<int> elements) => elements;
List<int> toList(List<int> elements) => elements.toList();
List<int> toUnmodifiable(List<int> elements) =>
    new List<int>.unmodifiable(elements);
Set<int> toSet(List<int> elements) => elements.toSet();
Queue<int> toQueue(List<int> elements) => new Queue<int>.from(elements);
// Creates an efficient-length iterable.
Iterable<int> toELIter(List<int> elements) => elements.map<int>((x) => x);
// Creates a non-efficient-length iterable.
Iterable<int> toNEIter(List<int> elements) => elements.where((x) => true);
List<int> toTyped(List<int> elements) => new Int32List.fromList(elements);
Iterable<int> toKeys(List<int> elements) =>
    new Map<int, int>.fromIterables(elements, elements).keys;
Iterable<int> toValues(List<int> elements) =>
    new Map<int, int>.fromIterables(elements, elements).values;

main() {
  types(<int>[], const <int>[], const <int>[], "0+0");
  types(<int>[1, 2, 3, 4], const <int>[], const <int>[1, 2, 3, 4], "0+4");
  types(<int>[1, 2, 3, 4], const <int>[1, 2], const <int>[3, 4], "2+2");
  types(<int>[1, 2, 3, 4], const <int>[1, 2, 3, 4], const <int>[], "4+0");
}
