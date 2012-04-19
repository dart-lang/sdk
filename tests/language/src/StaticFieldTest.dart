// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing setting/getting/initializing static fields.

class First {
  First() {}
  static var a;
  static var b;
  static final int c = 1;
  static setValues() {
    a = 24;
    b = 10;
    return a + b + c;
  }
}


class InitializerTest {
  static var one;
  static var two = 2;
  static var three = 2;

  static checkValueOfThree() {
    // We need to keep this check separate to prevent three from
    // getting initialized before the += is executed.
    Expect.equals(3, three);
  }

  static void testStaticFieldInitialization() {
    Expect.equals(null, one);
    Expect.equals(2, two);
    one = 11;
    two = 22;
    Expect.equals(11, one);
    Expect.equals(22, two);

    // Assignment operators exercise a different code path.  Make sure
    // that initialization works here as well.
    three += 1;
    checkValueOfThree();
  }
}


class StaticFieldTest {
  static testMain() {
    First.a = 3;
    First.b = First.a;
    Expect.equals(3, First.a);
    Expect.equals(First.a, First.b);
    First.b = (First.a = 10);
    Expect.equals(10, First.a);
    Expect.equals(10, First.b);
    First.b = First.a = 15;
    Expect.equals(15, First.a);
    Expect.equals(15, First.b);
    Expect.equals(35, First.setValues());
    Expect.equals(24, First.a);
    Expect.equals(10, First.b);
  }
}


main() {
  StaticFieldTest.testMain();
  InitializerTest.testStaticFieldInitialization();
}
