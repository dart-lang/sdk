// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test: positive `0x` hex strings exceeding 64 bits must fail with
// FormatException / null on 64-bit int platforms instead of wrapping modulo
// 2^64.

import "package:expect/expect.dart";
import "package:expect/variations.dart" as v;

void main() {
  if (!v.jsNumbers) {
    final int minInt64 = int.parse("-0x8000000000000000");
    final int maxInt64 = ~minInt64;

    // Valid unsigned 64-bit `0x` inputs, including leading zeros.
    Expect.equals(0, int.parse("0x000000000000000000000000"));
    Expect.equals(maxInt64, int.parse("0x7fffffffffffffff"));
    Expect.equals(minInt64, int.parse("0x8000000000000000"));
    Expect.equals(-1, int.parse("0xffffffffffffffff"));
    Expect.equals(-1, int.parse("+0xffffffffffffffff"));
    Expect.equals(-1, int.parse("0x00000000ffffffffffffffff"));

    // >64-bit `0x` inputs must be rejected, not truncated modulo 2^64.
    for (final input in [
      "0x10000000000000000",
      "0x10000000000000001",
      "0xfffffffffffffffff",
      "+0x10000000000000000",
      "0x000010000000000000000",
      "0xdeadbeefcafebabe1234567890abcdef",
    ]) {
      Expect.throwsFormatException(() => int.parse(input), input);
      Expect.isNull(int.tryParse(input), input);
    }
  }

  for (final invalid in [
    "0x100000000000000g",
    "0x1000000000000000g",
    "0x10000000000000000g",
  ]) {
    Expect.throwsFormatException(() => int.parse(invalid), invalid);
    Expect.isNull(int.tryParse(invalid), invalid);
  }
}
