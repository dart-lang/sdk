// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: testFunctionStatement:[null|exact=JSUInt31]*/
testFunctionStatement() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  closure(42);
  return res;
}

/*member: testFunctionExpression:[null|exact=JSUInt31]*/
testFunctionExpression() {
  var res;
  var closure = /*[exact=JSUInt31]*/ (/*[exact=JSUInt31]*/ a) => res = a;
  closure(42);
  return res;
}

/*member: staticField:[null|subclass=Closure]*/
var staticField;

/*member: testStoredInStatic:[null|exact=JSUInt31]*/
testStoredInStatic() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  staticField = closure;
  staticField(42);
  return res;
}

class A {
  /*member: A.field:[subclass=Closure]*/
  var field;
  /*member: A.:[exact=A]*/
  A(this. /*[subclass=Closure]*/ field);

  /*member: A.foo:[exact=JSUInt31]*/
  static foo(/*[exact=JSUInt31]*/ a) => topLevel3 = a;
}

/*member: testStoredInInstance:[null|exact=JSUInt31]*/
testStoredInInstance() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  var a = A(closure);
  a.field /*invoke: [exact=A]*/ (42);
  return res;
}

/*member: testStoredInMapOfList:[null|exact=JSUInt31]*/
testStoredInMapOfList() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic, dynamic>{'foo': 1};

  b
      /*update: Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSExtendableArray], [exact=JSUInt31]), map: {foo: [exact=JSUInt31], bar: Container([null|exact=JSExtendableArray], element: [subclass=Closure], length: 1)})*/
      ['bar'] = a;

  b
          /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSExtendableArray], [exact=JSUInt31]), map: {foo: [exact=JSUInt31], bar: Container([null|exact=JSExtendableArray], element: [subclass=Closure], length: 1)})*/
          ['bar']

      /*Container([null|exact=JSExtendableArray], element: [subclass=Closure], length: 1)*/
      [0](42);
  return res;
}

/*member: testStoredInListOfList:[null|exact=JSUInt31]*/
testStoredInListOfList() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

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

/*member: testStoredInListOfListUsingInsert:[null|exact=JSUInt31]*/
testStoredInListOfListUsingInsert() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

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

/*member: testStoredInListOfListUsingAdd:[null|exact=JSUInt31]*/
testStoredInListOfListUsingAdd() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

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

/*member: testStoredInRecord:[null|exact=JSUInt31]*/
testStoredInRecord() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  final a = (3, closure);

  a. /*[Record(RecordShape(2), [[exact=JSUInt31], [subclass=Closure]])]*/ $2(
      42);
  return res;
}

/*member: foo:[null]*/
foo(/*[subclass=Closure]*/ closure) {
  closure(42);
}

/*member: testPassedInParameter:[null|exact=JSUInt31]*/
testPassedInParameter() {
  var res;
  /*[exact=JSUInt31]*/ closure(/*[exact=JSUInt31]*/ a) => res = a;
  foo(closure);
  return res;
}

/*member: topLevel1:[null|exact=JSUInt31]*/
var topLevel1;
/*member: foo2:[exact=JSUInt31]*/
foo2(/*[exact=JSUInt31]*/ a) => topLevel1 = a;

/*member: testStaticClosure1:[null|exact=JSUInt31]*/
testStaticClosure1() {
  var a = foo2;
  a(42);
  return topLevel1;
}

/*member: topLevel2:Union(null, [exact=JSNumNotInt], [exact=JSUInt31])*/
var topLevel2;

/*member: bar:Union([exact=JSNumNotInt], [exact=JSUInt31])*/
bar(/*Union([exact=JSNumNotInt], [exact=JSUInt31])*/ a) => topLevel2 = a;

/*member: testStaticClosure2:Union(null, [exact=JSNumNotInt], [exact=JSUInt31])*/
testStaticClosure2() {
  var a = bar;
  a(42);
  var b = bar;
  b(2.5);
  return topLevel2;
}

/*member: topLevel3:[null|exact=JSUInt31]*/
var topLevel3;

/*member: testStaticClosure3:[null|exact=JSUInt31]*/ testStaticClosure3() {
  var a = A.foo;
  a(42);
  return topLevel3;
}

/*member: topLevel4:Union(null, [exact=JSNumNotInt], [exact=JSUInt31])*/
var topLevel4;

/*member: testStaticClosure4Helper:Union([exact=JSNumNotInt], [exact=JSUInt31])*/
testStaticClosure4Helper(/*Union([exact=JSNumNotInt], [exact=JSUInt31])*/ a) =>
    topLevel4 = a;

/*member: testStaticClosure4:Union(null, [exact=JSNumNotInt], [exact=JSUInt31])*/
testStaticClosure4() {
  var a = testStaticClosure4Helper;
  // Test calling the static after tearing it off.
  testStaticClosure4Helper(2.5);
  a(42);
  return topLevel4;
}

/*member: bar1:[subclass=Closure]*/
int Function(int, [int]) bar1(
        int /*[exact=JSUInt31]*/ a) => /*[subclass=JSInt]*/
    (int /*spec.[null|subclass=Object]*/ /*prod.[null|subclass=JSInt]*/ b,
            [int /*spec.[null|subclass=Object]*/ /*prod.[null|subclass=JSInt]*/
                c = 17]) =>
        a /*invoke: [exact=JSUInt31]*/ + b /*invoke: [subclass=JSInt]*/ + c;
/*member: bar2:[subclass=Closure]*/
int Function(int, [int]) bar2(
        int /*[exact=JSUInt31]*/ a) => /*[subclass=JSInt]*/
    (int /*spec.[null|subclass=Object]*/ /*prod.[null|subclass=JSInt]*/ b,
            [int /*spec.[null|subclass=Object]*/ /*prod.[null|subclass=JSInt]*/
                c = 17]) =>
        a /*invoke: [exact=JSUInt31]*/ + b /*invoke: [subclass=JSInt]*/ + c;
/*member: bar3:[subclass=Closure]*/
int Function(int, [int]) bar3(
        int /*[exact=JSUInt31]*/ a) => /*[subclass=JSPositiveInt]*/
    (int /*[exact=JSUInt31]*/ b, [int /*[exact=JSUInt31]*/ c = 17]) =>
        a /*invoke: [exact=JSUInt31]*/ + b /*invoke: [subclass=JSUInt32]*/ + c;

/*member: testFunctionApply:[null|subclass=Object]*/
testFunctionApply() {
  return Function.apply(bar1(10), [20]);
}

/*member: testRecordFunctionApply:[null|subclass=Object]*/
testRecordFunctionApply() {
  final rec = (bar2(10), bar3(10));
  (rec. /*[Record(RecordShape(2), [[subclass=Closure], [subclass=Closure]])]*/ $2)(
      2, 3);
  return Function.apply(
      rec. /*[Record(RecordShape(2), [[subclass=Closure], [subclass=Closure]])]*/ $1,
      [20]);
}

/*member: main:[null]*/
main() {
  testFunctionStatement();
  testFunctionExpression();
  testStoredInStatic();
  testStoredInInstance();
  testStoredInMapOfList();
  testStoredInListOfList();
  testStoredInListOfListUsingInsert();
  testStoredInListOfListUsingAdd();
  testStoredInRecord();
  testPassedInParameter();
  testStaticClosure1();
  testStaticClosure2();
  testStaticClosure3();
  testStaticClosure4();
  testFunctionApply();
  testRecordFunctionApply();
}
