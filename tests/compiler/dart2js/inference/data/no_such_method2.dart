// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: A.:[subclass=B]*/
abstract class A {
  /*element: A.noSuchMethod:[exact=JSUInt31]*/
  noSuchMethod(/*[null|subclass=Object]*/ im) => 42;
}

/*element: B.:[exact=B]*/
class B extends A {
  /*element: B.foo:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
  foo() => {};
}

/*element: C.:[exact=C]*/
class C extends B {
  /*element: C.foo:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
  foo() => {};
}

/*element: D.:[exact=D]*/
class D implements A {
  /*element: D.foo:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
  foo() => {};

  /*element: D.noSuchMethod:[exact=JSDouble]*/
  noSuchMethod(/*[null|subclass=Object]*/ im) => 42.5;
}

/*element: a:Union([exact=D], [null|subclass=B])*/
dynamic a = [new B(), new C(), new D()]
    /*Container([exact=JSExtendableArray], element: Union([exact=D], [subclass=B]), length: 3)*/
    [0];

/*element: test1:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test1() => a. /*invoke: Union([exact=D], [null|subclass=B])*/ foo();

/*element: test2:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test2() => new B(). /*invoke: [exact=B]*/ foo();

/*element: test3:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test3() => new C(). /*invoke: [exact=C]*/ foo();

/*element: test4:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test4() => (a ? new B() : new C()). /*invoke: [subclass=B]*/ foo();

/*element: test5:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test5() => (a ? new B() : new D())
    // ignore: undefined_method
    . /*invoke: Union([exact=B], [exact=D])*/ foo();

// Can hit A.noSuchMethod, D.noSuchMethod and Object.noSuchMethod.
/*element: test6:Union([exact=JSDouble], [exact=JSUInt31])*/
test6() => a. /*invoke: Union([exact=D], [null|subclass=B])*/ bar();

// Can hit A.noSuchMethod.
/*element: test7:[exact=JSUInt31]*/
test7() => new B()
    // ignore: undefined_method
    . /*invoke: [exact=B]*/ bar();

/*element: test8:[exact=JSUInt31]*/
test8() => new C()
    // ignore: undefined_method
    . /*invoke: [exact=C]*/ bar();

/*element: test9:[exact=JSUInt31]*/
test9() => (a ? new B() : new C())
    // ignore: undefined_method
    . /*invoke: [subclass=B]*/ bar();

// Can hit A.noSuchMethod and D.noSuchMethod.
/*element: test10:Union([exact=JSDouble], [exact=JSUInt31])*/
test10() => (a ? new B() : new D())
    // ignore: undefined_method
    . /*invoke: Union([exact=B], [exact=D])*/ bar();

// Can hit D.noSuchMethod.
/*element: test11:[exact=JSDouble]*/
test11() => new D()
    // ignore: undefined_method
    . /*invoke: [exact=D]*/ bar();

/*element: main:[null]*/
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
