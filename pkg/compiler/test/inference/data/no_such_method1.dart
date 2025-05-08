// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset={N}{O}]*/
class A {
  /*member: A.noSuchMethod:[exact=JSUInt31|powerset={I}{O}]*/
  noSuchMethod(
    /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
    /*prod.[exact=JSInvocationMirror|powerset={N}{O}]*/
    im,
  ) => 42;
}

/*member: B.:[exact=B|powerset={N}{O}]*/
class B extends A {
  /*member: B.foo:[exact=JSUInt31|powerset={I}{O}]*/
  /*invoke: [subclass=B|powerset={N}{O}]*/
  foo();
}

/*member: C.:[exact=C|powerset={N}{O}]*/
class C extends B {
  /*member: C.foo:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
  foo() => {};
}

/*member: a:[null|subclass=B|powerset={null}{N}{O}]*/
dynamic a =
    [new B(), C()]
    /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=B|powerset={N}{O}], length: 2, powerset: {I}{G})*/
    [0];

/*member: test1:[exact=JSUInt31|powerset={I}{O}]*/
test1() {
  dynamic e = A();
  return e. /*invoke: [exact=A|powerset={N}{O}]*/ foo();
}

/*member: test2:Union([exact=JSUInt31|powerset={I}{O}], [subclass=JsLinkedHashMap|powerset={N}{O}], powerset: {IN}{O})*/
test2() => a. /*invoke: [null|subclass=B|powerset={null}{N}{O}]*/ foo();

/*member: test3:[exact=JSUInt31|powerset={I}{O}]*/
test3() => B(). /*invoke: [exact=B|powerset={N}{O}]*/ foo();

/*member: test4:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
test4() => C(). /*invoke: [exact=C|powerset={N}{O}]*/ foo();

/*member: test5:Union([exact=JSUInt31|powerset={I}{O}], [subclass=JsLinkedHashMap|powerset={N}{O}], powerset: {IN}{O})*/
test5() {
  dynamic e = (a ? A() : B());
  return e. /*invoke: [subclass=A|powerset={N}{O}]*/ foo();
}

/*member: test6:Union([exact=JSUInt31|powerset={I}{O}], [subclass=JsLinkedHashMap|powerset={N}{O}], powerset: {IN}{O})*/
test6() => (a ? B() : C()). /*invoke: [subclass=B|powerset={N}{O}]*/ foo();

/*member: main:[null|powerset={null}]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}
