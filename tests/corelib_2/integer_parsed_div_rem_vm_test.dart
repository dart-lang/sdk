// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing integers with and without intrinsics.
// VMOptions=
// VMOptions=--no_intrinsify

library integer_arithmetic_test;

import "package:expect/expect.dart";

divRemParsed(String a, String b, String quotient, String remainder) {
  int int_a = int.parse(a);
  int int_b = int.parse(b);
  int int_quotient = int.parse(quotient);
  int int_remainder = int.parse(remainder);
  int computed_quotient = int_a ~/ int_b;
  Expect.equals(int_quotient, computed_quotient);
  String str_quotient = computed_quotient >= 0
      ? "0x${computed_quotient.toRadixString(16)}"
      : "-0x${computed_quotient.toRadixString(16).substring(1)}";
  Expect.equals(quotient.toLowerCase(), str_quotient);
  int computed_remainder = int_a.remainder(int_b);
  Expect.equals(int_remainder, computed_remainder);
  String str_remainder = computed_remainder >= 0
      ? "0x${computed_remainder.toRadixString(16)}"
      : "-0x${computed_remainder.toRadixString(16).substring(1)}";
  Expect.equals(remainder.toLowerCase(), str_remainder);
}

testDivideRemainder() {
  String zero = "0x0";
  String one = "0x1";
  String minus_one = "-0x1";

  divRemParsed(one, one, one, zero);
  divRemParsed(zero, one, zero, zero);
  divRemParsed(minus_one, one, minus_one, zero);
  divRemParsed(one, "0x2", zero, one);
  divRemParsed(minus_one, "0x7", zero, minus_one);
  divRemParsed("0xB", "0x7", one, "0x4");
  divRemParsed("0x12345678", "0x7", "0x299C335", "0x5");
  divRemParsed("-0x12345678", "0x7", "-0x299C335", "-0x5");
  divRemParsed("0x12345678", "-0x7", "-0x299C335", "0x5");
  divRemParsed("-0x12345678", "-0x7", "0x299C335", "-0x5");
  divRemParsed("0x7", "0x12345678", zero, "0x7");
  divRemParsed("-0x7", "0x12345678", zero, "-0x7");
  divRemParsed("-0x7", "-0x12345678", zero, "-0x7");
  divRemParsed("0x7", "-0x12345678", zero, "0x7");
  divRemParsed("0x12345678", "0x7", "0x299C335", "0x5");
  divRemParsed("-0x12345678", "0x7", "-0x299C335", "-0x5");
  divRemParsed("0x12345678", "-0x7", "-0x299C335", "0x5");
  divRemParsed("-0x12345678", "-0x7", "0x299C335", "-0x5");
  divRemParsed("9223372036854775807", "0x7", "0x1249249249249249", "0x0");
  divRemParsed("9223372036854775807", "-0x7", "-0x1249249249249249", "0x0");
  divRemParsed("-9223372036854775807", "0x7", "-0x1249249249249249", "0x0");
  divRemParsed("-9223372036854775807", "-0x7", "0x1249249249249249", "0x0");
  divRemParsed("-9223372036854775808", "-1", "-0x8000000000000000", "0x0"); //# 01: ok
  divRemParsed("-9223372036854775808", "0x7", "-0x1249249249249249", "-0x1");
  divRemParsed("-9223372036854775808", "-0x7", "0x1249249249249249", "-0x1");
}

main() {
  testDivideRemainder();
}
