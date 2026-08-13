// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  switch (x) {
    case [int a] when a > 0:
      return a;
    default:
      return null;
  }
}

test2(dynamic x) {
  switch (x) {
    case [num a, _] when a is int && a.isEven:
    case [_, num a] when a is double && a.ceil().isOdd:
      return a;
    default:
      return null;
  }
}

main() {
  expectEquals(1, test1([1]));
  expectEquals(null, test1([0]));
  expectEquals(null, test1([-1]));

  expectEquals(null, test2([1, "two"]));
  expectEquals(2, test2([2, "three"]));
  expectEquals(null, test2(["one", 1.5]));
  expectEquals(2.5, test2(["two", 2.5]));
  expectEquals(null, test2(null));
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
