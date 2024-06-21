// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'package:expect/variations.dart' as v;
import "dart:math" show pow, log;

void main() {
  final String oneByteWhiteSpace = v.jsNumbers
      ? "\x09\x0a\x0b\x0c\x0d\x20\xa0"
      : "\x09\x0a\x0b\x0c\x0d\x20\x85\xa0";
  final String whiteSpace = "$oneByteWhiteSpace\u1680"
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

  final max = 0x1FFFFFFFFFFFFF;
  for (int i = 2; i <= 36; i++) { //             //# 02: ok
    // Test with bignums. //                     //# 02: continued
    final n = (log(max) / log(i)).truncate(); // //# 02: continued
    var digit = digits[i - 1]; //                //# 02: continued
    testParse((pow(i, n) as int) - 1, digit * n, i); //   //# 02: continued
    testParse(0, zeros, i); //                   //# 02: continued
  } //                                           //# 02: continued

  // Allow both upper- and lower-case letters.
  Expect.equals(0xABCD, int.parse("ABCD", radix: 16));
  Expect.equals(0xABCD, int.parse("abcd", radix: 16));
  Expect.equals(15628859, int.parse("09azAZ", radix: 36));
  // Big-ish number. (2^53)
  Expect.equals(9007199254740991, int.parse("9007199254740991"));
  Expect.equals(-9007199254740991, int.parse("-9007199254740991"));
  Expect.equals(-9223372036854775808, int.parse("-9223372036854775808"));
  // Allow whitespace before and after the number.
  Expect.equals(1, int.parse(" 1", radix: 2));
  Expect.equals(1, int.parse("1 ", radix: 2));
  Expect.equals(1, int.parse(" 1 ", radix: 2));
  Expect.equals(1, int.parse("\n1", radix: 2));
  Expect.equals(1, int.parse("1\n", radix: 2));
  Expect.equals(1, int.parse("\n1\n", radix: 2));
  Expect.equals(1, int.parse("+1", radix: 2));

  void testFails(String source, int radix) {
    Expect.throwsFormatException(
        () => int.parse(source, radix: radix), "$source/$radix");
    Expect.isNull(int.tryParse(source, radix: radix));
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

  testBadArguments(String source, int radix) {
    // If the types match, it should be an ArgumentError of some sort.
    Expect.throwsArgumentError(() => int.parse(source, radix: radix));
  }

  testBadArguments("0", -1);
  testBadArguments("0", 0);
  testBadArguments("0", 1);
  testBadArguments("0", 37);

  // Test overflow checks. Overflow checks in bases 2 and 3 are simple because
  // `(number * <base>) + <digit>` always becomes negative when overflows.
  //
  // For other bases, this computation can overflow without turning the result
  // negative, because a high 1 bit can be shifted more than one place in the
  // binary representation.
  //
  // The inputs below cause losing bits without turning the number negative.
  if (!v.jsNumbers) {
    Expect.equals(
        null, int.tryParse("113333333333333333333333333333330", radix: 4));
    Expect.equals(null, int.tryParse("3324103204424323413431434140", radix: 5));
    Expect.equals(null, int.tryParse("5501203013133131110411030", radix: 6));
    Expect.equals(null, int.tryParse("100353032434101216220200", radix: 7));
    Expect.equals(null, int.tryParse("2777777777777777777770", radix: 8));
    Expect.equals(null, int.tryParse("224313870536325635680", radix: 9));
    Expect.equals(null, int.tryParse("27670116110564327420", radix: 10));
    Expect.equals(null, int.tryParse("4a820077a4642651970", radix: 11));
    Expect.equals(null, int.tryParse("1057b377b1343360a70", radix: 12));
    Expect.equals(null, int.tryParse("327772311192c9baa0", radix: 13));
    Expect.equals(null, int.tryParse("c9c177096975d9930", radix: 14));
    Expect.equals(null, int.tryParse("432c82996d3a44910", radix: 15));
    Expect.equals(null, int.tryParse("17ffffffffffffff0", radix: 16));
    Expect.equals(null, int.tryParse("9b5b67915g63c010", radix: 17));
    Expect.equals(null, int.tryParse("41eefg9h5a66had0", radix: 18));
    Expect.equals(null, int.tryParse("1fbicb30g29966f0", radix: 19));
    Expect.equals(null, int.tryParse("ghf7jfab7b70ib0", radix: 20));
    Expect.equals(null, int.tryParse("8b2dheee137ka70", radix: 21));
    Expect.equals(null, int.tryParse("49iabcb64igi290", radix: 22));
    Expect.equals(null, int.tryParse("28kecd2emc447d0", radix: 23));
    Expect.equals(null, int.tryParse("17dfll8bmd5f2f0", radix: 24));
    Expect.equals(null, int.tryParse("ie5h4mndljgnl0", radix: 25));
    Expect.equals(null, int.tryParse("b3olhc69fb4io0", radix: 26));
    Expect.equals(null, int.tryParse("6m9cq9g69nj5k0", radix: 27));
    Expect.equals(null, int.tryParse("474a0ha3nadcm0", radix: 28));
    Expect.equals(null, int.tryParse("2k5rdpg280drr0", radix: 29));
    Expect.equals(null, int.tryParse("1m1thg464g6600", radix: 30));
    Expect.equals(null, int.tryParse("1440anrglnuc90", radix: 31));
    Expect.equals(null, int.tryParse("nvvvvvvvvvvv0", radix: 32));
    Expect.equals(null, int.tryParse("gjfd4rsp6eo90", radix: 33));
    Expect.equals(null, int.tryParse("bk7kq5ppnkl90", radix: 34));
    Expect.equals(null, int.tryParse("86knwkq9vdv50", radix: 35));
    Expect.equals(null, int.tryParse("5u831jl976p60", radix: 36));
  }
}
