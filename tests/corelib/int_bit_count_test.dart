// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Testing int.trailingZeroBitCount and int.oneBitCount.

import "package:expect/expect.dart";
import "package:expect/variations.dart" show jsNumbers;

// Platform width for bit operations: 64 with native integer semantics
// (VM, dart2wasm), 32 with JS-number semantics (dart2js, DDC).
const int width = jsNumbers ? 32 : 64;

// `js == null` means the case is only meaningful on a native (64-bit)
// implementation and the JS assertion is skipped.
void checkTrailing(int i, int native, int? js) {
  final expected = jsNumbers ? js : native;
  if (expected == null) return;
  Expect.equals(expected, i.trailingZeroBitCount, '$i.trailingZeroBitCount');
}

void checkOne(int i, int native, int? js) {
  final expected = jsNumbers ? js : native;
  if (expected == null) return;
  Expect.equals(expected, i.oneBitCount, '$i.oneBitCount');
}

void testTrailingZeroBitCount() {
  // Zero: trailing count equals full platform width.
  checkTrailing(0, 64, 32);

  // Positive values.
  checkTrailing(1, 0, 0);
  checkTrailing(2, 1, 1);
  checkTrailing(3, 0, 0);
  checkTrailing(4, 2, 2);
  checkTrailing(8, 3, 3);
  checkTrailing(0x10, 4, 4);
  checkTrailing(4096, 12, 12);
  checkTrailing(0x8000_0000, 31, 31);
  checkTrailing(0x7fff_ffff, 0, 0);

  // Negative values: two's complement preserves low bits.
  checkTrailing(-1, 0, 0);
  checkTrailing(-2, 1, 1);
  checkTrailing(-4, 2, 2);
  checkTrailing(-1024, 10, 10);
  checkTrailing(-0x4000_0000, 30, 30);
  checkTrailing(-0x8000_0000, 31, 31);

  // Values above the 32-bit range. On JS the operation is defined as
  // counting trailing zeros of the low 32 bits, so any value whose low
  // 32 bits are zero yields the JS platform width (32) regardless of
  // what's above.
  checkTrailing(0x1_0000_0000, 32, 32);
  checkTrailing(0x2_0000_0000, 33, 32);
  checkTrailing(0x4_0000_0000, 34, 32);
  checkTrailing(0x100_0000_0000, 40, 32);
  checkTrailing(0x8000_0000_0000_0000, 63, 32);

  // 64-bit-range values whose low 32 bits are non-zero: the JS result
  // is determined entirely by the low half.
  checkTrailing(0x1_0000_0001, 0, 0);
  checkTrailing(0x2_0000_0080, 7, 7);

  // Near 2^63, JS doubles only have enough precision for values that
  // differ by 2048 (= 2^11), so consecutive integers can't all be
  // represented.
  // `2^63 + 4096` is exactly representable.
  // `2^63 + 4095` rounds up to the same value.
  checkTrailing(0x8000_0000_0000_0000 + 4096, 12, 12);
  checkTrailing(0x8000_0000_0000_0000 + 4095, 0, 12);
}

void testOneBitCount() {
  checkOne(0, 0, 0);
  checkOne(1, 1, 1);
  checkOne(2, 1, 1);
  checkOne(3, 2, 2);
  checkOne(7, 3, 3);
  checkOne(0x55, 4, 4);
  checkOne(0xff, 8, 8);
  checkOne(0xffff_ffff, 32, 32);

  // Negative values: sign-extend to platform width.
  checkOne(-1, 64, 32);
  checkOne(-2, 63, 31);
  checkOne(-3, 63, 31);
  checkOne(~0x55, 60, 28);
  checkOne(-0x5555_5555, 49, 17);
  checkOne(-0x7fff_ffff, 34, 2);
  checkOne(-0x8000_0000, 33, 1);

  // Values above the 32-bit range. JS counts only the low 32 bits, so
  // a single bit above bit 31 is invisible to JS oneBitCount.
  checkOne(0x1_0000_0000, 1, 0);
  checkOne(0x8000_0000_0000_0000, 1, 0);
  checkOne(0x2_0000_0001, 2, 1);
  checkOne(0x1_0000_FFFF, 17, 16);

  // `0x5555_5555_0000_0000 + 0x5555_5555` constructs
  // 0x5555_5555_5555_5555 on native, but the runtime addition overflows
  // JS double precision so the result on JS is unpredictable. Only the
  // native expectation is asserted.
  if (!jsNumbers) {
    final pattern = 0x5555_5555_0000_0000 + 0x5555_5555;
    checkOne(pattern, 32, null);
    checkOne(~0x8000_0000_0000_0000, 63, null);
    // Setting any odd-position bit on the alternating pattern should
    // raise the count from 32 to 33, exercising the 64-bit popcount path
    // across all positions.
    for (int i = 1; i < 64; i += 2) {
      Expect.equals(
        33,
        (pattern | (1 << i)).oneBitCount,
        '(pattern | (1<<$i)).oneBitCount',
      );
    }
  }
}

// Exhaustive single-bit coverage across the full platform width.
void testSingleBitCoverage() {
  for (int b = 0; b < width; b++) {
    final n = 1 << b;
    Expect.equals(b, n.trailingZeroBitCount, '(1<<$b).trailingZeroBitCount');
    Expect.equals(1, n.oneBitCount, '(1<<$b).oneBitCount');
  }
}

// Dart-on-JS guarantees that bit operations performed on unsigned 32-bit
// values produce the same answer as on a native 64-bit Dart implementation.
// Verify the new getters honor that for a representative set of inputs that
// span the full 32-bit unsigned range.
void testUnsigned32BitConsistency() {
  const cases = <(int, int, int)>[
    (0x0000_0001, 0, 1),
    (0x0000_0002, 1, 1),
    (0x0000_0080, 7, 1),
    (0x0000_FFFF, 0, 16),
    (0x5555_5555, 0, 16),
    (0xAAAA_AAAA, 1, 16),
    (0xCCCC_CCCC, 2, 16),
    (0xF0F0_F0F0, 4, 16),
    (0x4000_0000, 30, 1),
    (0x4000_0001, 0, 2),
    (0x8000_0000, 31, 1),
    (0x8000_0001, 0, 2),
    (0xC000_0000, 30, 2),
    (0xFFFF_FFFE, 1, 31),
    (0xFFFF_FFFF, 0, 32),
  ];
  for (final (n, tzc, obc) in cases) {
    Expect.equals(tzc, n.trailingZeroBitCount, '$n.trailingZeroBitCount');
    Expect.equals(obc, n.oneBitCount, '$n.oneBitCount');
  }
}

void testIdentities() {
  // n.oneBitCount + (~n).oneBitCount == platform width.
  for (final n in const [
    0,
    1,
    2,
    7,
    42,
    0x7fff_ffff,
    0x8000_0000,
    0xffff_ffff,
    -1,
    -2,
    -42,
  ]) {
    Expect.equals(
      width,
      n.oneBitCount + (~n).oneBitCount,
      '$n.oneBitCount + ~$n.oneBitCount',
    );
  }

  // Cross-check: for any nonzero n, `(n & -n) - 1` is a mask of exactly
  // `trailingZeroBitCount(n)` ones, so counting them recovers that count.
  // Exercises both getters against each other.
  void checkIdentity(int n) {
    Expect.equals(
      ((n & -n) - 1).oneBitCount,
      n.trailingZeroBitCount,
      '(($n & -$n) - 1).oneBitCount == $n.trailingZeroBitCount',
    );
  }

  // Small values + unsigned 32-bit boundaries + sign-extended negatives.
  // Identity holds on every backend.
  for (final n in const [
    1,
    2,
    3,
    7,
    42,
    0x4000_0000,
    0x8000_0000,
    0xffff_ffff,
    -1,
    -2,
    -42,
  ]) {
    checkIdentity(n);
  }

  // Values above the 32-bit range but within JS double mantissa precision
  // (≤ 2^52). Under Dart's "operate on the low 32 bits" web semantics
  // both sides of the identity collapse to 32, so the identity still
  // holds on dart2js / DDC.
  for (final n in const [
    0x1_0000_0000, // 2^32
    0x100_0000_0000, // 2^40
    0x10_0000_0000_0000, // 2^52
  ]) {
    checkIdentity(n);
  }

  // Native-only: values whose source bit pattern is not preserved by JS
  // doubles. Exercised only on backends with native 64-bit ints. The
  // `+ 1` form is used to keep `0x20_0000_0000_0000` as the literal,
  // since the dart2js analyzer rejects literals that can't be
  // represented exactly as a JS Number.
  if (!jsNumbers) {
    checkIdentity(0x20_0000_0000_0000 + 1); // 2^53 + 1
    checkIdentity(0x8000_0000_0000_0000); // 2^63
  }
}

void main() {
  testTrailingZeroBitCount();
  testOneBitCount();
  testSingleBitCoverage();
  testUnsigned32BitConsistency();
  testIdentities();
}
