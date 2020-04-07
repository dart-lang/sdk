// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

import "package:expect/expect.dart";

class MyException {
  const MyException([String message = ""]) : message_ = message;
  final String message_;
}

class Helper {
  static int f1(int i) {
    try {
      int j;
      i = 100;
      i = func();
      i = 200;
    } on MyException catch (exception) {
      i = 50;
      print(exception.message_);
    } finally {
      i = i + 800;
    }
    return i;
  }

  static int func() {
    try {
      int i = 0;
      while (i < 10) {
        i++;
      }
      if (i > 0) {
        throw new MyException("Test for exception being thrown");
      }
    } on MyException catch (ex) {
      print(ex.message_);
      rethrow; // Rethrow the exception.
    }
    return 10;
  }
}

class Throw3Test {
  static testMain() {
    Expect.equals(850, Helper.f1(1));
  }
}

main() {
  Throw3Test.testMain();
}
