// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test least upper bound through type checking of conditionals.

class A {
  var a;
}

class B {
  var b;
}

class C extends B {
  var c;
}

class D extends B {
  var d;
}

class E<T> {
  T e;

  E(this.e);
}

class F<T> extends E<T> {
  T f;

  F(T f)
      : this.f = f,
        super(f);
}

void main() {
  testAB(new A(), new B());
  testBC(new C(), new C());
  testCD(new C(), new D());
  testEE(new F<C>(new C()), new F<C>(new C()));
  testEF(new F<C>(new C()), new F<C>(new C()));
}

void testAB(A a, B b) {
  A r1 = true ? a : b;
  //     ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //          ^
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'A'.
  B r2 = false ? a : b;
  //     ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'B'.
  (true ? a : b).a = 0;
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'a' isn't defined for the class 'Object'.
  (false ? a : b).b = 0;
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'b' isn't defined for the class 'Object'.
  var c = new C();
  (true ? a as dynamic : c).a = 0;
  (false ? c : b).b = 0;
}

void testBC(B b, C c) {
  B r1 = true ? b : c;
  C r2 = false ? b : c;
  //     ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe] A value of type 'B' can't be assigned to a variable of type 'C'.
  (true ? b : c).b = 0;
  (false ? b : c).c = 0;
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'c' isn't defined for the class 'B'.
  var a = null;
  (true ? b : a).b = 0;
  (false ? a : b).c = 0;
  (true ? c : a).b = 0;
  (false ? a : c).c = 0;
}

void testCD(C c, D d) {
  C r1 = true ? c : d;
  //     ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //          ^
  // [cfe] A value of type 'B' can't be assigned to a variable of type 'C'.
  D r2 = false ? c : d;
  //     ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe] A value of type 'B' can't be assigned to a variable of type 'D'.
  (true ? c : d).b = 0;
  (false ? c : d).b = 0;
  (true ? c : d).c = 0;
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'c' isn't defined for the class 'B'.
  (false ? c : d).d = 0;
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'd' isn't defined for the class 'B'.
}

void testEE(E<B> e, E<C> f) {
  // The least upper bound of E<B> and E<C> is E<B>.
  E<B> r1 = true ? e : f;
  F<C> r2 = false ? e : f;
  //        ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //              ^
  // [cfe] A value of type 'E<B>' can't be assigned to a variable of type 'F<C>'.
  A r3 = true ? e : f;
  //     ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //          ^
  // [cfe] A value of type 'E<B>' can't be assigned to a variable of type 'A'.
  B r4 = false ? e : f;
  //     ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe] A value of type 'E<B>' can't be assigned to a variable of type 'B'.
  (true ? e : f).e = C();
  (false ? e : f).e = C();
}

void testEF(E<B> e, F<C> f) {
  // The least upper bound of E<B> and F<C> is E<B>.
  E<B> r1 = true ? e : f;
  F<C> r2 = false ? e : f;
  //        ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //              ^
  // [cfe] A value of type 'E<B>' can't be assigned to a variable of type 'F<C>'.
  A r3 = true ? e : f;
  //     ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //          ^
  // [cfe] A value of type 'E<B>' can't be assigned to a variable of type 'A'.
  B r4 = false ? e : f;
  //     ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe] A value of type 'E<B>' can't be assigned to a variable of type 'B'.
  var r5;
  r5 = (true ? e : f).e;
  r5 = (false ? e : f).f;
  //                   ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'f' isn't defined for the class 'E<B>'.
}
