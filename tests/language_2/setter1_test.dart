// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing setting/getting of fields when
// only getter/setter methods are specified.

import "package:expect/expect.dart";

class First {
  First(int val) : a_ = val {}

  void testMethod() {
    a = 20;
  }

  static void testStaticMethod() {
    b = 20;
  }

  int get a {
    return a_;
  }

  void set a(int val) {
    a_ = a_ + val;
  }

  static int get b {
    return b_;
  }

  static void set b(int val) {
    b_ = val;
  }

  int a_;
  static int b_;
}

class Second {
  static int c;
  int a_;

  Second(int value) : a_ = value {}

  void testMethod() {
    a = 20;
  }

  static void testStaticMethod() {
    int i;
    b = 20;
    i = d;
    // TODO(asiva): Turn these on once we have error handling.
    // i = b; // Should be an error.
    // d = 40; // Should be an error.
  }

  int get a {
    return a_;
  }

  void set a(int value) {
    a_ = a_ + value;
  }

  static void set b(int value) {
    Second.c = value;
  }

  static int get d {
    return Second.c;
  }
}

class Setter1Test {
  static testMain() {
    First obj1 = new First(10);
    Expect.equals(10, obj1.a);
    obj1.testMethod();
    Expect.equals(30, obj1.a);
    First.b = 10;
    Expect.equals(10, First.b);
    First.testStaticMethod();
    Expect.equals(20, First.b);

    Second obj = new Second(10);
    Expect.equals(10, obj.a);
    obj.testMethod();
    Expect.equals(30, obj.a);

    Second.testStaticMethod();
    Expect.equals(20, Second.c);
    Expect.equals(20, Second.d);
  }
}

main() {
  Setter1Test.testMain();
}
