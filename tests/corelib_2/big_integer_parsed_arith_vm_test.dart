// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing Bigints with and without intrinsics.
// VMOptions=
// VMOptions=--no_intrinsify

library big_integer_test;

import "package:expect/expect.dart";

addSubParsed(String a, String b, String sum) {
  int int_a = int.parse(a);
  int int_b = int.parse(b);
  int int_sum = int.parse(sum);
  int computed_sum = int_a + int_b;
  Expect.equals(int_sum, computed_sum);
  String str_sum = computed_sum >= 0
      ? "0x${computed_sum.toRadixString(16)}"
      : "-0x${(-computed_sum).toRadixString(16)}";
  Expect.equals(sum.toLowerCase(), str_sum);
  int computed_difference1 = int_sum - int_a;
  Expect.equals(int_b, computed_difference1);
  String str_difference1 = computed_difference1 >= 0
      ? "0x${computed_difference1.toRadixString(16)}"
      : "-0x${(-computed_difference1).toRadixString(16)}";
  Expect.equals(b.toLowerCase(), str_difference1);
  int computed_difference2 = int_sum - int_b;
  Expect.equals(int_a, computed_difference2);
  String str_difference2 = computed_difference2 >= 0
      ? "0x${computed_difference2.toRadixString(16)}"
      : "-0x${(-computed_difference2).toRadixString(16)}";
  Expect.equals(a.toLowerCase(), str_difference2);
}

testBigintAddSub() {
  String zero = "0x0";
  String one = "0x1";
  String minus_one = "-0x1";

  addSubParsed(zero, zero, zero);
  addSubParsed(zero, one, one);
  addSubParsed(one, zero, one);
  addSubParsed(one, one, "0x2");
  addSubParsed(minus_one, minus_one, "-0x2");
  addSubParsed("0x123", zero, "0x123");
  addSubParsed(zero, "0x123", "0x123");
  addSubParsed("0x123", one, "0x124");
  addSubParsed(one, "0x123", "0x124");
  addSubParsed(
      "0xFFFFFFF",
      one, // 28 bit overflow.
      "0x10000000");
  addSubParsed(
      "0xFFFFFFFF",
      one, // 32 bit overflow.
      "0x100000000");
  addSubParsed(
      "0xFFFFFFFFFFFFFF",
      one, // 56 bit overflow.
      "0x100000000000000");
  addSubParsed(
      "0xFFFFFFFFFFFFFFFF",
      one, // 64 bit overflow.
      "0x10000000000000000");
  addSubParsed(
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", // 128 bit.
      one,
      "0x100000000000000000000000000000000");
  addSubParsed("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", one,
      "0x10000000000000000000000000000000000000000000");
  addSubParsed(
      "0x8000000", // 28 bit overflow.
      "0x8000000",
      "0x10000000");
  addSubParsed(
      "0x80000000", // 32 bit overflow.
      "0x80000000",
      "0x100000000");
  addSubParsed(
      "0x80000000000000", // 56 bit overflow.
      "0x80000000000000",
      "0x100000000000000");
  addSubParsed(
      "0x8000000000000000", // 64 bit overflow.
      "0x8000000000000000",
      "0x10000000000000000");
  addSubParsed(
      "0x80000000000000000000000000000000", // 128 bit.
      "0x80000000000000000000000000000000",
      "0x100000000000000000000000000000000");
  addSubParsed(
      "0x8000000000000000000000000000000000000000000",
      "0x8000000000000000000000000000000000000000000",
      "0x10000000000000000000000000000000000000000000");

  {
    String a = "0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    String sum1 = "0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF1";
    String times2 = "0x2468ACF13579BDE02468ACF121579BDE02468ACF13579BDE0";
    addSubParsed(a, zero, a);
    addSubParsed(a, one, sum1);
    addSubParsed(a, a, times2);
  }

  addSubParsed("-0x123", minus_one, "-0x124");
  addSubParsed(minus_one, "-0x123", "-0x124");
  addSubParsed(
      "-0xFFFFFFF",
      minus_one, // 28 bit overflow.
      "-0x10000000");
  addSubParsed(
      "-0xFFFFFFFF",
      minus_one, // 32 bit overflow.
      "-0x100000000");
  addSubParsed(
      "-0xFFFFFFFFFFFFFF",
      minus_one, // 56 bit overflow.
      "-0x100000000000000");
  addSubParsed(
      "-0xFFFFFFFFFFFFFFFF",
      minus_one, // 64 bit overflow.
      "-0x10000000000000000");
  addSubParsed(
      "-0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", // 128 bit.
      minus_one,
      "-0x100000000000000000000000000000000");
  addSubParsed("-0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", minus_one,
      "-0x10000000000000000000000000000000000000000000");
  addSubParsed(
      "-0x8000000", // 28 bit overflow.
      "-0x8000000",
      "-0x10000000");
  addSubParsed(
      "-0x80000000", // 32 bit overflow.
      "-0x80000000",
      "-0x100000000");
  addSubParsed(
      "-0x80000000000000", // 56 bit overflow.
      "-0x80000000000000",
      "-0x100000000000000");
  addSubParsed(
      "-0x8000000000000000", // 64 bit overflow.
      "-0x8000000000000000",
      "-0x10000000000000000");
  addSubParsed(
      "-0x80000000000000000000000000000000", // 128 bit.
      "-0x80000000000000000000000000000000",
      "-0x100000000000000000000000000000000");
  addSubParsed(
      "-0x8000000000000000000000000000000000000000000",
      "-0x8000000000000000000000000000000000000000000",
      "-0x10000000000000000000000000000000000000000000");

  {
    String a = "-0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF0";
    String sum1 = "-0x123456789ABCDEF01234567890ABCDEF0123456789ABCDEF1";
    String times2 = "-0x2468ACF13579BDE02468ACF121579BDE02468ACF13579BDE0";
    addSubParsed(a, zero, a);
    addSubParsed(a, minus_one, sum1);
    addSubParsed(a, a, times2);
  }

  addSubParsed("0x10000000000000000000000000000000000000000000", "0xFFFF",
      "0x1000000000000000000000000000000000000000FFFF");
  addSubParsed("0x10000000000000000000000000000000000000000000",
      "0xFFFF00000000", "0x10000000000000000000000000000000FFFF00000000");
  addSubParsed("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", "0x100000000",
      "0x1000000000000000000000000000000000000FFFFFFFF");
  addSubParsed(
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
      "0x10000000000000000000",
      "0x10000000000000000000000000FFFFFFFFFFFFFFFFFFF");

  addSubParsed("0xB", "-0x7", "0x4");
  addSubParsed("-0xB", "-0x7", "-0x12");
  addSubParsed("0xB", "0x7", "0x12");
  addSubParsed("-0xB", "0x7", "-0x4");
  addSubParsed("-0x7", "0xB", "0x4");
  addSubParsed("-0x7", "-0xB", "-0x12");
  addSubParsed("0x7", "0xB", "0x12");
  addSubParsed("0x7", "-0xB", "-0x4");
}

shiftLeftParsed(String a, int amount, String result) {
  int int_a = int.parse(a);
  int int_result = int.parse(result);
  int shifted = int_a << amount;
  Expect.equals(int_result, shifted);
  String str_shifted = shifted >= 0
      ? "0x${shifted.toRadixString(16)}"
      : "-0x${(-shifted).toRadixString(16)}";
  Expect.equals(result.toLowerCase(), str_shifted);
  int back_shifted = shifted >> amount;
  Expect.equals(int_a, back_shifted);
  String str_back_shifted = back_shifted >= 0
      ? "0x${back_shifted.toRadixString(16)}"
      : "-0x${(-back_shifted).toRadixString(16)}";
  Expect.equals(a.toLowerCase(), str_back_shifted);
}

testBigintLeftShift() {
  String zero = "0x0";
  String one = "0x1";
  String minus_one = "-0x1";

  shiftLeftParsed(zero, 0, zero);
  shiftLeftParsed(one, 0, one);
  shiftLeftParsed("0x1234", 0, "0x1234");
  shiftLeftParsed(zero, 100000, zero);
  shiftLeftParsed(one, 1, "0x2");
  shiftLeftParsed(one, 28, "0x10000000");
  shiftLeftParsed(one, 32, "0x100000000");
  shiftLeftParsed(one, 64, "0x10000000000000000");
  shiftLeftParsed("0x5", 28, "0x50000000");
  shiftLeftParsed("0x5", 32, "0x500000000");
  shiftLeftParsed("0x5", 56, "0x500000000000000");
  shiftLeftParsed("0x5", 64, "0x50000000000000000");
  shiftLeftParsed("0x5", 128, "0x500000000000000000000000000000000");
  shiftLeftParsed("0x5", 27, "0x28000000");
  shiftLeftParsed("0x5", 31, "0x280000000");
  shiftLeftParsed("0x5", 55, "0x280000000000000");
  shiftLeftParsed("0x5", 63, "0x28000000000000000");
  shiftLeftParsed("0x5", 127, "0x280000000000000000000000000000000");
  shiftLeftParsed("0x8000001", 1, "0x10000002");
  shiftLeftParsed("0x80000001", 1, "0x100000002");
  shiftLeftParsed("0x8000000000000001", 1, "0x10000000000000002");
  shiftLeftParsed("0x8000001", 29, "0x100000020000000");
  shiftLeftParsed("0x80000001", 33, "0x10000000200000000");
  shiftLeftParsed(
      "0x8000000000000001", 65, "0x100000000000000020000000000000000");
  shiftLeftParsed(minus_one, 0, minus_one);
  shiftLeftParsed("-0x1234", 0, "-0x1234");
  shiftLeftParsed(minus_one, 1, "-0x2");
  shiftLeftParsed(minus_one, 28, "-0x10000000");
  shiftLeftParsed(minus_one, 32, "-0x100000000");
  shiftLeftParsed(minus_one, 64, "-0x10000000000000000");
  shiftLeftParsed("-0x5", 28, "-0x50000000");
  shiftLeftParsed("-0x5", 32, "-0x500000000");
  shiftLeftParsed("-0x5", 64, "-0x50000000000000000");
  shiftLeftParsed("-0x5", 27, "-0x28000000");
  shiftLeftParsed("-0x5", 31, "-0x280000000");
  shiftLeftParsed("-0x5", 63, "-0x28000000000000000");
  shiftLeftParsed("-0x8000001", 1, "-0x10000002");
  shiftLeftParsed("-0x80000001", 1, "-0x100000002");
  shiftLeftParsed("-0x8000000000000001", 1, "-0x10000000000000002");
  shiftLeftParsed("-0x8000001", 29, "-0x100000020000000");
  shiftLeftParsed("-0x80000001", 33, "-0x10000000200000000");
  shiftLeftParsed(
      "-0x8000000000000001", 65, "-0x100000000000000020000000000000000");
}

shiftRightParsed(String a, int amount, String result) {
  int int_a = int.parse(a);
  int int_result = int.parse(result);
  int shifted = int_a >> amount;
  Expect.equals(int_result, shifted);
  String str_shifted = shifted >= 0
      ? "0x${shifted.toRadixString(16)}"
      : "-0x${(-shifted).toRadixString(16)}";
  Expect.equals(result.toLowerCase(), str_shifted);
}

testBigintRightShift() {
  String zero = "0x0";
  String one = "0x1";
  String minus_one = "-0x1";

  shiftRightParsed(one, 1, zero);
  shiftRightParsed(minus_one, 1, minus_one);
  shiftRightParsed("-0x2", 1, minus_one);
  shiftRightParsed("0x12345678", 29, zero);
  shiftRightParsed("-0x12345678", 29, minus_one);
  shiftRightParsed("-0x12345678", 100, minus_one);
  shiftRightParsed("0x5", 1, "0x2");
  shiftRightParsed("0x5", 2, "0x1");
  shiftRightParsed("-0x5", 1, "-0x3");
  shiftRightParsed("-0x5", 2, "-0x2");
  shiftRightParsed("0x10000001", 28, one);
  shiftRightParsed("0x100000001", 32, one);
  shiftRightParsed("0x10000000000000001", 64, one);
  shiftRightParsed("-0x10000001", 28, "-0x2");
  shiftRightParsed("-0x100000001", 32, "-0x2");
  shiftRightParsed("-0x10000000000000001", 64, "-0x2");
  shiftRightParsed("0x30000000", 29, one);
  shiftRightParsed("0x300000000", 33, one);
  shiftRightParsed("0x30000000000000000", 65, one);
  shiftRightParsed("-0x30000000", 29, "-0x2");
  shiftRightParsed("-0x300000000", 33, "-0x2");
  shiftRightParsed("-0x30000000000000000", 65, "-0x2");
}

bitAndParsed(String a, String b, String result) {
  int int_a = int.parse(a);
  int int_b = int.parse(b);
  int int_result = int.parse(result);
  int anded = int_a & int_b;
  Expect.equals(int_result, anded);
  String str_anded = anded >= 0
      ? "0x${anded.toRadixString(16)}"
      : "-0x${(-anded).toRadixString(16)}";
  Expect.equals(result.toLowerCase(), str_anded);
  int anded2 = int_b & int_a;
  Expect.equals(int_result, anded2);
  String str_anded2 = anded2 >= 0
      ? "0x${anded2.toRadixString(16)}"
      : "-0x${(-anded2).toRadixString(16)}";
  Expect.equals(result.toLowerCase(), str_anded2);
}

testBigintBitAnd() {
  String zero = "0x0";
  String one = "0x1";
  String minus_one = "-0x1";

  bitAndParsed(one, zero, zero);
  bitAndParsed(one, one, one);
  bitAndParsed(minus_one, zero, zero);
  bitAndParsed(minus_one, one, one);
  bitAndParsed(minus_one, minus_one, minus_one);
  bitAndParsed("0x5", "0x3", one);
  bitAndParsed("0x5", minus_one, "0x5");
  bitAndParsed("0x50000000", one, zero);
  bitAndParsed("0x50000000", minus_one, "0x50000000");
  bitAndParsed("0x500000000", one, zero);
  bitAndParsed("0x500000000", minus_one, "0x500000000");
  bitAndParsed("0x50000000000000000", one, zero);
  bitAndParsed("0x50000000000000000", minus_one, "0x50000000000000000");
  bitAndParsed("-0x50000000", "-0x50000000", "-0x50000000");
  bitAndParsed("-0x500000000", "-0x500000000", "-0x500000000");
  bitAndParsed(
      "-0x50000000000000000", "-0x50000000000000000", "-0x50000000000000000");
  bitAndParsed("0x1234567890ABCDEF012345678", "0x876543210FEDCBA0987654321",
      "0x224422000A9C9A0002244220");
  bitAndParsed("-0x1234567890ABCDEF012345678", "-0x876543210FEDCBA0987654321",
      "-0x977557799FEFCFEF997755778");
  bitAndParsed("0x1234567890ABCDEF012345678", "-0x876543210FEDCBA0987654321",
      "0x101014589002044F010101458");
  bitAndParsed(
      "0x1234567890ABCDEF012345678FFFFFFFFFFFFFFFFFFFFFFFFF",
      "-0x876543210FEDCBA0987654321",
      "0x1234567890ABCDEF012345678789ABCDEF012345F6789ABCDF");
  bitAndParsed("0x12345678", "0xFFFFFFF", "0x2345678");
  bitAndParsed("0x123456789", "0xFFFFFFFF", "0x23456789");
  bitAndParsed("-0x10000000", "0xFFFFFFF", "0x0");
  bitAndParsed("-0x100000000", "0xFFFFFFFF", "0x0");
  bitAndParsed("-0x10000001", "0xFFFFFFF", "0xFFFFFFF");
  bitAndParsed("-0x100000001", "0xFFFFFFFF", "0xFFFFFFFF");
  bitAndParsed("-0x10000001", "0x3FFFFFFF", "0x2FFFFFFF");
  bitAndParsed("-0x100000001", "0x3FFFFFFFF", "0x2FFFFFFFF");
  bitAndParsed(
      "-0x10000000000000001", "0x3FFFFFFFFFFFFFFFF", "0x2FFFFFFFFFFFFFFFF");
  bitAndParsed("-0x100000000000000", "0xFFFFFFFFFFFFFF", "0x0");
  bitAndParsed("-0x10000000000000000", "0xFFFFFFFFFFFFFFFF", "0x0");
  bitAndParsed("-0x300000000000000", "0xFFFFFFFFFFFFFFF", "0xD00000000000000");
  bitAndParsed(
      "-0x30000000000000000", "0xFFFFFFFFFFFFFFFFF", "0xD0000000000000000");
  bitAndParsed("-0x10000000", "-0x10000000", "-0x10000000");
  bitAndParsed("-0x100000000", "-0x100000000", "-0x100000000");
  bitAndParsed(
      "-0x100000000000000", "-0x100000000000000", "-0x100000000000000");
  bitAndParsed(
      "-0x10000000000000000", "-0x10000000000000000", "-0x10000000000000000");
  bitAndParsed("-0x3", "-0x2", "-0x4");
  bitAndParsed("-0x10000000", "-0x10000001", "-0x20000000");
  bitAndParsed("-0x100000000", "-0x100000001", "-0x200000000");
  bitAndParsed(
      "-0x100000000000000", "-0x100000000000001", "-0x200000000000000");
  bitAndParsed(
      "-0x10000000000000000", "-0x10000000000000001", "-0x20000000000000000");
  bitAndParsed(
      "0x123456789ABCDEF01234567890",
      "0x3FFFFFFF", // Max Smi for 32 bits.
      "0x34567890");
  bitAndParsed(
      "0x123456789ABCDEF01274567890",
      "0x3FFFFFFF", // Max Smi for 32 bits.
      "0x34567890");
  bitAndParsed(
      "0x123456789ABCDEF01234567890",
      "0x40000000", // Max Smi for 32 bits + 1.
      "0x0");
  bitAndParsed(
      "0x123456789ABCDEF01274567890",
      "0x40000000", // Max Smi for 32 bits + 1.
      "0x40000000");
  bitAndParsed(
      "0x123456789ABCDEF01234567890",
      "0x3FFFFFFFFFFFFFFF", // Max Smi for 64 bits.
      "0x3CDEF01234567890");
  bitAndParsed(
      "0x123456789ACCDEF01234567890",
      "0x4000000000000000", // Max Smi for 64 bits + 1.
      "0x4000000000000000");
  bitAndParsed(
      "0x123456789ABCDEF01234567890",
      "0x4000000000000000", // Max Smi for 64 bits + 1.
      "0x0");
}

bitOrParsed(String a, String b, String result) {
  int int_a = int.parse(a);
  int int_b = int.parse(b);
  int int_result = int.parse(result);
  int ored = int_a | int_b;
  Expect.equals(int_result, ored);
  String str_ored = ored >= 0
      ? "0x${ored.toRadixString(16)}"
      : "-0x${(-ored).toRadixString(16)}";
  Expect.equals(result.toLowerCase(), str_ored);
  int ored2 = int_b | int_a;
  Expect.equals(int_result, ored2);
  String str_ored2 = ored2 >= 0
      ? "0x${ored2.toRadixString(16)}"
      : "-0x${(-ored2).toRadixString(16)}";
  Expect.equals(result.toLowerCase(), str_ored2);
}

testBigintBitOr() {
  String zero = "0x0";
  String one = "0x1";
  String minus_one = "-0x1";

  bitOrParsed(one, zero, one);
  bitOrParsed(one, one, one);
  bitOrParsed(minus_one, zero, minus_one);
  bitOrParsed(minus_one, one, minus_one);
  bitOrParsed(minus_one, minus_one, minus_one);
  bitOrParsed("-0x3", one, "-0x3");
  bitOrParsed("0x5", "0x3", "0x7");
  bitOrParsed("0x5", minus_one, minus_one);
  bitOrParsed("0x5", zero, "0x5");
  bitOrParsed("0x50000000", one, "0x50000001");
  bitOrParsed("0x50000000", minus_one, minus_one);
  bitOrParsed("0x500000000", one, "0x500000001");
  bitOrParsed("0x500000000", minus_one, minus_one);
  bitOrParsed("0x50000000000000000", one, "0x50000000000000001");
  bitOrParsed("0x50000000000000000", minus_one, minus_one);
  bitOrParsed("-0x50000000", "-0x50000000", "-0x50000000");
  bitOrParsed("-0x500000000", "-0x500000000", "-0x500000000");
  bitOrParsed(
      "-0x50000000000000000", "-0x50000000000000000", "-0x50000000000000000");
  bitOrParsed("0x1234567890ABCDEF012345678", "0x876543210FEDCBA0987654321",
      "0x977557799FEFCFEF997755779");
  bitOrParsed("-0x1234567890ABCDEF012345678", "-0x876543210FEDCBA0987654321",
      "-0x224422000A9C9A0002244221");
  bitOrParsed("0x1234567890ABCDEF012345678", "-0x876543210FEDCBA0987654321",
      "-0x854101010F440200985410101");
  bitOrParsed("0x1234567890ABCDEF012345678FFFFFFFFFFFFFFFFFFFFFFFFF",
      "-0x876543210FEDCBA0987654321", "-0x1");
  bitOrParsed("0x12345678", "0xFFFFFFF", "0x1FFFFFFF");
  bitOrParsed("0x123456789", "0xFFFFFFFF", "0x1FFFFFFFF");
  bitOrParsed("-0x10000000", "0xFFFFFFF", "-0x1");
  bitOrParsed("-0x100000000", "0xFFFFFFFF", "-0x1");
  bitOrParsed("-0x10000001", "0xFFFFFFF", "-0x10000001");
  bitOrParsed("-0x100000001", "0xFFFFFFFF", "-0x100000001");
  bitOrParsed("-0x10000001", "0x3FFFFFFF", "-0x1");
  bitOrParsed("-0x100000001", "0x3FFFFFFFF", "-0x1");
  bitOrParsed("-0x10000000000000001", "0x3FFFFFFFFFFFFFFFF", "-0x1");
  bitOrParsed("-0x100000000000000", "0xFFFFFFFFFFFFFF", "-0x1");
  bitOrParsed("-0x10000000000000000", "0xFFFFFFFFFFFFFFFF", "-0x1");
  bitOrParsed("-0x300000000000000", "0xFFFFFFFFFFFFFFF", "-0x1");
  bitOrParsed("-0x30000000000000000", "0xFFFFFFFFFFFFFFFFF", "-0x1");
  bitOrParsed("-0x10000000", "-0x10000000", "-0x10000000");
  bitOrParsed("-0x100000000", "-0x100000000", "-0x100000000");
  bitOrParsed("-0x100000000000000", "-0x100000000000000", "-0x100000000000000");
  bitOrParsed(
      "-0x10000000000000000", "-0x10000000000000000", "-0x10000000000000000");
  bitOrParsed("-0x10000000", "-0x10000001", "-0x1");
  bitOrParsed("-0x100000000", "-0x100000001", "-0x1");
  bitOrParsed("-0x100000000000000", "-0x100000000000001", "-0x1");
  bitOrParsed("-0x10000000000000000", "-0x10000000000000001", "-0x1");
  bitOrParsed("-0x10000000000000000", "-0x1", "-0x1");
}

bitXorParsed(String a, String b, String result) {
  int int_a = int.parse(a);
  int int_b = int.parse(b);
  int int_result = int.parse(result);
  int xored = int_a ^ int_b;
  Expect.equals(int_result, xored);
  String str_xored = xored >= 0
      ? "0x${xored.toRadixString(16)}"
      : "-0x${(-xored).toRadixString(16)}";
  Expect.equals(result.toLowerCase(), str_xored);
  int xored2 = int_b ^ int_a;
  Expect.equals(int_result, xored2);
  String str_xored2 = xored2 >= 0
      ? "0x${xored2.toRadixString(16)}"
      : "-0x${(-xored2).toRadixString(16)}";
  Expect.equals(result.toLowerCase(), str_xored2);
  int xored3 = int_a ^ xored2;
  Expect.equals(int_b, xored3);
  String str_xored3 = xored3 >= 0
      ? "0x${xored3.toRadixString(16)}"
      : "-0x${(-xored3).toRadixString(16)}";
  Expect.equals(b.toLowerCase(), str_xored3);
}

testBigintBitXor() {
  String zero = "0x0";
  String one = "0x1";
  String minus_one = "-0x1";

  bitXorParsed(one, zero, one);
  bitXorParsed(one, one, zero);
  bitXorParsed(minus_one, zero, minus_one);
  bitXorParsed(minus_one, one, "-0x2");
  bitXorParsed(minus_one, minus_one, zero);
  bitXorParsed("0x5", "0x3", "0x6");
  bitXorParsed("0x5", minus_one, "-0x6");
  bitXorParsed("0x5", zero, "0x5");
  bitXorParsed(minus_one, "-0x8", "0x7");
  bitXorParsed("0x50000000", one, "0x50000001");
  bitXorParsed("0x50000000", minus_one, "-0x50000001");
  bitXorParsed("0x500000000", one, "0x500000001");
  bitXorParsed("0x500000000", minus_one, "-0x500000001");
  bitXorParsed("0x50000000000000000", one, "0x50000000000000001");
  bitXorParsed("0x50000000000000000", minus_one, "-0x50000000000000001");
  bitXorParsed("-0x50000000", "-0x50000000", zero);
  bitXorParsed("-0x500000000", "-0x500000000", zero);
  bitXorParsed("-0x50000000000000000", "-0x50000000000000000", zero);
  bitXorParsed("0x1234567890ABCDEF012345678", "0x876543210FEDCBA0987654321",
      "0x955115599F46064F995511559");
  bitXorParsed("-0x1234567890ABCDEF012345678", "-0x876543210FEDCBA0987654321",
      "0x955115599F46064F995511557");
  bitXorParsed("0x1234567890ABCDEF012345678", "-0x876543210FEDCBA0987654321",
      "-0x955115599F46064F995511559");
  bitXorParsed(
      "0x1234567890ABCDEF012345678FFFFFFFFFFFFFFFFFFFFFFFFF",
      "-0x876543210FEDCBA0987654321",
      "-0x1234567890ABCDEF012345678789ABCDEF012345F6789ABCE0");
  bitXorParsed("0x12345678", "0xFFFFFFF", "0x1DCBA987");
  bitXorParsed("0x123456789", "0xFFFFFFFF", "0x1DCBA9876");
  bitXorParsed("-0x10000000", "0xFFFFFFF", "-0x1");
  bitXorParsed("-0x100000000", "0xFFFFFFFF", "-0x1");
  bitXorParsed("-0x10000001", "0xFFFFFFF", "-0x20000000");
  bitXorParsed("-0x100000001", "0xFFFFFFFF", "-0x200000000");
  bitXorParsed("-0x10000001", "0x3FFFFFFF", "-0x30000000");
  bitXorParsed("-0x100000001", "0x3FFFFFFFF", "-0x300000000");
  bitXorParsed(
      "-0x10000000000000001", "0x3FFFFFFFFFFFFFFFF", "-0x30000000000000000");
  bitXorParsed("-0x100000000000000", "0xFFFFFFFFFFFFFF", "-0x1");
  bitXorParsed("-0x10000000000000000", "0xFFFFFFFFFFFFFFFF", "-0x1");
  bitXorParsed("-0x300000000000000", "0xFFFFFFFFFFFFFFF", "-0xD00000000000001");
  bitXorParsed(
      "-0x30000000000000000", "0xFFFFFFFFFFFFFFFFF", "-0xD0000000000000001");
  bitXorParsed("-0x10000000", "-0x10000000", zero);
  bitXorParsed("-0x100000000", "-0x100000000", zero);
  bitXorParsed("-0x100000000000000", "-0x100000000000000", zero);
  bitXorParsed("-0x10000000000000000", "-0x10000000000000000", zero);
  bitXorParsed("-0x10000000", "-0x10000001", "0x1FFFFFFF");
  bitXorParsed("-0x100000000", "-0x100000001", "0x1FFFFFFFF");
  bitXorParsed("-0x100000000000000", "-0x100000000000001", "0x1FFFFFFFFFFFFFF");
  bitXorParsed(
      "-0x10000000000000000", "-0x10000000000000001", "0x1FFFFFFFFFFFFFFFF");
}

bitNotParsed(String a, String result) {
  int int_a = int.parse(a);
  int int_result = int.parse(result);
  int inverted = ~int_a;
  Expect.equals(int_result, inverted);
  String str_inverted = inverted >= 0
      ? "0x${inverted.toRadixString(16)}"
      : "-0x${(-inverted).toRadixString(16)}";
  Expect.equals(result.toLowerCase(), str_inverted);
  int back = ~inverted;
  Expect.equals(int_a, back);
  String str_back = back >= 0
      ? "0x${back.toRadixString(16)}"
      : "-0x${(-back).toRadixString(16)}";
  Expect.equals(a.toLowerCase(), str_back);
}

testBigintBitNot() {
  String zero = "0x0";
  String one = "0x1";
  String minus_one = "-0x1";

  bitNotParsed(zero, minus_one);
  bitNotParsed(one, "-0x2");
  bitNotParsed("0x5", "-0x6");
  bitNotParsed("0x50000000", "-0x50000001");
  bitNotParsed("0xFFFFFFF", "-0x10000000");
  bitNotParsed("0xFFFFFFFF", "-0x100000000");
  bitNotParsed("0xFFFFFFFFFFFFFF", "-0x100000000000000");
  bitNotParsed("0xFFFFFFFFFFFFFFFF", "-0x10000000000000000");
  bitNotParsed("0x1234567890ABCDEF012345678", "-0x1234567890ABCDEF012345679");
}

main() {
  testBigintAddSub();
  testBigintLeftShift();
  testBigintRightShift();
  testBigintBitAnd();
  testBigintBitOr();
  testBigintBitXor();
  testBigintBitNot();
}
