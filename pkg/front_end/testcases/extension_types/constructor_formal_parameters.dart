// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type I._(int it) {
  I(int x, [int? y]) : it = x + (y ?? 42);

  void m(String s, [int i = 1]) {}
}

extension type I2._(int it) {
  I2(int x, {int? y}) : it = x + (y ?? 87);

  void m(String s, {int i = 1}) {}
}

main() {
  expect(42, I(0));
  expect(0, I(0, 0));
  expect(87, I2(0));
  expect(0, I2(0, y: 0));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}
