// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: A.:[exact=A]*/
class A {
  /*member: A.noSuchMethod:[exact=JSUInt31]*/
  noSuchMethod(
          /*spec.[null|subclass=Object]*/
          /*prod.[null|exact=JSInvocationMirror]*/
          im) =>
      42;
}

/*member: B.:[exact=B]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31]*/
  /*invoke: [subclass=B]*/ foo();
}

/*member: C.:[exact=C]*/
class C extends B {
  /*member: C.foo:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
  foo() => {};
}

/*member: a:[null|subclass=B]*/
dynamic a = [new B(), new C()]
    /*Container([exact=JSExtendableArray], element: [subclass=B], length: 2)*/
    [0];

/*member: test1:[exact=JSUInt31]*/
test1() {
  dynamic e = new A();
  return e. /*invoke: [exact=A]*/ foo();
}

/*member: test2:Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/
test2() => a. /*invoke: [null|subclass=B]*/ foo();

/*member: test3:[exact=JSUInt31]*/
test3() => new B(). /*invoke: [exact=B]*/ foo();

/*member: test4:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test4() => new C(). /*invoke: [exact=C]*/ foo();

/*member: test5:Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/
test5() {
  dynamic e = (a ? new A() : new B());
  return e. /*invoke: [subclass=A]*/ foo();
}

/*member: test6:Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/
test6() => (a ? new B() : new C()). /*invoke: [subclass=B]*/ foo();

/*member: main:[null]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}
