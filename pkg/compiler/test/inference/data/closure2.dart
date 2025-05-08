// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: returnInt1:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt1() {
  var a = 42;
  // ignore: unused_local_variable
  var f = /*[exact=JSUInt31|powerset={I}{O}{N}]*/ () {
    return a;
  };
  return a;
}

/*member: returnDyn1:Union([exact=JSUInt31|powerset={I}{O}{N}], [exact=JsLinkedHashMap|powerset={N}{O}{N}], powerset: {IN}{O}{N})*/
returnDyn1() {
  dynamic a = 42;
  // ignore: unused_local_variable
  var f = /*[null|powerset={null}]*/ () {
    a = {};
  };
  return a;
}

/*member: returnInt2:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt2() {
  var a = 42;
  // ignore: unused_local_variable
  var f = /*[null|powerset={null}]*/ () {
    a = 54;
  };
  return a;
}

/*member: returnDyn2:Union([exact=JSUInt31|powerset={I}{O}{N}], [exact=JsLinkedHashMap|powerset={N}{O}{N}], powerset: {IN}{O}{N})*/
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

/*member: returnInt3:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt3() {
  var a = 42;
  if (a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == 53) {
    // ignore: unused_local_variable
    var f = /*[exact=JSUInt31|powerset={I}{O}{N}]*/ () {
      return a;
    };
  }
  return a;
}

/*member: returnDyn3:Union([exact=JSUInt31|powerset={I}{O}{N}], [exact=JsLinkedHashMap|powerset={N}{O}{N}], powerset: {IN}{O}{N})*/
returnDyn3() {
  dynamic a = 42;
  if (a /*invoke: Union([exact=JSUInt31|powerset={I}{O}{N}], [exact=JsLinkedHashMap|powerset={N}{O}{N}], powerset: {IN}{O}{N})*/ ==
      53) {
    // ignore: unused_local_variable
    var f = /*[null|powerset={null}]*/ () {
      a = {};
    };
  }
  return a;
}

/*member: returnInt4:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInt4() {
  var a = 42;
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  g() {
    return a;
  }

  return g();
}

/*member: returnNum1:Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
returnNum1() {
  dynamic a = 42.5;
  try {
    /*[exact=JSUInt31|powerset={I}{O}{N}]*/
    g() {
      dynamic b = {};
      b = 42;
      return b;
    }

    a = g();
  } finally {}
  return a;
}

/*member: returnIntOrNull:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
returnIntOrNull() {
  /*iterator: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
  /*current: [exact=ArrayIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=ArrayIterator|powerset={N}{O}{N}]*/
  for (
  // ignore: unused_local_variable
  var b in [42]) {
    int? bar = 42;
    /*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
    f() => bar;
    bar = null;
    return f();
  }
  return 42;
}

/*member: A.:[exact=A|powerset={N}{O}{N}]*/
class A {
  /*member: A.foo:[exact=A|powerset={N}{O}{N}]*/
  foo() {
    /*[exact=A|powerset={N}{O}{N}]*/
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
  A(). /*invoke: [exact=A|powerset={N}{O}{N}]*/ foo();
}
