// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_asserts
//
// Dart test program testing assert statements.

class AssertTest {
  static test() {
    int i = 0;
    try {
      assert(false);
    } on AssertionError catch (error) {
      i = 1;
      Expect.equals("false", error.failedAssertion);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("assert_test.dart", subs);
      Expect.equals(12, error.line);
      Expect.equals(14, error.column);
    }
    return i;
  }
  static testClosure() {
    int i = 0;
    try {
      assert(() => false);
    } on AssertionError catch (error) {
      i = 1;
      Expect.equals("() => false", error.failedAssertion);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("assert_test.dart", subs);
      Expect.equals(30, error.line);
      Expect.equals(14, error.column);
    }
    return i;
  }

  static testMain() {
    Expect.equals(1, test());
    Expect.equals(1, testClosure());
  }
}

main() {
  AssertTest.testMain();
}
