// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing Mints. Note that the tests may not work on 64-bit machines,
// as Smi's would be used to represent many of the numbers.

#library("MediumIntegerTest.dart");
#import("dart:coreimpl");

class MediumIntegerTest {

  static void checkSmi(int a) {
    Expect.equals(true, (a is Smi));
  }

  static void checkMint(int a) {
    Expect.equals(true, (a is Mint));
  }

  static void checkBigint(int a) {
    Expect.equals(true, (a is Bigint));
  }

  static int getMint() {
    return 1234567890123456789;
  }

  static testSmiOverflow() {
     int a = 1073741823;
     int b = 1073741822;
     checkSmi(a);
     checkSmi(b);
     checkMint(a + b);
     Expect.equals(2147483645, a + b);
     checkMint(a * b);
     Expect.equals(1152921501385621506, a * b);
     checkMint(-a - b);
     Expect.equals(-2147483645, -a - b);
  }

  static testMintAdd() {
    // Mint and Smi.
    var a = 1234567890123456789;
    var b = 2;
    checkMint(a);
    checkSmi(b);
    checkMint(a + b);
    Expect.equals(1234567890123456791, a + b);
    Expect.equals(1234567890123456791, b + a);
    a = 9223372036854775807;
    checkMint(a);
    checkBigint(a + 1);
    Expect.equals(9223372036854775808, a + 1);

    // Mint and Mint.
    a = 100000000000000001;
    checkMint(a);
    Expect.equals(200000000000000002, a + a);
    a = 9223372036854775800;
    b = 1000000000000000000;
    checkMint(a);
    checkMint(b);
    checkBigint(a + b);
    Expect.equals(10223372036854775800, a + b);

    // Mint and Bigint.
    a = 100000000000000001;
    b = 10000000000000000001;
    checkMint(a);
    checkBigint(b);
    Expect.equals(10100000000000000002, a + b);

    // Mint and double.
    a = 100000000000.0;
    b = 100000000000;
    checkMint(b);
    Expect.equals(200000000000.0, a + b);
    Expect.equals(200000000000.0, b + a);
  }

  static testMintSub() {
    // Mint and Smi.
    var a = 1234567890123456789;
    var b = 2;
    checkMint(a);
    checkSmi(b);
    checkMint(a - b);
    Expect.equals(1234567890123456787, a - b);
    a = -9223372036854775808;
    checkMint(a);
    checkBigint(a - 1);
    Expect.equals(-9223372036854775809, a - 1);

    // Mint and Mint.
    a = 1234567890123456789;
    b = 1000000000000000000;
    checkMint(a);
    checkMint(b);
    checkMint(a - b);
    Expect.equals(234567890123456789, a - b);
    a = -9223372036854775808;
    b = 1000000000000000000;
    checkMint(a);
    checkMint(b);
    checkBigint(a - b);
    Expect.equals(-10223372036854775808, a - b);
  }

  static testMintDiv() {
    // Mint and Smi.
    var a = 1234567890123456788;
    var b = 2;
    checkMint(a);
    checkSmi(b);
    Expect.equals(617283945061728394.0, a / b);
  }

  static testMintMul() {
    // Mint and Smi.
    var a = 4611686018427387904;
    var b = 10;
    checkMint(a);
    checkSmi(b);
    checkBigint(a * b);
    Expect.equals(46116860184273879040, a * b);
    b = 1000000000000000000;
    checkMint(a);
    checkMint(b);
    checkBigint(a * b);
    Expect.equals(4611686018427387904000000000000000000, a * b);
  }

  static testMintAnd(mint) {
    // Issue 1845.
    final int t = 0;
    var res = mint & (t - 1);
    Expect.equals(mint, res);
  }

  // TODO(srdjan): Add more tests.

  static void testMain() {
    checkMint(getMint());
    Expect.equals(1234567890123456789, getMint());
    testSmiOverflow();
    testMintAdd();
    testMintSub();
    testMintMul();
    testMintDiv();
    testMintAnd(-1925149952);
    testMintAnd(1925149952);
    var a = 100000000000;
    var b = 100000000001;
    checkMint(a);
    checkMint(b);
    Expect.equals(false, a.hashCode() == b.hashCode());
    Expect.equals(true, a.hashCode() == (b - 1).hashCode());
  }
}

main() {
  for (int i = 0; i < 1000; i++) {
    MediumIntegerTest.testMain();
  }
}
