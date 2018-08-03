// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int x = 1;
  A() {}
  A.reassign() : x = 2 {}
  A.reassign2(this.x) {}
}

class B extends A {
  B() : super() {}
  B.reassign() : super.reassign() {}
  B.reassign2() : super.reassign2(3) {}
}

class InstanceFieldInitializerTest {
  static testMain() {
    Expect.equals(1, new A().x);
    Expect.equals(2, new A.reassign().x);
    Expect.equals(3, new A.reassign2(3).x);

    Expect.equals(1, new B().x);
    Expect.equals(2, new B.reassign().x);
    Expect.equals(3, new B.reassign2().x);
  }
}

main() {
  InstanceFieldInitializerTest.testMain();
}
