// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int value = 0;

class C0 {
  int a = value++;
  int b = value++;
  int c = value++;
}

class C1() {
  int a = value++;
  int b = value++;
  int c = value++;
}

main() {
  var c0 = C0();
  expect(0, c0.a);
  expect(1, c0.b);
  expect(2, c0.c);

  var c1 = C1();
  expect(3, c1.a);
  expect(4, c1.b);
  expect(5, c1.c);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}
