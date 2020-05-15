// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[]*/
main() {
  outsideLoopNoArgsCalledOnce();
  outsideLoopNoArgsCalledTwice();
  outsideLoopOneArgCalledOnce();
  outsideLoopOneArgCalledTwice();
  insideLoopNoArgsCalledOnce();
  insideLoopNoArgsCalledTwice();
  insideLoopOneArgCalledOnce();
  insideLoopOneArgCalledTwice();
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with no parameters called once based regardless the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*member: _method1:[outsideLoopNoArgsCalledOnce]*/
_method1() {}

/*member: _outsideLoopNoArgsCalledOnce:[outsideLoopNoArgsCalledOnce]*/
_outsideLoopNoArgsCalledOnce() {
  _method1();
  _method1();
  _method1();
  _method1();
  // This would be one too many calls if this method were called twice.
  _method1();
}

/*member: outsideLoopNoArgsCalledOnce:[]*/
@pragma('dart2js:noInline')
outsideLoopNoArgsCalledOnce() {
  _outsideLoopNoArgsCalledOnce();
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with no parameters called twice based on the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*member: _method2:[_outsideLoopNoArgs2,outsideLoopNoArgsCalledTwice]*/
_method2() {}

/*member: _outsideLoopNoArgs1:[outsideLoopNoArgsCalledTwice]*/
_outsideLoopNoArgs1() {
  _method2();
  _method2();
  _method2();
  _method2();
}

/*member: _outsideLoopNoArgs2:[]*/
_outsideLoopNoArgs2() {
  _method2();
  _method2();
  _method2();
  _method2();
  // One too many calls:
  _method2();
}

/*member: outsideLoopNoArgsCalledTwice:[]*/
@pragma('dart2js:noInline')
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

/*member: _method3:[outsideLoopOneArgCalledOnce]*/
_method3() {}

/*member: _outsideLoopOneArgCalledOnce:[outsideLoopOneArgCalledOnce]*/
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

/*member: outsideLoopOneArgCalledOnce:[]*/
@pragma('dart2js:noInline')
outsideLoopOneArgCalledOnce() {
  _outsideLoopOneArgCalledOnce(0);
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with one parameter called twice based on the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*member: _method4:[_outsideLoopOneArg2,outsideLoopOneArgCalledTwice]*/
_method4() {}

/*member: _outsideLoopOneArg1:[outsideLoopOneArgCalledTwice]*/
_outsideLoopOneArg1(arg) {
  _method4();
  _method4();
  _method4();
  _method4();
  // Extra call granted by one parameter.
  _method4();
}

/*member: _outsideLoopOneArg2:[]*/
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

/*member: outsideLoopOneArgCalledTwice:[]*/
@pragma('dart2js:noInline')
outsideLoopOneArgCalledTwice() {
  _outsideLoopOneArg1(0);
  _outsideLoopOneArg1(0);
  _outsideLoopOneArg2(0);
  _outsideLoopOneArg2(0);
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with no parameters called once based regardless the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*member: _method5:[insideLoopNoArgsCalledOnce]*/
_method5() {}

/*member: _insideLoopNoArgsCalledOnce:[insideLoopNoArgsCalledOnce]*/
_insideLoopNoArgsCalledOnce() {
  _method5();
  _method5();
  _method5();
  _method5();
  _method5();
  _method5();
  _method5();
  _method5();
  _method5();
  // This would be one too many calls if this method were called twice.
  _method5();
}

/*member: insideLoopNoArgsCalledOnce:loop*/
@pragma('dart2js:noInline')
insideLoopNoArgsCalledOnce() {
  // ignore: UNUSED_LOCAL_VARIABLE
  for (var e in [1, 2, 3, 4]) {
    _insideLoopNoArgsCalledOnce();
  }
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with no parameters called twice based on the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*member: _method6:[_insideLoopNoArgs2,insideLoopNoArgsCalledTwice]*/
_method6() {}

/*member: _insideLoopNoArgs1:[insideLoopNoArgsCalledTwice]*/
_insideLoopNoArgs1() {
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
}

/*member: _insideLoopNoArgs2:[]*/
_insideLoopNoArgs2() {
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  _method6();
  // One too many calls:
  _method6();
}

/*member: insideLoopNoArgsCalledTwice:loop*/
@pragma('dart2js:noInline')
insideLoopNoArgsCalledTwice() {
  // ignore: UNUSED_LOCAL_VARIABLE
  for (var e in [1, 2, 3, 4]) {
    _insideLoopNoArgs1();
    _insideLoopNoArgs1();
    _insideLoopNoArgs2();
    _insideLoopNoArgs2();
  }
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with one parameter called once based regardless the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*member: _method7:[insideLoopOneArgCalledOnce]*/
_method7() {}

/*member: _insideLoopOneArgCalledOnce:[insideLoopOneArgCalledOnce]*/
_insideLoopOneArgCalledOnce(arg) {
  _method7();
  _method7();
  _method7();
  _method7();
  _method7();
  // This would be too many calls if this method were called twice.
  _method7();
  _method7();
  _method7();
  _method7();
  _method7();
  _method7();
  _method7();
  _method7();
  _method7();
  _method7();
  _method7();
}

/*member: insideLoopOneArgCalledOnce:loop*/
@pragma('dart2js:noInline')
insideLoopOneArgCalledOnce() {
  for (var e in [1, 2, 3, 4]) {
    _insideLoopOneArgCalledOnce(e);
  }
}

////////////////////////////////////////////////////////////////////////////////
// Inline a method with one parameter called twice based on the number of
// static no-arg calls in its body.
////////////////////////////////////////////////////////////////////////////////

/*member: _method8:[_insideLoopOneArg2,insideLoopOneArgCalledTwice]*/
_method8() {}

/*member: _insideLoopOneArg1:[insideLoopOneArgCalledTwice]*/
_insideLoopOneArg1(arg) {
  _method8();
  _method8();
  _method8();
  _method8();
  _method8();
  _method8();
  _method8();
  _method8();
  _method8();
  // Extra calls granted by one parameter.
  _method8();
  _method8();
}

/*member: _insideLoopOneArg2:[]*/
_insideLoopOneArg2(arg) {
  _method8();
  _method8();
  _method8();
  _method8();
  _method8();
  _method8();
  _method8();
  _method8();
  _method8();
  // Extra calls granted by one parameter.
  _method8();
  _method8();
  // One too many calls:
  _method8();
}

/*member: insideLoopOneArgCalledTwice:loop*/
@pragma('dart2js:noInline')
insideLoopOneArgCalledTwice() {
  for (var e in [1, 2, 3, 4]) {
    _insideLoopOneArg1(e);
    _insideLoopOneArg1(e);
    _insideLoopOneArg2(e);
    _insideLoopOneArg2(e);
  }
}
