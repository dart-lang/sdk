// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:math" show pow, log;

void main() {
  const String oneByteWhiteSpace = "\x09\x0a\x0b\x0c\x0d\x20"
      "\x85" //# 01: ok
      "\xa0";
  const String whiteSpace = "$oneByteWhiteSpace\u1680"
      "\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a"
      "\u2028\u2029\u202f\u205f\u3000\ufeff";

  var digits = "0123456789abcdefghijklmnopqrstuvwxyz";
  var zeros = "0" * 64;

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

  final max = 9223372036854775807;
  for (int i = 2; i <= 36; i++) { //             //# 02: ok
    // Test with bignums. //                     //# 02: continued
    final n = (log(max) / log(i)).truncate(); // //# 02: continued
    var digit = digits[i - 1]; //                //# 02: continued
    testParse(pow(i, n) - 1, digit * n, i); //   //# 02: continued
    testParse(0, zeros, i); //                   //# 02: continued
  } //                                           //# 02: continued

  // Big number.
  Expect.equals(9223372036854775807, int.parse("9223372036854775807"));
  Expect.equals(-9223372036854775808, int.parse("-9223372036854775808"));
}
