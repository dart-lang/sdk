// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement

import "package:expect/expect.dart";

class MyException {
  const MyException(String message) : message_ = message;
  final String message_;
}

class Helper {
  static int f1(int i) {
    try {
      i = func();
      i = 10;
    } on MyException catch (exception, stacktrace) {
      i = 50;
      print(exception.message_);
      Expect.isNotNull(stacktrace);
      print(stacktrace);
    }
    try {
      int j;
      i = func1();
      i = 200;
    } on MyException catch (exception, stacktrace) {
      i = 50;
      print(exception.message_);
      Expect.isNotNull(stacktrace);
      print(stacktrace);
    }
    try {
      int j;
      i = func2();
      i = 200;
    } on MyException catch (exception, stacktrace) {
      i = 50;
      print(exception.message_);
      Expect.isNotNull(stacktrace);
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
    } on MyException catch (exception) {
      throw new MyException("Exception Test for stack trace being printed");
      ;
    }
    return 10;
  }

  static int func2() {
    try {
      func();
    } on MyException catch (exception) {
      rethrow;
    }
    return 10;
  }
}

class StackTraceTest {
  static testMain() {
    Expect.equals(850, Helper.f1(1));
  }
}

// Test that the full stack trace is generated for rethrow.
class RethrowStacktraceTest {
  var config = 0;

  issue12940() {
    throw "Progy";
  }

  b() {
    issue12940();
  }

  c() {
    if (config == 0) {
      try {
        b();
      } catch (e) {
        rethrow;
      }
    } else {
      try {
        b();
      } catch (e, s) {
        rethrow;
      }
    }
  }

  d() {
    c();
  }

  testBoth() {
    for (config = 0; config < 2; config++) {
      try {
        d();
      } catch (e, s) {
        Expect.isTrue(s.toString().contains("issue12940"));
      }
    }
  }

  static testMain() {
    var test = new RethrowStacktraceTest();
    test.testBoth();
  }
}

main() {
  StackTraceTest.testMain();
  RethrowStacktraceTest.testMain();
}
