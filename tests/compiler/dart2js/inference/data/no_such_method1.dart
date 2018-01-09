// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: A.:[exact=A]*/
class A {
  /*element: A.noSuchMethod:[exact=JSUInt31]*/
  noSuchMethod(/*[null|subclass=Object]*/ im) => 42;
}

/*element: B.:[exact=B]*/
class B extends A {
  foo();
}

/*element: C.:[exact=C]*/
class C extends B {
  /*element: C.foo:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
  foo() => {};
}

/*element: a:[null|subclass=B]*/
dynamic a = [new B(), new C()]
    /*Container([exact=JSExtendableArray], element: [subclass=B], length: 2)*/
    [0];

/*element: test1:[exact=JSUInt31]*/
test1() => new A()
    // ignore: undefined_method
    . /*invoke: [exact=A]*/ foo();

/*element: test2:Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/
test2() => a. /*invoke: [null|subclass=B]*/ foo();

/*element: test3:[exact=JSUInt31]*/
test3() => new B(). /*invoke: [exact=B]*/ foo();

/*element: test4:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test4() => new C(). /*invoke: [exact=C]*/ foo();

/*element: test5:Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/
test5() => (a ? new A() : new B())
    // ignore: undefined_method
    . /*invoke: [subclass=A]*/ foo();

/*element: test6:Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/
test6() => (a ? new B() : new C()). /*invoke: [subclass=B]*/ foo();

/*element: main:[null]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}
