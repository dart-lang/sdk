// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  forInDirect();
  forInReturn();
  forInReturnMulti();
  forInReturnRefined();
  testInForIn();
  operatorInForIn();
}

////////////////////////////////////////////////////////////////////////////////
// For-in loop directly on a list literal.
////////////////////////////////////////////////////////////////////////////////

/*element: forInDirect:[null]*/
forInDirect() {
  /*iterator: Container mask: [exact=JSUInt31] length: 3 type: [exact=JSExtendableArray]*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var a in [1, 2, 3]) {
    print(a);
  }
}

////////////////////////////////////////////////////////////////////////////////
// Return element from a for-in loop on a list literal.
////////////////////////////////////////////////////////////////////////////////

/*element: forInReturn:[null|subclass=Object]*/
forInReturn() {
  /*iterator: Container mask: [exact=JSUInt31] length: 3 type: [exact=JSExtendableArray]*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var a in [1, 2, 3]) {
    // TODO(johnniwinther): We should know the type of [a] here.
    return a;
  }
}

////////////////////////////////////////////////////////////////////////////////
// Return element from a for-in loop on known list type.
////////////////////////////////////////////////////////////////////////////////

/*element: _forInReturn:[null|subclass=Object]*/
_forInReturn(
    /*Container mask: [exact=JSUInt31] length: null type: [exact=JSExtendableArray]*/ list) {
  /*iterator: Container mask: [exact=JSUInt31] length: null type: [exact=JSExtendableArray]*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var a in list) {
    // TODO(johnniwinther): We should know the type of [a] here.
    return a;
  }
}

/*element: forInReturnMulti:[null]*/
forInReturnMulti() {
  _forInReturn([1, 2]);
  _forInReturn([1, 2, 3]);
}

////////////////////////////////////////////////////////////////////////////////
// Sequentially refine element and return it from a for-in loop on known list
// type.
////////////////////////////////////////////////////////////////////////////////

/*element: forInReturnRefined:[null|subclass=JSInt]*/
forInReturnRefined() {
  /*iterator: Container mask: [exact=JSUInt31] length: 3 type: [exact=JSExtendableArray]*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var a in [1, 2, 3]) {
    // TODO(johnniwinther): We should know the type of [a] here.
    a.isEven;
    a. /*[subclass=JSInt]*/ isEven;
    return a;
  }
}

////////////////////////////////////////////////////////////////////////////////
// Refine element through test and return it from a for-in loop on known list
// type.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  /*element: Class1.field1:[exact=JSUInt31]*/
  var field1 = 42;
}

/*element: _testInForIn:[null|exact=Class1]*/
_testInForIn(
    /*Container mask: [exact=Class1] length: 2 type: [exact=JSExtendableArray]*/ list) {
  /*iterator: Container mask: [exact=Class1] length: 2 type: [exact=JSExtendableArray]*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var t in list) {
    if (t.field1) {
      return t;
    }
  }
}

/*element: testInForIn:[null]*/
testInForIn() {
  _testInForIn([new Class1(), new Class1()]);
}

////////////////////////////////////////////////////////////////////////////////
// Refine element through operator and return it from a for-in loop on known
// list type.
////////////////////////////////////////////////////////////////////////////////

/*element: Class2.:[exact=Class2]*/
class Class2 {
  /*element: Class2.field2a:[exact=JSUInt31]*/
  var field2a = 42;
  /*element: Class2.field2b:[exact=JSUInt31]*/
  var field2b = 42;
}

/*element: _operatorInForIn:[null|exact=Class2]*/
_operatorInForIn(
    /*Container mask: [exact=Class2] length: 2 type: [exact=JSExtendableArray]*/ list) {
  /*iterator: Container mask: [exact=Class2] length: 2 type: [exact=JSExtendableArray]*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var t in list) {
    if (t.field2a /*invoke: [exact=JSUInt31]*/ <
        t. /*[exact=Class2]*/ field2b) {
      return t;
    }
  }
}

/*element: operatorInForIn:[null]*/
operatorInForIn() {
  _operatorInForIn([new Class2(), new Class2()]);
}
