// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  refineBeforeCapture();
  refineAfterCapture();
  refineAfterNestedCapture();
  refineAfterCaptureInNested();
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local before it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  /*element: Class1.method1:[null]*/
  method1() {}
}

/*element: Class2.:[exact=Class2]*/
class Class2 {}

/*element: _refineBeforeCapture:[exact=Class1]*/
_refineBeforeCapture(/*Union of [[exact=Class1], [exact=Class2]]*/ o) {
  o. /*invoke: Union of [[exact=Class1], [exact=Class2]]*/ method1();
  o. /*invoke: [exact=Class1]*/ method1();

  /*[exact=Class1]*/ localFunction() => o;
  return localFunction();
}

/*element: refineBeforeCapture:[null]*/
refineBeforeCapture() {
  _refineBeforeCapture(new Class1());
  _refineBeforeCapture(new Class2());
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local after it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*element: Class3.:[exact=Class3]*/
class Class3 {
  /*element: Class3.method3:[null]*/
  method3() {}
}

/*element: Class4.:[exact=Class4]*/
class Class4 {}

/*element: _refineAfterCapture:Union of [[exact=Class3], [exact=Class4]]*/
_refineAfterCapture(/*Union of [[exact=Class3], [exact=Class4]]*/ o) {
  /*Union of [[exact=Class3], [exact=Class4]]*/ localFunction() => o;

  o. /*invoke: Union of [[exact=Class3], [exact=Class4]]*/ method3();
  o. /*invoke: Union of [[exact=Class3], [exact=Class4]]*/ method3();

  return localFunction();
}

/*element: refineAfterCapture:[null]*/
refineAfterCapture() {
  _refineAfterCapture(new Class3());
  _refineAfterCapture(new Class4());
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local after it has been captured in a nested local function.
////////////////////////////////////////////////////////////////////////////////

/*element: Class5.:[exact=Class5]*/
class Class5 {
  /*element: Class5.method5:[null]*/
  method5() {}
}

/*element: Class6.:[exact=Class6]*/
class Class6 {}

/*element: _refineAfterNestedCapture:Union of [[exact=Class5], [exact=Class6]]*/
_refineAfterNestedCapture(/*Union of [[exact=Class5], [exact=Class6]]*/ o) {
  /*Union of [[exact=Class5], [exact=Class6]]*/ localFunction() {
    /*Union of [[exact=Class5], [exact=Class6]]*/ nestedFunction() => o;
    return nestedFunction();
  }

  o. /*invoke: Union of [[exact=Class5], [exact=Class6]]*/ method5();
  o. /*invoke: Union of [[exact=Class5], [exact=Class6]]*/ method5();

  return localFunction();
}

/*element: refineAfterNestedCapture:[null]*/
refineAfterNestedCapture() {
  _refineAfterNestedCapture(new Class5());
  _refineAfterNestedCapture(new Class6());
}

////////////////////////////////////////////////////////////////////////////////
// Refine a local in a local function after it has been captured.
////////////////////////////////////////////////////////////////////////////////

/*element: Class7.:[exact=Class7]*/
class Class7 {
  /*element: Class7.method7:[null]*/
  method7() {}
}

/*element: Class8.:[exact=Class8]*/
class Class8 {}

/*element: _refineAfterCaptureInNested:Union of [[exact=Class7], [exact=Class8]]*/
_refineAfterCaptureInNested(/*Union of [[exact=Class7], [exact=Class8]]*/ o) {
  /*Union of [[exact=Class7], [exact=Class8]]*/ localFunction(
      /*Union of [[exact=Class7], [exact=Class8]]*/ p) {
    /*Union of [[exact=Class7], [exact=Class8]]*/ nestedFunction() => p;

    p. /*invoke: Union of [[exact=Class7], [exact=Class8]]*/ method7();
    p. /*invoke: Union of [[exact=Class7], [exact=Class8]]*/ method7();

    return nestedFunction();
  }

  return localFunction(o);
}

/*element: refineAfterCaptureInNested:[null]*/
refineAfterCaptureInNested() {
  _refineAfterCaptureInNested(new Class7());
  _refineAfterCaptureInNested(new Class8());
}
