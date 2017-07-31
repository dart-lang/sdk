// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--limit-ints-to-64-bits

// Test for int.parse in --limit-ints-to-64-bits mode (with limited 64-bit
// integers).

import "package:expect/expect.dart";

main() {
  var returnError = (_) => "ERROR";

  Expect.equals(0, int.parse("0"));
  Expect.equals(1, int.parse("1"));
  Expect.equals(-1, int.parse("-1"));

  Expect.equals(0x7ffffffffffffffe, int.parse("0x7ffffffffffffffe"));
  Expect.equals(0x7fffffffffffffff, int.parse("0x7fffffffffffffff"));
  Expect.equals(-0x7fffffffffffffff, int.parse("-0x7fffffffffffffff"));
  Expect.equals(-0x7fffffffffffffff - 1, int.parse("-0x8000000000000000"));

  Expect.equals("ERROR", int.parse("0x8000000000000000", onError: returnError));
  Expect.equals(
      "ERROR", int.parse("-0x8000000000000001", onError: returnError));

  Expect.equals(8999999999999999999, int.parse("8999999999999999999"));
  Expect.equals(-8999999999999999999, int.parse("-8999999999999999999"));
  Expect.equals(9223372036854775807, int.parse("9223372036854775807"));
  Expect.equals(-9223372036854775807, int.parse("-9223372036854775807"));
  Expect.equals(-9223372036854775807 - 1, int.parse("-9223372036854775808"));

  Expect.equals(
      "ERROR", int.parse("9223372036854775808", onError: returnError));
  Expect.equals(
      "ERROR", int.parse("9223372036854775809", onError: returnError));
  Expect.equals(
      "ERROR", int.parse("-9223372036854775809", onError: returnError));
  Expect.equals(
      "ERROR", int.parse("10000000000000000000", onError: returnError));

  Expect.equals(
      0x7fffffffffffffff,
      int.parse(
          "111111111111111111111111111111111111111111111111111111111111111",
          radix: 2));
  Expect.equals(
      -0x7fffffffffffffff,
      int.parse(
          "-111111111111111111111111111111111111111111111111111111111111111",
          radix: 2));
  Expect.equals(
      -0x7fffffffffffffff - 1,
      int.parse(
          "-1000000000000000000000000000000000000000000000000000000000000000",
          radix: 2));

  Expect.equals(
      "ERROR",
      int.parse(
          "1000000000000000000000000000000000000000000000000000000000000000",
          radix: 2,
          onError: returnError));
  Expect.equals(
      "ERROR",
      int.parse(
          "1111111111111111111111111111111111111111111111111111111111111110",
          radix: 2,
          onError: returnError));
  Expect.equals(
      "ERROR",
      int.parse(
          "1111111111111111111111111111111111111111111111111111111111111111",
          radix: 2,
          onError: returnError));
  Expect.equals(
      "ERROR",
      int.parse(
          "-1000000000000000000000000000000000000000000000000000000000000001",
          radix: 2,
          onError: returnError));
}
