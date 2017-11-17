// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test num.clamp.
// VMOptions=--no-use-field-guards
// VMOptions=

import "package:expect/expect.dart";

// Pedestrian implementation of sign, following its specification directly.
num sign(num value) {
  if (value is int) {
    if (value < 0) return -1;
    if (value > 0) return 1;
    return 0;
  }
  if (value.isNaN) return value;
  if (value == 0.0) return value;
  if (value > 0.0) return 1.0;
  return -1.0;
}

var numbers = [
  // Integers
  0,
  1,
  2,
  0x7f, //                     ~7 bits
  0x80,
  0xff, //                     ~8 bits
  0x100,
  0xffff, //                   ~16 bits
  0x10000,
  0x3fffffff, //               ~30 bits (max positive 32-bit tagged smi)
  0x40000000,
  0x40000001,
  0x7fffffff, //               ~31 bits
  0x80000000,
  0x80000001,
  0xfffffffff, //              ~32 bits
  0x100000000,
  0x100000001,
  0x10000000000000, //         ~53 bits
  0x10000000000001,
  0x1fffffffffffff,
  0x20000000000000,
  0x20000000000001, //         first integer not representable as double.
  0x20000000000002,
  0x7fffffffffffffff, //       ~63 bits
  0x8000000000000000,
  0x8000000000000001,
  0xffffffffffffffff, //       ~64 bits
  // Doubles.
  0.0,
  5e-324, //                   min positive
  2.225073858507201e-308, //   max denormal
  2.2250738585072014e-308, //  min normal
  0.49999999999999994, //      ~0.5
  0.5,
  0.5000000000000001,
  0.9999999999999999, //       ~1.0
  1.0,
  1.0000000000000002,
  4294967295.0, //             ~32 bits
  4294967296.0,
  4503599627370495.5, //       max fractional
  4503599627370497.0,
  9007199254740991.0,
  9007199254740992.0, //       max exact (+1 is not a double)
  1.7976931348623157e+308, //  max finite double
  1.0 / 0.0, //                Infinity
  0.0 / 0.0, //                NaN
];

main() {
  for (num number in numbers) {
    test(number);
    test(-number);
  }
}

void test(number) {
  num expectSign = sign(number);
  num actualSign = number.sign;
  if (expectSign.isNaN) {
    Expect.isTrue(actualSign.isNaN, "$number: $actualSign != NaN");
  } else {
    if (number is int) {
      Expect.isTrue(actualSign is int, "$number.sign is int");
    } else {
      Expect.isTrue(actualSign is double, "$number.sign is double");
    }
    Expect.equals(expectSign, actualSign, "$number");
    Expect.equals(number.isNegative, actualSign.isNegative, "$number:negative");
    var renumber = actualSign * number.abs();
    Expect.equals(number, renumber, "$number (sign*abs)");
    if (number is int) {
      Expect.isTrue(renumber is int, "$number (sign*abs) is int");
    } else {
      Expect.isTrue(renumber is double, "$number (sign*abs) is double");
    }
  }
}
