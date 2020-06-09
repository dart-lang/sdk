// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

// Test that type checks occur on native methods.

@Native("A")
class A {
  int foo(int x) native;
  int cmp(A other) native;
}

@Native("B")
class B {
  String foo(String x) native;
  int cmp(B other) native;
}

A makeA() native;
B makeB() native;

void setup() {
  JS('', r"""
(function(){
  function A() {}
  A.prototype.foo = function (x) { return x + 1; };
  A.prototype.cmp = function (x) { return 0; };

  function B() {}
  B.prototype.foo = function (x) { return x + 'ha!'; };
  B.prototype.cmp = function (x) { return 1; };

  makeA = function(){return new A()};
  makeB = function(){return new B()};

  self.nativeConstructor(A);
  self.nativeConstructor(B);
})()""");
}

expectThrows(action()) {
  bool threw = false;
  try {
    action();
  } catch (e) {
    threw = true;
  }
  Expect.isTrue(threw);
}

complianceModeTest() {
  var things = <dynamic>[makeA(), makeB()];
  var a = things[0];
  var b = things[1];

  Expect.equals(124, a.foo(123));
  expectThrows(() => a.foo('xxx'));

  Expect.equals('helloha!', b.foo('hello'));
  expectThrows(() => b.foo(123));

  Expect.equals(0, a.cmp(a));
  expectThrows(() => a.cmp(b));
  expectThrows(() => a.cmp(5));

  Expect.equals(1, b.cmp(b));
  expectThrows(() => b.cmp(a));
  expectThrows(() => b.cmp(5));
}

omitImplicitChecksModeTest() {
  var things = <dynamic>[makeA(), makeB()];
  var a = things[0];
  var b = things[1];

  Expect.equals(124, a.foo(123));
  Expect.equals('xxx1', a.foo('xxx'));

  Expect.equals('helloha!', b.foo('hello'));
  Expect.equals('123ha!', b.foo(123));

  Expect.equals(0, a.cmp(a));
  Expect.equals(0, a.cmp(b));
  Expect.equals(0, a.cmp(5));

  Expect.equals(1, b.cmp(b));
  Expect.equals(1, b.cmp(a));
  Expect.equals(1, b.cmp(5));
}

bool isComplianceMode() {
  var stuff = <dynamic>[1, 'string'];
  dynamic a = stuff[0];
  // compliance-mode detection.
  try {
    String s = a;
    return false;
  } catch (e) {
    // Ignore.
  }
  return true;
}

main() {
  nativeTesting();
  setup();

  if (isComplianceMode()) {
    complianceModeTest();
  } else {
    omitImplicitChecksModeTest();
  }
}
