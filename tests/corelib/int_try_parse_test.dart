// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:math" show pow, log;

void main() {
  const String oneByteWhiteSpace = "\x09\x0a\x0b\x0c\x0d\x20\xa0";
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
        result, int.tryParse(radixString.toLowerCase(), radix: radix), m);
    Expect.equals(
        result, int.tryParse(radixString.toUpperCase(), radix: radix), m);
    Expect.equals(result, int.tryParse(" $radixString", radix: radix), m);
    Expect.equals(result, int.tryParse("$radixString ", radix: radix), m);
    Expect.equals(result, int.tryParse(" $radixString ", radix: radix), m);
    Expect.equals(result, int.tryParse("+$radixString", radix: radix), m);
    Expect.equals(result, int.tryParse(" +$radixString", radix: radix), m);
    Expect.equals(result, int.tryParse("+$radixString ", radix: radix), m);
    Expect.equals(result, int.tryParse(" +$radixString ", radix: radix), m);
    Expect.equals(-result, int.tryParse("-$radixString", radix: radix), m);
    Expect.equals(-result, int.tryParse(" -$radixString", radix: radix), m);
    Expect.equals(-result, int.tryParse("-$radixString ", radix: radix), m);
    Expect.equals(-result, int.tryParse(" -$radixString ", radix: radix), m);
    Expect.equals(
        result,
        int.tryParse("$oneByteWhiteSpace$radixString$oneByteWhiteSpace",
            radix: radix),
        m);
    Expect.equals(
        -result,
        int.tryParse("$oneByteWhiteSpace-$radixString$oneByteWhiteSpace",
            radix: radix),
        m);
    Expect.equals(result,
        int.tryParse("$whiteSpace$radixString$whiteSpace", radix: radix), m);
    Expect.equals(-result,
        int.tryParse("$whiteSpace-$radixString$whiteSpace", radix: radix), m);

    Expect.equals(result, int.tryParse("$zeros$radixString", radix: radix), m);
    Expect.equals(result, int.tryParse("+$zeros$radixString", radix: radix), m);
    Expect.equals(
        -result, int.tryParse("-$zeros$radixString", radix: radix), m);
  }

  for (int r = 2; r <= 36; r++) {
    for (int i = 0; i <= r * r; i++) {
      String radixString = i.toRadixString(r);
      testParse(i, radixString, r);
    }
    for (var v in [
      0,
      0x10000,
      0x7FFFFFFF,
      0x80000000,
      0xFFFFFFFF,
      0x100000000,
      0x7FFFFFFFFFFFF8,
    ]) {
      var string = v.toRadixString(r);
      Expect.equals(v, int.tryParse(string, radix: r));
      if (v > 0) {
        Expect.equals(-v, int.tryParse("-$string", radix: r));
        if (r == 16) {
          Expect.equals(v, int.tryParse("0x$string"));
          Expect.equals(v, int.tryParse("0X$string"));
        }
      }
    }
  }

  // Allow both upper- and lower-case letters.
  Expect.equals(0xABCD, int.tryParse("ABCD", radix: 16));
  Expect.equals(0xABCD, int.tryParse("abcd", radix: 16));
  Expect.equals(15628859, int.tryParse("09azAZ", radix: 36));
  // Bigish numbers (representable precisely as both Int64 and double (2^53)).
  Expect.equals(9007199254740991, int.tryParse("9007199254740991"));
  Expect.equals(-9007199254740991, int.tryParse("-9007199254740991"));
  // Allow whitespace before and after the number.
  Expect.equals(1, int.tryParse(" 1", radix: 2));
  Expect.equals(1, int.tryParse("1 ", radix: 2));
  Expect.equals(1, int.tryParse(" 1 ", radix: 2));
  Expect.equals(1, int.tryParse("\n1", radix: 2));
  Expect.equals(1, int.tryParse("1\n", radix: 2));
  Expect.equals(1, int.tryParse("\n1\n", radix: 2));
  Expect.equals(1, int.tryParse("+1", radix: 2));

  void testFails(String source, int radix, [String? message]) {
    Expect.isNull(int.tryParse(source, radix: radix), message ?? "");
  }

  for (int i = 2; i < 36; i++) {
    var char = i.toRadixString(36);
    testFails(char.toLowerCase(), i);
    testFails(char.toUpperCase(), i);
  }
  testFails("", 2);
  testFails("+ 1", 2); // No space between sign and digits.
  testFails("- 1", 2); // No space between sign and digits.
  for (int i = 2; i <= 33; i++) {
    // No 0x specially allowed.
    // At radix 34 and above, "x" is a valid digit.
    testFails("0x10", i);
  }

  int digitX = 33;
  Expect.equals(((digitX * 34) + 1) * 34, int.tryParse("0x10", radix: 34));
  Expect.equals(((digitX * 35) + 1) * 35, int.tryParse("0x10", radix: 35));

  // Radix must be in the range 2 .. 36.
  Expect.throwsArgumentError(() => int.tryParse("0", radix: -1));
  Expect.throwsArgumentError(() => int.tryParse("0", radix: 0));
  Expect.throwsArgumentError(() => int.tryParse("0", radix: -1));
  Expect.throwsArgumentError(() => int.tryParse("0", radix: 37));

  // Regression test for http://dartbug.com/32858
  Expect.equals(
      -0x8000000000000000, int.tryParse("-0x8000000000000000"), "-minint");

  // Tests run only with 64-bit integers.
  if (0x8000000000000000 < 0) {
    // `int` is 64-bit signed integers.
    Expect.equals(
        -0x8000000000000000, int.tryParse("0x8000000000000000"), "0xUnsigned");
    Expect.equals(-1, int.tryParse("0xFFFFFFFFFFFFFFFF"), "0xUnsigned2");

    Expect.equals(
        0x8000000000000000 - 1, int.tryParse("0x7FFFFFFFFFFFFFFF"), "maxint");
    testFails("8000000000000000", 16, "2^63 radix: 16");
    testFails("FFFFFFFFFFFFFFFF", 16, "maxuint64 radix: 16");
  }
}
