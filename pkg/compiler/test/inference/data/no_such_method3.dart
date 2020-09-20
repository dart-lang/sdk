// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: A.:[exact=A]*/
class A {
  // We may ignore this for type inference because syntactically it always
  // throws an exception.
  /*member: A.noSuchMethod:[empty]*/
  noSuchMethod(
          /*spec.[null|subclass=Object]*/
          /*prod.[null|exact=JSInvocationMirror]*/
          im) =>
      throw 'foo';
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

/*member: a:[null|subclass=B]*/
dynamic a = [new B(), new C()]
    /*Container([exact=JSExtendableArray], element: [subclass=B], length: 2)*/
    [0];
/*member: test1:[empty]*/
test1() {
  dynamic e = new A();
  return e. /*invoke: [exact=A]*/ foo();
}

/*member: test2:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test2() => a. /*invoke: [null|subclass=B]*/ foo();

/*member: test3:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test3() => new B(). /*invoke: [exact=B]*/ foo();

/*member: test4:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test4() => new C(). /*invoke: [exact=C]*/ foo();

/*member: test5:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test5() {
  dynamic e = (a ? new A() : new B());
  return e. /*invoke: [subclass=A]*/ foo();
}

/*member: test6:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
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
