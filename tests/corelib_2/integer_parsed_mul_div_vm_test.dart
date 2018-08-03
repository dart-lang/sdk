// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing integers with and without intrinsics.
// VMOptions=
// VMOptions=--no_intrinsify

library integer_arithmetic_test;

import "package:expect/expect.dart";

mulDivParsed(String a, String b, String product,
    {String expected_quotient1, String expected_quotient2}) {
  int int_a = int.parse(a);
  int int_b = int.parse(b);
  int int_product = int.parse(product);
  int computed_product = int_a * int_b;
  Expect.equals(int_product, computed_product);
  String str_product = computed_product >= 0
      ? "0x${computed_product.toRadixString(16)}"
      : "-0x${(-computed_product).toRadixString(16)}";
  Expect.equals(product.toLowerCase(), str_product);
  int computed_product2 = int_b * int_a;
  Expect.equals(int_product, computed_product2);
  String str_product2 = computed_product2 >= 0
      ? "0x${computed_product2.toRadixString(16)}"
      : "-0x${(-computed_product2).toRadixString(16)}";
  Expect.equals(product.toLowerCase(), str_product2);

  if (int_a != 0) {
    expected_quotient1 ??= b;
    int int_expected_quotient1 = int.parse(expected_quotient1);
    int computed_quotient1 = int_product ~/ int_a;
    Expect.equals(int_expected_quotient1, computed_quotient1);
    String str_quotient1 = computed_quotient1 >= 0
        ? "0x${computed_quotient1.toRadixString(16)}"
        : "-0x${(-computed_quotient1).toRadixString(16)}";
    Expect.equals(expected_quotient1.toLowerCase(), str_quotient1);
  }

  if (int_b != 0) {
    expected_quotient2 ??= a;
    int int_expected_quotient2 = int.parse(expected_quotient2);
    int computed_quotient2 = int_product ~/ int_b;
    Expect.equals(int_expected_quotient2, computed_quotient2);
    String str_quotient2 = computed_quotient2 >= 0
        ? "0x${computed_quotient2.toRadixString(16)}"
        : "-0x${(-computed_quotient2).toRadixString(16)}";
    Expect.equals(expected_quotient2.toLowerCase(), str_quotient2);
  }
}

testMultiplyDivide() {
  String zero = "0x0";
  String one = "0x1";
  String minus_one = "-0x1";

  mulDivParsed(zero, zero, zero);
  mulDivParsed(one, one, one);
  mulDivParsed(one, zero, zero);
  mulDivParsed(zero, one, zero);
  mulDivParsed(one, minus_one, minus_one);
  mulDivParsed(minus_one, minus_one, one);
  mulDivParsed("0x42", one, "0x42");
  mulDivParsed("0x42", "0x2", "0x84");
  mulDivParsed("0xFFFF", "0x2", "0x1FFFE");
  mulDivParsed("0x3", "0x5", "0xF");
  mulDivParsed("0xFFFFF", "0x5", "0x4FFFFB");
  mulDivParsed("0xFFFFFFF", "0x5", "0x4FFFFFFB");
  mulDivParsed("0xFFFFFFFF", "0x5", "0x4FFFFFFFB");
  mulDivParsed("0x7FFFFFFFFFFFFFFF", "0x5", "0x7FFFFFFFFFFFFFFB",
      expected_quotient1: zero, expected_quotient2: "0x1999999999999998");
  mulDivParsed("0x7FFFFFFFFFFFFFFF", "0x3039", "0x7FFFFFFFFFFFCFC7",
      expected_quotient1: zero, expected_quotient2: "0x2A783BE38C73D");
  mulDivParsed("0x10000001", "0x5", "0x50000005");
}

main() {
  testMultiplyDivide();
}
