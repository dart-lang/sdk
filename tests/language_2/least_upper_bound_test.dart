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
  A r1 = true ? a : b; //# 01: ok
  B r2 = false ? a : b; //# 02: ok
  (true ? a : b).a = 0; //# 03: compile-time error
  (false ? a : b).b = 0; //# 04: compile-time error
  var c = new C();
  (true ? a as dynamic : c).a = 0; //# 05: ok
  (false ? c : b).b = 0; //# 06: ok
}

void testBC(B b, C c) {
  B r1 = true ? b : c; //# 07: ok
  C r2 = false ? b : c; //# 08: ok
  (true ? b : c).b = 0; //# 09: ok
  (false ? b : c).c = 0; //# 10: compile-time error
  var a = null;
  (true ? b : a).b = 0; //# 11: ok
  (false ? a : b).c = 0; //# 12: ok
  (true ? c : a).b = 0; //# 13: ok
  (false ? a : c).c = 0; //# 14: ok
}

void testCD(C c, D d) {
  C r1 = true ? c : d; //# 15: ok
  D r2 = false ? c : d; //# 16: ok
  (true ? c : d).b = 0; //# 17: ok
  (false ? c : d).b = 0; //# 18: ok
  (true ? c : d).c = 0; //# 19: compile-time error
  (false ? c : d).d = 0; //# 20: compile-time error
}

void testEE(E<B> e, E<C> f) {
  // The least upper bound of E<B> and E<C> is E<B>.
  E<B> r1 = true ? e : f; //# 21: ok
  F<C> r2 = false ? e : f; //# 22: ok
  A r3 = true ? e : f; //# 23: compile-time error
  B r4 = false ? e : f; //# 24: compile-time error
  (true ? e : f).e = null; //# 25: ok
  (false ? e : f).e = null; //# 26: ok
}

void testEF(E<B> e, F<C> f) {
  // The least upper bound of E<B> and F<C> is E<B>.
  E<B> r1 = true ? e : f; //# 27: ok
  F<C> r2 = false ? e : f; //# 28: ok
  A r3 = true ? e : f; //# 29: compile-time error
  B r4 = false ? e : f; //# 30: compile-time error
  var r5;
  r5 = (true ? e : f).e; //# 31: ok
  r5 = (false ? e : f).f; //# 32: compile-time error
}
