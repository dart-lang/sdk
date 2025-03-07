// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset=0]*/
class A {
  // We may ignore this for type inference because it forwards to a default
  // noSuchMethod implementation, which always throws an exception.
  noSuchMethod(im) => super.noSuchMethod(im);
}

/*member: B.:[exact=B|powerset=0]*/
class B extends A {
  /*member: B.foo:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
  foo() => {};
}

/*member: C.:[exact=C|powerset=0]*/
class C extends B {
  /*member: C.foo:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
  foo() => {};
}

/*member: a:[null|subclass=B|powerset=1]*/
dynamic a =
    [new B(), C()]
    /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=B|powerset=0], length: 2, powerset: 0)*/
    [0];

/*member: test1:[empty|powerset=0]*/
test1() {
  dynamic e = A();
  return e. /*invoke: [exact=A|powerset=0]*/ foo();
}

/*member: test2:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
test2() => a. /*invoke: [null|subclass=B|powerset=1]*/ foo();

/*member: test3:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
test3() => B(). /*invoke: [exact=B|powerset=0]*/ foo();

/*member: test4:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
test4() => C(). /*invoke: [exact=C|powerset=0]*/ foo();

/*member: test5:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
test5() {
  dynamic e = (a ? A() : B());
  return e. /*invoke: [subclass=A|powerset=0]*/ foo();
}

/*member: test6:Dictionary([exact=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
test6() => (a ? B() : C()). /*invoke: [subclass=B|powerset=0]*/ foo();

/*member: main:[null|powerset=1]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}
