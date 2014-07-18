// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:_js_helper' show Native, Creates, setNativeSubclassDispatchRecord;
import 'dart:_interceptors' show Interceptor, findInterceptorForType;

// Test type checks.

class I {}

class M implements I {
  miz() => 'M';
}

@Native("N")
class N {}

class A extends N {}

class B extends A with M {
}

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


var inscrutable;

main() {
  setup();
  inscrutable = (x) => x;

  setNativeSubclassDispatchRecord(getBPrototype(), findInterceptorForType(B));

  var b = inscrutable(makeB());

  inscrutable(testIsB)(b);
  inscrutable(testIsA)(b);
  inscrutable(testIsN)(b);
  inscrutable(testIsM)(b);
  inscrutable(testIsI)(b);

  inscrutable(new Checks<B>().isCheck)(b);
  inscrutable(new Checks<A>().isCheck)(b);
  inscrutable(new Checks<N>().isCheck)(b);
  inscrutable(new Checks<M>().isCheck)(b);
  inscrutable(new Checks<I>().isCheck)(b);

  if (isCheckedMode()) {
    inscrutable(testAssignB)(b);
    inscrutable(testAssignA)(b);
    inscrutable(testAssignN)(b);
    inscrutable(testAssignM)(b);
    inscrutable(testAssignI)(b);

    inscrutable(testCastB)(b);
    inscrutable(testCastA)(b);
    inscrutable(testCastN)(b);
    inscrutable(testCastM)(b);
    inscrutable(testCastI)(b);

    inscrutable(new Checks<B>().assignCheck)(b);
    inscrutable(new Checks<A>().assignCheck)(b);
    inscrutable(new Checks<N>().assignCheck)(b);
    inscrutable(new Checks<M>().assignCheck)(b);
    inscrutable(new Checks<I>().assignCheck)(b);

    inscrutable(new Checks<B>().castCheck)(b);
    inscrutable(new Checks<A>().castCheck)(b);
    inscrutable(new Checks<N>().castCheck)(b);
    inscrutable(new Checks<M>().castCheck)(b);
    inscrutable(new Checks<I>().castCheck)(b);
  }
}
