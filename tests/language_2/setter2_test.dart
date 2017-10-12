// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing use of 'this' in an instance method.

import "package:expect/expect.dart";

class Nested {
  Nested(int val) : a = val {}
  int a;
  int foo(int i) {
    return i;
  }
}

class Second {
  int a;
  static Nested obj;

  Second(int val) {}

  void bar(int value) {
    a = value;
    Second.obj.a = Second.obj.foo(this.a);
    this.a = 100;
    Expect.equals(100, a);
  }
}

class Setter2Test {
  static testMain() {
    Second obj = new Second(10);
    Second.obj = new Nested(10);
    Second.obj.a = 10;
    Expect.equals(10, Second.obj.a);
    Expect.equals(10, Second.obj.foo(10));
    obj.bar(20);
    Expect.equals(20, Second.obj.a);
  }
}

main() {
  Setter2Test.testMain();
}
