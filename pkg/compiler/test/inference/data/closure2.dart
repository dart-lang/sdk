// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: returnInt1:[exact=JSUInt31|powerset={I}{O}]*/
returnInt1() {
  var a = 42;
  // ignore: unused_local_variable
  var f = /*[exact=JSUInt31|powerset={I}{O}]*/ () {
    return a;
  };
  return a;
}

/*member: returnDyn1:Union([exact=JSUInt31|powerset={I}{O}], [exact=JsLinkedHashMap|powerset={N}{O}], powerset: {IN}{O})*/
returnDyn1() {
  dynamic a = 42;
  // ignore: unused_local_variable
  var f = /*[null|powerset={null}]*/ () {
    a = {};
  };
  return a;
}

/*member: returnInt2:[exact=JSUInt31|powerset={I}{O}]*/
returnInt2() {
  var a = 42;
  // ignore: unused_local_variable
  var f = /*[null|powerset={null}]*/ () {
    a = 54;
  };
  return a;
}

/*member: returnDyn2:Union([exact=JSUInt31|powerset={I}{O}], [exact=JsLinkedHashMap|powerset={N}{O}], powerset: {IN}{O})*/
returnDyn2() {
  dynamic a = 42;
  // ignore: unused_local_variable
  var f = /*[null|powerset={null}]*/ () {
    a = 54;
  };
  // ignore: unused_local_variable
  var g = /*[null|powerset={null}]*/ () {
    a = {};
  };
  return a;
}

/*member: returnInt3:[exact=JSUInt31|powerset={I}{O}]*/
returnInt3() {
  var a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ == 53) {
    // ignore: unused_local_variable
    var f = /*[exact=JSUInt31|powerset={I}{O}]*/ () {
      return a;
    };
  }
  return a;
}

/*member: returnDyn3:Union([exact=JSUInt31|powerset={I}{O}], [exact=JsLinkedHashMap|powerset={N}{O}], powerset: {IN}{O})*/
returnDyn3() {
  dynamic a = 42;
  if (a /*invoke: Union([exact=JSUInt31|powerset={I}{O}], [exact=JsLinkedHashMap|powerset={N}{O}], powerset: {IN}{O})*/ ==
      53) {
    // ignore: unused_local_variable
    var f = /*[null|powerset={null}]*/ () {
      a = {};
    };
  }
  return a;
}

/*member: returnInt4:[exact=JSUInt31|powerset={I}{O}]*/
returnInt4() {
  var a = 42;
  /*[exact=JSUInt31|powerset={I}{O}]*/
  g() {
    return a;
  }

  return g();
}

/*member: returnNum1:Union([exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
returnNum1() {
  dynamic a = 42.5;
  try {
    /*[exact=JSUInt31|powerset={I}{O}]*/
    g() {
      dynamic b = {};
      b = 42;
      return b;
    }

    a = g();
  } finally {}
  return a;
}

/*member: returnIntOrNull:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
returnIntOrNull() {
  /*iterator: Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  /*current: [exact=ArrayIterator|powerset={N}{O}]*/
  /*moveNext: [exact=ArrayIterator|powerset={N}{O}]*/
  for (
  // ignore: unused_local_variable
  var b in [42]) {
    int? bar = 42;
    /*[null|exact=JSUInt31|powerset={null}{I}{O}]*/
    f() => bar;
    bar = null;
    return f();
  }
  return 42;
}

/*member: A.:[exact=A|powerset={N}{O}]*/
class A {
  /*member: A.foo:[exact=A|powerset={N}{O}]*/
  foo() {
    /*[exact=A|powerset={N}{O}]*/
    f() => this;
    return f();
  }
}

/*member: main:[null|powerset={null}]*/
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
  A(). /*invoke: [exact=A|powerset={N}{O}]*/ foo();
}
