// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing Mints. Note that the tests may not work on 64-bit machines,
// as Smi's would be used to represent many of the numbers.

library MediumIntegerTest;

import "package:expect/expect.dart";

class MediumIntegerTest {
  static int getMint() {
    return 1234567890123456789;
  }

  static testSmiOverflow() {
    int a = 1073741823;
    int b = 1073741822;
    Expect.equals(2147483645, a + b);
    Expect.equals(1152921501385621506, a * b);
    Expect.equals(-2147483645, -a - b);
  }

  static testMintAdd() {
    // Mint and Smi.
    var a = 1234567890123456789;
    var b = 2;
    Expect.equals(1234567890123456791, a + b);
    Expect.equals(1234567890123456791, b + a);
    a = 9223372036854775807;
    Expect.equals(9223372036854775808, a + 1);

    // Mint and Mint.
    a = 100000000000000001;
    Expect.equals(200000000000000002, a + a);
    a = 9223372036854775800;
    b = 1000000000000000000;
    Expect.equals(10223372036854775800, a + b);

    // Mint and Bigint.
    a = 100000000000000001;
    b = 10000000000000000001;
    Expect.equals(10100000000000000002, a + b);

    // Mint and double.
    var da = 100000000000.0;
    b = 100000000000;
    Expect.equals(200000000000.0, da + b);
    Expect.equals(200000000000.0, b + da);
  }

  static testMintSub() {
    // Mint and Smi.
    var a = 1234567890123456789;
    var b = 2;
    Expect.equals(1234567890123456787, a - b);
    a = -9223372036854775808;
    Expect.equals(-9223372036854775809, a - 1);

    // Mint and Mint.
    a = 1234567890123456789;
    b = 1000000000000000000;
    Expect.equals(234567890123456789, a - b);
    a = -9223372036854775808;
    b = 1000000000000000000;
    Expect.equals(-10223372036854775808, a - b);
  }

  static testMintDiv() {
    // Mint and Smi.
    var a = 1234567890123456788;
    var b = 2;
    Expect.equals(617283945061728394.0, a / b);
  }

  static testMintMul() {
    // Mint and Smi.
    var a = 4611686018427387904;
    var b = 10;
    Expect.equals(46116860184273879040, a * b);
    b = 1000000000000000000;
    Expect.equals(4611686018427387904000000000000000000, a * b);
  }

  static testMintAnd(mint) {
    // Issue 1845.
    final int t = 0;
    var res = mint & (t - 1);
    Expect.equals(mint, res);
  }

  static void testMain() {
    Expect.equals(1234567890123456789, getMint());
    testSmiOverflow();
    testMintAdd();
    testMintSub();
    testMintMul();
    testMintDiv();
    testMintAnd(-1925149952);
    testMintAnd(1925149952);
    testMintAnd(0x100000001);
    var a = 100000000000;
    var b = 100000000001;
    Expect.equals(false, a.hashCode == b.hashCode);
    Expect.equals(true, a.hashCode == (b - 1).hashCode);
  }
}

main() {
  for (int i = 0; i < 4000; i++) {
    MediumIntegerTest.testMain();
  }
}
