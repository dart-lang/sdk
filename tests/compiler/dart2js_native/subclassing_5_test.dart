// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';
import 'dart:_js_helper' show setNativeSubclassDispatchRecord;
import 'dart:_interceptors' show Interceptor, findInterceptorForType;

// Test type checks.

class I {}

class M implements I {
  miz() => 'M';
}

@Native("N")
class N {}

class A extends N {}

class B extends A with M {}

class Checks<T> {
  bool isCheck(x) => x is T;
  void assignCheck(x) {
    T z = x;
    Expect.identical(x, z);
  }

  void castCheck(x) {
    var z = x as T;
    Expect.identical(x, z);
  }
}

makeB() native;

@Creates('=Object')
getBPrototype() native;

void setup() native r"""
function B() {}
makeB = function(){return new B;};
getBPrototype = function(){return B.prototype;};
""";

bool isCheckedMode() {
  var isChecked = false;
  assert(isChecked = true);
  return isChecked;
}

testIsI(x) {
  Expect.isTrue(x is I);
}

testIsM(x) {
  Expect.isTrue(x is M);
}

testIsN(x) {
  Expect.isTrue(x is N);
}

testIsA(x) {
  Expect.isTrue(x is A);
}

testIsB(x) {
  Expect.isTrue(x is B);
}

testAssignI(x) {
  I z = x;
  Expect.identical(x, z);
}

testAssignM(x) {
  M z = x;
  Expect.identical(x, z);
}

testAssignN(x) {
  N z = x;
  Expect.identical(x, z);
}

testAssignA(x) {
  A z = x;
  Expect.identical(x, z);
}

testAssignB(x) {
  B z = x;
  Expect.identical(x, z);
}

testCastI(x) {
  var z = x as I;
  Expect.identical(x, z);
}

testCastM(x) {
  var z = x as M;
  Expect.identical(x, z);
}

testCastN(x) {
  var z = x as N;
  Expect.identical(x, z);
}

testCastA(x) {
  var z = x as A;
  Expect.identical(x, z);
}

testCastB(x) {
  var z = x as B;
  Expect.identical(x, z);
}

main() {
  nativeTesting();
  setup();

  setNativeSubclassDispatchRecord(getBPrototype(), findInterceptorForType(B));

  var b = confuse(makeB());

  confuse(testIsB)(b);
  confuse(testIsA)(b);
  confuse(testIsN)(b);
  confuse(testIsM)(b);
  confuse(testIsI)(b);

  confuse(new Checks<B>().isCheck)(b);
  confuse(new Checks<A>().isCheck)(b);
  confuse(new Checks<N>().isCheck)(b);
  confuse(new Checks<M>().isCheck)(b);
  confuse(new Checks<I>().isCheck)(b);

  if (isCheckedMode()) {
    confuse(testAssignB)(b);
    confuse(testAssignA)(b);
    confuse(testAssignN)(b);
    confuse(testAssignM)(b);
    confuse(testAssignI)(b);

    confuse(testCastB)(b);
    confuse(testCastA)(b);
    confuse(testCastN)(b);
    confuse(testCastM)(b);
    confuse(testCastI)(b);

    confuse(new Checks<B>().assignCheck)(b);
    confuse(new Checks<A>().assignCheck)(b);
    confuse(new Checks<N>().assignCheck)(b);
    confuse(new Checks<M>().assignCheck)(b);
    confuse(new Checks<I>().assignCheck)(b);

    confuse(new Checks<B>().castCheck)(b);
    confuse(new Checks<A>().castCheck)(b);
    confuse(new Checks<N>().castCheck)(b);
    confuse(new Checks<M>().castCheck)(b);
    confuse(new Checks<I>().castCheck)(b);
  }
}
