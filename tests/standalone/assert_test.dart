// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_asserts
//
// Dart test program testing assert statements.

class AssertTest {
  static test() {
    try {
      assert(false);
      Expect.fail("Assertion 'false' didn't fail.");
    } on AssertionError catch (error) {
      Expect.equals("false", error.failedAssertion);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("assert_test.dart", subs);
      Expect.equals(11, error.line);
      Expect.equals(14, error.column);
    }
  }
  static testClosure() {
    try {
      assert(() => false);
      Expect.fail("Assertion '() => false' didn't fail.");
    } on AssertionError catch (error) {
      Expect.equals("() => false", error.failedAssertion);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("assert_test.dart", subs);
      Expect.equals(27, error.line);
      Expect.equals(14, error.column);
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
