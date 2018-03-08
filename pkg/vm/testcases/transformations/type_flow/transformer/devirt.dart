// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  int foo();
}

class B extends A {
  int foo() => 1;
}

class C implements A {
  int foo() => 2;
}

class D extends C {}

class E {
  String toString() => 'D';
}

void callerA1(A aa) {
  aa.foo();
}

void callerA2(A aa) {
  aa.foo();
}

void callerA3({A aa}) {
  aa.foo();
}

void callerA4(A aa) {
  aa.foo();
}

void callerE1(x) {
  x.toString();
}

void callerE2(x) {
  x.toString();
}

A dd;
E ee = new E();

main(List<String> args) {
  callerA1(new B());
  callerA1(new C());
  callerA2(new B());
  callerA3(aa: new C());
  callerA4(dd);
  dd = new D();

  callerE1('abc');
  callerE2(ee);
}
