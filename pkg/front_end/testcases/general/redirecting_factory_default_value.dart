// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int field;

  A([this.field = 42]);

  factory A.redirect([int field = 87]) = A;
}

main() {
  expect(42, new A().field);
  expect(123, new A(123).field);
  expect(42, new A.redirect().field);
  expect(123, new A.redirect(123).field);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}