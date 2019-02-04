// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: A.:invoke*/
class A {
  /*element: A.method1:invoke*/
  method1() {}

  method2() {}

  /*element: A.method4:invoke*/
  method4() {}

  /*element: A.getter:read*/
  get getter => 42;

  set setter(_) {}
}

/*element: B.:invoke*/
class B {
  method1() {}
  method2() {}

  /*element: B.method5:invoke*/
  method5() {}
  get getter => 42;

  /*element: B.setter=:write*/
  set setter(_) {}
}

/*element: C.:invoke*/
class C extends A {
  /*element: C.method1:invoke*/
  method1() {}

  /*element: B.method2:invoke*/
  method2() {}
  method4() {}

  /*element: C.getter:read*/
  get getter => 42;
  set setter(_) {}
}

/*element: D.:invoke*/
class D implements B {
  method1() {}

  /*element: D.method2:invoke*/
  method2() {}
  method5() {}
  get getter => 42;

  /*element: D.setter=:write*/
  set setter(_) {}
}

class E implements A {
  method1() {}
  method2() {}
  method4() {}
  get getter => 42;
  set setter(_) {}
}

class F extends B {
  method1() {}
  method2() {}
  method5() {}
  get getter => 42;
  set setter(_) {}
}

class G {
  /*element: G.method1:invoke*/
  method1() {}
  method2() {}
  method4() {}

  /*element: G.getter:read*/
  get getter => 42;
  set setter(_) {}
}

/*element: H.:invoke*/
class H extends Object with G implements A {}

/*element: I.:invoke*/
class I {
  /*element: I.method1:invoke*/
  method1() {}
  method2() {}
  method4() {}

  /*element: I.getter:read*/
  get getter => 42;
  set setter(_) {}
}

/*element: J.:invoke*/
class J extends I implements A {}

class K {
  /*element: K.method1:invoke*/
  method1() {}
  method2() {}

  /*element: K.getter:read*/
  get getter => 42;
  set setter(_) {}
}

class L = Object with K;
class L2 = Object with L;

/*element: M.:invoke*/
class M extends L {}

/*element: M2.:invoke*/
class M2 extends L2 {}

/*element: N.:invoke*/
class N {
  method1() {}
  get getter => 42;
  set setter(_) {}
}

abstract class O extends N {}

/*element: P.:invoke*/
class P implements O {
  /*element: P.method1:invoke*/
  method1() {}

  /*element: P.getter:read*/
  get getter => 42;

  /*element: P.setter=:write*/
  set setter(_) {}
}

/*element: Q.:invoke*/
class Q {
  /*element: Q.method3:invoke*/
  method3() {}
}

/*element: R.:invoke*/
class R extends Q {}

/*element: Class1a.:invoke*/
class Class1a {
  /*element: Class1a.call:invoke*/
  call(a, b, c) {} // Call structure only used in Class1a and Class2b.
}

/*element: Class1b.:invoke*/
class Class1b {
  call(a, b, c) {}
}

/*element: Class2.:invoke*/
class Class2 {
  /*element: Class2.c:read,write*/
  Class1a c;
}

/*element: main:invoke*/
main() {
  method1();
  method2();
}

/*element: method1:invoke*/
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

/*element: method2:invoke*/
method2() {
  A a = new A();
  B b = new B();
  a.method4();
  b.method5();
}
