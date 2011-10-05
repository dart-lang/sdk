// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing try/catch statement without any exceptions
// being thrown.
// Negative test should fail compilation illegal finally specifier.

interface TestException {
  String getMessage();
}

class MyException implements TestException {
  const MyException(String message = "") : message_ = message;
  String getMessage() { return message_; }
  final String message_;
}

class StackTrace {
  StackTrace() { }
}

class Helper {
  static int f1(int i) {
    try {
      int j;
      j = f2();
      j = f3();
    } finally (e) {
      i = 200;
    }
    return i;
  }

  static int f2() {
    return 2;
  }

  static int f3() {
    int i = 0;
    while (i < 10) {
      i++;
    }
    return i;
  }
}

class TryCatch4NegativeTest {
  static testMain() {
    Expect.equals(1, Helper.f1(1));
  }
}

main() {
  TryCatch4NegativeTest.testMain();
}
