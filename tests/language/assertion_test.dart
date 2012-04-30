// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test program testing assert statements.

class AssertionTest {
  static testTrue() {
    int i = 0;
    try {
      assert(true);
    } catch (AssertionError error) {
      i = 1;
    }
    return i;
  }

  static testFalse() {
    int i = 0;
    try {
      assert(false);
    } catch (AssertionError error) {
      i = 1;
    }
    return i;
  }

  static unknown(var a) {
    return (a) ? true : false;
  }

  static testUnknown() {
    var x = unknown(false);
    int i = 0;
    try {
      assert(x);
    } catch (AssertionError error) {
      i = 1;
    }
    return i;    
  }

  static testClosure() {
    int i = 0;
    try {
      assert(() => false);
    } catch (AssertionError error) {
      i = 1;
    }
    return i;
  }

  static testClosure2() {
    int i = 0;
    try {
      var x = () => false;
      assert(x);
    } catch (AssertionError error) {
      i = 1;
    }
    return i;
  }

  static testMain() {
    Expect.equals(0, testTrue());
    Expect.equals(1, testFalse());
    Expect.equals(1, testClosure());
    Expect.equals(1, testClosure2());
  }
}

main() {
  AssertionTest.testMain();
}
