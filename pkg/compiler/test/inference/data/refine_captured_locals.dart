// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  refineBeforeCapture();
  refineAfterCapture();
  refineAfterNestedCapture();
  refineAfterCaptureInNested();
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local before it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {
  /*member: Class1.method1:[null|powerset={null}]*/
  method1() {}
}

/*member: _refineBeforeCapture:[exact=Class1|powerset={N}{O}{N}]*/
_refineBeforeCapture(/*[null|exact=Class1|powerset={null}{N}{O}{N}]*/ o) {
  o. /*invoke: [null|exact=Class1|powerset={null}{N}{O}{N}]*/ method1();
  o. /*invoke: [exact=Class1|powerset={N}{O}{N}]*/ method1();

  /*[exact=Class1|powerset={N}{O}{N}]*/
  localFunction() => o;
  return localFunction();
}

/*member: refineBeforeCapture:[null|powerset={null}]*/
refineBeforeCapture() {
  _refineBeforeCapture(new Class1());
  _refineBeforeCapture(null);
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local after it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3.:[exact=Class3|powerset={N}{O}{N}]*/
class Class3 {
  /*member: Class3.method3:[null|powerset={null}]*/
  method3() {}
}

/*member: Class4.:[exact=Class4|powerset={N}{O}{N}]*/
class Class4 {}

/*member: _refineAfterCapture:Union([exact=Class3|powerset={N}{O}{N}], [exact=Class4|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
_refineAfterCapture(
  /*Union([exact=Class3|powerset={N}{O}{N}], [exact=Class4|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ o,
) {
  /*Union([exact=Class3|powerset={N}{O}{N}], [exact=Class4|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  localFunction() => o;

  o. /*invoke: Union([exact=Class3|powerset={N}{O}{N}], [exact=Class4|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ method3();
  o. /*invoke: Union([exact=Class3|powerset={N}{O}{N}], [exact=Class4|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ method3();

  return localFunction();
}

/*member: refineAfterCapture:[null|powerset={null}]*/
refineAfterCapture() {
  _refineAfterCapture(new Class3());
  _refineAfterCapture(new Class4());
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local after it has been captured in a nested local function.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5.:[exact=Class5|powerset={N}{O}{N}]*/
class Class5 {
  /*member: Class5.method5:[null|powerset={null}]*/
  method5() {}
}

/*member: Class6.:[exact=Class6|powerset={N}{O}{N}]*/
class Class6 {}

/*member: _refineAfterNestedCapture:Union([exact=Class5|powerset={N}{O}{N}], [exact=Class6|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
_refineAfterNestedCapture(
  /*Union([exact=Class5|powerset={N}{O}{N}], [exact=Class6|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ o,
) {
  /*Union([exact=Class5|powerset={N}{O}{N}], [exact=Class6|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  localFunction() {
    /*Union([exact=Class5|powerset={N}{O}{N}], [exact=Class6|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
    nestedFunction() => o;
    return nestedFunction();
  }

  o. /*invoke: Union([exact=Class5|powerset={N}{O}{N}], [exact=Class6|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ method5();
  o. /*invoke: Union([exact=Class5|powerset={N}{O}{N}], [exact=Class6|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ method5();

  return localFunction();
}

/*member: refineAfterNestedCapture:[null|powerset={null}]*/
refineAfterNestedCapture() {
  _refineAfterNestedCapture(new Class5());
  _refineAfterNestedCapture(new Class6());
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local in a local function after it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*member: Class7.:[exact=Class7|powerset={N}{O}{N}]*/
class Class7 {
  /*member: Class7.method7:[null|powerset={null}]*/
  method7() {}
}

/*member: Class8.:[exact=Class8|powerset={N}{O}{N}]*/
class Class8 {}

/*member: _refineAfterCaptureInNested:Union([exact=Class7|powerset={N}{O}{N}], [exact=Class8|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
_refineAfterCaptureInNested(
  /*Union([exact=Class7|powerset={N}{O}{N}], [exact=Class8|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ o,
) {
  /*Union([exact=Class7|powerset={N}{O}{N}], [exact=Class8|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  localFunction(
    /*Union([exact=Class7|powerset={N}{O}{N}], [exact=Class8|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ p,
  ) {
    /*Union([exact=Class7|powerset={N}{O}{N}], [exact=Class8|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
    nestedFunction() => p;

    p. /*invoke: Union([exact=Class7|powerset={N}{O}{N}], [exact=Class8|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ method7();
    p. /*invoke: Union([exact=Class7|powerset={N}{O}{N}], [exact=Class8|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ method7();

    return nestedFunction();
  }

  return localFunction(o);
}

/*member: refineAfterCaptureInNested:[null|powerset={null}]*/
refineAfterCaptureInNested() {
  _refineAfterCaptureInNested(new Class7());
  _refineAfterCaptureInNested(new Class8());
}
