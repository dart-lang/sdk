// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for the "is" and "as" operator with malformed type.

import "package:expect/expect.dart";

var evalCount = 0;
testEval(x) { evalCount++; return x; }

test99(e) {
  // Test that a runtime error is thrown when the 'is' operator checks for a
  // malformed type.
  try {
    if (e is Undefined) Expect.fail("unreachable");   /// 99: continued
    Expect.fail("unreachable");
  } catch(exc) {
    Expect.isTrue(exc is TypeError);
  }
}

test98(e) {
  // Test that a runtime error is thrown when the 'as' operator checks for a
  // malformed type.
  try {
    if (e as Undefined) Expect.fail("unreachable");   /// 98: continued
    Expect.fail("unreachable");
  } catch(exc) {
    Expect.isTrue(exc is TypeError);
  }
}

test97(e) {
  try {
    // Check that the remaining expression after the type test
    // with malformed type is parsed, but not executed at runtime.
    // Regression test for issue 16985.
    evalCount = 0;
    if (e is Undefined && testEval(e)) Expect.fail("unreachable");   /// 97: continued
    Expect.fail("unreachable");
  } catch(exc) {
    Expect.isTrue(exc is TypeError);
    Expect.equals(0, evalCount);
  }
}

test96(e) {
  try {
    // Check that the remaining expression after the type test
    // with malformed type is parsed, but not executed at runtime.
    // Regression test for issue 16985.
    evalCount = 0;
    if (e as Undefined && testEval(e)) Expect.fail("unreachable");   /// 96: continued
    Expect.fail("unreachable");
  } catch(exc) {
    Expect.isTrue(exc is TypeError);
    Expect.equals(0, evalCount);
  }
}

test95(e) {
  // Check that the type-tested expression is evaluated before the
  // runtime error is thrown.
  try {
    evalCount = 0;
    if (testEval(e) is Undefined) Expect.fail("unreachable");   /// 95: continued
    Expect.fail("unreachable");
  } catch(exc) {
    Expect.isTrue(exc is TypeError);
    Expect.equals(1, evalCount);
  }
}

test94(e) {
  // Check that the type-tested expression is evaluated before the
  // runtime error is thrown.
  try {
    evalCount = 0;
    if (testEval(e) as Undefined) Expect.fail("unreachable");  /// 94: continued
    Expect.fail("unreachable");
  } catch(exc) {
    Expect.isTrue(exc is TypeError);
    Expect.equals(1, evalCount);
  }
}

main() {
  test99("99 bottles"); /// 99: static type warning
  test98("98 bottles"); /// 98: static type warning
  test97("97 bottles"); /// 97: static type warning
  test96("96 bottles"); /// 96: static type warning
  test95("95 bottles"); /// 95: static type warning
  test94("94 bottles"); /// 94: static type warning
}
