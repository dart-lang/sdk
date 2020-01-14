// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing super calls

import "package:expect/expect.dart";

class A {
  A() : field = 0 {}
  int field;
  incrField() {
    field++;
  }

  timesX(v) {
    return v * 2;
  }
}

class B extends A {
  incrField() {
    field++;
    super.incrField();
  }

  timesX(v) {
    return super.timesX(v) * 3;
  }

  B() : super() {}
}

class SuperCallTest {
  static testMain() {
    var b = new B();
    b.incrField();
    Expect.equals(2, b.field);
    Expect.equals(12, b.timesX(2));
  }
}

main() {
  SuperCallTest.testMain();
}
