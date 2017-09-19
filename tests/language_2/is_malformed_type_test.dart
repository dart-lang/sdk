// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for the "is" and "as" operator with malformed type.

import "package:expect/expect.dart";

testEval(x) {
  return x;
}

test99(e) {
  // Test that a runtime error is thrown when the 'is' operator checks for a
  // malformed type.
    if (e is Undefined) Expect.fail("unreachable"); //  //# 99: continued
}

test98(e) {
  // Test that a runtime error is thrown when the 'as' operator checks for a
  // malformed type.
    if (e as Undefined) Expect.fail("unreachable"); //  //# 98: continued
}

test97(e) {
    // Check that the remaining expression after the type test
    // with malformed type is parsed, but not executed at runtime.
    // Regression test for issue 16985.
    if (e is Undefined && testEval(e)) Expect.fail("unreachable"); //  //# 97: continued
}

test96(e) {
    // Check that the remaining expression after the type test
    // with malformed type is parsed, but not executed at runtime.
    // Regression test for issue 16985.
    if (e as Undefined && testEval(e)) Expect.fail("unreachable"); //  //# 96: continued
}

test95(e) {
  // Check that the type-tested expression is evaluated before the
  // runtime error is thrown.
    if (testEval(e) is Undefined) Expect.fail("unreachable"); //  //# 95: continued
}

test94(e) {
  // Check that the type-tested expression is evaluated before the
  // runtime error is thrown.
    if (testEval(e) as Undefined) Expect.fail("unreachable"); // //# 94: continued
}

main() {
  test99("99 bottles"); //# 99: compile-time error
  test98("98 bottles"); //# 98: compile-time error
  test97("97 bottles"); //# 97: compile-time error
  test96("96 bottles"); //# 96: compile-time error
  test95("95 bottles"); //# 95: compile-time error
  test94("94 bottles"); //# 94: compile-time error
}
