// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing setting/getting/initializing static fields.

import "package:expect/expect.dart";

class First {
  First() {}
  static var a;
  static var b;
  static const int c = 1;
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

class StaticField1RunNegativeTest {
  static // //# 01: static type warning, runtime error
  var x;
  testMain() {
    var foo = new StaticField1RunNegativeTest();
    print(x); // Used to compile 'x' and force any errors.
    var result = foo.x;
  }
}

class StaticField1aRunNegativeTest {
  static // //# 02: static type warning, runtime error
  void m() {}

  testMain() {
    var foo = new StaticField1aRunNegativeTest();
    print(m); // Used to compile 'm' and force any errors.
    var result = foo.m;
  }
}

class StaticField2RunNegativeTest {
  static //# 03:  static type warning, runtime error
  var x;

  testMain() {
    var foo = new StaticField2RunNegativeTest();
    print(x); // Used to compile 'x' and force any errors.
    foo.x = 1;
  }
}

class StaticField2aRunNegativeTest {
  static //  //# 04: static type warning, runtime error
  void m() {}

  testMain() {
    var foo = new StaticField2aRunNegativeTest();
    print(m); // Used to compile 'm' and force any errors.
    foo.m = 1; //# 04:continued
  }
}

main() {
  StaticFieldTest.testMain();
  InitializerTest.testStaticFieldInitialization();
  new StaticField1RunNegativeTest().testMain();
  new StaticField1aRunNegativeTest().testMain();
  new StaticField2RunNegativeTest().testMain();
  new StaticField2aRunNegativeTest().testMain();
}
