// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

class A {
  int field = 42;
  int method() => field;
  int get getter => field;
  void set setter(int value) {
    field = value;
  }
}

class B extends A {}

extension type E(B it) implements B {}

extension type F(B it) implements E {}

main() {
  B b = B();
  E e = E(b);
  F f = F(b);

  expect(42, b.field);
  expect(42, e.field);
  expect(42, f.field);

  b.field = 87;
  expect(87, b.method());
  expect(87, e.method());
  expect(87, f.method());

  b.setter = 123;
  expect(123, b.getter);
  expect(123, e.getter);
  expect(123, f.getter);

  e.setter = 87;
  expect(87, b.field);
  expect(87, e.field);
  expect(87, f.field);

  e.field = 42;
  expect(42, b.getter);
  expect(42, e.getter);
  expect(42, f.getter);

  f.field = 87;
  expect(87, b.field);
  expect(87, e.field);
  expect(87, f.field);

  f.setter = 123;
  expect(123, b.method());
  expect(123, e.method());
  expect(123, f.method());
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}