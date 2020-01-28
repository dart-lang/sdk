// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

import 'dart:typed_data';
import "package:expect/expect.dart";

bool throwsSomeError(void Function() f) {
  try {
    f();
  } catch (e) {
    return e is TypeError ||
        e is NoSuchMethodError ||
        e is ArgumentError ||
        e is AssertionError;
  }
  return false;
}

main() {
  dynamic dynamicNull = null;
  // Float32x4
  final float32x4 = Float32x4(0.0, 0.0, 0.0, 0.0);
  Expect.equals(true, throwsSomeError(() => float32x4 + dynamicNull));
  Expect.equals(true, throwsSomeError(() => float32x4 - dynamicNull));
  Expect.equals(true, throwsSomeError(() => float32x4 * dynamicNull));
  Expect.equals(true, throwsSomeError(() => float32x4 / dynamicNull));
  Expect.equals(true, throwsSomeError(() => float32x4.lessThan(dynamicNull)));
  Expect.equals(
      true, throwsSomeError(() => float32x4.lessThanOrEqual(dynamicNull)));
  Expect.equals(
      true, throwsSomeError(() => float32x4.greaterThan(dynamicNull)));
  Expect.equals(
      true, throwsSomeError(() => float32x4.greaterThanOrEqual(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float32x4.equal(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float32x4.notEqual(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float32x4.scale(dynamicNull)));
  Expect.equals(
      true, throwsSomeError(() => float32x4.clamp(dynamicNull, float32x4)));
  Expect.equals(
      true, throwsSomeError(() => float32x4.clamp(float32x4, dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float32x4.shuffle(dynamicNull)));
  Expect.equals(true,
      throwsSomeError(() => float32x4.shuffleMix(float32x4, dynamicNull)));
  Expect.equals(
      true, throwsSomeError(() => float32x4.shuffleMix(dynamicNull, 0)));
  Expect.equals(true, throwsSomeError(() => float32x4.withX(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float32x4.withY(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float32x4.withZ(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float32x4.withW(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float32x4.min(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float32x4.max(dynamicNull)));
  Expect.equals(
      true, throwsSomeError(() => Float32x4(dynamicNull, 0.0, 0.0, 0.0)));
  Expect.equals(
      true, throwsSomeError(() => Float32x4(0.0, dynamicNull, 0.0, 0.0)));
  Expect.equals(
      true, throwsSomeError(() => Float32x4(0.0, 0.0, dynamicNull, 0.0)));
  Expect.equals(
      true, throwsSomeError(() => Float32x4(0.0, 0.0, 0.0, dynamicNull)));

  // Float32x4.splat
  Expect.equals(true, throwsSomeError(() => Float32x4.splat(dynamicNull)));

  // Float64x2
  final float64x2 = Float64x2(0.0, 0.0);
  Expect.equals(true, throwsSomeError(() => float64x2 + dynamicNull));
  Expect.equals(true, throwsSomeError(() => float64x2 - dynamicNull));
  Expect.equals(true, throwsSomeError(() => float64x2 * dynamicNull));
  Expect.equals(true, throwsSomeError(() => float64x2 / dynamicNull));
  Expect.equals(true, throwsSomeError(() => float64x2.scale(dynamicNull)));
  Expect.equals(
      true, throwsSomeError(() => float64x2.clamp(dynamicNull, float64x2)));
  Expect.equals(
      true, throwsSomeError(() => float64x2.clamp(float64x2, dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float64x2.withX(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float64x2.withY(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => Float64x2(dynamicNull, 0.0)));
  Expect.equals(true, throwsSomeError(() => Float64x2(0.0, dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float64x2.min(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => float64x2.max(dynamicNull)));

  // Float64x2.splat
  Expect.equals(true, throwsSomeError(() => Float64x2.splat(dynamicNull)));

  // Int32x4
  final int32x4 = Int32x4(0, 0, 0, 0);
  Expect.equals(true, throwsSomeError(() => int32x4 + dynamicNull));
  Expect.equals(true, throwsSomeError(() => int32x4 - dynamicNull));
  Expect.equals(true, throwsSomeError(() => int32x4 ^ dynamicNull));
  Expect.equals(true, throwsSomeError(() => int32x4 & dynamicNull));
  Expect.equals(true, throwsSomeError(() => int32x4 | dynamicNull));
  Expect.equals(true, throwsSomeError(() => int32x4.shuffle(dynamicNull)));
  Expect.equals(
      true, throwsSomeError(() => int32x4.shuffleMix(int32x4, dynamicNull)));
  Expect.equals(
      true, throwsSomeError(() => int32x4.shuffleMix(dynamicNull, 0)));
  Expect.equals(true, throwsSomeError(() => int32x4.withX(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => int32x4.withY(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => int32x4.withZ(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => int32x4.withW(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => int32x4.withFlagX(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => int32x4.withFlagY(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => int32x4.withFlagZ(dynamicNull)));
  Expect.equals(true, throwsSomeError(() => int32x4.withFlagW(dynamicNull)));

  Expect.equals(true, throwsSomeError(() => Int32x4(dynamicNull, 0, 0, 0)));
  Expect.equals(true, throwsSomeError(() => Int32x4(0, dynamicNull, 0, 0)));
  Expect.equals(true, throwsSomeError(() => Int32x4(0, 0, dynamicNull, 0)));
  Expect.equals(true, throwsSomeError(() => Int32x4(0, 0, 0, dynamicNull)));
  Expect.equals(
      true, throwsSomeError(() => int32x4.select(dynamicNull, float32x4)));
  Expect.equals(
      true, throwsSomeError(() => int32x4.select(float32x4, dynamicNull)));

  // Int32x4.bool
  Expect.equals(true,
      throwsSomeError(() => Int32x4.bool(dynamicNull, false, false, false)));
  Expect.equals(true,
      throwsSomeError(() => Int32x4.bool(false, dynamicNull, false, false)));
  Expect.equals(true,
      throwsSomeError(() => Int32x4.bool(false, false, dynamicNull, false)));
  Expect.equals(true,
      throwsSomeError(() => Int32x4.bool(false, false, false, dynamicNull)));
}
