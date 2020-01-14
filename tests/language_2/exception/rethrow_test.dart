// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

import "package:expect/expect.dart";

class MyException {
  const MyException();
}

class OtherException {
  const OtherException();
}

class RethrowTest {
  MyException currentException;

  void throwException() {
    currentException = new MyException();
    throw currentException;
  }

  void testRethrowPastUncaught() {
    try {
      try {
        try {
          throwException();
          Expect.fail("Should have thrown an exception");
        } catch (e) {
          Expect.equals(true, identical(e, currentException));
          rethrow;
          Expect.fail("Should have thrown an exception");
        }
      } on OtherException catch (e) {
        Expect.fail("Should not have caught OtherException");
      }
    } catch (e) {
      Expect.equals(true, identical(e, currentException));
    }
  }

  void testRethrow() {
    try {
      try {
        throwException();
        Expect.fail("Should have thrown an exception");
      } catch (e) {
        Expect.equals(true, identical(e, currentException));
        rethrow;
        Expect.fail("Should have thrown an exception");
      }
    } catch (e) {
      Expect.equals(true, identical(e, currentException));
    }
  }
}

main() {
  RethrowTest t = new RethrowTest();
  t.testRethrow();
  t.testRethrowPastUncaught();
}
