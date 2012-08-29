// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing Bigints.
// TODO(srdjan): Make sure the numbers are Bigint and not Mint or Smi.

#library("BigIntegerTest.dart");
#import("dart:coreimpl");

class BigIntegerTest {

  static void checkBigint(int a) {
    Expect.equals(true, (a is Bigint));
  }

  static foo() {
    return 1234567890123456789;
  }

  static testSmiOverflow() {
    var a = 1073741823;
    var b = 1073741822;
    Expect.equals(2147483645, a + b);
    a = -1000000000;
    b =  1000000001;
    Expect.equals(-2000000001, a - b);
    Expect.equals(-1000000001000000000, a * b);
  }

  static testBigintAdd() {
    // Bigint and Smi.
    var a = 12345678901234567890;
    var b = 2;
    Expect.equals(12345678901234567892, a + b);
    Expect.equals(12345678901234567892, b + a);
    // Bigint and Bigint.
    a = 10000000000000000001;
    Expect.equals(20000000000000000002, a + a);
    // Bigint and double.
    a = 100000000000.0;
    b = 100000000000;
    Expect.equals(200000000000.0, a + b);
    Expect.equals(200000000000.0, b + a);
  }

  static testBigintSub() {
    // Bigint and Smi.
    var a = 12345678901234567890;
    var b = 2;
    Expect.equals(12345678901234567888, a - b);
    Expect.equals(-12345678901234567888, b - a);
    // Bigint and Bigint.
    a = 10000000000000000001;
    Expect.equals(20000000000000000002, a + a);
    // Bigint and double.
    a = 100000000000.0;
    b = 100000000000;
    Expect.equals(200000000000.0, a + b);
    Expect.equals(200000000000.0, b + a);
    Expect.equals(-1, 0xF00000000 - 0xF00000001);
  }

  static testBigintMul() {
    // Bigint and Smi.
    var a = 12345678901234567890;
    var b = 10;
    Expect.equals(123456789012345678900, a * b);
    Expect.equals(123456789012345678900, b * a);
    // Bigint and Bigint.
    a = 12345678901234567890;
    b = 10000000000000000;
    Expect.equals(123456789012345678900000000000000000, a * b);
    // Bigint and double.
    a = 200.0;
    b = 100000000000;
    Expect.equals(20000000000000.0, a * b);
    Expect.equals(20000000000000.0, b * a);
  }

  static testBigintTruncDiv() {
    var a = 12345678901234567890;
    var b = 10;
    // Bigint and Smi.
    Expect.equals(1234567890123456789, a ~/ b);
    Expect.equals(0, b ~/ a);
    Expect.equals(123456789, 123456789012345678 ~/ 1000000000);
    // Bigint and Bigint.
    a = 12345678901234567890;
    b = 10000000000000000;
    Expect.equals(1234, a ~/ b);
    // Bigint and double.
    a = 200.0;
    b = 100000000000;
    Expect.equals(0.0, a ~/ b);
    Expect.equals(500000000.0, b ~/ a);
  }

  static testBigintDiv() {
    // Bigint and Smi.
    Expect.equals(1234567890123456789.1, 12345678901234567891 / 10);
    Expect.equals(0.000000001234, 1234 / 1000000000000);
    Expect.equals(12345678901234000000.0, 123456789012340000000 / 10);
    // Bigint and Bigint.
    var a = 12345670000000000000;
    var b = 10000000000000000;
    Expect.equals(1234.567, a / b);
    // Bigint and double.
    a = 200.0;
    b = 100000000000;
    Expect.equals(0.000000002, a / b);
    Expect.equals(500000000.0, b / a);
  }

  static testBigintRemainder() {
    // Bigint and Smi.
    var a = 1000000000005;
    var b = 10;
    Expect.equals(5, a % b);
    Expect.equals(10, b % a);
    // Bigint & Bigint
    a = 10000000000000000001;
    b = 10000000000000000000;
    Expect.equals(1, a % b);
    Expect.equals(10000000000000000000, b % a);
    // Bigint & double.
    a = 100000000001.0;
    b = 100000000000;
    Expect.equals(1.0, a % b);
    Expect.equals(100000000000.0, b % a);
  }

  static testBigintNegate() {
    var a = 0xF000000000F;
    var b = ~a;  // negate.
    Expect.equals(-0xF0000000010, b);
    Expect.equals(0, a & b);
    Expect.equals(-1, a | b);
  }

  static testShiftAmount() {
    Expect.equals(0, 12 >> 111111111111111111111111111111);
    Expect.equals(-1, -12 >> 111111111111111111111111111111);
    bool exceptionCaught = false;
    try {
      var a = 1 << 1111111111111111111111111111;
    } on OutOfMemoryException catch (e) {
      exceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
  }

  static testMain() {
    Expect.equals(1234567890123456789, foo());
    testSmiOverflow();
    testBigintAdd();
    testBigintSub();
    testBigintMul();
    testBigintRemainder();
    testBigintTruncDiv();
    testBigintDiv();
    testBigintNegate();
    testShiftAmount();
    Expect.equals(1234567890123456, (1234567890123456).abs());
    Expect.equals(1234567890123456, (-1234567890123456).abs());
    var a = 10000000000000000000;
    var b = 10000000000000000001;
    checkBigint(a);
    checkBigint(b);
    Expect.equals(false, a.hashCode() == b.hashCode());
    Expect.equals(true, a.hashCode() == (b - 1).hashCode());
  }
}

main() {
  BigIntegerTest.testMain();
}
