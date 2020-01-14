// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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




  var c = new C();
  (true ? a as dynamic : c).a = 0;

}

void testBC(B b, C c) {




  var a = null;




}

void testCD(C c, D d) {






}

void testEE(E<B> e, E<C> f) {
  // The least upper bound of E<B> and E<C> is E<B>.






}

void testEF(E<B> e, F<C> f) {
  // The least upper bound of E<B> and F<C> is E<B>.




  var r5;


}
