// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

import "package:expect/expect.dart";

class MyException1 {
  const MyException1([String message = "1"]) : message_ = message;
  final String message_;
}

class MyException2 {
  const MyException2([String message = "2"]) : message_ = message;
  final String message_;
}

class MyException3 {
  const MyException3([String message = "3"]) : message_ = message;
  final String message_;
}

class Helper {
  static int f1(int i) {
    try {
      int j;
      j = func();
    } on MyException3 catch (exception) {
      i = 300;
      print(exception.message_);
    } on MyException2 catch (exception) {
      i = 200;
      print(exception.message_);
    } on MyException1 catch (exception) {
      i = 100;
      print(exception.message_);
    } finally {
      i = i + 800;
    }
    return i;
  }

  // No catch in the same function for the type of exception being thrown
  // in the try block here. We expect the handler if checks to fall thru and
  // implicit rethrow to happen.
  static int func() {
    int i = 0;
    try {
      while (i < 10) {
        i++;
      }
      if (i > 0) {
        throw new MyException1("Test for MyException1 being thrown");
      }
    } on MyException3 catch (exception) {
      i = 300;
      print(exception.message_);
    } on MyException2 catch (exception) {
      i = 200;
      print(exception.message_);
    }
    return i;
  }
}

class Throw5Test {
  static testMain() {
    Expect.equals(900, Helper.f1(1));
  }
}

main() {
  Throw5Test.testMain();
}
