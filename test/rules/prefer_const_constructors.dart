// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_const_constructors`

class A {
  const A();
}

void accessA_1() {
  A a = new A(); //LINT
}

void accessA_2() {
  A a = const A(); //OK
}

class B {
  B();
}

void accessB() {
  B b = new B(); //OK
}

class C {
  final int x;

  const C(this.x);
}

C foo(int x) => new C(x); //OK
C bar() => const C(5); //OK
C baz() => new C(5); //LINT

void objectId() {
  Object id = new Object(); //OK
}

void accessD() {
  D b = new D();
}

class E {
  final String s;

  const E(this.s);

  static E m1(int i) => new E('$i'); // OK
  static E m2() => new E('adjacent' 'string'); // LINT
  static E m3(int i) => new E('adjacent' '$i'); // OK
}
