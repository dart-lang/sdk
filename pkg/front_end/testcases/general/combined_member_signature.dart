// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  (Object?, dynamic) method();
  (Object?, dynamic) get getter;
  void set setter((int, int) Function(Object?, dynamic) f);
}

abstract class B {
  (dynamic, Object?) method();
  (dynamic, Object?) get getter;
  void set setter((int, int) Function(dynamic, Object?) f);
}

abstract class E implements A, B {}

class D implements E {
  (int, int) method() => (42, 87);
  (int, int) get getter => (42, 87);
  void set setter((int, int) Function(dynamic, dynamic) f) {}
}

(Object?, Object?) testMethod0(E e) => e.method(); // Ok
(int, Object?) testMethod1(E e) => e.method(); // Error
(Object?, int) testMethod2(E e) => e.method(); // Error

(Object?, Object?) testGetter0(E e) => e.getter; // Ok
(int, Object?) testGetter1(E e) => e.getter; // Error
(Object?, int) testGetter2(E e) => e.getter; // Error

void testSetter(E e) {
  e.setter = (a, b) => (a as int, b as int); // Ok
  e.setter = (a, b) => (a, b as int); // Error
  e.setter = (a, b) => (a as int, b); // Error
}

void method(E e) {
  var (a, b) = e.method();
  expect(42, a);
  expect(87, b);
  var (c, d) = e.getter;
  expect(42, c);
  expect(87, d);
  e.setter = (dynamic a, dynamic b) => (42, 87);
}

main() {
  method(D());
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
