// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class T1 {}

class T2 {}

abstract class A {
  Object foo();
}

class B implements A {
  Object foo() => new T1();
}

class C implements A {
  Object foo() => new T2();
}

Function unknown;

getDynamic() => unknown.call();

Object getValue() {
  A aa = getDynamic();
  return aa.foo();
}

Object field1 = getValue();

class DeepCaller1 {
  barL1() => barL2();
  barL2() => barL3();
  barL3() => barL4();
  barL4() => field1;
}

class D {
  Object field2 = getValue();
}

class DeepCaller2 {
  barL1(D dd) => barL2(dd);
  barL2(D dd) => barL3(dd);
  barL3(D dd) => barL4(dd);
  barL4(D dd) => dd.field2;
}

use1(DeepCaller1 x) => x.barL1();
use2(DeepCaller2 x) => x.barL1(new D());

createC() {
  new C();
}

main(List<String> args) {
  new B();

  use1(new DeepCaller1());
  use2(new DeepCaller2());

  createC();
}
