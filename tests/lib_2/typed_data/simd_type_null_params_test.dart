// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import "package:expect/expect.dart";

bool throwsArgumentError(void Function() f) {
  bool caught = false;
  try {
    f();
  } on ArgumentError catch (e) {
    caught = true;
  } on TypeError catch (e) {
    // dart2js
    caught = true;
  }
  return caught;
}

main() {
  // Float32x4
  final float32x4 = Float32x4(0.0, 0.0, 0.0, 0.0);
  Expect.equals(throwsArgumentError(() => float32x4 + null), true);
  Expect.equals(throwsArgumentError(() => float32x4 - null), true);
  Expect.equals(throwsArgumentError(() => float32x4 * null), true);
  Expect.equals(throwsArgumentError(() => float32x4 / null), true);
  Expect.equals(throwsArgumentError(() => float32x4.lessThan(null)), true);
  Expect.equals(
      throwsArgumentError(() => float32x4.lessThanOrEqual(null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.greaterThan(null)), true);
  Expect.equals(
      throwsArgumentError(() => float32x4.greaterThanOrEqual(null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.equal(null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.notEqual(null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.scale(null)), true);
  Expect.equals(
      throwsArgumentError(() => float32x4.clamp(null, float32x4)), true);
  Expect.equals(
      throwsArgumentError(() => float32x4.clamp(float32x4, null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.shuffle(null)), true);
  Expect.equals(
      throwsArgumentError(() => float32x4.shuffleMix(float32x4, null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.shuffleMix(null, 0)), true);
  Expect.equals(throwsArgumentError(() => float32x4.withX(null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.withY(null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.withZ(null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.withW(null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.min(null)), true);
  Expect.equals(throwsArgumentError(() => float32x4.max(null)), true);
  Expect.equals(
      throwsArgumentError(() => Float32x4(null, 0.0, 0.0, 0.0)), true);
  Expect.equals(
      throwsArgumentError(() => Float32x4(0.0, null, 0.0, 0.0)), true);
  Expect.equals(
      throwsArgumentError(() => Float32x4(0.0, 0.0, null, 0.0)), true);
  Expect.equals(
      throwsArgumentError(() => Float32x4(0.0, 0.0, 0.0, null)), true);

  // Float32x4.splat
  Expect.equals(throwsArgumentError(() => Float32x4.splat(null)), true);

  // Float64x2
  final float64x2 = Float64x2(0.0, 0.0);
  Expect.equals(throwsArgumentError(() => float64x2 + null), true);
  Expect.equals(throwsArgumentError(() => float64x2 - null), true);
  Expect.equals(throwsArgumentError(() => float64x2 * null), true);
  Expect.equals(throwsArgumentError(() => float64x2 / null), true);
  Expect.equals(throwsArgumentError(() => float64x2.scale(null)), true);
  Expect.equals(
      throwsArgumentError(() => float64x2.clamp(null, float64x2)), true);
  Expect.equals(
      throwsArgumentError(() => float64x2.clamp(float64x2, null)), true);
  Expect.equals(throwsArgumentError(() => float64x2.withX(null)), true);
  Expect.equals(throwsArgumentError(() => float64x2.withY(null)), true);
  Expect.equals(throwsArgumentError(() => Float64x2(null, 0.0)), true);
  Expect.equals(throwsArgumentError(() => Float64x2(0.0, null)), true);
  Expect.equals(throwsArgumentError(() => float64x2.min(null)), true);
  Expect.equals(throwsArgumentError(() => float64x2.max(null)), true);

  // Float64x2.splat
  Expect.equals(throwsArgumentError(() => Float64x2.splat(null)), true);

  // Int32x4
  final int32x4 = Int32x4(0, 0, 0, 0);
  Expect.equals(throwsArgumentError(() => int32x4 + null), true);
  Expect.equals(throwsArgumentError(() => int32x4 - null), true);
  Expect.equals(throwsArgumentError(() => int32x4 ^ null), true);
  Expect.equals(throwsArgumentError(() => int32x4 & null), true);
  Expect.equals(throwsArgumentError(() => int32x4 | null), true);
  Expect.equals(throwsArgumentError(() => int32x4.shuffle(null)), true);
  Expect.equals(
      throwsArgumentError(() => int32x4.shuffleMix(int32x4, null)), true);
  Expect.equals(throwsArgumentError(() => int32x4.shuffleMix(null, 0)), true);
  Expect.equals(throwsArgumentError(() => int32x4.withX(null)), true);
  Expect.equals(throwsArgumentError(() => int32x4.withY(null)), true);
  Expect.equals(throwsArgumentError(() => int32x4.withZ(null)), true);
  Expect.equals(throwsArgumentError(() => int32x4.withW(null)), true);
  Expect.equals(throwsArgumentError(() => int32x4.withFlagX(null)), true);
  Expect.equals(throwsArgumentError(() => int32x4.withFlagY(null)), true);
  Expect.equals(throwsArgumentError(() => int32x4.withFlagZ(null)), true);
  Expect.equals(throwsArgumentError(() => int32x4.withFlagW(null)), true);

  Expect.equals(throwsArgumentError(() => Int32x4(null, 0, 0, 0)), true);
  Expect.equals(throwsArgumentError(() => Int32x4(0, null, 0, 0)), true);
  Expect.equals(throwsArgumentError(() => Int32x4(0, 0, null, 0)), true);
  Expect.equals(throwsArgumentError(() => Int32x4(0, 0, 0, null)), true);
  Expect.equals(
      throwsArgumentError(() => int32x4.select(null, float32x4)), true);
  Expect.equals(
      throwsArgumentError(() => int32x4.select(float32x4, null)), true);

  // Int32x4.bool
  Expect.equals(
      throwsArgumentError(() => Int32x4.bool(null, false, false, false)), true);
  Expect.equals(
      throwsArgumentError(() => Int32x4.bool(false, null, false, false)), true);
  Expect.equals(
      throwsArgumentError(() => Int32x4.bool(false, false, null, false)), true);
  Expect.equals(
      throwsArgumentError(() => Int32x4.bool(false, false, false, null)), true);
}
