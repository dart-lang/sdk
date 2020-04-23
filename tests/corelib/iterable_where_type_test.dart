// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection" show Queue;
import "dart:typed_data" show Int32List;

import "package:expect/expect.dart";

// Tests behavior of result of an operation on a followedBy iterable.
test(List expects, Iterable iterable, [String? name]) {
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
    Expect.isFalse(it.moveNext(), "$name: extra element at ${expects.length}");
  } on Error {
    print("Failed during: $name");
    rethrow;
  }
}

main() {
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
  for (var data in [
    const <int>[],
    const <int>[1],
    const <int>[1, 2, 3]
  ]) {
    conversions.forEach((name, c) {
      test(data, c(data).whereType<int>(), "$name#${data.length}.wt<int>");
      test(data, c(data).whereType<num>(), "$name#${data.length}.wt<num>");
      test([], c(data).whereType<Null>(), "$name#${data.length}.wt<Null>");
    });
  }

  test([1, 0.1], ["a", 1, new Object(), 0.1, null].whereType<num>(), "mixed");

  var o = new Object();
  var a = new A();
  var b = new B();
  var c = new C();
  var d = new D();
  var n = null;
  test([o, a, b, c, d, n], [o, a, b, c, d, n].whereType<Object?>(), "Object?");
  test([o, a, b, c, d], [o, a, b, c, d, n].whereType<Object>(), "Object");
  test([a, b, c, d, n], [o, a, b, c, d, n].whereType<A?>(), "A?");
  test([a, b, c, d], [o, a, b, c, d, n].whereType<A>(), "A");
  test([b, d, n], [o, a, b, c, d, n].whereType<B?>(), "B?");
  test([b, d], [o, a, b, c, d, n].whereType<B>(), "B");
  test([c, d, n], [o, a, b, c, d, n].whereType<C?>(), "C?");
  test([c, d], [o, a, b, c, d, n].whereType<C>(), "C");
  test([d, n], [o, a, b, c, d, n].whereType<D?>(), "D?");
  test([d], [o, a, b, c, d, n].whereType<D>(), "D");
  test([n], [o, a, b, c, d, n].whereType<Null>(), "Null");

  test([d], <B>[d].whereType<C>(), "Unrelated");
}

class A {}

class B implements A {}

class C implements A {}

class D implements B, C {}

List<int> toConst(List<int> elements) => elements; // Argument is const.
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
