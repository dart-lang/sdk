// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extreme values from int_modulo_arith_test. Test cases that that have
// intermediate values that overflow the precision of 'int'.

import "package:expect/expect.dart";

import "dart:math" show pow;

main() {
  test(x, e, m, expectedResult) {
    var result = x.modPow(e, m);
    Expect.equals(expectedResult, result, "$x.modPow($e, $m)");
  }

  for (int mBase in [
    50000000,
    94906266, // Smallest integer with square over 2^53.
    100000000,
    1000000000,
    3037000500, // Smallest integer with square over 2^63.
    4000000000,
    0x7FFFFFFFFFFFF000 + 0xFFC
  ]) {
    // On 'web' platforms skip values outside web number safe range.
    if (mBase == mBase + 1) continue;

    for (int mAdjustment in [0, 1, 2, 3, -1]) {
      int m = mBase + mAdjustment;
      for (int e = 1; e < 100; e++) {
        // Test "M-k ^ N mod M == (-k) ^ N mod M" for some small values of k.
        test(m - 1, e, m, pow(-1, e) % m);
        if (e < 53) {
          test(m - 2, e, m, pow(-2, e) % m);
        }
        if (e < 33) {
          test(m - 3, e, m, pow(-3, e) % m);
        }
        if (e < 26) {
          test(m - 4, e, m, pow(-4, e) % m);
        }
      }
    }
  }
}
