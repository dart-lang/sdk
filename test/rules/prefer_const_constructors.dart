// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_const_constructors`

import 'package:meta/meta.dart';

class A {
  const A({A parent});
  const A.a();
}

void accessA_0() {
  A a = A(); // LINT
  A a1 = A( // LINT
    parent: A.a(), // LINT
  );
}

void accessA_1() {
  A a = new A(); // LINT
}

void accessA_2() {
  A a = const A(); // OK
}

class B {
  B();
}

void accessB() {
  B b = new B(); // OK
}

class C {
  final int x;

  const C(this.x);
}

C foo(int x) => new C(x); // OK
C bar() => const C(5); // OK
C baz() => new C(5); // LINT

void objectId() {
  Object id = new Object(); // OK
}

class E {
  final String s;

  const E(this.s);

  static E m1(int i) => new E('$i'); // OK
  static E m2() => new E('adjacent' 'string'); // LINT
  static E m3(int i) => new E('adjacent' '$i'); // OK
  static E m4(String s) => new E(s); // OK
  static void m5() {
    final String s = '';
    E e = new E(s); // OK
  }
}

class F {
  final List<F> l;

  const F(this.l);

  static F m1() => new F(null); // LINT
  static F m2(List<F> l) => new F(l); // OK
  static F m3(F f) => new F([f]); // OK
}

class G {
  final Map<G, G> m;

  const G(this.m);

  static G m1() => new G(null); // LINT
  static G m2(Map<G, G> m) => new G(m); // OK
  static G m3(G g) => new G({g: g}); // OK
}

// optional new : https://github.com/dart-lang/linter/issues/995
class H {}
class I {
  final H foo;
  const I({this.foo});

  I makeI() => I(foo: H()); // OK
}

class J<T> {
  const J();
}
void gimmeJ<T>() => new J<T>(); // OK
void gimmeJofString() => new J<String>(); // LINT
void gimmeJofDynamic() => new J<dynamic>(); // LINT

class K {
  @literal
  const K();
}

k() {
  var kk = K(); // OK (handled by analyzer hint)
}
