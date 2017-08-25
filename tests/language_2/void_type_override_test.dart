// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for type checks involving the void type and overriding.

import 'package:expect/expect.dart';

use<T>(T x) {}

class A<T> {
  T x;
  Object y;
  int z;

  T foo() => null;
  void bar() {}
  void gee(T x) {}

  f(A<Object> a) {}
  g(A<void> a) {}
  h(A<T> a) {}
}

class B implements A<Object> {
  void   //# 00: compile-time error
  /*     //# 00: continued
  var
  */     //# 00: continued
  x;

  void   //# 00b: compile-time error
  /*     //# 00b: continued
  var
  */     //# 00b: continued
  y;

  void   //# 00c: compile-time error
  /*     //# 00c: continued
  int
  */     //# 00c: continued
  z;

  // Overriding an Object function with a void function is an error.
  void  //# 01: compile-time error
  foo() => null;

  int bar() => 499;
  void gee(void x) {}
  f(A<void> a) {}
  g(A<void> a) {}
  h(A<void> a) {}
}

class C implements A<void> {
  void x;
  Object y;
  int z;

  void foo() {}
  void bar() {}
  void gee(void x) {
    use(x);  //# 03: compile-time error
  }

  f(covariant C c) {}
  g(covariant C c) {}
  h(covariant C c) {}
}

class D implements A<void> {
  Object x; // Setter will become a voidness preservation violation.
  Object y;
  int z;

  Object foo() => null;
  void bar() {}
  void gee(
      Object // Will become a voidness preservation violation.
      x) {}

  f(A<Object> a) {}
  g(
      A<Object> // Will become a voidness preservation violation.
      a) {}
  h(
      A<Object> // Will become a voidness preservation violation.
      a) {}
}

void instantiateClasses() {
  var a = new A<void>();
  var b = new B();
  var c = new C();
  var d = new D();

  a.foo();
  b.foo();
  c.foo();
  d.foo();
  a.bar();
  b.bar();
  c.bar();
  d.bar();
  a.gee(499);
  b.gee(499);
  c.gee(499);
  d.gee(499);
}

void testAssignments() {
  A<void> a1 = new A<Object>();
  A<Object> a2 = new A<void>();
  A a3 = new A<void>();
  A<dynamic> a4 = new A<void>();
  dynamic a5 = new A<void>();
}

main() {
  instantiateClasses();
  testAssignments();
}
