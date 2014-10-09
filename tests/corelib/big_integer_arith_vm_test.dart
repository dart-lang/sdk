// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing Bigints with and without intrinsics.
// VMOptions=
// VMOptions=--no_intrinsify

library big_integer_test;
import "package:expect/expect.dart";

foo() => 1234567890123456789;
bar() => 12345678901234567890;

testSmiOverflow() {
  var a = 1073741823;
  var b = 1073741822;
  Expect.equals(2147483645, a + b);
  a = -1000000000;
  b =  1000000001;
  Expect.equals(-2000000001, a - b);
  Expect.equals(-1000000001000000000, a * b);
}

testBigintAdd() {
  // Bigint and Smi.
  var a = 12345678901234567890;
  var b = 2;
  Expect.equals(12345678901234567892, a + b);
  Expect.equals(12345678901234567892, b + a);
  // Bigint and Bigint.
  a = 10000000000000000001;
  Expect.equals(20000000000000000002, a + a);
  // Bigint and double.
  a = 100000000000000000000.0;
  b = 200000000000000000000;
  Expect.isTrue((a + b) is double);
  Expect.equals(300000000000000000000.0, a + b);
  Expect.isTrue((b + a) is double);
  Expect.equals(300000000000000000000.0, b + a);
}

testBigintSub() {
  // Bigint and Smi.
  var a = 12345678901234567890;
  var b = 2;
  Expect.equals(12345678901234567888, a - b);
  Expect.equals(-12345678901234567888, b - a);
  // Bigint and Bigint.
  a = 10000000000000000001;
  Expect.equals(20000000000000000002, a + a);
  // Bigint and double.
  a = 100000000000000000000.0;
  b = 200000000000000000000;
  Expect.isTrue((a + b) is double);
  Expect.equals(-100000000000000000000.0, a - b);
  Expect.isTrue((b + a) is double);
  Expect.equals(100000000000000000000.0, b - a);
  Expect.equals(-1, 0xF00000000 - 0xF00000001);
}

testBigintMul() {
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
  a = 2.0;
  b = 200000000000000000000;
  Expect.isTrue((a * b) is double);
  Expect.equals(400000000000000000000.0, a * b);
  Expect.isTrue((b * a) is double);
  Expect.equals(400000000000000000000.0, b * a);
}

testBigintTruncDiv() {
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
  a = 100000000000000000000.0;
  b = 200000000000000000000;
  Expect.equals(0, a ~/ b);
  Expect.equals(2, b ~/ a);
}

testBigintDiv() {
  // Bigint and Smi.
  Expect.equals(1234567890123456789.1, 12345678901234567891 / 10);
  Expect.equals(0.000000001234, 1234 / 1000000000000);
  Expect.equals(12345678901234000000.0, 123456789012340000000 / 10);
  // Bigint and Bigint.
  var a = 12345670000000000000;
  var b = 10000000000000000;
  Expect.equals(1234.567, a / b);
  // Bigint and double.
  a = 400000000000000000000.0;
  b = 200000000000000000000;
  Expect.equals(2.0, a / b);
  Expect.equals(0.5, b / a);
}

testBigintModulo() {
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
  a = 10000000100000000.0;
  b = 10000000000000000;
  Expect.equals(100000000.0, a % b);
  Expect.equals(10000000000000000.0, b % a);
  // Transitioning from Mint to Bigint.
  var iStart = 4611686018427387900;
  var prevX = -23 % iStart;
  for (int i = iStart + 1; i < iStart + 10; i++) {
    var x = -23 % i;
    Expect.equals(1, x - prevX);
    Expect.isTrue(x > 0);
    prevX = x;
  }
}

testBigintNegate() {
  var a = 0xF000000000000000F;
  var b = ~a;  // negate.
  Expect.equals(-0xF0000000000000010, b);
  Expect.equals(0, a & b);
  Expect.equals(-1, a | b);
}

testShiftAmount() {
  Expect.equals(0, 12 >> 111111111111111111111111111111);
  Expect.equals(-1, -12 >> 111111111111111111111111111111);
  bool exceptionCaught = false;
  try {
    var a = 1 << 1111111111111111111111111111;
  } on OutOfMemoryError catch (e) {
    exceptionCaught = true;
  }
  Expect.equals(true, exceptionCaught);
}

main() {
  Expect.equals(1234567890123456789, foo());
  Expect.equals(12345678901234567890, bar());
  testSmiOverflow();
  testBigintAdd();
  testBigintSub();
  testBigintMul();
  testBigintModulo();
  testBigintTruncDiv();
  testBigintDiv();
  testBigintNegate();
  testShiftAmount();
  Expect.equals(12345678901234567890, (12345678901234567890).abs());
  Expect.equals(12345678901234567890, (-12345678901234567890).abs());
  var a = 10000000000000000000;
  var b = 10000000000000000001;
  Expect.equals(false, a.hashCode == b.hashCode);
  Expect.equals(true, a.hashCode == (b - 1).hashCode);
  // TODO(regis): Add a test for modPow once it is public.
}
