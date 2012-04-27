// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing try/catch statement without any exceptions
// being thrown.

interface TestException {
  String getMessage();
}

class MyException implements TestException {
  const MyException([String message = ""]) : this._message = message;
  String getMessage() { return _message; }
  final String _message;
}

class MyParameterizedException<U, V> implements TestException {
  const MyParameterizedException([String message = ""])
      : this._message = message;
  String getMessage() { return _message; }
  final String _message;
}

class StackTrace {
  StackTrace() { }
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
      } catch (MyException ex) {
        int i = 10;
        print(i);
      } catch (TestException ex) {
        int k = 10;
        print(k);
      }
      try {
        j = j + 24;
      } catch (var e) {
        i = 300;
        print(e.getMessage());
      }
      try {
        j += 20;
      } catch (final e) {
        i = 400;
        print(e.getMessage());
      }
      try {
        j += 40;
      } catch (var e) {
        i = 600;
        print(e.getMessage());
      }
      try {
        j += 60;
      } catch (var e, var trace) {
        i = 700;
        trace.printStackTrace(e);
        print(e.getMessage());
      }
      try {
        j += 80;
      } catch (final MyException e) {
        i = 500;
        print(e.getMessage());
      }
    } catch (MyParameterizedException<String, TestException> e, var trace) {
      i = 800;
      trace.printStackTrace(e);
      throw;
    } catch (MyException exception) {
      i = 100;
      print(exception.getMessage());
    } catch (TestException e, StackTrace trace) {
      i = 200;
      trace.printStackTrace(e);
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
  TryCatchTest.testMain();
}
