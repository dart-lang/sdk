// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests that we can call functions through getters which return null.

const TOP_LEVEL_NULL = null;

var topLevel;

class CallThroughNullGetterTest {
  static void testMain() {
    testTopLevel();
    testField();
    testGetter();
    testMethod();
  }

  static void testTopLevel() {
    topLevel = null;
    expectThrowsNoSuchMethodError(() {
      topLevel();
    });
    expectThrowsNoSuchMethodError(() {
      (topLevel)();
    });
    expectThrowsNoSuchMethodError(() {
      TOP_LEVEL_NULL();
    });
    expectThrowsNoSuchMethodError(() {
      (TOP_LEVEL_NULL)();
    });
  }

  static void testField() {
    A a = new A();

    a.field = null;
    expectThrowsNoSuchMethodError(() {
      a.field();
    });
    expectThrowsNoSuchMethodError(() {
      (a.field)();
    });
  }

  static void testGetter() {
    A a = new A();

    a.field = null;
    expectThrowsNoSuchMethodError(() {
      a.getter();
    });
    expectThrowsNoSuchMethodError(() {
      (a.getter)();
    });
  }

  static void testMethod() {
    A a = new A();

    a.field = null;
    expectThrowsNoSuchMethodError(() {
      a.method()();
    });
  }

  static void expectThrowsNoSuchMethodError(fn) {
    Expect.throws(
        fn, (e) => e is NoSuchMethodError, "Should throw NoSuchMethodError");
  }
}

class A {
  A() {}
  var field;
  get getter {
    return field;
  }

  method() {
    return field;
  }
}

main() {
  CallThroughNullGetterTest.testMain();
}
