// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing invocation of implicit closures.

import "package:expect/expect.dart";

class BaseClass {
  BaseClass(this._i) {}
  int foo() {
    return _i;
  }

  int _i;
}

class DerivedClass extends BaseClass {
  DerivedClass(this._y, int j) : super(j) {}
  int foo() {
    return _y;
  }

  getSuper() {
    return super.foo;
  }

  int _y;
}

class SuperImplicitClosureTest {
  static void testMain() {
    DerivedClass obj = new DerivedClass(20, 10);

    var ib = obj.foo;
    Expect.equals(obj._y, ib());

    ib = obj.getSuper();
    Expect.equals(obj._i, ib());
  }
}

main() {
  SuperImplicitClosureTest.testMain();
}
