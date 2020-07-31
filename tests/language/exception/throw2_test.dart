// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

import "package:expect/expect.dart";

abstract class TestException {
  String getMessage();
}

class MyException implements TestException {
  const MyException([String message = ""]) : message_ = message;
  String getMessage() {
    return message_;
  }

  final String message_;
}

class MyException2 implements TestException {
  const MyException2([String message = ""]) : message_ = message;
  String getMessage() {
    return message_;
  }

  final String message_;
}

class MyException3 implements TestException {
  const MyException3([String message = ""]) : message_ = message;
  String getMessage() {
    return message_;
  }

  final String message_;
}

class Helper {
  static int f1(int i) {
    try {
      int j;
      j = func();
    } on MyException3 catch (exception) {
      i = 100;
      print(exception.getMessage());
    } on MyException2 catch (exception) {
      try {
        i = func2();
        i = 200;
      } on TestException catch (exception) {
        i = 50;
      }
      print(exception.getMessage());
    } on MyException catch (exception) {
      i = func2();
      print(exception.getMessage());
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
      throw new MyException2("Test for exception being thrown");
    }
    return i;
  }

  static int func2() {
    int i = 0;
    while (i < 10) {
      i++;
    }
    if (i > 0) {
      throw new MyException2("Test for exception being thrown");
    }
    return i;
  }
}

class Throw2Test {
  static testMain() {
    Expect.equals(850, Helper.f1(1));
  }
}

main() {
  Throw2Test.testMain();
}
