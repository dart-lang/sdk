// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'native_testing.dart';

// Test that type checks occur on assignment to fields of native methods.

@Native("A")
class A {
  int foo;
}

@Native("B")
class B {
  String foo;
}

A makeA() native;
B makeB() native;

void setup() {
  JS('', r"""
(function(){
  function A() {}

  function B() {}

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

  a.foo = 123;
  expectThrows(() => a.foo = 'xxx');
  Expect.equals(123, a.foo);

  b.foo = 'hello';
  expectThrows(() => b.foo = 123);
  Expect.equals('hello', b.foo);
}

omitImplicitChecksTest() {
  var things = <dynamic>[makeA(), makeB()];
  var a = things[0];
  var b = things[1];

  a.foo = 123;
  Expect.equals(123, a.foo);
  a.foo = 'xxx';
  Expect.equals('xxx', a.foo);

  b.foo = 'hello';
  Expect.equals('hello', b.foo);
  b.foo = 123;
  Expect.equals(b.foo, 123);
}

bool isComplianceMode() {
  var stuff = [1, 'string'];
  var a = stuff[0];
  // Detect whether we are using --omit-implicit-checks.
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
    omitImplicitChecksTest();
  }
}
