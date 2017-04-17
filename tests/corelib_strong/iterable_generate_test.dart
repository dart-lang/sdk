// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  bool checkedMode = false;
  assert((checkedMode = true));
  void test(expectedList, generatedIterable) {
    Expect.equals(expectedList.length, generatedIterable.length);
    Expect.listEquals(expectedList, generatedIterable.toList());
  }

  test([], new Iterable.generate(0));
  test([0], new Iterable.generate(1));
  test([0, 1, 2, 3, 4], new Iterable.generate(5));
  test(["0", "1", "2", "3", "4"], new Iterable.generate(5, (x) => "$x"));
  test([2, 3, 4, 5, 6], new Iterable.generate(7).skip(2));
  test([0, 1, 2, 3, 4], new Iterable.generate(7).take(5));
  test([], new Iterable.generate(5).skip(6));
  test([], new Iterable.generate(5).take(0));
  test([], new Iterable.generate(5).take(3).skip(3));
  test([], new Iterable.generate(5).skip(6).take(0));

  // Test types.

  Iterable<int> it = new Iterable<int>.generate(5);
  Expect.isTrue(it is Iterable<int>);
  Expect.isTrue(it.iterator is Iterator<int>);
  Expect.isTrue(it is! Iterable<String>);
  Expect.isTrue(it.iterator is! Iterator<String>);
  test([0, 1, 2, 3, 4], it);

  Iterable<String> st = new Iterable<String>.generate(5, (x) => "$x");
  Expect.isTrue(st is Iterable<String>);
  Expect.isTrue(st.iterator is Iterator<String>);
  Expect.isFalse(st is Iterable<int>);
  Expect.isFalse(st.iterator is Iterator<int>);
  test(["0", "1", "2", "3", "4"], st);

  if (checkedMode) {
    Expect.throws(() => new Iterable<String>.generate(5));
  }
}
