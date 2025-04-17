// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[subclass=B|powerset={N}]*/
abstract class A {
  /*member: A.noSuchMethod:[exact=JSUInt31|powerset={I}]*/
  noSuchMethod(
    /*spec.[null|subclass=Object|powerset={null}{IN}]*/
    /*prod.[exact=JSInvocationMirror|powerset={N}]*/
    im,
  ) => 42;
}

/*member: B.:[exact=B|powerset={N}]*/
class B extends A {
  /*member: B.foo:Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N})*/
  foo() => {};
}

/*member: C.:[exact=C|powerset={N}]*/
class C extends B {
  /*member: C.foo:Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N})*/
  foo() => {};
}

/*member: D.:[exact=D|powerset={N}]*/
class D implements A {
  /*member: D.foo:Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N})*/
  foo() => {};

  /*member: D.noSuchMethod:[exact=JSNumNotInt|powerset={I}]*/
  noSuchMethod(
    /*prod.[exact=JSInvocationMirror|powerset={N}]*/
    /*spec.[null|subclass=Object|powerset={null}{IN}]*/
    im,
  ) => 42.5;
}

/*member: a:Union(null, [exact=D|powerset={N}], [subclass=B|powerset={N}], powerset: {null}{N})*/
dynamic a =
    [new B(), C(), D()]
    /*Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=D|powerset={N}], [subclass=B|powerset={N}], powerset: {N}), length: 3, powerset: {I})*/
    [0];

/*member: test1:Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N})*/
test1() =>
    a. /*invoke: Union(null, [exact=D|powerset={N}], [subclass=B|powerset={N}], powerset: {null}{N})*/ foo();

/*member: test2:Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N})*/
test2() => B(). /*invoke: [exact=B|powerset={N}]*/ foo();

/*member: test3:Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N})*/
test3() => C(). /*invoke: [exact=C|powerset={N}]*/ foo();

/*member: test4:Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N})*/
test4() => (a ? B() : C()). /*invoke: [subclass=B|powerset={N}]*/ foo();

/*member: test5:Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N})*/
test5() {
  dynamic e = (a ? B() : D());
  return e
      . /*invoke: Union([exact=B|powerset={N}], [exact=D|powerset={N}], powerset: {N})*/ foo();
}

// Can hit A.noSuchMethod, D.noSuchMethod and Object.noSuchMethod.
/*member: test6:Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
test6() =>
    a. /*invoke: Union(null, [exact=D|powerset={N}], [subclass=B|powerset={N}], powerset: {null}{N})*/ bar();

// Can hit A.noSuchMethod.
/*member: test7:[exact=JSUInt31|powerset={I}]*/
test7() {
  dynamic e = B();
  return e. /*invoke: [exact=B|powerset={N}]*/ bar();
}

/*member: test8:[exact=JSUInt31|powerset={I}]*/
test8() {
  dynamic e = C();
  return e. /*invoke: [exact=C|powerset={N}]*/ bar();
}

/*member: test9:[exact=JSUInt31|powerset={I}]*/
test9() {
  dynamic e = (a ? B() : C());
  return e. /*invoke: [subclass=B|powerset={N}]*/ bar();
}

// Can hit A.noSuchMethod and D.noSuchMethod.
/*member: test10:Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
test10() {
  dynamic e = (a ? B() : D());
  return e
      . /*invoke: Union([exact=B|powerset={N}], [exact=D|powerset={N}], powerset: {N})*/ bar();
}

// Can hit D.noSuchMethod.
/*member: test11:[exact=JSNumNotInt|powerset={I}]*/
test11() {
  dynamic e = D();
  return e. /*invoke: [exact=D|powerset={N}]*/ bar();
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
