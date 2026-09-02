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

void testAnyTrue() {
  // Exhaustive over all 16 zero/non-zero lane combinations: anyTrue is true
  // iff at least one lane is non-zero.
  for (int bits = 0; bits < 16; bits++) {
    final v = Int32x4(
      (bits & 1) != 0 ? 1 : 0,
      (bits & 2) != 0 ? 1 : 0,
      (bits & 4) != 0 ? 1 : 0,
      (bits & 8) != 0 ? 1 : 0,
    );
    Expect.equals(bits != 0, v.anyTrue);
  }

  // anyTrue is "any bit set in any lane", not "signMask != 0" (which only
  // checks the sign bit). Int32x4(1, 0, 0, 0) distinguishes them: it is
  // non-zero but the sign bit is clear, so signMask is 0 while anyTrue is true.
  final lowBit = Int32x4(1, 0, 0, 0);
  Expect.equals(0, lowBit.signMask);
  Expect.isTrue(lowBit.anyTrue);

  // All lanes non-zero -> true.
  Expect.isTrue(Int32x4(-1, -1, -1, -1).anyTrue);

  // Consistent with the comparison mask: a match makes anyTrue true.
  final a = Int32x4(1, 2, 3, 4);
  Expect.isFalse(a.equal(Int32x4(5, 6, 7, 8)).anyTrue);
  Expect.isTrue(a.equal(Int32x4(0, 2, 0, 0)).anyTrue);
  Expect.isTrue(a.equal(a).anyTrue);

  // Equivalent to the disjunction of the lane flags.
  final m = a.equal(Int32x4(0, 2, 0, 4));
  Expect.equals(m.flagX || m.flagY || m.flagZ || m.flagW, m.anyTrue);
}

void main() {
  for (int i = 0; i < 20; i++) {
    testEquality(true); // equal
    testEquality(false); // notEqual
    testAnyTrue();
  }
}
