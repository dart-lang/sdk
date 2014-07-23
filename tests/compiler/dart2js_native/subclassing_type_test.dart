// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:_js_helper' show Native, Creates, setNativeSubclassDispatchRecord;
import 'dart:_interceptors' show Interceptor, findInterceptorForType;

// Test that type checks and casts work for subclasses of native classes and
// mixins on native classes.

class M {}

@Native("N")
class N {}

class A extends N {}

class B extends A with M {       // native mixin application.
}

class C extends Object with M {  // non-native mixin application.
}

B makeB() native;

@Creates('=Object')
getBPrototype() native;

void setup() native r"""
function B() {}
makeB = function(){return new B;};

getBPrototype = function(){return B.prototype;};
""";

A gA;
B gB;
C gC;
M gM;

isA(x) => x is A;
asA(x) => x as A;
setA(x) => gA = x;

isB(x) => x is B;
asB(x) => x as B;
setB(x) => gB = x;

isC(x) => x is C;
asC(x) => x as C;
setC(x) => gC = x;

isM(x) => x is M;
asM(x) => x as M;
setM(x) => gM = x;

checkTrue(f) => (x) { Expect.isTrue(f(x)); };
checkFalse(f) => (x) { Expect.isFalse(f(x)); };
checkId(f) => (x) { Expect.identical(x, f(x)); };
checkThrows(f) => (x) { Expect.throws(() => f(x)); };

bool get checkedMode {
  try {
    setA(1);
    gA = null;
    return false;
  } catch (e) {
    return true;
  }
}

main() {
  setup();

  setNativeSubclassDispatchRecord(getBPrototype(), findInterceptorForType(B));

  B b = makeB();
  C c = new C();


  checkFalse(isA)(1);
  checkFalse(isB)(1);
  checkFalse(isC)(1);
  checkFalse(isM)(1);

  checkTrue(isA)(b);
  checkTrue(isB)(b);
  checkTrue(isM)(b);
  checkFalse(isC)(b);

  checkTrue(isC)(c);
  checkTrue(isM)(c);
  checkFalse(isA)(c);
  checkFalse(isB)(c);


  checkThrows(asA)(1);
  checkThrows(asB)(1);
  checkThrows(asC)(1);
  checkThrows(asM)(1);

  checkId(asA)(b);
  checkId(asB)(b);
  checkId(asM)(b);
  checkThrows(asC)(b);

  checkId(asC)(c);
  checkId(asM)(c);
  checkThrows(asA)(c);
  checkThrows(asB)(c);


  if (checkedMode) {
    checkThrows(setA)(1);
    checkThrows(setB)(1);
    checkThrows(setC)(1);
    checkThrows(setM)(1);

    checkId(setA)(b);
    checkId(setB)(b);
    checkId(setM)(b);
    checkThrows(setC)(b);

    checkId(setC)(c);
    checkId(setM)(c);
    checkThrows(setA)(c);
    checkThrows(setB)(c);

    // One of the above assignments had a value of the correct type.
    Expect.isNotNull(gA);
    Expect.isNotNull(gB);
    Expect.isNotNull(gC);
    Expect.isNotNull(gM);

    checkId(setA)(null);
    checkId(setB)(null);
    checkId(setC)(null);
    checkId(setM)(null);

    Expect.isNull(gA);
    Expect.isNull(gB);
    Expect.isNull(gC);
    Expect.isNull(gM);
  }
}
