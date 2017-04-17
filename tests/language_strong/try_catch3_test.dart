// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing try/catch statement without any exceptions
// being thrown.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

abstract class TestException {
  String getMessage();
}

class MyException implements TestException {
  const MyException([String message = ""]) : this._message = message;
  String getMessage() {
    return _message;
  }

  final String _message;
}

class MyParameterizedException<U, V> implements TestException {
  const MyParameterizedException([String message = ""])
      : this._message = message;
  String getMessage() {
    return _message;
  }

  final String _message;
}

class StackTrace {
  StackTrace() {}
  printStackTrace(TestException ex) {
    print(ex);
  }
}

class Helper {
  static int test1(int i) {
    try {
      int j;
      j = f2();
      j = f3();
      try {
        int k = f2();
        f3();
      } on MyException catch (ex) {
        int i = 10;
        print(i);
      } on TestException catch (ex) {
        int k = 10;
        print(k);
      }
      try {
        j = j + 24;
      } catch (e) {
        i = 300;
        print(e.getMessage());
      }
      try {
        j += 20;
      } catch (e) {
        i = 400;
        print(e.getMessage());
      }
      try {
        j += 40;
      } catch (e) {
        i = 600;
        print(e.getMessage());
      }
      try {
        j += 60;
      } catch (e, trace) {
        i = 700;
        print(trace.toString());
        print(e.getMessage());
      }
      try {
        j += 80;
      } on MyException catch (e) {
        i = 500;
        print(e.getMessage());
      }
    } on MyParameterizedException<String, TestException> catch (e, trace) {
      i = 800;
      print(trace.toString());
      rethrow;
    } on MyException catch (exception) {
      i = 100;
      print(exception.getMessage());
    } on TestException catch (e, trace) {
      i = 200;
      print(trace.toString());
    } finally {
      i = 900;
    }
    return i;
  }

  static int f2() {
    return 2;
  }

  static int f3() {
    int i = 0;
    while (i < 10) {
      i++;
    }
    return i;
  }
}

class TryCatchTest {
  static testMain() {
    Expect.equals(900, Helper.test1(1));
  }
}

main() {
  for (var i = 0; i < 20; i++) {
    TryCatchTest.testMain();
  }
}
