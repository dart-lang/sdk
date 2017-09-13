// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.

import "package:expect/expect.dart";

class NamedParametersTest {
  static int F00() {
    return 0;
  }

  int f11() {
    return 0;
  }

  static int F11(int a) {
    return a;
  }

  int f22(int a) {
    return a;
  }

  static int F10([int b = 20]) {
    return b;
  }

  int f21([int b = 20]) {
    return b;
  }

  static int F21(int a, [int b = 20]) {
    return 100 * a + b;
  }

  int f32(int a, [int b = 20]) {
    return 100 * a + b;
  }

  static int F31(int a, [int b = 20, int c = 30]) {
    return 100 * (100 * a + b) + c;
  }

  int f42(int a, [int b = 20, int c = 30]) {
    return 100 * (100 * a + b) + c;
  }

  static int F41(int a, [int b = 20, int c, int d = 40]) {
    return 100 * (100 * (100 * a + b) + (c == null ? 0 : c)) + d;
  }

  int f52(int a, [int b = 20, int c, int d = 40]) {
    return 100 * (100 * (100 * a + b) + (c == null ? 0 : c)) + d;
  }

  static testMain() {
    NamedParametersTest np = new NamedParametersTest();
    Expect.equals(0, F00());
    Expect.equals(0, np.f11());
    Expect.equals(10, F11(10));
    Expect.equals(10, np.f22(10));
    Expect.equals(20, F10());
    Expect.equals(20, np.f21());
    Expect.equals(20, F10(20));
    Expect.equals(20, np.f21(20));
    Expect.equals(20, F10(b:20)); // //# 01: compile-time error
    Expect.equals(20, np.f21(b:20)); // //# 02: compile-time error
    Expect.equals(1020, F21(10));
    Expect.equals(1020, np.f32(10));
    Expect.equals(1025, F21(10, 25));
    Expect.equals(1025, np.f32(10, 25));
    Expect.equals(1025, F21(10, b:25)); // //# 03: compile-time error
    Expect.equals(1025, np.f32(10, b:25)); // //# 04: compile-time error
    Expect.equals(102030, F31(10));
    Expect.equals(102030, np.f42(10));
    Expect.equals(102530, F31(10, 25));
    Expect.equals(102530, np.f42(10, 25));
    Expect.equals(102035, F31(10, c:35)); // //# 05: compile-time error
    Expect.equals(102035, np.f42(10, c:35)); // //# 06: compile-time error
    Expect.equals(102535, F31(10, 25, 35));
    Expect.equals(102535, np.f42(10, 25, 35));
    Expect.equals(102535, F31(10, 25, c:35)); // //# 07: compile-time error
    Expect.equals(102535, np.f42(10, 25, c:35)); // //# 08: compile-time error
    Expect.equals(10200040, F41(10));
    Expect.equals(10200040, np.f52(10));
    Expect.equals(10203540, F41(10, c:35)); // //# 09: compile-time error
    Expect.equals(10203540, np.f52(10, c:35)); // //# 10: compile-time error
  }
}

abstract class I {
  factory I() = C;
  int mul(int a, [int factor]);
}

class C implements I {
  int mul(int a, [int factor = 10]) {
    return a * factor;
  }
}

hello(msg, to, {from}) => '${from} sent ${msg} to ${to}';
message() => hello("gladiolas", "possums", from: "Edna");

main() {
  NamedParametersTest.testMain();
  var i = new I();
  Expect.equals(100, i.mul(10));
  Expect.equals(1000, i.mul(10, 100));
  var c = new C();
  Expect.equals(100, c.mul(10));
  Expect.equals(1000, c.mul(10, 100));
  Expect.equals("Edna sent gladiolas to possums", message());
}
