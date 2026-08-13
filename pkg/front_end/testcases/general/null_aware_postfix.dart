// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  B b;

  A(this.b);
}

class B {
  C operator +(int i) => new C();
}

class C extends B {}

main() {
  A? a;

  expect(null, a?.b);
  a?.b++;
  expect(null, a?.b);
  B? c1 = a?.b++;
  expect(null, a?.b);
  expect(null, c1);

  a = A(B());
  expect(false, a?.b is C);
  a?.b++;
  expect(true, a?.b is C);

  a = A(B());
  B? c2 = a?.b++;
  expect(true, a?.b is C);
  expect(false, c2 is C);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
