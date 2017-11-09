// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that for an async method, the following three
// types are all appropriately matched:
// - The static return type
// - The return type of reified runtime type of a tearoff of the function or
//   method
// - The reified type of the future returned by the function or method
//
// Specific attention is paid to the following conditions:
// - The static return type is determined by type inference
// - The static return type is `dynamic`
// - The function or method immediately returns a value or future with a
//   different type (possibly using `=>` syntax)

import 'dart:async';

import 'package:expect/expect.dart';

class A {}

class B extends A {}

class B2 extends A {}

Future quick() async {}

Future<B> futureB() => new Future<B>.value(new B());

abstract class I {
  dynamic f_inferred_dynamic();
  Future<A> f_inferred_A();
}

class C implements I {
  f_inferred_dynamic() async {
    await quick();
    return new B();
  }

  f_inferred_A() async {
    await quick();
    return new B();
  }

  dynamic f_dynamic() async {
    await quick();
    return new B();
  }

  Future<A> f_A() async {
    await quick();
    return new B();
  }

  Future<A> f_immediateReturn_B() async {
    return new B();
  }

  Future<A> f_immediateReturn_FutureB() async {
    return futureB();
  }

  Future<A> f_expressionSyntax_B() async => new B();

  Future<A> f_expressionSyntax_FutureB() async => futureB();
}

// Not executed
void checkStaticTypes(C c) {
  // Check that f_inferred_dynamic's static return type is `dynamic`, by
  // verifying that no error occurs if we try to call `foo` on its return value.
  c.f_inferred_dynamic().foo();

  // Check that f_inferred_A's static return type is `Future<A>`, by verifying
  // that its return value can be assigned to `Future<B2>` but not
  // `Future<int>`.
  Future<B2> v1 = c.f_inferred_A();
  Future<int> v2 = c.f_inferred_A(); //# 01: compile-time error
}

void checkDynamic(dynamic tearoff) {
  Expect.isTrue(tearoff is dynamic Function());
  Expect.isFalse(tearoff is Future<dynamic> Function());
  dynamic f = tearoff();
  Expect.isTrue(f is Future<dynamic>);
  Expect.isFalse(f is Future<A>);
}

void checkFutureA(dynamic tearoff) {
  Expect.isTrue(tearoff is Future<A> Function());
  Expect.isFalse(tearoff is Future<B> Function());
  dynamic f = tearoff();
  Expect.isTrue(f is Future<A>);
  Expect.isFalse(f is Future<B>);
}

void test(C c) {
  checkDynamic(c.f_inferred_dynamic);
  checkFutureA(c.f_inferred_A);
  checkDynamic(c.f_dynamic);
  checkFutureA(c.f_A);
  checkFutureA(c.f_immediateReturn_B);
  checkFutureA(c.f_immediateReturn_FutureB);
  checkFutureA(c.f_expressionSyntax_B);
  checkFutureA(c.f_expressionSyntax_FutureB);
}

main() {
  test(new C());
}
