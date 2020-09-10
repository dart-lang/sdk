// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum { e1, e2 }

int method1(Enum? e) {
  switch (e) {
    case Enum.e1:
    case Enum.e2:
      return 0;
  }
}

int method2(Enum? e) {
  switch (e) {
    case Enum.e1:
    case Enum.e2:
      return 0;
    case null:
      return 1;
  }
}

int method3(Enum? e) {
  switch (e) {
    case Enum.e1:
    case Enum.e2:
      return 0;
    default:
      return 1;
  }
}

int method4(Enum? e) {
  switch (e) {
    case Enum.e1:
    case Enum.e2:
      return 0;
    case null:
    default:
      return 1;
  }
}

test() {
  method1(Enum.e1);
}

main() {
  expect(0, method2(Enum.e1));
  expect(0, method2(Enum.e2));
  expect(1, method2(null));

  expect(0, method3(Enum.e1));
  expect(0, method3(Enum.e2));
  expect(1, method3(null));

  expect(0, method4(Enum.e1));
  expect(0, method4(Enum.e2));
  expect(1, method4(null));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual.';
  }
}
