// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

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

void setup() native """
function A() {}
A.prototype.foo = function (x) { return x + 1; };
A.prototype.cmp = function (x) { return 0; };

function B() {}
B.prototype.foo = function (x) { return x + 'ha!'; };
B.prototype.cmp = function (x) { return 1; };

makeA = function(){return new A;};
makeB = function(){return new B;};
""";

expectThrows(action()) {
  bool threw = false;
  try {
    action();
  } catch (e) {
    threw = true;
  }
  Expect.isTrue(threw);
}

checkedModeTest() {
  var things = [makeA(), makeB()];
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

  // Check that we throw the same errors when the locals are typed.
  A aa = things[0];
  B bb = things[1];

  Expect.equals(124, aa.foo(123));
  expectThrows(() => aa.foo('xxx'));

  Expect.equals('helloha!', bb.foo('hello'));
  expectThrows(() => bb.foo(123));

  Expect.equals(0, aa.cmp(aa));
  expectThrows(() => aa.cmp(bb));
  expectThrows(() => aa.cmp(5));

  Expect.equals(1, bb.cmp(bb));
  expectThrows(() => bb.cmp(aa));
  expectThrows(() => bb.cmp(5));
}

uncheckedModeTest() {
  var things = [makeA(), makeB()];
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

  // Check that we do not throw errors when the locals are typed.
  A aa = things[0];
  B bb = things[1];

  Expect.equals(124, aa.foo(123));
  Expect.equals('xxx1', aa.foo('xxx'));

  Expect.equals('helloha!', bb.foo('hello'));
  Expect.equals('123ha!', bb.foo(123));

  Expect.equals(0, aa.cmp(aa));
  Expect.equals(0, aa.cmp(bb));
  Expect.equals(0, aa.cmp(5));

  Expect.equals(1, bb.cmp(bb));
  Expect.equals(1, bb.cmp(aa));
  Expect.equals(1, bb.cmp(5));
}

bool isCheckedMode() {
  var stuff = [1, 'string'];
  var a = stuff[0];
  // Checked-mode detection.
  try {
    String s = a;
    return false;
  } catch (e) {
    // Ignore.
  }
  return true;
}

main() {
  setup();

  if (isCheckedMode()) {
    checkedModeTest();
  } else {
    uncheckedModeTest();
  }
}
