// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test megamorphic calls.

import "package:expect/expect.dart";

class A {
  A() {}
  f1() {
    return 1;
  }

  f2() {
    return 2;
  }

  f3() {
    return 3;
  }

  f4() {
    return 4;
  }

  f5() {
    return 5;
  }

  f6() {
    return 6;
  }

  f7() {
    return 7;
  }

  f8() {
    return 8;
  }

  f9() {
    return 9;
  }

  f11() {
    return 11;
  }

  f12() {
    return 12;
  }

  f13() {
    return 13;
  }

  f14() {
    return 14;
  }

  f15() {
    return 15;
  }

  f16() {
    return 16;
  }

  f17() {
    return 17;
  }

  f18() {
    return 18;
  }

  f19() {
    return 19;
  }

  f20() {
    return 20;
  }

  f21() {
    return 21;
  }

  f22() {
    return 22;
  }

  f23() {
    return 23;
  }

  f24() {
    return 24;
  }

  f25() {
    return 25;
  }

  f26() {
    return 26;
  }

  f27() {
    return 27;
  }

  f28() {
    return 28;
  }

  f29() {
    return 29;
  }

  f30() {
    return 30;
  }

  f31() {
    return 31;
  }

  f32() {
    return 32;
  }

  f33() {
    return 33;
  }

  f34() {
    return 34;
  }

  f35() {
    return 35;
  }

  f36() {
    return 36;
  }

  f37() {
    return 37;
  }

  f38() {
    return 38;
  }

  f39() {
    return 39;
  }
}

class B extends A {
  B() : super() {}
}

class ManyCallsTest {
  static testMain() {
    var list = new List(10);
    for (int i = 0; i < (list.length ~/ 2); i++) {
      list[i] = new A();
    }
    for (int i = (list.length ~/ 2); i < list.length; i++) {
      list[i] = new B();
    }
    for (int loop = 0; loop < 7; loop++) {
      for (int i = 0; i < list.length; i++) {
        Expect.equals(1, list[i].f1());
        Expect.equals(2, list[i].f2());
        Expect.equals(3, list[i].f3());
        Expect.equals(4, list[i].f4());
        Expect.equals(5, list[i].f5());
        Expect.equals(6, list[i].f6());
        Expect.equals(7, list[i].f7());
        Expect.equals(8, list[i].f8());
        Expect.equals(9, list[i].f9());
        Expect.equals(11, list[i].f11());
        Expect.equals(12, list[i].f12());
        Expect.equals(13, list[i].f13());
        Expect.equals(14, list[i].f14());
        Expect.equals(15, list[i].f15());
        Expect.equals(16, list[i].f16());
        Expect.equals(17, list[i].f17());
        Expect.equals(18, list[i].f18());
        Expect.equals(19, list[i].f19());
        Expect.equals(20, list[i].f20());
        Expect.equals(21, list[i].f21());
        Expect.equals(22, list[i].f22());
        Expect.equals(23, list[i].f23());
        Expect.equals(24, list[i].f24());
        Expect.equals(25, list[i].f25());
        Expect.equals(26, list[i].f26());
        Expect.equals(27, list[i].f27());
        Expect.equals(28, list[i].f28());
        Expect.equals(29, list[i].f29());
        Expect.equals(30, list[i].f30());
        Expect.equals(31, list[i].f31());
        Expect.equals(32, list[i].f32());
        Expect.equals(33, list[i].f33());
        Expect.equals(34, list[i].f34());
        Expect.equals(35, list[i].f35());
        Expect.equals(36, list[i].f36());
        Expect.equals(37, list[i].f37());
        Expect.equals(38, list[i].f38());
        Expect.equals(39, list[i].f39());
      }
    }
  }
}

main() {
  ManyCallsTest.testMain();
}
