// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

import "package:expect/expect.dart";

class MyException {
  const MyException(String message) : message_ = message;
  final String message_;
}

class Helper1 {
  static int func1() {
    return func2();
  }

  static int func2() {
    return func3();
  }

  static int func3() {
    return func4();
  }

  static int func4() {
    var i = 0;
    try {
      i = 10;
      func5();
    } on ArgumentError catch (e) {
      i = 100;
      Expect.isNotNull(e.stackTrace, "Errors need a stackTrace on throw");
    }
    return i;
  }

  static void func5() {
    // Throw an Error.
    throw new ArgumentError("ArgumentError in func5");
  }
}

class Helper2 {
  static int func1() {
    return func2();
  }

  static int func2() {
    return func3();
  }

  static int func3() {
    return func4();
  }

  static int func4() {
    var i = 0;
    try {
      i = 10;
      func5();
    } on ArgumentError catch (e, s) {
      i = 200;
      Expect.isNotNull(e.stackTrace, "Errors need a stackTrace on throw");
      Expect.equals(e.stackTrace.toString(), s.toString());
    }
    return i;
  }

  static List func5() {
    // Throw an Error.
    throw new ArgumentError("ArgumentError in func5");
  }
}

class Helper3 {
  static int func1() {
    return func2();
  }

  static int func2() {
    return func3();
  }

  static int func3() {
    return func4();
  }

  static int func4() {
    var i = 0;
    try {
      i = 10;
      func5();
    } on MyException catch (e) {
      i = 300;
      try {// //# 00: continued
        // There should be no stackTrace in this normal exception object.
        // We should get a NoSuchMethodError.
        var trace = e.stackTrace; //  //# 00: compile-time error
      } on NoSuchMethodError catch (e) {// //# 00: continued
        Expect.isNotNull(e.stackTrace, "Error needs a stackTrace on throw");// //# 00: continued
      }// //# 00: continued
    }
    return i;
  }

  static List func5() {
    // Throw an Exception (any random object).
    throw new MyException("MyException in func5");
  }
}

class ErrorStackTraceTest {
  static testMain() {
    Expect.equals(100, Helper1.func1());
    Expect.equals(200, Helper2.func1());
    Expect.equals(300, Helper3.func1());
  }
}

main() {
  ErrorStackTraceTest.testMain();
}
