// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: testFunctionStatement:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testFunctionStatement() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => res = a;
  closure(42);
  return res;
}

/*member: testFunctionExpression:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testFunctionExpression() {
  var res;
  var closure = /*[exact=JSUInt31|powerset={I}{O}{N}]*/
      (/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => res = a;
  closure(42);
  return res;
}

/*member: staticField:[null|subclass=Closure|powerset={null}{N}{O}{N}]*/
var staticField;

/*member: testStoredInStatic:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testStoredInStatic() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => res = a;
  staticField = closure;
  staticField(42);
  return res;
}

class A {
  /*member: A.field:[subclass=Closure|powerset={N}{O}{N}]*/
  var field;
  /*member: A.:[exact=A|powerset={N}{O}{N}]*/
  A(this. /*[subclass=Closure|powerset={N}{O}{N}]*/ field);

  /*member: A.foo:[exact=JSUInt31|powerset={I}{O}{N}]*/
  static foo(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => topLevel3 = a;
}

/*member: testStoredInInstance:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testStoredInInstance() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => res = a;
  var a = A(closure);
  a.field /*invoke: [exact=A|powerset={N}{O}{N}]*/ (42);
  return res;
}

/*member: testStoredInMapOfList:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testStoredInMapOfList() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic, dynamic>{'foo': 1};

  b
      /*update: Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{MN}), map: {foo: [exact=JSUInt31|powerset={I}{O}{N}], bar: Container([null|exact=JSExtendableArray|powerset={null}{I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: 1, powerset: {null}{I}{G}{M})}, powerset: {N}{O}{N})*/
      ['bar'] =
      a;

  b
  /*Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{GO}{MN}), map: {foo: [exact=JSUInt31|powerset={I}{O}{N}], bar: Container([null|exact=JSExtendableArray|powerset={null}{I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: 1, powerset: {null}{I}{G}{M})}, powerset: {N}{O}{N})*/
  ['bar']
  /*Container([null|exact=JSExtendableArray|powerset={null}{I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: 1, powerset: {null}{I}{G}{M})*/
  [0](42);
  return res;
}

/*member: testStoredInListOfList:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testStoredInListOfList() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{GO}{MN}), length: 3, powerset: {I}{G}{M})*/
      [1] =
      a;

  b
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{GO}{MN}), length: 3, powerset: {I}{G}{M})*/
  [1]
  /*Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{GO}{MN})*/
  [0](42);
  return res;
}

/*member: testStoredInListOfListUsingInsert:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testStoredInListOfListUsingInsert() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b.
  /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{GO}{MN}), length: null, powerset: {I}{G}{M})*/
  insert(1, a);

  b /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{GO}{MN}), length: null, powerset: {I}{G}{M})*/ [1]
  /*Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{GO}{MN})*/
  [0](42);
  return res;
}

/*member: testStoredInListOfListUsingAdd:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testStoredInListOfListUsingAdd() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b.
  /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{GO}{MN}), length: null, powerset: {I}{G}{M})*/
  add(a);

  b
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{GO}{MN}), length: null, powerset: {I}{G}{M})*/
  [3]
  /*Union([exact=JSExtendableArray|powerset={I}{G}{M}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{GO}{MN})*/
  [0](42);
  return res;
}

/*member: testStoredInRecord:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testStoredInRecord() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => res = a;
  final a = (3, closure);

  a. /*[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}{O}{N}], [subclass=Closure|powerset={N}{O}{N}]], powerset: {N}{O}{N})]*/ $2(
    42,
  );
  return res;
}

/*member: foo:[null|powerset={null}]*/
foo(/*[subclass=Closure|powerset={N}{O}{N}]*/ closure) {
  closure(42);
}

/*member: testPassedInParameter:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testPassedInParameter() {
  var res;
  /*[exact=JSUInt31|powerset={I}{O}{N}]*/
  closure(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => res = a;
  foo(closure);
  return res;
}

/*member: topLevel1:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
var topLevel1;
/*member: foo2:[exact=JSUInt31|powerset={I}{O}{N}]*/
foo2(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a) => topLevel1 = a;

/*member: testStaticClosure1:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testStaticClosure1() {
  var a = foo2;
  a(42);
  return topLevel1;
}

/*member: topLevel2:Union(null, [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{N})*/
var topLevel2;

/*member: bar:Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
bar(
  /*Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/ a,
) => topLevel2 = a;

/*member: testStaticClosure2:Union(null, [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{N})*/
testStaticClosure2() {
  var a = bar;
  a(42);
  var b = bar;
  b(2.5);
  return topLevel2;
}

/*member: topLevel3:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
var topLevel3;

/*member: testStaticClosure3:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
testStaticClosure3() {
  var a = A.foo;
  a(42);
  return topLevel3;
}

/*member: topLevel4:Union(null, [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{N})*/
var topLevel4;

/*member: testStaticClosure4Helper:Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
testStaticClosure4Helper(
  /*Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/ a,
) => topLevel4 = a;

/*member: testStaticClosure4:Union(null, [exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{N})*/
testStaticClosure4() {
  var a = testStaticClosure4Helper;
  // Test calling the static after tearing it off.
  testStaticClosure4Helper(2.5);
  a(42);
  return topLevel4;
}

/*member: bar1:[subclass=Closure|powerset={N}{O}{N}]*/
int Function(int, [int]) bar1(
  int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ a,
) => /*[subclass=JSInt|powerset={I}{O}{N}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ /*prod.[subclass=JSInt|powerset={I}{O}{N}]*/
      b, [
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ /*prod.[subclass=JSInt|powerset={I}{O}{N}]*/
          c =
          17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ +
        c;
/*member: bar2:[subclass=Closure|powerset={N}{O}{N}]*/
int Function(int, [int]) bar2(
  int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ a,
) => /*[subclass=JSInt|powerset={I}{O}{N}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ /*prod.[subclass=JSInt|powerset={I}{O}{N}]*/
      b, [
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ /*prod.[subclass=JSInt|powerset={I}{O}{N}]*/
          c =
          17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ +
        c;
/*member: bar3:[subclass=Closure|powerset={N}{O}{N}]*/
int Function(int, [int]) bar3(
  int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ a,
) => /*[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
    (
      int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ b, [
      int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ c = 17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ +
        b /*invoke: [subclass=JSUInt32|powerset={I}{O}{N}]*/ +
        c;
/*member: bar4:[subclass=Closure|powerset={N}{O}{N}]*/
num Function(int, [int]) bar4(
  int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ a,
) => /*[subclass=JSNumber|powerset={I}{O}{N}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ /*prod.[subclass=JSInt|powerset={I}{O}{N}]*/
      b, [
      dynamic /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ c,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ +
        c;
/*member: bar5:[subclass=Closure|powerset={N}{O}{N}]*/
num Function(int, [int]) bar5(
  int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ a,
) => /*[subclass=JSNumber|powerset={I}{O}{N}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ /*prod.[subclass=JSInt|powerset={I}{O}{N}]*/
      b, [
      num? /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/ /*prod.[null|subclass=JSNumber|powerset={null}{I}{O}{N}]*/
      c,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ +
        (c ?? 0);

/*member: testFunctionApply:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testFunctionApply() {
  return Function.apply(bar1(10), [20]);
}

/*member: testFunctionApplyNoDefault:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testFunctionApplyNoDefault() {
  Function.apply(bar4(10), [30]);
  return Function.apply(bar5(10), [30]);
}

/*member: testRecordFunctionApply:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
testRecordFunctionApply() {
  final rec = (bar2(10), bar3(10));
  (rec. /*[Record(RecordShape(2), [[subclass=Closure|powerset={N}{O}{N}], [subclass=Closure|powerset={N}{O}{N}]], powerset: {N}{O}{N})]*/ $2)(
    2,
    3,
  );
  return Function.apply(
    rec. /*[Record(RecordShape(2), [[subclass=Closure|powerset={N}{O}{N}], [subclass=Closure|powerset={N}{O}{N}]], powerset: {N}{O}{N})]*/ $1,
    [20],
  );
}

/*member: main:[null|powerset={null}]*/
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
