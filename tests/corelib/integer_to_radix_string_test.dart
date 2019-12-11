// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Test that we accept radix 2 to 36 and that we use lower-case
  // letters.
  var expected = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z'
  ];
  for (var radix = 2; radix <= 36; radix++) {
    for (var i = 0; i < radix; i++) {
      Expect.equals(expected[i], i.toRadixString(radix));
    }
  }

  var illegalRadices = [-1, 0, 1, 37];
  for (var radix in illegalRadices) {
    try {
      42.toRadixString(radix);
      Expect.fail("Exception expected");
    } on ArgumentError catch (e) {
      // Nothing to do.
    }
  }

  // Try large numbers (regression test for issue 15316).
  var bignums = [
    0x80000000,
    0x100000000,
    0x10000000000000,
    0x10000000000001, // 53 significant bits.
    0x20000000000000,
    0x20000000000002,
    0x1000000000000000,
    0x1000000000000100,
    0x2000000000000000,
    0x2000000000000200,
    0x8000000000000000, //# 01: ok
    0x8000000000000800, //# 02: ok
  ];
  for (var bignum in bignums) {
    for (int radix = 2; radix <= 36; radix++) {
      String digits = bignum.toRadixString(radix);
      int result = int.parse(digits, radix: radix);
      Expect.equals(
          bignum, result, "${bignum.toRadixString(16)} -> $digits/$radix");
    }
  }
}
