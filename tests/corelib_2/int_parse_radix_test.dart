// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:math" show pow;

void main() {
  const String oneByteWhiteSpace = "\x09\x0a\x0b\x0c\x0d\x20"
    "\x85" //# 01: ok
      "\xa0";
  const String whiteSpace = "$oneByteWhiteSpace\u1680"
      "\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a"
      "\u2028\u2029\u202f\u205f\u3000\ufeff";

  var digits = "0123456789abcdefghijklmnopqrstuvwxyz";
  var zeros = "0" * 64;

  for (int i = 0; i < whiteSpace.length; i++) {
    var ws = whiteSpace[i];
    Expect.equals(0, int.parse("${ws}0${ws}", radix: 2));
  }

  void testParse(int result, String radixString, int radix) {
    var m = "$radixString/$radix->$result";
    Expect.equals(
        result, int.parse(radixString.toLowerCase(), radix: radix), m);
    Expect.equals(
        result, int.parse(radixString.toUpperCase(), radix: radix), m);
    Expect.equals(result, int.parse(" $radixString", radix: radix), m);
    Expect.equals(result, int.parse("$radixString ", radix: radix), m);
    Expect.equals(result, int.parse(" $radixString ", radix: radix), m);
    Expect.equals(result, int.parse("+$radixString", radix: radix), m);
    Expect.equals(result, int.parse(" +$radixString", radix: radix), m);
    Expect.equals(result, int.parse("+$radixString ", radix: radix), m);
    Expect.equals(result, int.parse(" +$radixString ", radix: radix), m);
    Expect.equals(-result, int.parse("-$radixString", radix: radix), m);
    Expect.equals(-result, int.parse(" -$radixString", radix: radix), m);
    Expect.equals(-result, int.parse("-$radixString ", radix: radix), m);
    Expect.equals(-result, int.parse(" -$radixString ", radix: radix), m);
    Expect.equals(
        result,
        int.parse("$oneByteWhiteSpace$radixString$oneByteWhiteSpace",
            radix: radix),
        m);
    Expect.equals(
        -result,
        int.parse("$oneByteWhiteSpace-$radixString$oneByteWhiteSpace",
            radix: radix),
        m);
    Expect.equals(result,
        int.parse("$whiteSpace$radixString$whiteSpace", radix: radix), m);
    Expect.equals(-result,
        int.parse("$whiteSpace-$radixString$whiteSpace", radix: radix), m);

    Expect.equals(result, int.parse("$zeros$radixString", radix: radix), m);
    Expect.equals(result, int.parse("+$zeros$radixString", radix: radix), m);
    Expect.equals(-result, int.parse("-$zeros$radixString", radix: radix), m);
  }

  for (int r = 2; r <= 36; r++) {
    for (int i = 0; i <= r * r; i++) {
      String radixString = i.toRadixString(r);
      testParse(i, radixString, r);
    }
  }

  for (int i = 2; i <= 36; i++) { //             //# 02: ok
    // Test with bignums. //                     //# 02: continued
    var digit = digits[i - 1]; //                //# 02: continued
    testParse(pow(i, 64) - 1, digit * 64, i); // //# 02: continued
    testParse(0, zeros, i); //                   //# 02: continued
  } //                                           //# 02: continued

  // Allow both upper- and lower-case letters.
  Expect.equals(0xABCD, int.parse("ABCD", radix: 16));
  Expect.equals(0xABCD, int.parse("abcd", radix: 16));
  Expect.equals(15628859, int.parse("09azAZ", radix: 36));
  // Big number.
  Expect.equals(0x12345678123456781234567812345678, // //# 02: continued
                int.parse("0x1234567812345678" //      //# 02: continued
                          "1234567812345678")); //     //# 02: continued
  // Allow whitespace before and after the number.
  Expect.equals(1, int.parse(" 1", radix: 2));
  Expect.equals(1, int.parse("1 ", radix: 2));
  Expect.equals(1, int.parse(" 1 ", radix: 2));
  Expect.equals(1, int.parse("\n1", radix: 2));
  Expect.equals(1, int.parse("1\n", radix: 2));
  Expect.equals(1, int.parse("\n1\n", radix: 2));
  Expect.equals(1, int.parse("+1", radix: 2));

  void testFails(String source, int radix) {
    Expect.throws(() {
      throw int.parse(source, radix: radix, onError: (s) {
        throw "FAIL";
      });
    }, isFail, "$source/$radix");
    Expect.equals(-999, int.parse(source, radix: radix, onError: (s) => -999));
  }

  for (int i = 2; i < 36; i++) {
    var char = i.toRadixString(36);
    testFails(char.toLowerCase(), i);
    testFails(char.toUpperCase(), i);
  }
  testFails("", 2);
  testFails("+ 1", 2); // No space between sign and digits.
  testFails("- 1", 2); // No space between sign and digits.
  testFails("0x", null);
  for (int i = 2; i <= 33; i++) {
    // No 0x specially allowed.
    // At radix 34 and above, "x" is a valid digit.
    testFails("0x10", i);
  }

  testBadTypes(var source, var radix) {
    Expect.throwsTypeError(() => int.parse(source, radix: radix, onError: (s) => 0)); //# badTypes: ok
  }

  testBadTypes(9, 10);
  testBadTypes(true, 10);
  testBadTypes("0", true);
  testBadTypes("0", "10");

  testBadArguments(String source, int radix) {
    // If the types match, it should be an ArgumentError of some sort.
    Expect.throwsArgumentError(
        () => int.parse(source, radix: radix, onError: (s) => 0));
  }

  testBadArguments("0", -1);
  testBadArguments("0", 0);
  testBadArguments("0", 1);
  testBadArguments("0", 37);

  // See also int_parse_radix_bad_handler_test.dart
}

bool isFail(e) => e == "FAIL";
