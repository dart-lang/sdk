// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

class MyException {
  const MyException(String message) : message_ = message;
  final String message_;
}

class Helper {
  static int f1(int i) {
    try {
      i = func();
      i = 10;
    } catch (MyException exception, var stacktrace) {
      i = 50;
      print(exception.message_);
      Expect.equals((stacktrace != null), true);
      print(stacktrace);
    }
    try {
      int j;
      i = func1();
      i = 200;
    } catch (MyException exception, var stacktrace) {
      i = 50;
      print(exception.message_);
      Expect.equals((stacktrace != null), true);
      print(stacktrace);
    }
    try {
      int j;
      i = func2();
      i = 200;
    } catch (MyException exception, var stacktrace) {
      i = 50;
      print(exception.message_);
      Expect.equals((stacktrace != null), true);
      print(stacktrace);
    } finally {
      i = i + 800;
    }
    return i;
  }

  static int func() {
    int i = 0;
    while (i < 10) {
      i++;
    }
    if (i > 0) {
      throw new MyException("Exception Test for stack trace being printed");
    }
    return 10;
  }

  static int func1() {
    try {
      func();
    } catch (MyException exception) {
      throw new MyException("Exception Test for stack trace being printed");;
    }
    return 10;
  }

  static int func2() {
    try {
      func();
    } catch (MyException exception) {
      throw;
    }
    return 10;
  }

}

class StackTraceTest {
  static testMain() {
    Expect.equals(850, Helper.f1(1));
  }
}

main() {
  StackTraceTest.testMain();
}
