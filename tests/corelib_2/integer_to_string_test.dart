// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  /// Test that converting [value] to a string gives [expect].
  /// Also test that `-value` gives `"-"+expect`.
  test(int value, String expect) {
    Expect.equals(expect, value.toString());
    Expect.equals(expect, "$value");
    Expect.equals(expect, (new StringBuffer()..write(value)).toString());
    if (value == 0) return;
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
  test(0x20000000000001, "9007199254740993"); //        //# 01: ok
  // ~2^62.
  test(0x3fffffffffffffff, "4611686018427387903"); //   //# 01: continued
  test(0x4000000000000000, "4611686018427387904"); //   //# 01: continued
  test(0x4000000000000001, "4611686018427387905"); //   //# 01: continued
  // ~2^63.
  test(0x7fffffffffffffff, "9223372036854775807"); //   //# 01: continued
  test(0x8000000000000000, "9223372036854775808"); //   //# 01: continued
  test(0x8000000000000001, "9223372036854775809"); //   //# 01: continued
  // ~2^64.
  test(0xffffffffffffffff, "18446744073709551615"); //  //# 01: continued
  test(0x10000000000000000, "18446744073709551616"); // //# 01: continued
  test(0x10000000000000001, "18446744073709551617"); // //# 01: continued
  // Big bignum.
  test(123456789012345678901234567890, //               //# 01: continued
       "123456789012345678901234567890"); //            //# 01: continued

  // Decimal special cases.

  int number = 10;
  // Numbers 99..99, 100...00, and 100..01 up to 23 digits.
  for (int i = 1; i < 15; i++) {
    // Works in dart2js up to 10^15.
    test(number - 1, "9" * i);
    test(number, "1" + "0" * i);
    test(number + 1, "1" + "0" * (i - 1) + "1");
    number *= 10;
  }
  // Fails to represent exactly in dart2js.
  for (int i = 15; i < 22; i++) { //                    //# 01: continued
    test(number - 1, "9" * i); //                       //# 01: continued
    test(number, "1" + "0" * i); //                     //# 01: continued
    test(number + 1, "1" + "0" * (i - 1) + "1"); //     //# 01: continued
    number *= 10; //                                    //# 01: continued
  } //                                                  //# 01: continued
}
