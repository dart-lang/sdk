// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  refineBeforeCapture();
  refineAfterCapture();
  refineAfterNestedCapture();
  refineAfterCaptureInNested();
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local before it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  /*member: Class1.method1:[null|powerset=1]*/
  method1() {}
}

/*member: _refineBeforeCapture:[exact=Class1|powerset=0]*/
_refineBeforeCapture(/*[null|exact=Class1|powerset=1]*/ o) {
  o. /*invoke: [null|exact=Class1|powerset=1]*/ method1();
  o. /*invoke: [exact=Class1|powerset=0]*/ method1();

  /*[exact=Class1|powerset=0]*/
  localFunction() => o;
  return localFunction();
}

/*member: refineBeforeCapture:[null|powerset=1]*/
refineBeforeCapture() {
  _refineBeforeCapture(new Class1());
  _refineBeforeCapture(null);
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local after it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset=0]*/
class Class3 {
  /*member: Class3.method3:[null|powerset=1]*/
  method3() {}
}

/*member: Class4.:[exact=Class4|powerset=0]*/
class Class4 {}

/*member: _refineAfterCapture:Union([exact=Class3|powerset=0], [exact=Class4|powerset=0], powerset: 0)*/
_refineAfterCapture(
  /*Union([exact=Class3|powerset=0], [exact=Class4|powerset=0], powerset: 0)*/ o,
) {
  /*Union([exact=Class3|powerset=0], [exact=Class4|powerset=0], powerset: 0)*/
  localFunction() => o;

  o. /*invoke: Union([exact=Class3|powerset=0], [exact=Class4|powerset=0], powerset: 0)*/ method3();
  o. /*invoke: Union([exact=Class3|powerset=0], [exact=Class4|powerset=0], powerset: 0)*/ method3();

  return localFunction();
}

/*member: refineAfterCapture:[null|powerset=1]*/
refineAfterCapture() {
  _refineAfterCapture(new Class3());
  _refineAfterCapture(new Class4());
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local after it has been captured in a nested local function.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5|powerset=0]*/
class Class5 {
  /*member: Class5.method5:[null|powerset=1]*/
  method5() {}
}

/*member: Class6.:[exact=Class6|powerset=0]*/
class Class6 {}

/*member: _refineAfterNestedCapture:Union([exact=Class5|powerset=0], [exact=Class6|powerset=0], powerset: 0)*/
_refineAfterNestedCapture(
  /*Union([exact=Class5|powerset=0], [exact=Class6|powerset=0], powerset: 0)*/ o,
) {
  /*Union([exact=Class5|powerset=0], [exact=Class6|powerset=0], powerset: 0)*/
  localFunction() {
    /*Union([exact=Class5|powerset=0], [exact=Class6|powerset=0], powerset: 0)*/
    nestedFunction() => o;
    return nestedFunction();
  }

  o. /*invoke: Union([exact=Class5|powerset=0], [exact=Class6|powerset=0], powerset: 0)*/ method5();
  o. /*invoke: Union([exact=Class5|powerset=0], [exact=Class6|powerset=0], powerset: 0)*/ method5();

  return localFunction();
}

/*member: refineAfterNestedCapture:[null|powerset=1]*/
refineAfterNestedCapture() {
  _refineAfterNestedCapture(new Class5());
  _refineAfterNestedCapture(new Class6());
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local in a local function after it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*member: Class7.:[exact=Class7|powerset=0]*/
class Class7 {
  /*member: Class7.method7:[null|powerset=1]*/
  method7() {}
}

/*member: Class8.:[exact=Class8|powerset=0]*/
class Class8 {}

/*member: _refineAfterCaptureInNested:Union([exact=Class7|powerset=0], [exact=Class8|powerset=0], powerset: 0)*/
_refineAfterCaptureInNested(
  /*Union([exact=Class7|powerset=0], [exact=Class8|powerset=0], powerset: 0)*/ o,
) {
  /*Union([exact=Class7|powerset=0], [exact=Class8|powerset=0], powerset: 0)*/
  localFunction(
    /*Union([exact=Class7|powerset=0], [exact=Class8|powerset=0], powerset: 0)*/ p,
  ) {
    /*Union([exact=Class7|powerset=0], [exact=Class8|powerset=0], powerset: 0)*/
    nestedFunction() => p;

    p. /*invoke: Union([exact=Class7|powerset=0], [exact=Class8|powerset=0], powerset: 0)*/ method7();
    p. /*invoke: Union([exact=Class7|powerset=0], [exact=Class8|powerset=0], powerset: 0)*/ method7();

    return nestedFunction();
  }

  return localFunction(o);
}

/*member: refineAfterCaptureInNested:[null|powerset=1]*/
refineAfterCaptureInNested() {
  _refineAfterCaptureInNested(new Class7());
  _refineAfterCaptureInNested(new Class8());
}
