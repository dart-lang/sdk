// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_asserts

// Dart test program testing assert statements.

import "package:expect/expect.dart";

class AssertTest {
  static test() {
    try {
      assert(false);
      Expect.fail("Assertion 'false' didn't fail.");
    } on AssertionError catch (error) {
      Expect.isTrue(error.toString().contains("'false'"));
      Expect.isTrue(
          error.stackTrace.toString().contains("assert_test.dart:13:14"));
    }
  }

  static testClosure() {
    try {
      assert(() => false);
      Expect.fail("Assertion '() => false' didn't fail.");
    } on AssertionError catch (error) {
      Expect.isTrue(error.toString().contains("'() => false'"));
      Expect.isTrue(
          error.stackTrace.toString().contains("assert_test.dart:24:14"));
    }
  }

  static testMain() {
    test();
    testClosure();
  }
}

main() {
  AssertTest.testMain();
}
