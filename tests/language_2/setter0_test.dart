// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing setting/getting of fields when
// only getter/setter methods are specified.

import "package:expect/expect.dart";

class First {
  First(int val) : a_ = val {}
  int a_;
}

class Second extends First {
  static int c;

  Second(int val) : super(val) {}

  static void testStaticMethod() {
    int i;
    Second.static_a = 20;
    i = Second.c;
  }

  void set instance_a(int value) {
    a_ = a_ + value;
  }

  int get instance_a {
    return a_;
  }

  static void set static_a(int value) {
    Second.c = value;
  }

  static int get static_d {
    return Second.c;
  }
}

class Setter0Test {
  static testMain() {
    Second obj = new Second(10);
    Expect.equals(10, obj.instance_a);
    obj.instance_a = 20;
    Expect.equals(30, obj.instance_a);

    Second.testStaticMethod();
    Expect.equals(20, Second.c);
    Expect.equals(20, Second.static_d);
  }
}

main() {
  Setter0Test.testMain();
}
