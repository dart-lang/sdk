// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is an error if a named parameter that is part of a required
// group is not bound to an argument at a call site.
typedef String F({required String x});

class A {
  A({required int a}) {}
  A.named() : this(); //# 01: compile-time error
  void m1({required int a}) {}
  F m2() => ({required String x}) => '';
}

class B extends A { B() : super(); } //# 02: compile-time error

void f({required int a}) {}

void Function({required int a}) g() => throw '';

main() {
  A a = new A(); //# 03: compile-time error
  A a = A(); //# 04: compile-time error
  f(); //# 05: compile-time error
  g()(); //# 06: compile-time error
  new A(a: 0).m1(); //# 07: compile-time error
  new A(a: 0).m2()(); //# 08: compile-time error
}
