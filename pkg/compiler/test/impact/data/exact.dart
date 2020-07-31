// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: A.:static=[Object.(0)]*/
class A {
  method1() {}
  method2() {}
  method3() {}
}

/*member: B.:static=[A.(0)]*/
class B extends A {
  method1() {}
  method2() {}
  method3() {}
}

/*member: C.:static=[B.(0)]*/
class C extends B {
  method1() {}
  method2() {}
  method3() {}
}

/*member: main:static=[callOnEffectivelyFinalB(0),callOnNewB(0),callOnNewC(0)]*/
main() {
  callOnNewB();
  callOnNewC();
  callOnEffectivelyFinalB();
  callOnEffectivelyFinalB();
}

/*member: callOnNewB:dynamic=[exact:B.method1(0)],static=[B.(0)]*/
callOnNewB() {
  new B().method1();
}

/*member: callOnNewC:dynamic=[exact:C.method2(0)],static=[C.(0)]*/
callOnNewC() {
  new C().method2();
}

/*member: callOnEffectivelyFinalB:dynamic=[exact:B.method3(0)],static=[B.(0)]*/
callOnEffectivelyFinalB() {
  A a = new B();
  a.method3();
}
