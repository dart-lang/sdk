// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// ignore: IMPORT_INTERNAL_LIBRARY
import 'dart:_js_helper';

/*element: main:[]*/
main() {
  outsideLoopNoArgsCalledOnce();
  outsideLoopNoArgsCalledTwice();
  outsideLoopOneArgCalledOnce();
  outsideLoopOneArgCalledTwice();
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with no parameters called once based regardless the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*element: _method1:[outsideLoopNoArgsCalledOnce]*/
_method1() {}

/*element: _outsideLoopNoArgsCalledOnce:[outsideLoopNoArgsCalledOnce]*/
_outsideLoopNoArgsCalledOnce() {
  _method1();
  _method1();
  _method1();
  _method1();
  // This would be one too many calls if this method were called twice.
  _method1();
}

/*element: outsideLoopNoArgsCalledOnce:[]*/
@NoInline()
outsideLoopNoArgsCalledOnce() {
  _outsideLoopNoArgsCalledOnce();
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with no parameters called twice based on the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*element: _method2:[_outsideLoopNoArgs2,outsideLoopNoArgsCalledTwice]*/
_method2() {}

/*element: _outsideLoopNoArgs1:[outsideLoopNoArgsCalledTwice]*/
_outsideLoopNoArgs1() {
  _method2();
  _method2();
  _method2();
  _method2();
}

/*element: _outsideLoopNoArgs2:[]*/
_outsideLoopNoArgs2() {
  _method2();
  _method2();
  _method2();
  _method2();
  // One too many calls:
  _method2();
}

/*element: outsideLoopNoArgsCalledTwice:[]*/
@NoInline()
outsideLoopNoArgsCalledTwice() {
  _outsideLoopNoArgs1();
  _outsideLoopNoArgs1();
  _outsideLoopNoArgs2();
  _outsideLoopNoArgs2();
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with one parameter called once based regardless the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*element: _method3:[outsideLoopOneArgCalledOnce]*/
_method3() {}

/*element: _outsideLoopOneArgCalledOnce:[outsideLoopOneArgCalledOnce]*/
_outsideLoopOneArgCalledOnce(arg) {
  _method3();
  _method3();
  _method3();
  _method3();
  _method3();
  // This would be too many calls if this method were called twice.
  _method3();
  _method3();
  _method3();
  _method3();
  _method3();
  _method3();
  _method3();
  _method3();
  _method3();
  _method3();
  _method3();
}

/*element: outsideLoopOneArgCalledOnce:[]*/
@NoInline()
outsideLoopOneArgCalledOnce() {
  _outsideLoopOneArgCalledOnce(0);
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with one parameter called twice based on the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*element: _method4:[_outsideLoopOneArg2,outsideLoopOneArgCalledTwice]*/
_method4() {}

/*element: _outsideLoopOneArg1:[outsideLoopOneArgCalledTwice]*/
_outsideLoopOneArg1(arg) {
  _method4();
  _method4();
  _method4();
  _method4();
  // Extra call granted by one parameter.
  _method4();
}

/*element: _outsideLoopOneArg2:[]*/
_outsideLoopOneArg2(arg) {
  _method4();
  _method4();
  _method4();
  _method4();
  // Extra call granted by one parameter.
  _method4();
  // One too many calls:
  _method4();
}

/*element: outsideLoopOneArgCalledTwice:[]*/
@NoInline()
outsideLoopOneArgCalledTwice() {
  _outsideLoopOneArg1(0);
  _outsideLoopOneArg1(0);
  _outsideLoopOneArg2(0);
  _outsideLoopOneArg2(0);
}
