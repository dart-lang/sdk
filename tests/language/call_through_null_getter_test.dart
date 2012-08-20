// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that we can call functions through getters which return null.

final TOP_LEVEL_NULL = null;

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
    expectThrowsObjectNotClosureException(() { topLevel(); });
    expectThrowsObjectNotClosureException(() { (topLevel)(); });
    expectThrowsObjectNotClosureException(() { TOP_LEVEL_NULL(); });
    expectThrowsObjectNotClosureException(() { (TOP_LEVEL_NULL)(); });
  }

  static void testField() {
    A a = new A();

    a.field = null;
    expectThrowsObjectNotClosureException(() { a.field(); });
    expectThrowsObjectNotClosureException(() { (a.field)(); });
  }

  static void testGetter() {
    A a = new A();

    a.field = null;
    expectThrowsObjectNotClosureException(() { a.getter(); });
    expectThrowsObjectNotClosureException(() { (a.getter)(); });
  }

  static void testMethod() {
    A a = new A();

    a.field = null;
    expectThrowsObjectNotClosureException(() { a.method()(); });
  }

  static void expectThrowsNullPointerException(fn) {
    var exception = catchException(fn);
    if (!(exception is NullPointerException)) {
      Expect.fail("Wrong exception.  Expected: NullPointerException"
          " got: ${exception}");
    }
  }

  static void expectThrowsObjectNotClosureException(fn) {
    var exception = catchException(fn);
    if (!(exception is ObjectNotClosureException)) {
      Expect.fail("Wrong exception.  Expected: ObjectNotClosureException"
          " got: ${exception}");
    }
  }

  static catchException(fn) {
    bool caught = false;
    var result = null;
    try {
      fn();
      Expect.equals(true, false);  // Shouldn't reach this.
    } catch (var e) {
      caught = true;
      result = e;
    }
    Expect.equals(true, caught);
    return result;
  }

}


class A {

  A() { }
  var field;
  get getter { return field; }
  method() { return field; }

}

main() {
  CallThroughNullGetterTest.testMain();
}
