// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correct instance compound assignment operator.

class A {
  A() : f = 2 {}
  var f;
}


class B {
  B() : _a = new A(), count = 0 {}
  get a() {
    count++;
    return _a;
  }
  var _a;
  var count;
}


class InstanceCompoundAssignmentOperatorTest {
  static void testMain() {
    B b = new B();
    Expect.equals(0, b.count);
    Expect.equals(2, b.a.f);
    Expect.equals(1, b.count);
    var o = b.a;
    Expect.equals(2, b.count);
    b.a.f = 1;
    Expect.equals(3, b.count);
    b.a.f += 1;
    Expect.equals(4, b.count);
  }
}
main() {
  InstanceCompoundAssignmentOperatorTest.testMain();
}
