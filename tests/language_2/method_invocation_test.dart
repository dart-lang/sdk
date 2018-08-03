// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Testing method invocation.
// Currently testing only NoSuchMethodError.

class A {
  A() {}
  int foo() {
    return 1;
  }
}

class B {
  get f {
    throw 123;
  }
}

class MethodInvocationTest {
  static void testNullReceiver() {
    A a = new A();
    Expect.equals(1, a.foo());
    a = null;
    bool exceptionCaught = false;
    try {
      a.foo();
    } on NoSuchMethodError catch (e) {
      exceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
  }

  static testGetterMethodInvocation() {
    var b = new B();
    try {
      b.f();
    } catch (e) {
      Expect.equals(123, e);
    }
  }

  static void testMain() {
    testNullReceiver();
    testGetterMethodInvocation();
  }
}

main() {
  MethodInvocationTest.testMain();
}
