// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[subclass=B|powerset={N}{O}]*/
abstract class A {
  /*member: A.noSuchMethod:[exact=JSUInt31|powerset={I}{O}]*/
  noSuchMethod(
    /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
    /*prod.[exact=JSInvocationMirror|powerset={N}{O}]*/
    im,
  ) => 42;
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

/*member: D.:[exact=D|powerset={N}{O}]*/
class D implements A {
  /*member: D.foo:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
  foo() => {};

  /*member: D.noSuchMethod:[exact=JSNumNotInt|powerset={I}{O}]*/
  noSuchMethod(
    /*prod.[exact=JSInvocationMirror|powerset={N}{O}]*/
    /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
    im,
  ) => 42.5;
}

/*member: a:Union(null, [exact=D|powerset={N}{O}], [subclass=B|powerset={N}{O}], powerset: {null}{N}{O})*/
dynamic a =
    [new B(), C(), D()]
    /*Container([exact=JSExtendableArray|powerset={I}{G}], element: Union([exact=D|powerset={N}{O}], [subclass=B|powerset={N}{O}], powerset: {N}{O}), length: 3, powerset: {I}{G})*/
    [0];

/*member: test1:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
test1() =>
    a. /*invoke: Union(null, [exact=D|powerset={N}{O}], [subclass=B|powerset={N}{O}], powerset: {null}{N}{O})*/ foo();

/*member: test2:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
test2() => B(). /*invoke: [exact=B|powerset={N}{O}]*/ foo();

/*member: test3:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
test3() => C(). /*invoke: [exact=C|powerset={N}{O}]*/ foo();

/*member: test4:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
test4() => (a ? B() : C()). /*invoke: [subclass=B|powerset={N}{O}]*/ foo();

/*member: test5:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
test5() {
  dynamic e = (a ? B() : D());
  return e
      . /*invoke: Union([exact=B|powerset={N}{O}], [exact=D|powerset={N}{O}], powerset: {N}{O})*/ foo();
}

// Can hit A.noSuchMethod, D.noSuchMethod and Object.noSuchMethod.
/*member: test6:Union([exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
test6() =>
    a. /*invoke: Union(null, [exact=D|powerset={N}{O}], [subclass=B|powerset={N}{O}], powerset: {null}{N}{O})*/ bar();

// Can hit A.noSuchMethod.
/*member: test7:[exact=JSUInt31|powerset={I}{O}]*/
test7() {
  dynamic e = B();
  return e. /*invoke: [exact=B|powerset={N}{O}]*/ bar();
}

/*member: test8:[exact=JSUInt31|powerset={I}{O}]*/
test8() {
  dynamic e = C();
  return e. /*invoke: [exact=C|powerset={N}{O}]*/ bar();
}

/*member: test9:[exact=JSUInt31|powerset={I}{O}]*/
test9() {
  dynamic e = (a ? B() : C());
  return e. /*invoke: [subclass=B|powerset={N}{O}]*/ bar();
}

// Can hit A.noSuchMethod and D.noSuchMethod.
/*member: test10:Union([exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
test10() {
  dynamic e = (a ? B() : D());
  return e
      . /*invoke: Union([exact=B|powerset={N}{O}], [exact=D|powerset={N}{O}], powerset: {N}{O})*/ bar();
}

// Can hit D.noSuchMethod.
/*member: test11:[exact=JSNumNotInt|powerset={I}{O}]*/
test11() {
  dynamic e = D();
  return e. /*invoke: [exact=D|powerset={N}{O}]*/ bar();
}

/*member: main:[null|powerset={null}]*/
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
