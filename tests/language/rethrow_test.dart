// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

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
        } catch (var e) {
          Expect.equals(true, e === currentException);
          throw;
          Expect.fail("Should have thrown an exception");
        }
      } catch (OtherException e) {
        Expect.fail("Should not have caught OtherException");
      }
    } catch (var e) {
      Expect.equals(true, e === currentException);
    }
  }

  void testRethrow() {
    try {
      try {
        throwException();
        Expect.fail("Should have thrown an exception");
      } catch (var e) {
        Expect.equals(true, e === currentException);
        throw;
        Expect.fail("Should have thrown an exception");
      }
    } catch (var e) {
      Expect.equals(true, e === currentException);
    }
  }
}

main() {
  RethrowTest t = new RethrowTest();
  t.testRethrow();
  t.testRethrowPastUncaught();
}
