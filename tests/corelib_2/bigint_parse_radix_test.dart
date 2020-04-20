// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing Bigints with and without intrinsics.
// VMOptions=--intrinsify --no-enable-asserts
// VMOptions=--intrinsify --enable-asserts
// VMOptions=--no-intrinsify --enable-asserts
// VMOptions=--optimization-counter-threshold=5 --no-background-compilation

import "package:expect/expect.dart";

import 'dart:math' show pow;

void testParseRadix() {
  bool checkedMode = false;
  assert((checkedMode = true));
  const String oneByteWhiteSpace = "\x09\x0a\x0b\x0c\x0d\x20"
      // "\x85" // Might make troubles on some systems. Was marked as OK test.
      "\xa0";
  const String whiteSpace = "$oneByteWhiteSpace\u1680"
      "\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a"
      "\u2028\u2029\u202f\u205f\u3000\ufeff";

  var digits = "0123456789abcdefghijklmnopqrstuvwxyz";
  var zeros = "0" * 64;

  for (int i = 0; i < whiteSpace.length; i++) {
    var ws = whiteSpace[i];
    Expect.equals(BigInt.zero, BigInt.parse("${ws}0${ws}", radix: 2));
  }

  void testParse(BigInt result, String radixString, int radix) {
    var m = "$radixString/$radix->$result";
    Expect.equals(
        result, BigInt.parse(radixString.toLowerCase(), radix: radix), m);
    Expect.equals(
        result, BigInt.parse(radixString.toUpperCase(), radix: radix), m);
    Expect.equals(result, BigInt.parse(" $radixString", radix: radix), m);
    Expect.equals(result, BigInt.parse("$radixString ", radix: radix), m);
    Expect.equals(result, BigInt.parse(" $radixString ", radix: radix), m);
    Expect.equals(result, BigInt.parse("+$radixString", radix: radix), m);
    Expect.equals(result, BigInt.parse(" +$radixString", radix: radix), m);
    Expect.equals(result, BigInt.parse("+$radixString ", radix: radix), m);
    Expect.equals(result, BigInt.parse(" +$radixString ", radix: radix), m);
    Expect.equals(-result, BigInt.parse("-$radixString", radix: radix), m);
    Expect.equals(-result, BigInt.parse(" -$radixString", radix: radix), m);
    Expect.equals(-result, BigInt.parse("-$radixString ", radix: radix), m);
    Expect.equals(-result, BigInt.parse(" -$radixString ", radix: radix), m);
    Expect.equals(
        result,
        BigInt.parse("$oneByteWhiteSpace$radixString$oneByteWhiteSpace",
            radix: radix),
        m);
    Expect.equals(
        -result,
        BigInt.parse("$oneByteWhiteSpace-$radixString$oneByteWhiteSpace",
            radix: radix),
        m);
    Expect.equals(result,
        BigInt.parse("$whiteSpace$radixString$whiteSpace", radix: radix), m);
    Expect.equals(-result,
        BigInt.parse("$whiteSpace-$radixString$whiteSpace", radix: radix), m);

    Expect.equals(result, BigInt.parse("$zeros$radixString", radix: radix), m);
    Expect.equals(result, BigInt.parse("+$zeros$radixString", radix: radix), m);
    Expect.equals(
        -result, BigInt.parse("-$zeros$radixString", radix: radix), m);
  }

  for (int r = 2; r <= 36; r++) {
    for (var i = BigInt.zero; i <= new BigInt.from(r * r); i += BigInt.one) {
      String radixString = i.toRadixString(r);
      testParse(i, radixString, r);
    }
  }

  for (int i = 2; i <= 36; i++) {
    var digit = digits[i - 1];
    testParse(new BigInt.from(i).pow(64) - BigInt.one, digit * 64, i);
    testParse(BigInt.zero, zeros, i);
  }

  // Allow both upper- and lower-case letters.
  Expect.equals(new BigInt.from(0xABCD), BigInt.parse("ABCD", radix: 16));
  Expect.equals(new BigInt.from(0xABCD), BigInt.parse("abcd", radix: 16));
  Expect.equals(new BigInt.from(15628859), BigInt.parse("09azAZ", radix: 36));

  Expect.equals(
      (new BigInt.from(0x12345678) << 96) +
          (new BigInt.from(0x12345678) << 64) +
          (new BigInt.from(0x12345678) << 32) +
          new BigInt.from(0x12345678),
      BigInt.parse("0x12345678123456781234567812345678"));

  // Allow whitespace before and after the number.
  Expect.equals(BigInt.one, BigInt.parse(" 1", radix: 2));
  Expect.equals(BigInt.one, BigInt.parse("1 ", radix: 2));
  Expect.equals(BigInt.one, BigInt.parse(" 1 ", radix: 2));
  Expect.equals(BigInt.one, BigInt.parse("\n1", radix: 2));
  Expect.equals(BigInt.one, BigInt.parse("1\n", radix: 2));
  Expect.equals(BigInt.one, BigInt.parse("\n1\n", radix: 2));
  Expect.equals(BigInt.one, BigInt.parse("+1", radix: 2));

  void testFails(String source, int radix) {
    Expect.throws(() {
      BigInt.parse(source, radix: radix);
    }, (e) => e is FormatException, "$source/$radix");
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

  testBadArguments(String source, int radix) {
    // If the types match, it should be an ArgumentError of some sort.
    Expect.throws(
        () => BigInt.parse(source, radix: radix), (e) => e is ArgumentError);
  }

  testBadArguments("0", -1);
  testBadArguments("0", 0);
  testBadArguments("0", 1);
  testBadArguments("0", 37);
}

main() {
  testParseRadix();
}
