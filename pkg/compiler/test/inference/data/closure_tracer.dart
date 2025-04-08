// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: testFunctionStatement:[null|exact=JSUInt31|powerset=1]*/
testFunctionStatement() {
  var res;
  /*[exact=JSUInt31|powerset=0]*/
  closure(/*[exact=JSUInt31|powerset=0]*/ a) => res = a;
  closure(42);
  return res;
}

/*member: testFunctionExpression:[null|exact=JSUInt31|powerset=1]*/
testFunctionExpression() {
  var res;
  var closure = /*[exact=JSUInt31|powerset=0]*/
      (/*[exact=JSUInt31|powerset=0]*/ a) => res = a;
  closure(42);
  return res;
}

/*member: staticField:[null|subclass=Closure|powerset=1]*/
var staticField;

/*member: testStoredInStatic:[null|exact=JSUInt31|powerset=1]*/
testStoredInStatic() {
  var res;
  /*[exact=JSUInt31|powerset=0]*/
  closure(/*[exact=JSUInt31|powerset=0]*/ a) => res = a;
  staticField = closure;
  staticField(42);
  return res;
}

class A {
  /*member: A.field:[subclass=Closure|powerset=0]*/
  var field;
  /*member: A.:[exact=A|powerset=0]*/
  A(this. /*[subclass=Closure|powerset=0]*/ field);

  /*member: A.foo:[exact=JSUInt31|powerset=0]*/
  static foo(/*[exact=JSUInt31|powerset=0]*/ a) => topLevel3 = a;
}

/*member: testStoredInInstance:[null|exact=JSUInt31|powerset=1]*/
testStoredInInstance() {
  var res;
  /*[exact=JSUInt31|powerset=0]*/
  closure(/*[exact=JSUInt31|powerset=0]*/ a) => res = a;
  var a = A(closure);
  a.field /*invoke: [exact=A|powerset=0]*/ (42);
  return res;
}

/*member: testStoredInMapOfList:[null|exact=JSUInt31|powerset=1]*/
testStoredInMapOfList() {
  var res;
  /*[exact=JSUInt31|powerset=0]*/
  closure(/*[exact=JSUInt31|powerset=0]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic, dynamic>{'foo': 1};

  b
      /*update: Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {foo: [exact=JSUInt31|powerset=0], bar: Container([null|exact=JSExtendableArray|powerset=1], element: [subclass=Closure|powerset=0], length: 1, powerset: 1)}, powerset: 0)*/
      ['bar'] =
      a;

  b
  /*Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: Union(null, [exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), map: {foo: [exact=JSUInt31|powerset=0], bar: Container([null|exact=JSExtendableArray|powerset=1], element: [subclass=Closure|powerset=0], length: 1, powerset: 1)}, powerset: 0)*/
  ['bar']
  /*Container([null|exact=JSExtendableArray|powerset=1], element: [subclass=Closure|powerset=0], length: 1, powerset: 1)*/
  [0](42);
  return res;
}

/*member: testStoredInListOfList:[null|exact=JSUInt31|powerset=1]*/
testStoredInListOfList() {
  var res;
  /*[exact=JSUInt31|powerset=0]*/
  closure(/*[exact=JSUInt31|powerset=0]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b
      /*update: Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), length: 3, powerset: 0)*/
      [1] =
      a;

  b
  /*Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), length: 3, powerset: 0)*/
  [1]
  /*Union([exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  [0](42);
  return res;
}

/*member: testStoredInListOfListUsingInsert:[null|exact=JSUInt31|powerset=1]*/
testStoredInListOfListUsingInsert() {
  var res;
  /*[exact=JSUInt31|powerset=0]*/
  closure(/*[exact=JSUInt31|powerset=0]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b.
  /*invoke: Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), length: null, powerset: 0)*/
  insert(1, a);

  b /*Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), length: null, powerset: 0)*/ [1]
  /*Union([exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  [0](42);
  return res;
}

/*member: testStoredInListOfListUsingAdd:[null|exact=JSUInt31|powerset=1]*/
testStoredInListOfListUsingAdd() {
  var res;
  /*[exact=JSUInt31|powerset=0]*/
  closure(/*[exact=JSUInt31|powerset=0]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b.
  /*invoke: Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), length: null, powerset: 0)*/
  add(a);

  b
  /*Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), length: null, powerset: 0)*/
  [3]
  /*Union([exact=JSExtendableArray|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  [0](42);
  return res;
}

/*member: testStoredInRecord:[null|exact=JSUInt31|powerset=1]*/
testStoredInRecord() {
  var res;
  /*[exact=JSUInt31|powerset=0]*/
  closure(/*[exact=JSUInt31|powerset=0]*/ a) => res = a;
  final a = (3, closure);

  a. /*[Record(RecordShape(2), [[exact=JSUInt31|powerset=0], [subclass=Closure|powerset=0]], powerset: 0)]*/ $2(
    42,
  );
  return res;
}

/*member: foo:[null|powerset=1]*/
foo(/*[subclass=Closure|powerset=0]*/ closure) {
  closure(42);
}

/*member: testPassedInParameter:[null|exact=JSUInt31|powerset=1]*/
testPassedInParameter() {
  var res;
  /*[exact=JSUInt31|powerset=0]*/
  closure(/*[exact=JSUInt31|powerset=0]*/ a) => res = a;
  foo(closure);
  return res;
}

/*member: topLevel1:[null|exact=JSUInt31|powerset=1]*/
var topLevel1;
/*member: foo2:[exact=JSUInt31|powerset=0]*/
foo2(/*[exact=JSUInt31|powerset=0]*/ a) => topLevel1 = a;

/*member: testStaticClosure1:[null|exact=JSUInt31|powerset=1]*/
testStaticClosure1() {
  var a = foo2;
  a(42);
  return topLevel1;
}

/*member: topLevel2:Union(null, [exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1)*/
var topLevel2;

/*member: bar:Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
bar(
  /*Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ a,
) => topLevel2 = a;

/*member: testStaticClosure2:Union(null, [exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1)*/
testStaticClosure2() {
  var a = bar;
  a(42);
  var b = bar;
  b(2.5);
  return topLevel2;
}

/*member: topLevel3:[null|exact=JSUInt31|powerset=1]*/
var topLevel3;

/*member: testStaticClosure3:[null|exact=JSUInt31|powerset=1]*/
testStaticClosure3() {
  var a = A.foo;
  a(42);
  return topLevel3;
}

/*member: topLevel4:Union(null, [exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1)*/
var topLevel4;

/*member: testStaticClosure4Helper:Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
testStaticClosure4Helper(
  /*Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ a,
) => topLevel4 = a;

/*member: testStaticClosure4:Union(null, [exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1)*/
testStaticClosure4() {
  var a = testStaticClosure4Helper;
  // Test calling the static after tearing it off.
  testStaticClosure4Helper(2.5);
  a(42);
  return topLevel4;
}

/*member: bar1:[subclass=Closure|powerset=0]*/
int Function(int, [int]) bar1(
  int /*[exact=JSUInt31|powerset=0]*/ a,
) => /*[subclass=JSInt|powerset=0]*/
    (
      int /*spec.[null|subclass=Object|powerset=1]*/ /*prod.[subclass=JSInt|powerset=0]*/
      b, [
      int /*spec.[null|subclass=Object|powerset=1]*/ /*prod.[subclass=JSInt|powerset=0]*/
          c =
          17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset=0]*/ +
        b /*invoke: [subclass=JSInt|powerset=0]*/ +
        c;
/*member: bar2:[subclass=Closure|powerset=0]*/
int Function(int, [int]) bar2(
  int /*[exact=JSUInt31|powerset=0]*/ a,
) => /*[subclass=JSInt|powerset=0]*/
    (
      int /*spec.[null|subclass=Object|powerset=1]*/ /*prod.[subclass=JSInt|powerset=0]*/
      b, [
      int /*spec.[null|subclass=Object|powerset=1]*/ /*prod.[subclass=JSInt|powerset=0]*/
          c =
          17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset=0]*/ +
        b /*invoke: [subclass=JSInt|powerset=0]*/ +
        c;
/*member: bar3:[subclass=Closure|powerset=0]*/
int Function(int, [int]) bar3(
  int /*[exact=JSUInt31|powerset=0]*/ a,
) => /*[subclass=JSPositiveInt|powerset=0]*/
    (
      int /*[exact=JSUInt31|powerset=0]*/ b, [
      int /*[exact=JSUInt31|powerset=0]*/ c = 17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset=0]*/ +
        b /*invoke: [subclass=JSUInt32|powerset=0]*/ +
        c;
/*member: bar4:[subclass=Closure|powerset=0]*/
num Function(int, [int]) bar4(
  int /*[exact=JSUInt31|powerset=0]*/ a,
) => /*[subclass=JSNumber|powerset=0]*/
    (
      int /*spec.[null|subclass=Object|powerset=1]*/ /*prod.[subclass=JSInt|powerset=0]*/
      b, [
      dynamic /*[null|subclass=Object|powerset=1]*/ c,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset=0]*/ +
        b /*invoke: [subclass=JSInt|powerset=0]*/ +
        c;
/*member: bar5:[subclass=Closure|powerset=0]*/
num Function(int, [int]) bar5(
  int /*[exact=JSUInt31|powerset=0]*/ a,
) => /*[subclass=JSNumber|powerset=0]*/
    (
      int /*spec.[null|subclass=Object|powerset=1]*/ /*prod.[subclass=JSInt|powerset=0]*/
      b, [
      num? /*spec.[null|subclass=Object|powerset=1]*/ /*prod.[null|subclass=JSNumber|powerset=1]*/
      c,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset=0]*/ +
        b /*invoke: [subclass=JSInt|powerset=0]*/ +
        (c ?? 0);

/*member: testFunctionApply:[null|subclass=Object|powerset=1]*/
testFunctionApply() {
  return Function.apply(bar1(10), [20]);
}

/*member: testFunctionApplyNoDefault:[null|subclass=Object|powerset=1]*/
testFunctionApplyNoDefault() {
  Function.apply(bar4(10), [30]);
  return Function.apply(bar5(10), [30]);
}

/*member: testRecordFunctionApply:[null|subclass=Object|powerset=1]*/
testRecordFunctionApply() {
  final rec = (bar2(10), bar3(10));
  (rec. /*[Record(RecordShape(2), [[subclass=Closure|powerset=0], [subclass=Closure|powerset=0]], powerset: 0)]*/ $2)(
    2,
    3,
  );
  return Function.apply(
    rec. /*[Record(RecordShape(2), [[subclass=Closure|powerset=0], [subclass=Closure|powerset=0]], powerset: 0)]*/ $1,
    [20],
  );
}

/*member: main:[null|powerset=1]*/
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
  testFunctionApplyNoDefault();
  testRecordFunctionApply();
}
