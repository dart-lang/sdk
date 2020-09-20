// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: A.:[subclass=B]*/
abstract class A {
  /*member: A.noSuchMethod:[exact=JSUInt31]*/
  noSuchMethod(
          /*spec.[null|subclass=Object]*/
          /*prod.[null|exact=JSInvocationMirror]*/
          im) =>
      42;
}

/*member: B.:[exact=B]*/
class B extends A {
  /*member: B.foo:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
  foo() => {};
}

/*member: C.:[exact=C]*/
class C extends B {
  /*member: C.foo:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
  foo() => {};
}

/*member: D.:[exact=D]*/
class D implements A {
  /*member: D.foo:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
  foo() => {};

  /*member: D.noSuchMethod:[exact=JSDouble]*/
  noSuchMethod(
          /*prod.[null|exact=JSInvocationMirror]*/
          /*spec.[null|subclass=Object]*/
          im) =>
      42.5;
}

/*member: a:Union(null, [exact=D], [subclass=B])*/
dynamic a = [new B(), new C(), new D()]
    /*Container([exact=JSExtendableArray], element: Union([exact=D], [subclass=B]), length: 3)*/
    [0];

/*member: test1:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test1() => a. /*invoke: Union(null, [exact=D], [subclass=B])*/ foo();

/*member: test2:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test2() => new B(). /*invoke: [exact=B]*/ foo();

/*member: test3:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test3() => new C(). /*invoke: [exact=C]*/ foo();

/*member: test4:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test4() => (a ? new B() : new C()). /*invoke: [subclass=B]*/ foo();

/*member: test5:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test5() {
  dynamic e = (a ? new B() : new D());
  return e. /*invoke: Union([exact=B], [exact=D])*/ foo();
}

// Can hit A.noSuchMethod, D.noSuchMethod and Object.noSuchMethod.
/*member: test6:Union([exact=JSDouble], [exact=JSUInt31])*/
test6() => a. /*invoke: Union(null, [exact=D], [subclass=B])*/ bar();

// Can hit A.noSuchMethod.
/*member: test7:[exact=JSUInt31]*/
test7() {
  dynamic e = new B();
  return e. /*invoke: [exact=B]*/ bar();
}

/*member: test8:[exact=JSUInt31]*/
test8() {
  dynamic e = new C();
  return e. /*invoke: [exact=C]*/ bar();
}

/*member: test9:[exact=JSUInt31]*/
test9() {
  dynamic e = (a ? new B() : new C());
  return e. /*invoke: [subclass=B]*/ bar();
}

// Can hit A.noSuchMethod and D.noSuchMethod.
/*member: test10:Union([exact=JSDouble], [exact=JSUInt31])*/
test10() {
  dynamic e = (a ? new B() : new D());
  return e. /*invoke: Union([exact=B], [exact=D])*/ bar();
}

// Can hit D.noSuchMethod.
/*member: test11:[exact=JSDouble]*/
test11() {
  dynamic e = new D();
  return e. /*invoke: [exact=D]*/ bar();
}

/*member: main:[null]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
  test8();
  test9();
  test10();
  test11();
}
