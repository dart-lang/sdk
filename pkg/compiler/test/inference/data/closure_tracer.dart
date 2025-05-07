// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: testFunctionStatement:[null|exact=JSUInt31|powerset={null}{I}]*/
testFunctionStatement() {
  var res;
  /*[exact=JSUInt31|powerset={I}]*/
  closure(/*[exact=JSUInt31|powerset={I}]*/ a) => res = a;
  closure(42);
  return res;
}

/*member: testFunctionExpression:[null|exact=JSUInt31|powerset={null}{I}]*/
testFunctionExpression() {
  var res;
  var closure = /*[exact=JSUInt31|powerset={I}]*/
      (/*[exact=JSUInt31|powerset={I}]*/ a) => res = a;
  closure(42);
  return res;
}

/*member: staticField:[null|subclass=Closure|powerset={null}{N}]*/
var staticField;

/*member: testStoredInStatic:[null|exact=JSUInt31|powerset={null}{I}]*/
testStoredInStatic() {
  var res;
  /*[exact=JSUInt31|powerset={I}]*/
  closure(/*[exact=JSUInt31|powerset={I}]*/ a) => res = a;
  staticField = closure;
  staticField(42);
  return res;
}

class A {
  /*member: A.field:[subclass=Closure|powerset={N}]*/
  var field;
  /*member: A.:[exact=A|powerset={N}]*/
  A(this. /*[subclass=Closure|powerset={N}]*/ field);

  /*member: A.foo:[exact=JSUInt31|powerset={I}]*/
  static foo(/*[exact=JSUInt31|powerset={I}]*/ a) => topLevel3 = a;
}

/*member: testStoredInInstance:[null|exact=JSUInt31|powerset={null}{I}]*/
testStoredInInstance() {
  var res;
  /*[exact=JSUInt31|powerset={I}]*/
  closure(/*[exact=JSUInt31|powerset={I}]*/ a) => res = a;
  var a = A(closure);
  a.field /*invoke: [exact=A|powerset={N}]*/ (42);
  return res;
}

/*member: testStoredInMapOfList:[null|exact=JSUInt31|powerset={null}{I}]*/
testStoredInMapOfList() {
  var res;
  /*[exact=JSUInt31|powerset={I}]*/
  closure(/*[exact=JSUInt31|powerset={I}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic, dynamic>{'foo': 1};

  b
      /*update: Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: Union(null, [exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I}), map: {foo: [exact=JSUInt31|powerset={I}], bar: Container([null|exact=JSExtendableArray|powerset={null}{I}], element: [subclass=Closure|powerset={N}], length: 1, powerset: {null}{I})}, powerset: {N})*/
      ['bar'] =
      a;

  b
  /*Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: Union(null, [exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I}), map: {foo: [exact=JSUInt31|powerset={I}], bar: Container([null|exact=JSExtendableArray|powerset={null}{I}], element: [subclass=Closure|powerset={N}], length: 1, powerset: {null}{I})}, powerset: {N})*/
  ['bar']
  /*Container([null|exact=JSExtendableArray|powerset={null}{I}], element: [subclass=Closure|powerset={N}], length: 1, powerset: {null}{I})*/
  [0](42);
  return res;
}

/*member: testStoredInListOfList:[null|exact=JSUInt31|powerset={null}{I}]*/
testStoredInListOfList() {
  var res;
  /*[exact=JSUInt31|powerset={I}]*/
  closure(/*[exact=JSUInt31|powerset={I}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b
      /*update: Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), length: 3, powerset: {I})*/
      [1] =
      a;

  b
  /*Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), length: 3, powerset: {I})*/
  [1]
  /*Union([exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  [0](42);
  return res;
}

/*member: testStoredInListOfListUsingInsert:[null|exact=JSUInt31|powerset={null}{I}]*/
testStoredInListOfListUsingInsert() {
  var res;
  /*[exact=JSUInt31|powerset={I}]*/
  closure(/*[exact=JSUInt31|powerset={I}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b.
  /*invoke: Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), length: null, powerset: {I})*/
  insert(1, a);

  b /*Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), length: null, powerset: {I})*/ [1]
  /*Union([exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  [0](42);
  return res;
}

/*member: testStoredInListOfListUsingAdd:[null|exact=JSUInt31|powerset={null}{I}]*/
testStoredInListOfListUsingAdd() {
  var res;
  /*[exact=JSUInt31|powerset={I}]*/
  closure(/*[exact=JSUInt31|powerset={I}]*/ a) => res = a;
  dynamic a = <dynamic>[closure];
  dynamic b = <dynamic>[0, 1, 2];

  b.
  /*invoke: Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), length: null, powerset: {I})*/
  add(a);

  b
  /*Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), length: null, powerset: {I})*/
  [3]
  /*Union([exact=JSExtendableArray|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  [0](42);
  return res;
}

/*member: testStoredInRecord:[null|exact=JSUInt31|powerset={null}{I}]*/
testStoredInRecord() {
  var res;
  /*[exact=JSUInt31|powerset={I}]*/
  closure(/*[exact=JSUInt31|powerset={I}]*/ a) => res = a;
  final a = (3, closure);

  a. /*[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}], [subclass=Closure|powerset={N}]], powerset: {N})]*/ $2(
    42,
  );
  return res;
}

/*member: foo:[null|powerset={null}]*/
foo(/*[subclass=Closure|powerset={N}]*/ closure) {
  closure(42);
}

/*member: testPassedInParameter:[null|exact=JSUInt31|powerset={null}{I}]*/
testPassedInParameter() {
  var res;
  /*[exact=JSUInt31|powerset={I}]*/
  closure(/*[exact=JSUInt31|powerset={I}]*/ a) => res = a;
  foo(closure);
  return res;
}

/*member: topLevel1:[null|exact=JSUInt31|powerset={null}{I}]*/
var topLevel1;
/*member: foo2:[exact=JSUInt31|powerset={I}]*/
foo2(/*[exact=JSUInt31|powerset={I}]*/ a) => topLevel1 = a;

/*member: testStaticClosure1:[null|exact=JSUInt31|powerset={null}{I}]*/
testStaticClosure1() {
  var a = foo2;
  a(42);
  return topLevel1;
}

/*member: topLevel2:Union(null, [exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I})*/
var topLevel2;

/*member: bar:Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
bar(
  /*Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ a,
) => topLevel2 = a;

/*member: testStaticClosure2:Union(null, [exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I})*/
testStaticClosure2() {
  var a = bar;
  a(42);
  var b = bar;
  b(2.5);
  return topLevel2;
}

/*member: topLevel3:[null|exact=JSUInt31|powerset={null}{I}]*/
var topLevel3;

/*member: testStaticClosure3:[null|exact=JSUInt31|powerset={null}{I}]*/
testStaticClosure3() {
  var a = A.foo;
  a(42);
  return topLevel3;
}

/*member: topLevel4:Union(null, [exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I})*/
var topLevel4;

/*member: testStaticClosure4Helper:Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
testStaticClosure4Helper(
  /*Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ a,
) => topLevel4 = a;

/*member: testStaticClosure4:Union(null, [exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I})*/
testStaticClosure4() {
  var a = testStaticClosure4Helper;
  // Test calling the static after tearing it off.
  testStaticClosure4Helper(2.5);
  a(42);
  return topLevel4;
}

/*member: bar1:[subclass=Closure|powerset={N}]*/
int Function(int, [int]) bar1(
  int /*[exact=JSUInt31|powerset={I}]*/ a,
) => /*[subclass=JSInt|powerset={I}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}]*/ /*prod.[subclass=JSInt|powerset={I}]*/
      b, [
      int /*spec.[null|subclass=Object|powerset={null}{IN}]*/ /*prod.[subclass=JSInt|powerset={I}]*/
          c =
          17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}]*/ +
        c;
/*member: bar2:[subclass=Closure|powerset={N}]*/
int Function(int, [int]) bar2(
  int /*[exact=JSUInt31|powerset={I}]*/ a,
) => /*[subclass=JSInt|powerset={I}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}]*/ /*prod.[subclass=JSInt|powerset={I}]*/
      b, [
      int /*spec.[null|subclass=Object|powerset={null}{IN}]*/ /*prod.[subclass=JSInt|powerset={I}]*/
          c =
          17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}]*/ +
        c;
/*member: bar3:[subclass=Closure|powerset={N}]*/
int Function(int, [int]) bar3(
  int /*[exact=JSUInt31|powerset={I}]*/ a,
) => /*[subclass=JSPositiveInt|powerset={I}]*/
    (
      int /*[exact=JSUInt31|powerset={I}]*/ b, [
      int /*[exact=JSUInt31|powerset={I}]*/ c = 17,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}]*/ +
        b /*invoke: [subclass=JSUInt32|powerset={I}]*/ +
        c;
/*member: bar4:[subclass=Closure|powerset={N}]*/
num Function(int, [int]) bar4(
  int /*[exact=JSUInt31|powerset={I}]*/ a,
) => /*[subclass=JSNumber|powerset={I}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}]*/ /*prod.[subclass=JSInt|powerset={I}]*/
      b, [
      dynamic /*[null|subclass=Object|powerset={null}{IN}]*/ c,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}]*/ +
        c;
/*member: bar5:[subclass=Closure|powerset={N}]*/
num Function(int, [int]) bar5(
  int /*[exact=JSUInt31|powerset={I}]*/ a,
) => /*[subclass=JSNumber|powerset={I}]*/
    (
      int /*spec.[null|subclass=Object|powerset={null}{IN}]*/ /*prod.[subclass=JSInt|powerset={I}]*/
      b, [
      num? /*spec.[null|subclass=Object|powerset={null}{IN}]*/ /*prod.[null|subclass=JSNumber|powerset={null}{I}]*/
      c,
    ]) =>
        a /*invoke: [exact=JSUInt31|powerset={I}]*/ +
        b /*invoke: [subclass=JSInt|powerset={I}]*/ +
        (c ?? 0);

/*member: testFunctionApply:[null|subclass=Object|powerset={null}{IN}]*/
testFunctionApply() {
  return Function.apply(bar1(10), [20]);
}

/*member: testFunctionApplyNoDefault:[null|subclass=Object|powerset={null}{IN}]*/
testFunctionApplyNoDefault() {
  Function.apply(bar4(10), [30]);
  return Function.apply(bar5(10), [30]);
}

/*member: testRecordFunctionApply:[null|subclass=Object|powerset={null}{IN}]*/
testRecordFunctionApply() {
  final rec = (bar2(10), bar3(10));
  (rec. /*[Record(RecordShape(2), [[subclass=Closure|powerset={N}], [subclass=Closure|powerset={N}]], powerset: {N})]*/ $2)(
    2,
    3,
  );
  return Function.apply(
    rec. /*[Record(RecordShape(2), [[subclass=Closure|powerset={N}], [subclass=Closure|powerset={N}]], powerset: {N})]*/ $1,
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
