// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing left shifts of a constant.

import "package:expect/expect.dart";

shiftLeft0(c) => 0 << c;
shiftLeft1(c) => 1 << c;
shiftLeft8448(c) => 8448 << c;

shiftLeftNeg1(c) => -1 << c;
shiftLeftNeg8448(c) => -8448 << c;

main() {
  // Optimize shifts.
  for (int i = 0; i < 6000; i++) {
    shiftLeft1(2);
    shiftLeft0(2);
    shiftLeft8448(2);
    shiftLeftNeg1(2);
    shiftLeftNeg8448(2);
  }
  for (int i = 0; i < 80; i++) {
    Expect.equals(0, shiftLeft0(i));
  }
  // Exceptions.
  Expect.throws(() => shiftLeft0(-1));

  return;
  Expect.equals(1, shiftLeft1(0));
  Expect.equals(128, shiftLeft1(7));
  Expect.equals(536870912, shiftLeft1(29));
  // Deoptimize on 32-bit.
  Expect.equals(1073741824, shiftLeft1(30));
  Expect.equals(2147483648, shiftLeft1(31));
  Expect.equals(1152921504606846976, shiftLeft1(60));
  Expect.equals(2305843009213693952, shiftLeft1(61));
  // Deoptimize on 64 bits.
  Expect.equals(4611686018427387904, shiftLeft1(62));
  Expect.equals(9223372036854775808, shiftLeft1(63));

  Expect.equals(8448, shiftLeft8448(0));
  Expect.equals(1081344, shiftLeft8448(7));
  Expect.equals(553648128, shiftLeft8448(16));
  // Deoptimize on 32-bit.
  Expect.equals(1107296256, shiftLeft8448(17));
  Expect.equals(2214592512, shiftLeft8448(18));
  Expect.equals(1188950301625810944, shiftLeft8448(47));
  Expect.equals(2377900603251621888, shiftLeft8448(48));
  // Deoptimize on 64 bits.
  Expect.equals(4755801206503243776, shiftLeft8448(49));
  Expect.equals(9511602413006487552, shiftLeft8448(50));

  Expect.equals(-1, shiftLeftNeg1(0));
  Expect.equals(-128, shiftLeftNeg1(7));
  Expect.equals(-536870912, shiftLeftNeg1(29));
  // Deoptimize on 32-bit.
  Expect.equals(-1073741824, shiftLeftNeg1(30));
  Expect.equals(-2147483648, shiftLeftNeg1(31));
  Expect.equals(-1152921504606846976, shiftLeftNeg1(60));
  Expect.equals(-2305843009213693952, shiftLeftNeg1(61));
  // Deoptimize on 64 bits.
  Expect.equals(-4611686018427387904, shiftLeftNeg1(62));
  Expect.equals(-9223372036854775808, shiftLeftNeg1(63));

  Expect.equals(-8448, shiftLeftNeg8448(0));
  Expect.equals(-1081344, shiftLeftNeg8448(7));
  Expect.equals(-553648128, shiftLeftNeg8448(16));
  // Deoptimize on 32-bit.
  Expect.equals(-1107296256, shiftLeftNeg8448(17));
  Expect.equals(-2214592512, shiftLeftNeg8448(18));
  Expect.equals(-1188950301625810944, shiftLeftNeg8448(47));
  Expect.equals(-2377900603251621888, shiftLeftNeg8448(48));
  // Deoptimize on 64 bits.
  Expect.equals(-4755801206503243776, shiftLeftNeg8448(49));
  Expect.equals(-9511602413006487552, shiftLeftNeg8448(50));
}
