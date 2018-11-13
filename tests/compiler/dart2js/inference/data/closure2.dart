// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: returnInt1:[exact=JSUInt31]*/
returnInt1() {
  var a = 42;
  // ignore: unused_local_variable
  var f = /*[exact=JSUInt31]*/ () {
    return a;
  };
  return a;
}

/*element: returnDyn1:Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/
returnDyn1() {
  dynamic a = 42;
  // ignore: unused_local_variable
  var f = /*[null]*/ () {
    a = {};
  };
  return a;
}

/*element: returnInt2:[exact=JSUInt31]*/
returnInt2() {
  var a = 42;
  // ignore: unused_local_variable
  var f = /*[null]*/ () {
    a = 54;
  };
  return a;
}

/*element: returnDyn2:Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/
returnDyn2() {
  dynamic a = 42;
  // ignore: unused_local_variable
  var f = /*[null]*/ () {
    a = 54;
  };
  // ignore: unused_local_variable
  var g = /*[null]*/ () {
    a = {};
  };
  return a;
}

/*element: returnInt3:[exact=JSUInt31]*/
returnInt3() {
  var a = 42;
  if (a /*invoke: [exact=JSUInt31]*/ == 53) {
    // ignore: unused_local_variable
    var f = /*[exact=JSUInt31]*/ () {
      return a;
    };
  }
  return a;
}

/*element: returnDyn3:Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/
returnDyn3() {
  dynamic a = 42;
  if (a /*invoke: Union([exact=JSUInt31], [subclass=JsLinkedHashMap])*/ == 53) {
    // ignore: unused_local_variable
    var f = /*[null]*/ () {
      a = {};
    };
  }
  return a;
}

/*element: returnInt4:[exact=JSUInt31]*/
returnInt4() {
  var a = 42;
  /*[exact=JSUInt31]*/ g() {
    return a;
  }

  return g();
}

/*element: returnNum1:Union([exact=JSDouble], [exact=JSUInt31])*/
returnNum1() {
  dynamic a = 42.5;
  try {
    /*[exact=JSUInt31]*/ g() {
      dynamic b = {};
      b = 42;
      return b;
    }

    a = g();
  } finally {}
  return a;
}

/*element: returnIntOrNull:[null|exact=JSUInt31]*/
returnIntOrNull() {
  /*iterator: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (
      // ignore: unused_local_variable
      var b in [42]) {
    var bar = 42;
    /*[null|exact=JSUInt31]*/ f() => bar;
    bar = null;
    return f();
  }
  return 42;
}

/*element: A.:[exact=A]*/
class A {
  /*element: A.foo:[exact=A]*/
  foo() {
    /*[exact=A]*/ f() => this;
    return f();
  }
}

/*element: main:[null]*/
main() {
  returnInt1();
  returnDyn1();
  returnInt2();
  returnDyn2();
  returnInt3();
  returnDyn3();
  returnInt4();
  returnNum1();
  returnIntOrNull();
  new A(). /*invoke: [exact=A]*/ foo();
}
