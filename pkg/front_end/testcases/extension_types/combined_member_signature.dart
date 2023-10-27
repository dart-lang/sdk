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

class C implements A, B {
  (int, int) method() => (42, 87);
  (int, int) get getter => (42, 87);
  void set setter((int, int) Function(dynamic, dynamic) f) {}
}

extension type E(C c) implements A, B {}

(Object?, Object?) testMethod0(E e) => e.method(); // Ok
(int, Object?) testMethod1(E e) => e.method(); // Error
(Object?, int) testMethod2(E e) => e.method(); // Error
testMethod3(E e) => e.method().$1.unresolved(); // Error
testMethod4(E e) => e.method().$2.unresolved(); // Error

(Object?, Object?) testGetter0(E e) => e.getter; // Ok
(int, Object?) testGetter1(E e) => e.getter; // Error
(Object?, int) testGetter2(E e) => e.getter; // Error

void testSetter(E e) {
  e.setter = (a, b) => (a as int, b as int); // Ok
  e.setter = (a, b) => (a, b as int); // Error
  e.setter = (a, b) => (a as int, b); // Error
}

E e = E(C());

var f = e.method();
(Object?, Object?) f1 = f; // Ok
(Object?, int) f2 = f; // Error
(int, Object?) f3 = f; // Error
testMethod5(E e) => f.$1.unresolved(); // Error
testMethod6(E e) => f.$2.unresolved(); // Error

var g = e.getter;
(Object?, Object?) g1 = g; // Ok
(Object?, int) g2 = g; // Error
(int, Object?) g3 = g; // Error
testGetter5(E e) => g.$1.unresolved(); // Error
testGetter6(E e) => g.$2.unresolved(); // Error

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
  method(E(C()));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}