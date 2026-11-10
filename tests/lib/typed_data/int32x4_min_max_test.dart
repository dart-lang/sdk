// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import 'dart:typed_data';

import 'package:expect/expect.dart';

// Int32 min and max.
const _min = -2147483648;
const _max = 2147483647;

void expectSameLanes(Int32x4 expected, Int32x4 actual, String what) {
  Expect.equals(expected.x, actual.x, '$what.x');
  Expect.equals(expected.y, actual.y, '$what.y');
  Expect.equals(expected.z, actual.z, '$what.z');
  Expect.equals(expected.w, actual.w, '$what.w');
}

/// Checks `a.min(b)` and `a.max(b)` lane by lane against a scalar oracle,
/// and that both are commutative.
void check(Int32x4 a, Int32x4 b) {
  int minLane(int x, int y) => x < y ? x : y;
  int maxLane(int x, int y) => x > y ? x : y;

  final expectedMin = Int32x4(
    minLane(a.x, b.x),
    minLane(a.y, b.y),
    minLane(a.z, b.z),
    minLane(a.w, b.w),
  );
  final expectedMax = Int32x4(
    maxLane(a.x, b.x),
    maxLane(a.y, b.y),
    maxLane(a.z, b.z),
    maxLane(a.w, b.w),
  );

  expectSameLanes(expectedMin, a.min(b), 'a.min(b)');
  expectSameLanes(expectedMax, a.max(b), 'a.max(b)');
  // Both are commutative.
  expectSameLanes(expectedMin, b.min(a), 'b.min(a)');
  expectSameLanes(expectedMax, b.max(a), 'b.max(a)');
}

void testSigned() {
  // The comparison is signed, so the lanes with the sign bit set are the
  // small ones. Read as unsigned, _min and -1 would instead be the largest
  // values of all.
  check(Int32x4(_min, _max, -1, 0), Int32x4.splat(0));
  check(Int32x4(_min, _min + 1, _max, _max - 1), Int32x4(-1, 1, -1, 1));
  check(Int32x4.splat(_min), Int32x4.splat(_max));
}

/// Checks that `v.min(v)` and `v.max(v)` are `v`, so applying either again
/// changes nothing.
void checkIdempotent(Int32x4 v) {
  expectSameLanes(v, v.min(v), 'v.min(v)');
  expectSameLanes(v, v.max(v), 'v.max(v)');
  expectSameLanes(v, v.min(v).min(v), 'v.min(v).min(v)');
  expectSameLanes(v, v.max(v).max(v), 'v.max(v).max(v)');
}

void testIdempotent() {
  checkIdempotent(Int32x4(7, -7, 0, 42));
  checkIdempotent(Int32x4.splat(_min));
  checkIdempotent(Int32x4.splat(_max));
  checkIdempotent(Int32x4.splat(-1));
}

/// Checks that `_min` is the identity of max and absorbing for min, and that
/// `_max` is the other way around.
void checkExtremesAreAbsorbing(int value) {
  final v = Int32x4.splat(value);
  expectSameLanes(Int32x4.splat(_min), v.min(Int32x4.splat(_min)), 'min _min');
  expectSameLanes(v, v.max(Int32x4.splat(_min)), 'max _min');
  expectSameLanes(v, v.min(Int32x4.splat(_max)), 'min _max');
  expectSameLanes(Int32x4.splat(_max), v.max(Int32x4.splat(_max)), 'max _max');
}

void testExtremesAreAbsorbing() {
  checkExtremesAreAbsorbing(_min);
  checkExtremesAreAbsorbing(_max);
  checkExtremesAreAbsorbing(-1);
  checkExtremesAreAbsorbing(0);
  checkExtremesAreAbsorbing(1);
  checkExtremesAreAbsorbing(123456789);
  checkExtremesAreAbsorbing(-987654321);
}

void main() {
  for (int i = 0; i < 20; i++) {
    testSigned();
    testIdempotent();
    testExtremesAreAbsorbing();
  }
}
