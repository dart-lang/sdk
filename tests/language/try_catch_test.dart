// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MyException {
  MyException() {}
}

class MyException1 extends MyException {
  MyException1() : super() {}
}

class MyException2 extends MyException {
  MyException2() : super() {}
}

class TryCatchTest {
  static void test1() {
    var foo = 0;
    try {
      throw new MyException1();
    } catch (MyException2 e) {
      foo = 1;
    } catch (MyException1 e) {
      foo = 2;
    } catch (MyException e) {
      foo = 3;
    }
    Expect.equals(2, foo);
  }

  static void test2() {
    var foo = 0;
    try {
      throw new MyException1();
    } catch (MyException2 e) {
      foo = 1;
    } catch (MyException e) {
      foo = 2;
    } catch (MyException1 e) {
      foo = 3;
    }
    Expect.equals(2, foo);
  }

  static void test3() {
    var foo = 0;
    try {
      throw new MyException();
    } catch (MyException2 e) {
      foo = 1;
    } catch (MyException1 e) {
      foo = 2;
    } catch (MyException e) {
      foo = 3;
    }
    Expect.equals(3, foo);
  }

  static void test4() {
    var foo = 0;
    try {
      try {
        throw new MyException();
      } catch (MyException2 e) {
        foo = 1;
      } catch (MyException1 e) {
        foo = 2;
      }
    } catch (MyException e) {
      Expect.equals(0, foo);
      foo = 3;
    }
    Expect.equals(3, foo);
  }

  static void test5() {
    var foo = 0;
    try {
      throw new MyException1();
    } catch (MyException2 e) {
      foo = 1;
    } catch (var e) {
      foo = 2;
    }
    Expect.equals(2, foo);
  }

  static void test6() {
    var foo = 0;
    try {
      throw new MyException();
    } catch (MyException2 e) {
      foo = 1;
    } catch (MyException1 e) {
      foo = 2;
    } catch (var e) {
      foo = 3;
    }
    Expect.equals(3, foo);
  }

  static void test7() {
    var foo = 0;
    try {
      try {
        throw new MyException();
      } catch (MyException2 e) {
        foo = 1;
      } catch (MyException1 e) {
        foo = 2;
      }
    } catch (var e) {
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
    } catch (var exc) {
      caught = true;
    }
    Expect.equals(true, caught);
    Expect.equals(3, e);
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
  }
}

main() {
  TryCatchTest.testMain();
}
