// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: A.:invoke*/
class A {
  /*member: A.method1:invoke*/
  method1() {}

  method2() {}

  /*member: A.method4:invoke*/
  method4() {}

  /*member: A.getter:read*/
  get getter => 42;

  set setter(_) {}
}

/*member: B.:invoke*/
class B {
  method1() {}
  method2() {}

  /*member: B.method5:invoke*/
  method5() {}
  get getter => 42;

  /*member: B.setter=:write*/
  set setter(_) {}
}

/*member: C.:invoke*/
class C extends A {
  /*member: C.method1:invoke*/
  @override
  method1() {}

  /*member: B.method2:invoke*/
  @override
  method2() {}

  @override
  method4() {}

  /*member: C.getter:read*/
  @override
  get getter => 42;

  @override
  set setter(_) {}
}

/*member: D.:invoke*/
class D implements B {
  @override
  method1() {}

  /*member: D.method2:invoke*/
  @override
  method2() {}

  @override
  method5() {}

  @override
  get getter => 42;

  /*member: D.setter=:write*/
  @override
  set setter(_) {}
}

class E implements A {
  @override
  method1() {}

  @override
  method2() {}

  @override
  method4() {}

  @override
  get getter => 42;

  @override
  set setter(_) {}
}

class F extends B {
  @override
  method1() {}

  @override
  method2() {}

  @override
  method5() {}

  @override
  get getter => 42;

  @override
  set setter(_) {}
}

class G {
  /*member: G.method1:invoke*/
  method1() {}
  method2() {}
  method4() {}

  /*member: G.getter:read*/
  get getter => 42;
  set setter(_) {}
}

/*member: H.:invoke*/
class H extends Object with G implements A {}

/*member: I.:invoke*/
class I {
  /*member: I.method1:invoke*/
  method1() {}
  method2() {}
  method4() {}

  /*member: I.getter:read*/
  get getter => 42;
  set setter(_) {}
}

/*member: J.:invoke*/
class J extends I implements A {}

class K {
  /*member: K.method1:invoke*/
  method1() {}
  method2() {}

  /*member: K.getter:read*/
  get getter => 42;
  set setter(_) {}
}

class L = Object with K;
class L2 = Object with L;

/*member: M.:invoke*/
class M extends L {}

/*member: M2.:invoke*/
class M2 extends L2 {}

/*member: N.:invoke*/
class N {
  method1() {}
  get getter => 42;
  set setter(_) {}
}

abstract class O extends N {}

/*member: P.:invoke*/
class P implements O {
  /*member: P.method1:invoke*/
  @override
  method1() {}

  /*member: P.getter:read*/
  @override
  get getter => 42;

  /*member: P.setter=:write*/
  @override
  set setter(_) {}
}

/*member: Q.:invoke*/
class Q {
  /*member: Q.method3:invoke*/
  method3() {}
}

/*member: R.:invoke*/
class R extends Q {}

/*member: Class1a.:invoke*/
class Class1a {
  /*member: Class1a.call:invoke*/
  call(a, b, c) {} // Call structure only used in Class1a and Class2b.
}

/*member: Class1b.:invoke*/
class Class1b {
  call(a, b, c) {}
}

/*member: Class2.:invoke*/
class Class2 {
  /*member: Class2.c:init,invoke,read=static*/
  Class1a c;
}

/*member: main:invoke*/
main() {
  method1();
  method2();
}

/*member: method1:invoke*/
@pragma('dart2js:disableFinal')
method1() {
  A a = new A();
  B b = new B();
  a.method1();
  a.getter;
  b.method2();
  b.setter = 42;
  new C();
  new D();
  new H();
  new J();
  new M().method1();
  new M2().getter;
  new N();
  O o = new P();
  o.method1();
  o.getter;
  o.setter = 42;
  R r;
  r.method3();
  r = new R(); // Create R after call.
  new Class1a();
  new Class1b();
  new Class2().c(0, 1, 2);
}

/*member: method2:invoke*/
method2() {
  A a = new A();
  B b = new B();
  a.method4();
  b.method5();
}
