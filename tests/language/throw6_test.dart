// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

import "package:expect/expect.dart";

class MyException1 {
  const MyException1([String message = "1"]) : message_ = message;
  final String message_;
}

class Helper {
  Helper() : i = 0 {}

  int f1() {
    int j = 0;
    try {
      j = func();
    } catch (exception) {
      i = i + 100;
      print(exception.message_);
    } finally {
      i = i + 1000;
    }
    return i;
  }

  // No catch in the same function for the type of exception being thrown
  // in the try block here. We expect the handler if checks to fall thru,
  // the finally block to run and an implicit rethrow to happen.
  int func() {
    i = 0;
    try {
      while (i < 10) {
        i++;
      }
      if (i > 0) {
        throw new MyException1("Test for MyException1 being thrown");
      }
    } finally {
      i = 800;
    }
    return i;
  }

  int i;
}

class Throw6Test {
  static testMain() {
    Expect.equals(1900, new Helper().f1());
  }
}

main() {
  Throw6Test.testMain();
}
