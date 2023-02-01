// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int test(o) {
  switch (o) {
    case [var a]:
      return a;
    case 0:
      continue CASE2;
    CASE1:
    case 1:
      return 1;
    CASE2:
    case 2:
      return 2;
    case 3:
      continue DEFAULT;
    case 4:
      return 4;
    DEFAULT:
    default:
      return -1;
  }
}

main() {
  expect(0, test([0]));
  expect(1, test([1]));
  expect(2, test(0));
  expect(1, test(1));
  expect(2, test(2));
  expect(-1, test(3));
  expect(4, test(4));
  expect(-1, test(5));
  expect(-1, test([]));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}