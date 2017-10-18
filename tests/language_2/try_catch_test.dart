// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

class MyException {}

class MyException1 extends MyException {}

class MyException2 extends MyException {}

class TryCatchTest {
  static void test1() {
    var foo = 0;
    try {
      throw new MyException1();
    } on MyException2 catch (e) {
      foo = 1;
    } on MyException1 catch (e) {
      foo = 2;
    } on MyException catch (e) {
      foo = 3;
    }
    Expect.equals(2, foo);
  }

  static void test2() {
    var foo = 0;
    try {
      throw new MyException1();
    } on MyException2 catch (e) {
      foo = 1;
    } on MyException catch (e) {
      foo = 2;
    } on MyException1 catch (e) {
      foo = 3;
    }
    Expect.equals(2, foo);
  }

  static void test3() {
    var foo = 0;
    try {
      throw new MyException();
    } on MyException2 catch (e) {
      foo = 1;
    } on MyException1 catch (e) {
      foo = 2;
    } on MyException catch (e) {
      foo = 3;
    }
    Expect.equals(3, foo);
  }

  static void test4() {
    var foo = 0;
    try {
      try {
        throw new MyException();
      } on MyException2 catch (e) {
        foo = 1;
      } on MyException1 catch (e) {
        foo = 2;
      }
    } on MyException catch (e) {
      Expect.equals(0, foo);
      foo = 3;
    }
    Expect.equals(3, foo);
  }

  static void test5() {
    var foo = 0;
    try {
      throw new MyException1();
    } on MyException2 catch (e) {
      foo = 1;
    } catch (e) {
      foo = 2;
    }
    Expect.equals(2, foo);
  }

  static void test6() {
    var foo = 0;
    try {
      throw new MyException();
    } on MyException2 catch (e) {
      foo = 1;
    } on MyException1 catch (e) {
      foo = 2;
    } catch (e) {
      foo = 3;
    }
    Expect.equals(3, foo);
  }

  static void test7() {
    var foo = 0;
    try {
      try {
        throw new MyException();
      } on MyException2 catch (e) {
        foo = 1;
      } on MyException1 catch (e) {
        foo = 2;
      }
    } catch (e) {
      Expect.equals(0, foo);
      foo = 3;
    }
    Expect.equals(3, foo);
  }

  static void test8() {
    var e = 3;
    var caught = false;
    try {
      throw new MyException();
    } catch (exc) {
      caught = true;
    }
    Expect.equals(true, caught);
    Expect.equals(3, e);
  }

  static void test9() {
    dynamic e = 6;
    try {
      throw "up";
    } on String {
      e = "s";
    } on int {
      e = "i";
    }
    Expect.equals("s", e);
  }

  static void test10() {
    try {
      throw "up";
    } on String catch (e) {
      var e = 1; // ok, shadows exception variable.
      Expect.equals(1, e);
    }
  }

  static void test11() {
    var e0 = 11;
    try {
      throw "up";
    } on int catch (e0) {
      Expect.fail("unreachable");
    } on String catch (e1) {
      // e0 from the other catch clause is not in scope.
      Expect.equals(11, e0);
    }
  }

  static void test12() {
    const x = const [];
    try {
      throw "up";
    } catch (e) {
      Expect.equals("up", e);
    } on String catch (e) {
      // Compile-time constants in unreachable catch blocks are still
      // compiled.
      const y = x[0]; // //# 01: compile-time error
      Expect.fail("unreachable");
    }
  }

  static void testMain() {
    test1();
    test2();
    test3();
    test4();
    test5();
    test6();
    test7();
    test8();
    test9();
    test10();
    test11();
    test12();
  }
}

main() {
  for (var i = 0; i < 20; i++) {
    TryCatchTest.testMain();
  }
}
