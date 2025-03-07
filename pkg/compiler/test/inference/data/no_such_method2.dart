// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[subclass=B|powerset=0]*/
abstract class A {
  /*member: A.noSuchMethod:[exact=JSUInt31|powerset=0]*/
  noSuchMethod(
    /*spec.[null|subclass=Object|powerset=1]*/
    /*prod.[exact=JSInvocationMirror|powerset=0]*/
    im,
  ) => 42;
}

/*member: B.:[exact=B|powerset=0]*/
class B extends A {
  /*member: B.foo:Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
  foo() => {};
}

/*member: C.:[exact=C|powerset=0]*/
class C extends B {
  /*member: C.foo:Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
  foo() => {};
}

/*member: D.:[exact=D|powerset=0]*/
class D implements A {
  /*member: D.foo:Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
  foo() => {};

  /*member: D.noSuchMethod:[exact=JSNumNotInt|powerset=0]*/
  noSuchMethod(
    /*prod.[exact=JSInvocationMirror|powerset=0]*/
    /*spec.[null|subclass=Object|powerset=1]*/
    im,
  ) => 42.5;
}

/*member: a:Union(null, [exact=D|powerset=0], [subclass=B|powerset=0], powerset: 1)*/
dynamic a =
    [new B(), C(), D()]
    /*Container([exact=JSExtendableArray|powerset=0], element: Union([exact=D|powerset=0], [subclass=B|powerset=0], powerset: 0), length: 3, powerset: 0)*/
    [0];

/*member: test1:Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
test1() =>
    a. /*invoke: Union(null, [exact=D|powerset=0], [subclass=B|powerset=0], powerset: 1)*/ foo();

/*member: test2:Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
test2() => B(). /*invoke: [exact=B|powerset=0]*/ foo();

/*member: test3:Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
test3() => C(). /*invoke: [exact=C|powerset=0]*/ foo();

/*member: test4:Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
test4() => (a ? B() : C()). /*invoke: [subclass=B|powerset=0]*/ foo();

/*member: test5:Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
test5() {
  dynamic e = (a ? B() : D());
  return e
      . /*invoke: Union([exact=B|powerset=0], [exact=D|powerset=0], powerset: 0)*/ foo();
}

// Can hit A.noSuchMethod, D.noSuchMethod and Object.noSuchMethod.
/*member: test6:Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
test6() =>
    a. /*invoke: Union(null, [exact=D|powerset=0], [subclass=B|powerset=0], powerset: 1)*/ bar();

// Can hit A.noSuchMethod.
/*member: test7:[exact=JSUInt31|powerset=0]*/
test7() {
  dynamic e = B();
  return e. /*invoke: [exact=B|powerset=0]*/ bar();
}

/*member: test8:[exact=JSUInt31|powerset=0]*/
test8() {
  dynamic e = C();
  return e. /*invoke: [exact=C|powerset=0]*/ bar();
}

/*member: test9:[exact=JSUInt31|powerset=0]*/
test9() {
  dynamic e = (a ? B() : C());
  return e. /*invoke: [subclass=B|powerset=0]*/ bar();
}

// Can hit A.noSuchMethod and D.noSuchMethod.
/*member: test10:Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
test10() {
  dynamic e = (a ? B() : D());
  return e
      . /*invoke: Union([exact=B|powerset=0], [exact=D|powerset=0], powerset: 0)*/ bar();
}

// Can hit D.noSuchMethod.
/*member: test11:[exact=JSNumNotInt|powerset=0]*/
test11() {
  dynamic e = D();
  return e. /*invoke: [exact=D|powerset=0]*/ bar();
}

/*member: main:[null|powerset=1]*/
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
