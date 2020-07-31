// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that when a super-bounded type is produced by instantiate-to-bounds,
// it's properly allowed or rejected depending on the context in which it's
// used.

// Raw `A` will be instantiated to `A<B<dynamic>>`, which is super-bounded.
class A<T extends B<T>> extends Base {
  const A();
}

class B<T> {}

class Base {
  const Base();

  factory Base.test() = A; //# 01: compile-time error
}

typedef void OldStyleTypedef<T>();

typedef NewStyleTypedef<T> = void Function();

void genericFunction<T>() {}

mixin Mixin {}

class C {
  dynamic field;

  void genericMethod<T>() {}

  A? test; //# 02: ok

  A? test() {} //# 03: ok

  void test(A param()) {} //# 04: ok

  void test(A? param) {} //# 05: ok

  void test([A? param]) {} //# 06: ok

  void test({A? param}) {} //# 07: ok

  C(A param()); //# 08: ok

  C(A this.field); //# 09: ok

  C(A param); //# 10: ok

  C([A? param]); //# 11: ok

  C({A? param}); //# 12: ok
}

class Test extends B<A> {} //# 13: ok

class Test extends A {} //# 14: compile-time error

class Test implements A {} //# 15: compile-time error

class Test extends Object with A {} //# 16: compile-time error

class Test = A with Mixin; //# 17: compile-time error

class Test = Object with Mixin implements A; //# 18: compile-time error

class Test = Object with A; //# 19: compile-time error

mixin Test implements A {} //# 20: compile-time error

mixin Test on A {} //# 21: compile-time error

A? test; //# 22: ok

A? test() {} //# 23: ok

void test(A param()) {} //# 24: ok

void test(A param) {} //# 25: ok

void test([A? param]) {} //# 26: ok

void test({A? param}) {} //# 27: ok

typedef A Test(); //# 28: ok

typedef void Test(A param()); //# 29: ok

typedef void Test(A param); //# 30: ok

typedef void Test([A? param]); //# 31: ok

typedef void Test({A? param}); //# 32: ok

typedef Test = A Function(); //# 33: ok

typedef Test = void Function(A param); //# 34: ok

typedef Test = void Function(A); //# 35: ok

typedef Test = void Function([A? param]); //# 36: ok

typedef Test = void Function([A]); //# 37: ok

typedef Test = void Function({A? param}); //# 38: ok

void f(dynamic x) {
  void localFunction<T>() {}

  g(x as A?); //# 39: ok
  g(x is A); //# 40: ok
  try {} on A catch (_) {} //# 41: ok
  for (A? test in [x]) {} //# 42: ok
  A? test; //# 43: ok
  OldStyleTypedef<A> test; //# 44: ok
  NewStyleTypedef<A> test; //# 45: ok
  genericFunction<A>(); //# 46: ok
  new C().genericMethod<A>(); //# 47: ok
  localFunction<A>(); //# 48: ok
  A? test() {} //# 49: ok
  void test(A param()) {} //# 50: ok
  void test(A param) {} //# 51: ok
  void test([A? param]) {} //# 52: ok
  void test({A? param}) {} //# 53: ok
  void Function(A param) test; //# 54: ok
  void Function(A) test; //# 55: ok
  void Function([A? param]) test; //# 56: ok
  void Function([A]) test; //# 57: ok
  void Function({A? param}) test; //# 58: ok
  A(); //# 59: compile-time error
  new A(); //# 60: compile-time error
  const A(); //# 61: compile-time error
  const test = A(); //# 62: compile-time error
}

void g(dynamic x) {}

main() {
  f(null);
}
