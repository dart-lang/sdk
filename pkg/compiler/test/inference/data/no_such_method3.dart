// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset={N}{O}{N}]*/
class A {
  // We may ignore this for type inference because syntactically it always
  // throws an exception.
  /*member: A.noSuchMethod:[empty|powerset=empty]*/
  noSuchMethod(
    /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
    /*prod.[exact=JSInvocationMirror|powerset={N}{O}{N}]*/
    im,
  ) => throw 'foo';
}

/*member: B.:[exact=B|powerset={N}{O}{N}]*/
class B extends A {
  /*member: B.foo:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}{N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O}{N})*/
  foo() => {};
}

/*member: C.:[exact=C|powerset={N}{O}{N}]*/
class C extends B {
  /*member: C.foo:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}{N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O}{N})*/
  foo() => {};
}

/*member: a:[null|subclass=B|powerset={null}{N}{O}{N}]*/
dynamic a =
    [new B(), C()]
    /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=B|powerset={N}{O}{N}], length: 2, powerset: {I}{G}{M})*/
    [0];
/*member: test1:[empty|powerset=empty]*/
test1() {
  dynamic e = A();
  return e. /*invoke: [exact=A|powerset={N}{O}{N}]*/ foo();
}

/*member: test2:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}{N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O}{N})*/
test2() => a. /*invoke: [null|subclass=B|powerset={null}{N}{O}{N}]*/ foo();

/*member: test3:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}{N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O}{N})*/
test3() => B(). /*invoke: [exact=B|powerset={N}{O}{N}]*/ foo();

/*member: test4:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}{N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O}{N})*/
test4() => C(). /*invoke: [exact=C|powerset={N}{O}{N}]*/ foo();

/*member: test5:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}{N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O}{N})*/
test5() {
  dynamic e = (a ? A() : B());
  return e. /*invoke: [subclass=A|powerset={N}{O}{N}]*/ foo();
}

/*member: test6:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}{N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O}{N})*/
test6() => (a ? B() : C()). /*invoke: [subclass=B|powerset={N}{O}{N}]*/ foo();

/*member: main:[null|powerset={null}]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}
