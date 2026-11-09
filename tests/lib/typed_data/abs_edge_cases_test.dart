// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests abs on double, Float32x4 and Float64x2 edge cases.

import 'dart:typed_data';

import "package:expect/expect.dart";
import "package:expect/float_bits.dart";
import "package:expect/variations.dart" show jsNumbers;

void main() {
  const ninf = Float64.negativeInfinity;
  const pinf = Float64.positiveInfinity;
  const nz = Float64.negativeZero;
  const pz = Float64.positiveZero;
  const nnorm = Float64.negativeNormal;
  const pnorm = Float64.positiveNormal;
  const pnan = Float64.positiveQuietNan;
  const nnan = Float64.negativeQuietNan;
  const pSubMin = Float64.positiveSmallestSubnormal;
  const nSubMin = Float64.negativeSmallestSubnormal;
  const pSubMax = Float64.positiveLargestSubnormal;
  const nSubMax = Float64.negativeLargestSubnormal;
  const pqNanLo = Float64.positiveQuietNanLowPayload;
  const nqNanLo = Float64.negativeQuietNanLowPayload;
  const psNanLo = Float64.positiveSignalingNanLowPayload;
  const nsNanLo = Float64.negativeSignalingNanLowPayload;
  const ninf32 = Float32.negativeInfinity;
  const pinf32 = Float32.positiveInfinity;
  const nz32 = Float32.negativeZero;
  const pz32 = Float32.positiveZero;
  const nnorm32 = Float32.negativeNormal;
  const pnorm32 = Float32.positiveNormal;
  const pSubMin32 = Float32.positiveSmallestSubnormal;
  const nSubMin32 = Float32.negativeSmallestSubnormal;
  const pSubMax32 = Float32.positiveLargestSubnormal;
  const nSubMax32 = Float32.negativeLargestSubnormal;
  const pnan32 = Float32.positiveQuietNan;
  const nnan32 = Float32.negativeQuietNan;
  const pqNan32 = Float32.positiveQuietNanPayload;
  const nqNan32 = Float32.negativeQuietNanPayload;
  const psNan32 = Float32.positiveSignalingNanPayload;
  const nsNan32 = Float32.negativeSignalingNanPayload;

  const float64Cases = [
    (ninf, pinf),
    (nnorm, pnorm),
    (nSubMax, pSubMax),
    (nSubMin, pSubMin),
    (nz, pz),
    (pz, pz),
    (pSubMin, pSubMin),
    (pSubMax, pSubMax),
    (pnorm, pnorm),
    (pinf, pinf),
    (pnan, pnan),
    (nnan, pnan),
    (pqNanLo, pqNanLo),
    (psNanLo, psNanLo),
    (nqNanLo, pqNanLo),
    (nsNanLo, psNanLo),
  ];

  const float32Cases = [
    (ninf32, pinf32),
    (nnorm32, pnorm32),
    (nSubMax32, pSubMax32),
    (nSubMin32, pSubMin32),
    (nz32, pz32),
    (pz32, pz32),
    (pSubMin32, pSubMin32),
    (pSubMax32, pSubMax32),
    (pnorm32, pnorm32),
    (pinf32, pinf32),
    (pnan32, pnan32),
    (nnan32, pnan32),
    (pqNan32, pqNan32),
    (psNan32, psNan32),
    (nqNan32, pqNan32),
    (nsNan32, psNan32),
  ];

  void check<T extends FloatBits>(
    String name,
    FloatBits Function(T) abs,
    List<(T, T)> cases,
  ) {
    for (final (operand, want) in cases) {
      final got = abs(operand);
      // A NaN's bit pattern is not observable on JavaScript.
      if (want.isNaN && jsNumbers) {
        Expect.isTrue(got.isNaN, '$name: abs($operand) was $got');
      } else {
        Expect.equals(want, got, '$name: abs($operand)');
      }
    }
  }

  check('double', (v) => Float64.fromDouble(v.toDouble().abs()), float64Cases);
  for (var lane = 0; lane < 4; lane++) {
    check('Float32x4 lane $lane', (v) {
      // The lanes go in and out as bits, so no NaN is converted.
      final r = Int32x4.fromFloat32x4Bits(
        Float32x4.fromInt32x4Bits(Int32x4.splat(v.bits)).abs(),
      );
      return Float32([r.x, r.y, r.z, r.w][lane].toUnsigned(32));
    }, float32Cases);
  }
  for (var lane = 0; lane < 2; lane++) {
    check('Float64x2 lane $lane', (v) {
      final r = Float64x2.splat(v.toDouble()).abs();
      return Float64.fromDouble([r.x, r.y][lane]);
    }, float64Cases);
  }
}
