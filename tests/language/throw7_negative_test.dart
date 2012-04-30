// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

class MyException1 {
  const MyException1([String message = "1"]) : message_ = message;
  final String message_;
}

class Helper {
  Helper() : i = 0 { }

  int f1() {
    int j = 0;
    try {
      j = i;
    } catch (var exception) {
      i = i + 100;
      print(exception.message_);
    }
    // Since there is a generic 'catch all' statement preceding this
    // we expect to get a dead code error/warning over here.
    catch (MyException1 exception) {
      i = i + 100;
      print(exception.message_);
    }
    finally {
      i = i + 1000;
    }
    return i;
  }

  int i;
}

class Throw7NegativeTest {
  static testMain() {
    new Helper().f1();
  }
}

main() {
  Throw7NegativeTest.testMain();
}
