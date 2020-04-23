// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";
import "package:expect/expect.dart";

void main() {
  test([1, 2, 3, 4], [5, 6], 2, [1, 2, 5, 6]);
  test([1, 2, 3, 4], [5, 6], 0, [5, 6, 3, 4]);
  test([1, 2, 3, 4], [5, 6], 1, [1, 5, 6, 4]);
  test([1, 2, 3, 4], [], 2, [1, 2, 3, 4]);
  test([1, 2, 3, 4], [5, 6], 2, [1, 2, 5, 6]);
  test([1, 2, 3, 4], [5, 6], 2, [1, 2, 5, 6]);
  test([1, 2, 3, 4], [5, 6], 2, [1, 2, 5, 6]);
  test([], [], 0, []);
  test([1], [2], 0, [2]);

  // Other (non-list) iterables.
  test([1, 2, 3, 4], new Iterable.generate(2, (x) => x + 7), 1, [1, 7, 8, 4]);
  test([1, 2, 3, 4], [9, 9, 5, 6].skip(2), 1, [1, 5, 6, 4]);
  test([1, 2, 3, 4], [5, 6, 9, 9].take(2), 1, [1, 5, 6, 4]);
  test([1, 2, 3, 4], [9, 5, 9, 6, 9, 9].where((x) => x != 9), 1, [1, 5, 6, 4]);
  test([1, 2, 3, 4], new Set.from([5, 6]), 1, [1, 5, 6, 4]);

  // Other types of lists.
  test(new Uint8List(4), [5, 6], 1, [0, 5, 6, 0]);
  test(new Uint8List(4), [-5, 6], 1, [0, 256 - 5, 6, 0]);

  // Over-long iterables. Updates until end, then throws.
  testThrows([], [1], 0);
  testThrows([2], [1], 1);
  testThrows([2], [1], 1);
  testThrows([1, 2, 3, 4], [5, 6, 7, 8], 2, [1, 2, 5, 6]);

  // Throwing iterable.
  Expect.throws(() {
    Iterable<int> throwingIterable() sync* {
      yield 1;
      throw "2";
    }

    List.writeIterable([1, 2, 3], 1, throwingIterable());
  }, (e) => e == "2");

  // Bad start index.
  testThrows([1, 2], [1], -1);
  testThrows([1, 2], [1], 2);

  // Working at a supertype is practical and useful.
  test<Object>(<int>[1, 2, 3, 4], <num>[5, 6], 1, [1, 5, 6, 4]);

  var d = new D();
  test<Object?>(<B?>[null], <C>[d], 0, [d]);
}

testThrows<T>(list, iterable, start, [expect]) {
  Expect.throws(() {
    List.writeIterable<T>(list, start, iterable);
  });
  if (expect != null) {
    Expect.listEquals(expect, list);
  }
}

test<T>(List<T> list, Iterable<T> iterable, int start, List expect) {
  List.writeIterable<T>(list, start, iterable);
  Expect.listEquals(expect, list);
}

class B {}

class C {}

class D implements B, C {}
