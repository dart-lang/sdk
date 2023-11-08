// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type A(int it) {
  int methodA() => it + 5;
}

extension type B<T>(T it) {
  T methodB() => it;
}

extension type C1(int it) implements A {
  int methodC1() => it + 42;
}

extension type C2(int it) implements A, B<int> {
  int methodC2() => it + 87;
}

extension type D1(int it) implements C1 {
  int methodD1() => it + 123;
}

errors(A a, B<String> b1, B<num> b2, C1 c1, C2 c2, D1 d1) {
  a.methodB(); // Error
  a.methodC1(); // Error
  a.methodC2(); // Error
  a.methodD1(); // Error

  b1.methodA(); // Error
  b1.methodC1(); // Error
  b1.methodC2(); // Error
  b1.methodD1(); // Error

  b2.methodA(); // Error
  b2.methodC1(); // Error
  b2.methodC2(); // Error
  b2.methodD1(); // Error

  c1.methodB(); // Error
  c1.methodC2(); // Error
  c1.methodD1(); // Error

  c2.methodC1(); // Error
  c2.methodD1(); // Error

  d1.methodB(); // Error
  d1.methodC2(); // Error

  a = b1; // Error
  a = b2; // Error

  b1 = a; // Error
  b1 = b2; // Error
  b1 = c1; // Error
  b1 = c2; // Error
  b1 = d1; // Error

  b2 = a; // Error
  b2 = b1; // Error
  b2 = c1; // Error
  b2 = d1; // Error

  c1 = a; // Error
  c1 = b1; // Error
  c1 = b2; // Error
  c1 = c2; // Error

  c2 = a; // Error
  c2 = b1; // Error
  c2 = b2; // Error
  c2 = c1; // Error
  c2 = d1; // Error

  d1 = a; // Error
  d1 = b1; // Error
  d1 = b2; // Error
  d1 = c1; // Error
  d1 = c2; // Error
}

method(A a, B<String> b1, B<num> b2, C1 c1, C2 c2, D1 d1) {
  expect(0 + 5, a.methodA()); // OK

  expect('0', b1.methodB()); // OK

  expect(1 + 0, b2.methodB()); // OK

  expect(2 + 5, c1.methodA()); // OK
  expect(2 + 42, c1.methodC1()); // OK

  expect(3 + 5, c2.methodA()); // OK
  expect(3, c2.methodB()); // OK
  expect(3 + 87, c2.methodC2()); // OK

  expect(4 + 5, d1.methodA()); // OK
  expect(4 + 42, d1.methodC1()); // OK
  expect(4 + 123, d1.methodD1()); // OK

  a = a; // OK
  a = c1; // OK
  a = c2; // OK
  a = d1; // OK

  b1 = b1; // OK

  b2 = b2; // OK
  b2 = c2; // OK

  c1 = c1; // OK
  c1 = d1; // OK

  c2 = c2; // OK

  d1 = d1; // OK
}

main() {
  method(A(0), B<String>('0'), B<num>(1), C1(2), C2(3), D1(4));
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Expected $expected, actual $actual';
  }
}