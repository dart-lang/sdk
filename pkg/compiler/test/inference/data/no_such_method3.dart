// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset={N}{O}]*/
class A {
  // We may ignore this for type inference because syntactically it always
  // throws an exception.
  /*member: A.noSuchMethod:[empty|powerset=empty]*/
  noSuchMethod(
    /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
    /*prod.[exact=JSInvocationMirror|powerset={N}{O}]*/
    im,
  ) => throw 'foo';
}

/*member: B.:[exact=B|powerset={N}{O}]*/
class B extends A {
  /*member: B.foo:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
  foo() => {};
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
/*member: test1:[empty|powerset=empty]*/
test1() {
  dynamic e = A();
  return e. /*invoke: [exact=A|powerset={N}{O}]*/ foo();
}

/*member: test2:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
test2() => a. /*invoke: [null|subclass=B|powerset={null}{N}{O}]*/ foo();

/*member: test3:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
test3() => B(). /*invoke: [exact=B|powerset={N}{O}]*/ foo();

/*member: test4:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
test4() => C(). /*invoke: [exact=C|powerset={N}{O}]*/ foo();

/*member: test5:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
test5() {
  dynamic e = (a ? A() : B());
  return e. /*invoke: [subclass=A|powerset={N}{O}]*/ foo();
}

/*member: test6:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
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
