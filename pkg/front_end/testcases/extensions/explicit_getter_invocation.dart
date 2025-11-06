// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E on int {
  int Function(int) get f =>
      (x) => x;

  m() {
    expect(42, f(42));
  }
}

test(int i1, int? i2, int? i3) {
  expect(87, E(i1).f(87));
  expect(123, E(i2)?.f(123));
  expect(null, E(i3)?.f(321));
}

main() {
  0.m();
  test(0, 0, null);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}
