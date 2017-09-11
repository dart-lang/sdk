// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing unhandled exceptions.

class MyException {
  const MyException(String message) : message_ = message;
  String getMessage() { return message_; }
  final String message_;
}

class Helper {
  static int f1(int i) {
    int j;
    j = i + 200;
    j = j + 300;
    throw new MyException("Unhandled Exception");
    return i;
  }
}

class UnhandledExceptionNegativeTest {
  static testMain() {
    Helper.f1(1);
  }
}

main() {
  UnhandledExceptionNegativeTest.testMain();
}
