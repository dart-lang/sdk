// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: A.:[exact=A]*/
class A {
  // We may ignore this for type inference because it forwards to a default
  // noSuchMethod implementation, which always throws an exception.
  noSuchMethod(im) => super.noSuchMethod(im);
}

/*element: B.:[exact=B]*/
class B extends A {
  /*element: B.foo:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/ foo() =>
      {};
}

/*element: C.:[exact=C]*/
class C extends B {
  /*element: C.foo:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/ foo() =>
      {};
}

/*element: a:[null|subclass=B]*/
dynamic a = [new B(), new C()]
    /*Container([exact=JSExtendableArray], element: [subclass=B], length: 2)*/
    [0];

/*element: test1:[empty]*/
test1() => new A()
    // ignore: undefined_method
    . /*invoke: [exact=A]*/ foo();

/*element: test2:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test2() => a. /*invoke: [null|subclass=B]*/ foo();

/*element: test3:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test3() => new B(). /*invoke: [exact=B]*/ foo();

/*element: test4:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test4() => new C(). /*invoke: [exact=C]*/ foo();

/*element: test5:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
test5() => (a ? new A() : new B())
    // ignore: undefined_method
    . /*invoke: [subclass=A]*/ foo();

/*element: test6:Dictionary([subclass=JsLinkedHashMap], key: [empty], value: [null], map: {})*/
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
