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

  F(T f) : this.f = f, super(f);
}

void main() {
  testAB(new A(), new B());
  testBC(new C(), new C());
  testCD(new C(), new D());
  testEE(new F<C>(new C()), new F<C>(new C()));
  testEF(new F<C>(new C()), new F<C>(new C()));
}

void testAB(A a, B b) {
  A r1 = true ? a : b; /// 01: ok
  B r2 = false ? a : b; /// 02: ok
  (true ? a : b).a = 0; /// 03: static type warning
  (false ? a : b).b = 0; /// 04: static type warning
  var c = new C();
  (true ? a : c).a = 0; /// 05: ok
  (false ? c : b).b = 0; /// 06: ok
}

void testBC(B b, C c) {
  B r1 = true ? b : c; /// 07: ok
  C r2 = false ? b : c; /// 08: ok
  (true ? b : c).b = 0; /// 09: ok
  (false ? b : c).c = 0; /// 10: static type warning
  var a = null;
  (true ? b : a).b = 0; /// 11: ok
  (false ? a : b).c = 0; /// 12: ok
  (true ? c : a).b = 0; /// 13: ok
  (false ? a : c).c = 0; /// 14: ok
}

void testCD(C c, D d) {
  C r1 = true ? c : d; /// 15: ok
  D r2 = false ? c : d; /// 16: ok
  (true ? c : d).b = 0; /// 17: ok
  (false ? c : d).b = 0; /// 18: ok
  (true ? c : d).c = 0; /// 19: static type warning
  (false ? c : d).d = 0; /// 20: static type warning
}

void testEE(E<B> e, E<C> f) {
  // The least upper bound of E<B> and E<C> is Object since the supertypes are
  //     {E<B>, Object} for E<B> and
  //     {E<C>, Object} for E<C> and
  // Object is the most specific type in the intersection of the supertypes.
  E<B> r1 = true ? e : f; /// 21: ok
  F<C> r2 = false ? e : f; /// 22: ok
  try {
    A r3 = true ? e : f; /// 23: ok
    B r4 = false ? e : f; /// 24: ok
  } catch (e) {
    // Type error in checked mode.
  }
  (true ? e : f).e = null; /// 25: static type warning
  (false ? e : f).e = null; /// 26: static type warning
}

void testEF(E<B> e, F<C> f) {
  // The least upper bound of E<B> and F<C> is Object since the supertypes are
  //     {E<B>, Object} for E<B> and
  //     {F<C>, E<C>, Object} for F<C> and
  // Object is the most specific type in the intersection of the supertypes.
  E<B> r1 = true ? e : f; /// 27: ok
  F<C> r2 = false ? e : f; /// 28: ok
  try {
    A r3 = true ? e : f; /// 29: ok
    B r4 = false ? e : f; /// 30: ok
  } catch (e) {
    // Type error in checked mode.
  }
  var r5;
  r5 = (true ? e : f).e; /// 31: static type warning
  r5 = (false ? e : f).f; /// 32: static type warning
}