// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";
import 'dart:_foreign_helper' show JS_INTERCEPTOR_CONSTANT;
import 'dart:_interceptors'
    show
        Interceptor,
        JavaScriptObject,
        PlainJavaScriptObject,
        UnknownJavaScriptObject;

// Test for safe formatting of JavaScript objects by Error.safeToString.

@Native('PPPP')
class Purple {}

@Native('QQQQ')
class Q {}

@Native('RRRR')
class Rascal {
  toString() => 'RRRRRRRR';
}

makeA() native;
makeB() native;
makeC() native;
makeD() native;
makeE() native;
makeP() native;
makeQ() native;
makeR() native;

void setup() {
  JS('', r"""
(function(){
  makeA = function(){return {hello: 123};};

  function BB(){}
  makeB = function(){return new BB();};

  function CC(){}
  makeC = function(){
    var x = new CC();
    x.constructor = null;  // Foils constructor lookup.
    return x;
  };

  function DD(){}
  makeD = function(){
    var x = new DD();
    x.constructor = {name: 'DDxxx'};  // Foils constructor lookup.
    return x;
  };

  function EE(){}
  makeE = function(){
    var x = new EE();
    x.constructor = function Liar(){};  // Looks like a legitimate constructor.
    return x;
  };

  function PPPP(){}
  makeP = function(){return new PPPP();};

  function QQQQ(){}
  makeQ = function(){return new QQQQ();};

  function RRRR(){}
  makeR = function(){return new RRRR();};

  self.nativeConstructor(PPPP);
  self.nativeConstructor(QQQQ);
  self.nativeConstructor(RRRR);
})()""");
}

expectTypeName(expectedName, s) {
  var m = new RegExp(r"Instance of '(.*)'").firstMatch(s);
  Expect.isNotNull(m);
  var name = m.group(1);
  Expect.isTrue(expectedName == name || name.length <= 3,
      "Is '$expectedName' or minified: '$name'");
}

final plainJsString =
    Error.safeToString(JS_INTERCEPTOR_CONSTANT(PlainJavaScriptObject));

final unknownJsString =
    Error.safeToString(JS_INTERCEPTOR_CONSTANT(UnknownJavaScriptObject));

final interceptorString =
    Error.safeToString(JS_INTERCEPTOR_CONSTANT(Interceptor));

testDistinctInterceptors() {
  // Test invariants needed for the other tests.

  Expect.notEquals(plainJsString, unknownJsString);
  Expect.notEquals(plainJsString, interceptorString);
  Expect.notEquals(unknownJsString, interceptorString);

  expectTypeName('PlainJavaScriptObject', plainJsString);
  expectTypeName('UnknownJavaScriptObject', unknownJsString);
  expectTypeName('Interceptor', interceptorString);

  // Sometimes interceptor *objects* are used instead of the prototypes. Check
  // these work too.
  var plain2 = Error.safeToString(const PlainJavaScriptObject());
  Expect.equals(plainJsString, plain2);

  var unk2 = Error.safeToString(const UnknownJavaScriptObject());
  Expect.equals(unknownJsString, unk2);
}

testExternal() {
  var x = makeA();
  Expect.equals(plainJsString, Error.safeToString(x));

  x = makeB();
  // Gets name from constructor, regardless of minification.
  Expect.equals("Instance of 'BB'", Error.safeToString(x));

  x = makeC();
  Expect.equals(unknownJsString, Error.safeToString(x));

  x = makeD();
  Expect.equals(unknownJsString, Error.safeToString(x));

  x = makeE();
  Expect.equals("Instance of 'Liar'", Error.safeToString(x));
}

testNative() {
  var x = makeP();
  Expect.isTrue(x is Purple); // This test forces Purple to be distinguished.
  Expect.notEquals(plainJsString, Error.safeToString(x));
  Expect.notEquals(unknownJsString, Error.safeToString(x));
  Expect.notEquals(interceptorString, Error.safeToString(x));
  // And not the native class constructor.
  Expect.notEquals("Instance of 'PPPP'", Error.safeToString(x));
  expectTypeName('Purple', Error.safeToString(x));

  x = makeQ();
  print('Q:  $x  ${Error.safeToString(x)}');
  // We are going to get either the general interceptor or the JavaScript
  // constructor.
  Expect.isTrue("Instance of 'QQQQ'" == Error.safeToString(x) ||
      interceptorString == Error.safeToString(x));

  x = makeR();

  // Rascal overrides 'toString'.  The toString() call causes Rascal to be
  // distinguished.
  x.toString();
  Expect.notEquals(plainJsString, Error.safeToString(x));
  Expect.notEquals(unknownJsString, Error.safeToString(x));
  Expect.notEquals(interceptorString, Error.safeToString(x));
  // And not the native class constructor.
  Expect.notEquals("Instance of 'RRRR'", Error.safeToString(x));
  expectTypeName('Rascal', Error.safeToString(x));
}

main() {
  nativeTesting();
  setup();

  testDistinctInterceptors();
  testExternal();
  testNative();
}
