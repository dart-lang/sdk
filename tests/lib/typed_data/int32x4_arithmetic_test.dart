// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation

import 'dart:typed_data';

import "package:expect/expect.dart";

void testAdd() {
  var m = Int32x4.zero();
  var n = Int32x4(-1, -1, -1, -1);
  var o = m + n;
  Expect.equals(-1, o.x);
  Expect.equals(-1, o.y);
  Expect.equals(-1, o.z);
  Expect.equals(-1, o.w);

  m = Int32x4.zero();
  n = Int32x4(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
  o = m + n;
  Expect.equals(-1, o.x);
  Expect.equals(-1, o.y);
  Expect.equals(-1, o.z);
  Expect.equals(-1, o.w);

  n = Int32x4(1, 1, 1, 1);
  m = Int32x4(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
  o = m + n;
  Expect.equals(0, o.x);
  Expect.equals(0, o.y);
  Expect.equals(0, o.z);
  Expect.equals(0, o.w);

  n = Int32x4(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
  m = Int32x4(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
  o = m + n;
  Expect.equals(-2, o.x);
  Expect.equals(-2, o.y);
  Expect.equals(-2, o.z);
  Expect.equals(-2, o.w);

  n = Int32x4(1, 0, 0, 0);
  m = Int32x4(2, 0, 0, 0);
  o = n + m;
  Expect.equals(3, o.x);
  Expect.equals(0, o.y);
  Expect.equals(0, o.z);
  Expect.equals(0, o.w);

  n = Int32x4(1, 3, 0, 0);
  m = Int32x4(2, 4, 0, 0);
  o = n + m;
  Expect.equals(3, o.x);
  Expect.equals(7, o.y);
  Expect.equals(0, o.z);
  Expect.equals(0, o.w);

  n = Int32x4(1, 3, 5, 0);
  m = Int32x4(2, 4, 6, 0);
  o = n + m;
  Expect.equals(3, o.x);
  Expect.equals(7, o.y);
  Expect.equals(11, o.z);
  Expect.equals(0, o.w);

  n = Int32x4(1, 3, 5, 7);
  m = Int32x4(-2, -4, -6, -8);
  o = n + m;
  Expect.equals(-1, o.x);
  Expect.equals(-1, o.y);
  Expect.equals(-1, o.z);
  Expect.equals(-1, o.w);
}

void testSub() {
  var m = Int32x4.zero();
  var n = Int32x4(1, 1, 1, 1);
  var o = m - n;
  Expect.equals(-1, o.x);
  Expect.equals(-1, o.y);
  Expect.equals(-1, o.z);
  Expect.equals(-1, o.w);

  o = n - m;
  Expect.equals(1, o.x);
  Expect.equals(1, o.y);
  Expect.equals(1, o.z);
  Expect.equals(1, o.w);
}

void testNegate() {
  const int min = -2147483648;
  const int max = 2147483647;

  // (input lanes, expected -input lanes). Negation can overflow near the
  // extremes and wrap back into range.
  const cases = <((int, int, int, int), (int, int, int, int))>[
    // Distinct lanes negate independently.
    ((1, -2, 3, -4), (-1, 2, -3, 4)),
    // Around zero.
    ((0, 1, -1, 2), (0, -1, 1, -2)),
    // Near the minimum.
    ((min, min + 1, min + 2, min + 3), (min, max, max - 1, max - 2)),
    // Near the maximum.
    ((max, max - 1, max - 2, max - 3), (min + 1, min + 2, min + 3, min + 4)),
    // Arbitrary values away from all the edges.
    ((123456789, -987654321, 50000, -77), (-123456789, 987654321, -50000, 77)),
  ];
  for (final ((ix, iy, iz, iw), (ex, ey, ez, ew)) in cases) {
    final v = Int32x4(ix, iy, iz, iw);
    final r = -v;
    Expect.equals(ex, r.x);
    Expect.equals(ey, r.y);
    Expect.equals(ez, r.z);
    Expect.equals(ew, r.w);
    // Double negation is the identity.
    final rr = -r;
    Expect.equals(ix, rr.x);
    Expect.equals(iy, rr.y);
    Expect.equals(iz, rr.z);
    Expect.equals(iw, rr.w);
  }
}

void testAbs() {
  const int min = -2147483648;
  const int max = 2147483647;

  // (input lanes, expected abs lanes). The absolute value can overflow near the
  // minimum and wrap back into range.
  const cases = <((int, int, int, int), (int, int, int, int))>[
    // Distinct lanes take abs independently.
    ((-1, 2, -3, 0), (1, 2, 3, 0)),
    // Around zero.
    ((0, 1, -1, 2), (0, 1, 1, 2)),
    // Near the minimum.
    ((min, min + 1, min + 2, min + 3), (min, max, max - 1, max - 2)),
    // Near the maximum.
    ((max, max - 1, max - 2, max - 3), (max, max - 1, max - 2, max - 3)),
    // Arbitrary values away from all the edges.
    ((123456789, -987654321, 50000, -77), (123456789, 987654321, 50000, 77)),
  ];
  for (final ((ix, iy, iz, iw), (ex, ey, ez, ew)) in cases) {
    final r = Int32x4(ix, iy, iz, iw).abs();
    Expect.equals(ex, r.x);
    Expect.equals(ey, r.y);
    Expect.equals(ez, r.z);
    Expect.equals(ew, r.w);
    // abs is idempotent.
    final rr = r.abs();
    Expect.equals(ex, rr.x);
    Expect.equals(ey, rr.y);
    Expect.equals(ez, rr.z);
    Expect.equals(ew, rr.w);
  }

  // Check that `Int32x4.splat(0).abs()` has only positive zeros.
  // A hypothetical bugged implementation of `abs` doing
  // `abs(int n) => n <= 0 ? -n : n;` could make you end up with negative zeros
  // on the web.
  final zeroAbs = Int32x4.splat(0).abs();
  expectPositiveZero(zeroAbs.x, "Int32x4.splat(0).abs().x");
  expectPositiveZero(zeroAbs.y, "Int32x4.splat(0).abs().y");
  expectPositiveZero(zeroAbs.z, "Int32x4.splat(0).abs().z");
  expectPositiveZero(zeroAbs.w, "Int32x4.splat(0).abs().w");
}

void testShift() {
  const int min = -2147483648;
  const int max = 2147483647;

  void checkShift(
    (int, int, int, int) lanes,
    int shift,
    (int, int, int, int) leftShiftResult,
    (int, int, int, int) rightShiftResult,
  ) {
    final (x, y, z, w) = lanes;
    final (lx, ly, lz, lw) = leftShiftResult;
    final (rx, ry, rz, rw) = rightShiftResult;

    final v = Int32x4(x, y, z, w);
    final l = v << shift;
    Expect.equals(lx, l.x);
    Expect.equals(ly, l.y);
    Expect.equals(lz, l.z);
    Expect.equals(lw, l.w);
    final r = v >> shift;
    Expect.equals(rx, r.x);
    Expect.equals(ry, r.y);
    Expect.equals(rz, r.z);
    Expect.equals(rw, r.w);
  }

  // Small shift, distinct lanes shifted independently.
  checkShift((1, 2, 3, -1), 4, (16, 32, 48, -16), (0, 0, 0, -1));
  // Left shift into the sign bit produces the minimum.
  checkShift((0x40000000, 0, 0, 0), 1, (min, 0, 0, 0), (0x20000000, 0, 0, 0));
  // Right shift sign-extends the negative lanes.
  checkShift((-8, 8, -1, 1024), 1, (-16, 16, -2, 2048), (-4, 4, -1, 512));
  // Arithmetic right shift of odd negatives rounds toward negative infinity,
  // so it differs from truncating division (-7 >> 1 is -4).
  checkShift((-7, -3, -5, -1), 1, (-14, -6, -10, -2), (-4, -2, -3, -1));
  // Extremes by one: `<<` overflows (max flips into the sign, min's sign bit
  // drops), `>>` halves each lane and keeps its sign.
  const halved = (min ~/ 2, max ~/ 2, min ~/ 2, max ~/ 2);
  checkShift((min, max, min, max), 1, (0, -2, 0, -2), halved);
  // Extremes by 31, all the way onto the sign bit.
  checkShift((min, max, -1, 1), 31, (0, min, min, min), (-1, 0, -1, 0));
  // Shifting by zero is the identity.
  const unshifted = (5, min, -7, 0x12345678);
  checkShift(unshifted, 0, unshifted, unshifted);

  // The shift count is taken modulo 32, matching the WASM i32x4 shift
  // instructions, so out-of-range and negative counts act like their low five
  // bits. A count of -1 shifts by 31 rather than being an error.
  const plainCounts = <int>[32, 33, 63, 64, 100, -1, -31, -32, -33];
  final wideCounts = <int>[
    ...plainCounts,
    if (usingJavaScriptNumbers) ...[
      // JavaScript classifies these as `int` too. Converting either to a shift
      // count gives zero, so both act like a shift by zero.
      -0.0 as dynamic,
      double.infinity as dynamic,
    ],
  ];
  final v = Int32x4(min, max, -7, 0x12345678);
  for (final n in wideCounts) {
    final k = n & 31;
    Expect.equals((v << k).x, (v << n).x);
    Expect.equals((v << k).y, (v << n).y);
    Expect.equals((v << k).z, (v << n).z);
    Expect.equals((v << k).w, (v << n).w);
    Expect.equals((v >> k).x, (v >> n).x);
    Expect.equals((v >> k).y, (v >> n).y);
    Expect.equals((v >> k).z, (v >> n).z);
    Expect.equals((v >> k).w, (v >> n).w);
  }

  // Scalar `int` shifts diverge here: a negative count throws for `int`, but
  // the lane shifts mask it to a valid amount, so `<< -1` matches `<< 31`.
  final int negativeCount = -1;
  Expect.throwsArgumentError(() => 1 << negativeCount);
  Expect.throwsArgumentError(() => 1 >> negativeCount);
  Expect.equals((v << 31).x, (v << negativeCount).x);
  Expect.equals((v >> 31).x, (v >> negativeCount).x);
}

const int53 = 0x20000000000000; // 2^53.
final usingJavaScriptNumbers = (int53 + 1) == int53;

void testTruncation() {
  // Check that various bits from bit 32 and up are masked away.
  var base = usingJavaScriptNumbers ? 0x1BCCDD00000000 : 0xAABBCCDD00000000;
  var x1 = Int32x4(base + 1, 0, 0, 0);
  Expect.equals(1, x1.x);

  // Check that all even bits up to bit 30 are preserved.
  var x2 = Int32x4(base + 0x55555555, 0, 0, 0);
  Expect.equals(0x55555555, x2.x);

  // Check that the odd bits up to bit 31 are preserved, and that
  // bit 31 is treated as a sign bit.
  var x3 = Int32x4(base + 0xAAAAAAAA, 0, 0, 0);
  const signExtended = -1431655766; // 0xFFFFFFFFAAAAAAAA or 0x3FFFFFAAAAAAAA.
  Expect.equals(signExtended, x3.x);

  // Check that all bits from bit 32 and up are masked away.
  var highBase = 0xFFFFFFFF10000000;
  var x4 = Int32x4(highBase, 0, 0, 0);
  Expect.equals(0x10000000, x4.x);
}

/// Checks that [value] is positive zero, not negative zero.
///
/// On the web an `int` is a JavaScript number, which has a distinct negative
/// zero that an [Int32x4] lane should never contain. `1.0 / 0.0` is `+Infinity`
/// while `1.0 / -0.0` is `-Infinity`, so this tells them apart.
void expectPositiveZero(int value, String description) {
  Expect.equals(0, value, description);
  Expect.equals(
    double.infinity,
    1.0 / value,
    "$description should be positive zero, not negative zero",
  );
}

/// Returns a negative zero `int` at runtime, observable only on the web.
@pragma("dart2js:noInline")
int negativeZero(int zero) => -zero;

void testNegativeZero() {
  // Storing a negative zero lane comes back out as positive zero.
  final z = negativeZero(0);
  final stored = Int32x4(z, z, z, z);
  expectPositiveZero(stored.x, "Int32x4(-0).x");
  expectPositiveZero(stored.y, "Int32x4(-0).y");
  expectPositiveZero(stored.z, "Int32x4(-0).z");
  expectPositiveZero(stored.w, "Int32x4(-0).w");

  // Negating a zero lane yields positive zero, not negative zero.
  final negated = -Int32x4(0, 0, 0, 0);
  expectPositiveZero(negated.x, "(-Int32x4(0)).x");
  expectPositiveZero(negated.y, "(-Int32x4(0)).y");
  expectPositiveZero(negated.z, "(-Int32x4(0)).z");
  expectPositiveZero(negated.w, "(-Int32x4(0)).w");

  // The absolute value of a zero lane is positive zero.
  final absed = Int32x4(0, 0, 0, 0).abs();
  expectPositiveZero(absed.x, "Int32x4(0).abs().x");
  expectPositiveZero(absed.y, "Int32x4(0).abs().y");
  expectPositiveZero(absed.z, "Int32x4(0).abs().z");
  expectPositiveZero(absed.w, "Int32x4(0).abs().w");
}

void main() {
  for (int i = 0; i < 20; i++) {
    testAdd();
    testSub();
    testNegate();
    testAbs();
    testNegativeZero();
    testShift();
    testTruncation();
  }
}
