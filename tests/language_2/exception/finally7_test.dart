// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing execution of finally blocks after an exception
// is thrown from inside a local function capturing a variable.

import "package:expect/expect.dart";

class MyException {
  const MyException(String message) : message_ = message;
  final String message_;
}

class Helper {
  static int f1(int k) {
    var b;
    try {
      var a = new List(10);
      int i = 0;
      while (i < 10) {
        int j = i;
        a[i] = () {
          if (j == 5) {
            throw new MyException("Test for exception being thrown");
          }
          k += 10;
          return j;
        };
        if (i == 0) {
          b = a[i];
        }
        i++;
      }
      for (int i = 0; i < 10; i++) {
        a[i]();
      }
    } on MyException catch (exception) {
      k += 100;
      print(exception.message_);
      b();
    } finally {
      k += 1000;
      b();
    }
    return k;
  }
}

class ExecuteFinally7Test {
  static testMain() {
    Expect.equals(1171, Helper.f1(1));
  }
}

main() {
  ExecuteFinally7Test.testMain();
}
