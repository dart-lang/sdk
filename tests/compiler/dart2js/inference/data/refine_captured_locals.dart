// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  refineBeforeCapture();
  refineAfterCapture();
  refineAfterNestedCapture();
  refineAfterCaptureInNested();
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local before it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1]*/
class Class1 {
  /*member: Class1.method1:[null]*/
  method1() {}
}

/*member: _refineBeforeCapture:[exact=Class1]*/
_refineBeforeCapture(/*[null|exact=Class1]*/ o) {
  o. /*invoke: [null|exact=Class1]*/ method1();
  o. /*invoke: [exact=Class1]*/ method1();

  /*[exact=Class1]*/ localFunction() => o;
  return localFunction();
}

/*member: refineBeforeCapture:[null]*/
refineBeforeCapture() {
  _refineBeforeCapture(new Class1());
  _refineBeforeCapture(null);
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local after it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3]*/
class Class3 {
  /*member: Class3.method3:[null]*/
  method3() {}
}

/*member: Class4.:[exact=Class4]*/
class Class4 {}

/*member: _refineAfterCapture:Union([exact=Class3], [exact=Class4])*/
_refineAfterCapture(/*Union([exact=Class3], [exact=Class4])*/ o) {
  /*Union([exact=Class3], [exact=Class4])*/ localFunction() => o;

  o. /*invoke: Union([exact=Class3], [exact=Class4])*/ method3();
  o. /*invoke: Union([exact=Class3], [exact=Class4])*/ method3();

  return localFunction();
}

/*member: refineAfterCapture:[null]*/
refineAfterCapture() {
  _refineAfterCapture(new Class3());
  _refineAfterCapture(new Class4());
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local after it has been captured in a nested local function.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5]*/
class Class5 {
  /*member: Class5.method5:[null]*/
  method5() {}
}

/*member: Class6.:[exact=Class6]*/
class Class6 {}

/*member: _refineAfterNestedCapture:Union([exact=Class5], [exact=Class6])*/
_refineAfterNestedCapture(/*Union([exact=Class5], [exact=Class6])*/ o) {
  /*Union([exact=Class5], [exact=Class6])*/ localFunction() {
    /*Union([exact=Class5], [exact=Class6])*/ nestedFunction() => o;
    return nestedFunction();
  }

  o. /*invoke: Union([exact=Class5], [exact=Class6])*/ method5();
  o. /*invoke: Union([exact=Class5], [exact=Class6])*/ method5();

  return localFunction();
}

/*member: refineAfterNestedCapture:[null]*/
refineAfterNestedCapture() {
  _refineAfterNestedCapture(new Class5());
  _refineAfterNestedCapture(new Class6());
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local in a local function after it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*member: Class7.:[exact=Class7]*/
class Class7 {
  /*member: Class7.method7:[null]*/
  method7() {}
}

/*member: Class8.:[exact=Class8]*/
class Class8 {}

/*member: _refineAfterCaptureInNested:Union([exact=Class7], [exact=Class8])*/
_refineAfterCaptureInNested(/*Union([exact=Class7], [exact=Class8])*/ o) {
  /*Union([exact=Class7], [exact=Class8])*/ localFunction(
      /*Union([exact=Class7], [exact=Class8])*/ p) {
    /*Union([exact=Class7], [exact=Class8])*/ nestedFunction() => p;

    p. /*invoke: Union([exact=Class7], [exact=Class8])*/ method7();
    p. /*invoke: Union([exact=Class7], [exact=Class8])*/ method7();

    return nestedFunction();
  }

  return localFunction(o);
}

/*member: refineAfterCaptureInNested:[null]*/
refineAfterCaptureInNested() {
  _refineAfterCaptureInNested(new Class7());
  _refineAfterCaptureInNested(new Class8());
}
