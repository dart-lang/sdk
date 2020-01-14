// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

import "package:expect/expect.dart";

class MyException {
  const MyException(String this.message_);
  final String message_;
}

class Helper {
  static int f1(int i) {
    try {
      int j;
      j = func();
      if (j > 0) {
        throw new MyException("Test for exception being thrown");
      }
    } on MyException catch (exception) {
      i = 100;
      print(exception.message_);
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
    return i;
  }
}

class ThrowTest {
  static testMain() {
    Expect.equals(900, Helper.f1(1));
  }
}

main() {
  ThrowTest.testMain();
}
