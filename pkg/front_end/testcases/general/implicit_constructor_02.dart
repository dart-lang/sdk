// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9
// Derived from co19/Language/Mixins/Mixin_Application/implicit_constructor_t02

class A {
  bool v1;
  num v2;
  A(bool this.v1, num this.v2);
}

class M1 {
  num v2 = -1;
}

class C = A with M1;

main() {
  C c = new C(true, 2);
  expect(true, c.v1);
  expect(-1, c.v2);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
