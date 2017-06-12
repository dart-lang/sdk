// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests static and instance fields initialization.
class DefaultInitTest {
  static testMain() {
    Expect.equals(0, A.a);
    Expect.equals(2, A.b);
    Expect.equals(null, A.c);

    A a1 = new A(42);
    Expect.equals(42, a1.d);
    Expect.equals(null, a1.e);

    A a2 = new A.named(43);
    Expect.equals(null, a2.d);
    Expect.equals(43, a2.e);

    Expect.equals(42, B.instance.x);
    Expect.equals(3, C.instance.z);
  }
}

class A {
  static const int a = 0;
  static const int b = 2;
  static int c;
  int d;
  int e;

  A(int val) {
    d = val;
  }

  A.named(int val) {
    e = val;
  }
}

// The following tests cover cases described in b/4101270

class B {
  static const B instance = const B();
  // by putting this field after the static initializer above, the JS code gen
  // was calling the constructor before the setter of this property was defined.
  final int x;
  const B() : this.x = (41 + 1);
}

class C {
  // forward reference to another class
  static const D instance = const D();
  C() {}
}

class D {
  const D() : this.z = 3;
  final int z;
}

main() {
  DefaultInitTest.testMain();
}
