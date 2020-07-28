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
    if (e is Undefined) Expect.fail("unreachable");
    //       ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_UNDEFINED_NAME
    // [cfe] 'Undefined' isn't a type.
}

test98(e) {
  // Test that a runtime error is thrown when the 'as' operator checks for a
  // malformed type.
    if (e as Undefined) Expect.fail("unreachable");
    //       ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
    // [cfe] 'Undefined' isn't a type.
}

test97(e) {
    // Check that the remaining expression after the type test
    // with malformed type is parsed, but not executed at runtime.
    // Regression test for issue 16985.
    if (e is Undefined && testEval(e)) Expect.fail("unreachable");
    //       ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_UNDEFINED_NAME
    // [cfe] 'Undefined' isn't a type.
}

test96(e) {
    // Check that the remaining expression after the type test
    // with malformed type is parsed, but not executed at runtime.
    // Regression test for issue 16985.
    if (e as Undefined && testEval(e)) Expect.fail("unreachable");
    //       ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
    // [cfe] 'Undefined' isn't a type.
}

test95(e) {
  // Check that the type-tested expression is evaluated before the
  // runtime error is thrown.
    if (testEval(e) is Undefined) Expect.fail("unreachable");
    //                 ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_UNDEFINED_NAME
    // [cfe] 'Undefined' isn't a type.
}

test94(e) {
  // Check that the type-tested expression is evaluated before the
  // runtime error is thrown.
    if (testEval(e) as Undefined) Expect.fail("unreachable");
    //                 ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
    // [cfe] 'Undefined' isn't a type.
}

main() {
  test99("99 bottles");
  test98("98 bottles");
  test97("97 bottles");
  test96("96 bottles");
  test95("95 bottles");
  test94("94 bottles");
}
