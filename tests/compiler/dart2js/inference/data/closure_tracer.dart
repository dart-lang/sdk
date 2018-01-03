// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: testFunctionStatement:[null|exact=JSUInt31]*/
testFunctionStatement() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  closure(42);
  return res;
}

/*element: testFunctionExpression:[null|exact=JSUInt31]*/
testFunctionExpression() {
  var res;
  var closure = /*[exact=JSUInt31]*/ (/*[exact=JSUInt31]*/ a) => res = a;
  closure(42);
  return res;
}

/*element: staticField:[null|subclass=Closure]*/
var staticField;

/*element: testStoredInStatic:[null|exact=JSUInt31]*/
testStoredInStatic() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  staticField = closure;
  staticField(42);
  return res;
}

class A {
  /*element: A.field:[subclass=Closure]*/
  var field;
  /*element: A.:[exact=A]*/
  A(this. /*[subclass=Closure]*/ field);

  /*element: A.foo:[exact=JSUInt31]*/
  static foo(/*[exact=JSUInt31]*/ a) => topLevel3 = a;
}

/*element: testStoredInInstance:[null|exact=JSUInt31]*/
testStoredInInstance() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  var a = new A(closure);
  a. /*invoke: [exact=A]*/ field(42);
  return res;
}

/*element: testStoredInMapOfList:[null|subclass=Object]*/
testStoredInMapOfList() {
  var res;
  /*[null|subclass=Object]*/ closure(/*[null|subclass=Object]*/ a) => res = a;
  dynamic a = [closure];
  dynamic b = {'foo': 1};

  b
      /*update: Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSUInt31], [null|exact=JSExtendableArray]), map: {foo: [exact=JSUInt31], bar: Container([null|exact=JSExtendableArray], element: [null|subclass=Object], length: null)})*/
      ['bar'] = a;

  b
          /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSUInt31], [null|exact=JSExtendableArray]), map: {foo: [exact=JSUInt31], bar: Container([null|exact=JSExtendableArray], element: [null|subclass=Object], length: null)})*/
          ['bar']

      /*Container([null|exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
      [0](42);
  return res;
}

/*element: testStoredInListOfList:[null|exact=JSUInt31]*/
testStoredInListOfList() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  dynamic a = [closure];
  dynamic b = [0, 1, 2];

  b
      /*update: Container([exact=JSExtendableArray], element: Union([exact=JSExtendableArray], [exact=JSUInt31]), length: 3)*/
      [1] = a;

  b
          /*Container([exact=JSExtendableArray], element: Union([exact=JSExtendableArray], [exact=JSUInt31]), length: 3)*/
          [1]
      /*Union([exact=JSExtendableArray], [exact=JSUInt31])*/
      [0](42);
  return res;
}

/*element: testStoredInListOfListUsingInsert:[null|exact=JSUInt31]*/
testStoredInListOfListUsingInsert() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  dynamic a = [closure];
  dynamic b = [0, 1, 2];

  b
      .
      /*invoke: Container([exact=JSExtendableArray], element: Union([exact=JSExtendableArray], [exact=JSUInt31]), length: null)*/
      insert(1, a);

  b /*Container([exact=JSExtendableArray], element: Union([exact=JSExtendableArray], [exact=JSUInt31]), length: null)*/
          [1]
      /*Union([exact=JSExtendableArray], [exact=JSUInt31])*/
      [0](42);
  return res;
}

/*element: testStoredInListOfListUsingAdd:[null|exact=JSUInt31]*/
testStoredInListOfListUsingAdd() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  dynamic a = [closure];
  dynamic b = [0, 1, 2];

  b
      .
      /*invoke: Container([exact=JSExtendableArray], element: Union([exact=JSExtendableArray], [exact=JSUInt31]), length: null)*/
      add(a);

  b
          /*Container([exact=JSExtendableArray], element: Union([exact=JSExtendableArray], [exact=JSUInt31]), length: null)*/
          [3]
      /*Union([exact=JSExtendableArray], [exact=JSUInt31])*/
      [0](42);
  return res;
}

/*element: foo:[null]*/
foo(/*[subclass=Closure]*/ closure) {
  closure(42);
}

/*element: testPassedInParameter:[null|exact=JSUInt31]*/
testPassedInParameter() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  foo(closure);
  return res;
}

/*element: topLevel1:[null|exact=JSUInt31]*/
var topLevel1;
/*element: foo2:[exact=JSUInt31]*/
foo2(/*[exact=JSUInt31]*/ a) => topLevel1 = a;

/*element: testStaticClosure1:[null|exact=JSUInt31]*/
testStaticClosure1() {
  var a = foo2;
  a(42);
  return topLevel1;
}

/*element: topLevel2:Union([exact=JSUInt31], [null|exact=JSDouble])*/
var topLevel2;

/*element: bar:Union([exact=JSDouble], [exact=JSUInt31])*/
bar(/*Union([exact=JSDouble], [exact=JSUInt31])*/ a) => topLevel2 = a;

/*element: testStaticClosure2:Union([exact=JSUInt31], [null|exact=JSDouble])*/
testStaticClosure2() {
  var a = bar;
  a(42);
  var b = bar;
  b(2.5);
  return topLevel2;
}

/*element: topLevel3:[null|exact=JSUInt31]*/
var topLevel3;

/*element: testStaticClosure3:[null|exact=JSUInt31]*/ testStaticClosure3() {
  var a = A.foo;
  a(42);
  return topLevel3;
}

/*element: topLevel4:Union([exact=JSUInt31], [null|exact=JSDouble])*/
var topLevel4;

/*element: testStaticClosure4Helper:Union([exact=JSDouble], [exact=JSUInt31])*/
testStaticClosure4Helper(/*Union([exact=JSDouble], [exact=JSUInt31])*/ a) =>
    topLevel4 = a;

/*element: testStaticClosure4:Union([exact=JSUInt31], [null|exact=JSDouble])*/
testStaticClosure4() {
  var a = testStaticClosure4Helper;
  // Test calling the static after tearing it off.
  testStaticClosure4Helper(2.5);
  a(42);
  return topLevel4;
}

/*element: main:[null]*/
main() {
  testFunctionStatement();
  testFunctionExpression();
  testStoredInStatic();
  testStoredInInstance();
  testStoredInMapOfList();
  testStoredInListOfList();
  testStoredInListOfListUsingInsert();
  testStoredInListOfListUsingAdd();
  testPassedInParameter();
  testStaticClosure1();
  testStaticClosure2();
  testStaticClosure3();
  testStaticClosure4();
}
