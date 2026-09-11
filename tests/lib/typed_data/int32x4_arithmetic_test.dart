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
    testTruncation();
  }
}
