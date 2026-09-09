// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library int32x4_compare;

import 'dart:typed_data';

import 'package:expect/expect.dart';

// Int32 min and max.
const _min = -2147483648;
const _max = 2147483647;

/// Tests Int32x4 equality comparisons.
///
/// If [testingEqual] is true, tests [Int32x4.equal].
/// If [testingEqual] is false, tests [Int32x4.notEqual].
void testEquality(bool testingEqual) {
  Int32x4 compare(Int32x4 a, Int32x4 b) =>
      testingEqual ? a.equal(b) : a.notEqual(b);

  // Checks that:
  // - compare produces the expected mask
  // - compare is symmetric
  // - each operand is reflexive (equals itself in every lane)
  // - equal and notEqual are inverses, i.e. never equal to each other
  void check(Int32x4 a, Int32x4 b) {
    void expectSameLanes(Int32x4 expected, Int32x4 actual) {
      Expect.equals(expected.x, actual.x);
      Expect.equals(expected.y, actual.y);
      Expect.equals(expected.z, actual.z);
      Expect.equals(expected.w, actual.w);
    }

    // -1 where the operator is true for the lane, else 0.
    int compareLane(int a, int b) => (a == b) == testingEqual ? -1 : 0;
    final r = compare(a, b);
    Expect.equals(compareLane(a.x, b.x), r.x);
    Expect.equals(compareLane(a.y, b.y), r.y);
    Expect.equals(compareLane(a.z, b.z), r.z);
    Expect.equals(compareLane(a.w, b.w), r.w);
    var sign = 0;
    if (r.x == -1) sign |= 1;
    if (r.y == -1) sign |= 2;
    if (r.z == -1) sign |= 4;
    if (r.w == -1) sign |= 8;
    Expect.equals(sign, r.signMask);

    // Symmetry: swapping the operands gives the same mask.
    expectSameLanes(r, compare(b, a));

    // Reflexivity: each operand compares equal to itself in every lane.
    void reflexive(Int32x4 v) {
      final selfMask = compare(v, v);
      final expected = testingEqual ? -1 : 0;
      Expect.equals(expected, selfMask.x);
      Expect.equals(expected, selfMask.y);
      Expect.equals(expected, selfMask.z);
      Expect.equals(expected, selfMask.w);
    }

    reflexive(a);
    reflexive(b);

    // equal and notEqual are inverses: ~ turns one into the other, and they
    // disagree in every lane (eq.notEqual(neq) all true, eq.equal(neq) all
    // false).
    final eq = a.equal(b);
    final neq = a.notEqual(b);
    expectSameLanes(neq, ~eq);
    expectSameLanes(eq, ~neq);
    final eqNeq = eq.notEqual(neq);
    Expect.equals(-1, eqNeq.x);
    Expect.equals(-1, eqNeq.y);
    Expect.equals(-1, eqNeq.z);
    Expect.equals(-1, eqNeq.w);
    final eqEq = eq.equal(neq);
    Expect.equals(0, eqEq.x);
    Expect.equals(0, eqEq.y);
    Expect.equals(0, eqEq.z);
    Expect.equals(0, eqEq.w);
  }

  // All lanes equal.
  check(Int32x4(1, 2, 3, 4), Int32x4(1, 2, 3, 4));
  check(Int32x4(-3, -2, -1, 0), Int32x4(-3, -2, -1, 0));
  check(Int32x4(_min, _max, 0, -1), Int32x4(_min, _max, 0, -1));
  // No lanes equal.
  check(Int32x4(1, 2, 3, 4), Int32x4(5, 6, 7, 8));
  check(Int32x4(-3, -2, -1, 0), Int32x4(-7, -6, -5, -4));
  check(Int32x4(_min, _max, 0, -1), Int32x4(_max, _min, -1, 0));
  // Only y and w match.
  check(Int32x4(1, 2, 3, 4), Int32x4(0, 2, 0, 4));
  check(Int32x4(-3, -2, -1, 0), Int32x4(0, -2, 0, 0));
  check(Int32x4(_min, 2, _max, 4), Int32x4(0, 2, 0, 4));
}

void testAnyTrueAndAllTrue() {
  // For the full 16-combination matrix:
  // - anyTrue is true iff at least one lane is non-zero (disjunction of the
  //   lane flags).
  // - allTrue is true iff every lane is non-zero (conjunction of the flags).
  // - a lane counts as non-zero for any set bit, so each combination is filled
  //   from several lane-value sets, including one with a distinct bit per lane
  //   (no bit in common) and the int32 extremes.
  const laneValueSets = [
    (1, 2, 4, 8),
    (-1, -1, -1, -1),
    (1, 2147483647, -2147483648, 8),
  ];
  for (final vals in laneValueSets) {
    for (int bits = 0; bits < 16; bits++) {
      final v = Int32x4(
        (bits & 1) != 0 ? vals.$1 : 0,
        (bits & 2) != 0 ? vals.$2 : 0,
        (bits & 4) != 0 ? vals.$3 : 0,
        (bits & 8) != 0 ? vals.$4 : 0,
      );
      // Expected result: at least one lane non-zero.
      Expect.equals(bits != 0, v.anyTrue);
      // Equivalent to the disjunction of the lane flags.
      Expect.equals(v.flagX || v.flagY || v.flagZ || v.flagW, v.anyTrue);
      // Expected result: every lane non-zero.
      Expect.equals(bits == 0xf, v.allTrue);
      // Equivalent to the conjunction of the lane flags.
      Expect.equals(v.flagX && v.flagY && v.flagZ && v.flagW, v.allTrue);
    }
  }

  // Both look at any set bit, not the sign bit that signMask reads. Lanes with
  // only low bits set have signMask 0 but are still non-zero.
  final lowBit = Int32x4(1, 0, 0, 0);
  Expect.equals(0, lowBit.signMask);
  Expect.isTrue(lowBit.anyTrue);
  Expect.isFalse(lowBit.allTrue);

  final lowBits = Int32x4(1, 1, 1, 1);
  Expect.equals(0, lowBits.signMask);
  Expect.isTrue(lowBits.allTrue);

  // Typically applied to a comparison mask.
  final a = Int32x4(1, 2, 3, 4);
  Expect.isTrue(a.equal(a).allTrue);
  Expect.isFalse(a.equal(Int32x4(5, 6, 7, 8)).anyTrue);
  Expect.isTrue(a.equal(Int32x4(0, 2, 0, 0)).anyTrue);
  Expect.isFalse(a.equal(Int32x4(1, 2, 3, 0)).allTrue);
}

void testComparisons() {
  const lanes = [-2147483648, -1, 0, 1, 2147483647];
  for (final p in lanes) {
    for (final q in lanes) {
      final a = Int32x4(p, p, p, p);
      final b = Int32x4(q, q, q, q);

      final lt = a.lessThan(b);
      final le = a.lessThanOrEqual(b);
      final gt = a.greaterThan(b);
      final ge = a.greaterThanOrEqual(b);

      final expLt = p < q ? -1 : 0;
      final expLe = p <= q ? -1 : 0;
      final expGt = p > q ? -1 : 0;
      final expGe = p >= q ? -1 : 0;

      Expect.equals(expLt, lt.x);
      Expect.equals(expLt, lt.y);
      Expect.equals(expLt, lt.z);
      Expect.equals(expLt, lt.w);

      Expect.equals(expLe, le.x);
      Expect.equals(expLe, le.y);
      Expect.equals(expLe, le.z);
      Expect.equals(expLe, le.w);

      Expect.equals(expGt, gt.x);
      Expect.equals(expGt, gt.y);
      Expect.equals(expGt, gt.z);
      Expect.equals(expGt, gt.w);

      Expect.equals(expGe, ge.x);
      Expect.equals(expGe, ge.y);
      Expect.equals(expGe, ge.z);
      Expect.equals(expGe, ge.w);
    }
  }
}

void main() {
  for (int i = 0; i < 20; i++) {
    testEquality(true); // equal
    testEquality(false); // notEqual
    testAnyTrueAndAllTrue();
    testComparisons();
  }
}
