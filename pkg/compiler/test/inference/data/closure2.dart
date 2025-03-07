// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: returnInt1:[exact=JSUInt31|powerset=0]*/
returnInt1() {
  var a = 42;
  // ignore: unused_local_variable
  var f = /*[exact=JSUInt31|powerset=0]*/ () {
    return a;
  };
  return a;
}

/*member: returnDyn1:Union([exact=JSUInt31|powerset=0], [exact=JsLinkedHashMap|powerset=0], powerset: 0)*/
returnDyn1() {
  dynamic a = 42;
  // ignore: unused_local_variable
  var f = /*[null|powerset=1]*/ () {
    a = {};
  };
  return a;
}

/*member: returnInt2:[exact=JSUInt31|powerset=0]*/
returnInt2() {
  var a = 42;
  // ignore: unused_local_variable
  var f = /*[null|powerset=1]*/ () {
    a = 54;
  };
  return a;
}

/*member: returnDyn2:Union([exact=JSUInt31|powerset=0], [exact=JsLinkedHashMap|powerset=0], powerset: 0)*/
returnDyn2() {
  dynamic a = 42;
  // ignore: unused_local_variable
  var f = /*[null|powerset=1]*/ () {
    a = 54;
  };
  // ignore: unused_local_variable
  var g = /*[null|powerset=1]*/ () {
    a = {};
  };
  return a;
}

/*member: returnInt3:[exact=JSUInt31|powerset=0]*/
returnInt3() {
  var a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset=0]*/ == 53) {
    // ignore: unused_local_variable
    var f = /*[exact=JSUInt31|powerset=0]*/ () {
      return a;
    };
  }
  return a;
}

/*member: returnDyn3:Union([exact=JSUInt31|powerset=0], [exact=JsLinkedHashMap|powerset=0], powerset: 0)*/
returnDyn3() {
  dynamic a = 42;
  if (a /*invoke: Union([exact=JSUInt31|powerset=0], [exact=JsLinkedHashMap|powerset=0], powerset: 0)*/ ==
      53) {
    // ignore: unused_local_variable
    var f = /*[null|powerset=1]*/ () {
      a = {};
    };
  }
  return a;
}

/*member: returnInt4:[exact=JSUInt31|powerset=0]*/
returnInt4() {
  var a = 42;
  /*[exact=JSUInt31|powerset=0]*/
  g() {
    return a;
  }

  return g();
}

/*member: returnNum1:Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
returnNum1() {
  dynamic a = 42.5;
  try {
    /*[exact=JSUInt31|powerset=0]*/
    g() {
      dynamic b = {};
      b = 42;
      return b;
    }

    a = g();
  } finally {}
  return a;
}

/*member: returnIntOrNull:[null|exact=JSUInt31|powerset=1]*/
returnIntOrNull() {
  /*iterator: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
  /*current: [exact=ArrayIterator|powerset=0]*/
  /*moveNext: [exact=ArrayIterator|powerset=0]*/
  for (
  // ignore: unused_local_variable
  var b in [42]) {
    int? bar = 42;
    /*[null|exact=JSUInt31|powerset=1]*/
    f() => bar;
    bar = null;
    return f();
  }
  return 42;
}

/*member: A.:[exact=A|powerset=0]*/
class A {
  /*member: A.foo:[exact=A|powerset=0]*/
  foo() {
    /*[exact=A|powerset=0]*/
    f() => this;
    return f();
  }
}

/*member: main:[null|powerset=1]*/
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
  A(). /*invoke: [exact=A|powerset=0]*/ foo();
}
