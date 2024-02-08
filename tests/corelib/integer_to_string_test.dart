// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'package:expect/variations.dart' as v;

main() {
  /// Test that converting [value] to a string gives [expect].
  /// Also test that `-value` gives `"-"+expect`.
  test(int value, String expect) {
    Expect.equals(expect, value.toString());
    Expect.equals(expect, "$value");
    Expect.equals(expect, (new StringBuffer()..write(value)).toString());
    if (value <= 0) return;
    expect = "-$expect";
    value = -value;
    Expect.equals(expect, value.toString());
    Expect.equals(expect, "$value");
    Expect.equals(expect, (new StringBuffer()..write(value)).toString());
  }

  // Very simple tests.
  test(0, "0");
  test(1, "1");
  test(2, "2");
  test(5, "5");

  // Binary special cases.

  // ~2^30.
  test(0x3fffffff, "1073741823");
  test(0x40000000, "1073741824");
  test(0x40000001, "1073741825");
  // ~2^31.
  test(0x7fffffff, "2147483647");
  test(0x80000000, "2147483648");
  test(0x80000001, "2147483649");
  // ~2^32.
  test(0xffffffff, "4294967295");
  test(0x100000000, "4294967296");
  test(0x100000001, "4294967297");

  // ~2^51.
  test(0x7ffffffffffff, "2251799813685247");
  test(0x8000000000000, "2251799813685248");
  test(0x8000000000001, "2251799813685249");
  // ~2^52.
  test(0xfffffffffffff, "4503599627370495");
  test(0x10000000000000, "4503599627370496");
  test(0x10000000000001, "4503599627370497");
  // ~2^53.
  test(0x1fffffffffffff, "9007199254740991");
  test(0x20000000000000, "9007199254740992");
  // Split literals into sum of two web numbers to avoid compilation errors.
  if (v.jsNumbers) {
    // The String for large integral web numbers (doubles) could be any sequence
    // of digits that parse back to the same value. The algorithm chooses 'nice'
    // rounded numbers rather than the equivalent digits for some multiple of a
    // power of two.
    test(0x20000000000000 + 1, "9007199254740992");
    // ~2^62.
    test(0x3ffffffffffff000 + 0xfff, "4611686018427388000");
    test(0x4000000000000000, "4611686018427388000");
    test(0x4000000000000000 + 1, "4611686018427388000");
    // ~2^63.
    test(0x7ffffffffffff000 + 0xfff, "9223372036854776000");
    test(0x8000000000000000, "9223372036854776000");
    test(0x8000000000000000 + 1, "9223372036854776000");
    // ~2^64.
    test(0xfffffffffffff000 + 0xfff, "18446744073709552000");
  } else {
    test(0x20000000000000 + 1, "9007199254740993");
    // ~2^62.
    test(0x3ffffffffffff000 + 0xfff, "4611686018427387903");
    test(0x4000000000000000, "4611686018427387904");
    test(0x4000000000000000 + 1, "4611686018427387905");
    // ~2^63.
    test(0x7ffffffffffff000 + 0xfff, "9223372036854775807");
    test(0x8000000000000000, "-9223372036854775808");
    test(0x8000000000000000 + 1, "-9223372036854775807");
    // ~2^64.
    test(0xfffffffffffff000 + 0xfff, "-1");
  }

  // Decimal special cases.

  int number = 10;
  // Numbers 99..99, 100...00, and 100..01 up to 18 digits.
  for (int i = 1; i < 19; i++) {
    // Works in dart2js up to 10^15.
    if (v.jsNumbers && i > 15) break;
    test(number - 1, "9" * i);
    test(number, "1" + "0" * i);
    test(number + 1, "1" + "0" * (i - 1) + "1");
    number *= 10;
  }
}
