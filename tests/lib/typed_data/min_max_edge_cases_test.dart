// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An exhaustive edge-case test for min and max across the scalar dart:math
// functions and the Float32x4 and Float64x2 value-type implementations.

import "package:expect/expect.dart";
import "package:expect/float_bits.dart";

import 'dart:math' as math;
import 'dart:typed_data';

final ninf = Float64.negativeInfinity;
final pinf = Float64.positiveInfinity;
final nz = Float64.negativeZero;
final pz = Float64.positiveZero;
final nnorm = Float64.negativeNormal;
final pnorm = Float64.positiveNormal;
final pnan = Float64.positiveQuietNan;
final nnan = Float64.negativeQuietNan;
final pSubMin = Float64.positiveSmallestSubnormal;
final nSubMin = Float64.negativeSmallestSubnormal;
final pSubMax = Float64.positiveLargestSubnormal;
final nSubMax = Float64.negativeLargestSubnormal;
final qNanLo = Float64.positiveQuietNanLowPayload;
final sNanLo = Float64.positiveSignalingNanLowPayload;

final pSubMin32 = Float32.positiveSmallestSubnormal;
final nSubMin32 = Float32.negativeSmallestSubnormal;
final pSubMax32 = Float32.positiveLargestSubnormal;
final nSubMax32 = Float32.negativeLargestSubnormal;
final ninf32 = Float32.negativeInfinity;
final pinf32 = Float32.positiveInfinity;
final nz32 = Float32.negativeZero;
final pz32 = Float32.positiveZero;
final nnorm32 = Float32.negativeNormal;
final pnorm32 = Float32.positiveNormal;
final pnan32 = Float32.positiveQuietNan;
final nnan32 = Float32.negativeQuietNan;
final qNan32 = Float32.positiveQuietNanPayload;
final sNan32 = Float32.positiveSignalingNanPayload;

// A table cell. Empty means the result is a NaN of unspecified payload and
// sign, which are not portable across the VM, dart2wasm, dart2js, and float32,
// so only NaN-ness is checked. A non-empty cell lists the acceptable results,
// each matched bit for bit.
const nans = <Never>[];

// dart format off
final ieeeMinDouble = <List<List<Float64>>>[
  //               -inf    -norm    -subMax    -subMin    -0.0       +0.0       +subMin    +subMax    +norm      +inf      +NaN  -NaN  +qNaN.lo +sNaN.lo
  /* -inf     */ [[ninf], [ninf],  [ninf],    [ninf],    [ninf],    [ninf],    [ninf],    [ninf],    [ninf],    [ninf],    nans, nans, nans,    nans],
  /* -norm    */ [[ninf], [nnorm], [nnorm],   [nnorm],   [nnorm],   [nnorm],   [nnorm],   [nnorm],   [nnorm],   [nnorm],   nans, nans, nans,    nans],
  /* -subMax  */ [[ninf], [nnorm], [nSubMax], [nSubMax], [nSubMax], [nSubMax], [nSubMax], [nSubMax], [nSubMax], [nSubMax], nans, nans, nans,    nans],
  /* -subMin  */ [[ninf], [nnorm], [nSubMax], [nSubMin], [nSubMin], [nSubMin], [nSubMin], [nSubMin], [nSubMin], [nSubMin], nans, nans, nans,    nans],
  /* -0.0     */ [[ninf], [nnorm], [nSubMax], [nSubMin], [nz],      [nz],      [nz],      [nz],      [nz],      [nz],      nans, nans, nans,    nans],
  /* +0.0     */ [[ninf], [nnorm], [nSubMax], [nSubMin], [nz],      [pz],      [pz],      [pz],      [pz],      [pz],      nans, nans, nans,    nans],
  /* +subMin  */ [[ninf], [nnorm], [nSubMax], [nSubMin], [nz],      [pz],      [pSubMin], [pSubMin], [pSubMin], [pSubMin], nans, nans, nans,    nans],
  /* +subMax  */ [[ninf], [nnorm], [nSubMax], [nSubMin], [nz],      [pz],      [pSubMin], [pSubMax], [pSubMax], [pSubMax], nans, nans, nans,    nans],
  /* +norm    */ [[ninf], [nnorm], [nSubMax], [nSubMin], [nz],      [pz],      [pSubMin], [pSubMax], [pnorm],   [pnorm],   nans, nans, nans,    nans],
  /* +inf     */ [[ninf], [nnorm], [nSubMax], [nSubMin], [nz],      [pz],      [pSubMin], [pSubMax], [pnorm],   [pinf],    nans, nans, nans,    nans],
  /* +NaN     */ [nans,   nans,    nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans, nans, nans,    nans],
  /* -NaN     */ [nans,   nans,    nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans, nans, nans,    nans],
  /* +qNaN.lo */ [nans,   nans,    nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans, nans, nans,    nans],
  /* +sNaN.lo */ [nans,   nans,    nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans, nans, nans,    nans],
];
// dart format on

// dart format off
final ieeeMaxDouble = <List<List<Float64>>>[
  //               -inf       -norm      -subMax    -subMin    -0.0       +0.0       +subMin    +subMax    +norm    +inf   +NaN  -NaN  +qNaN.lo +sNaN.lo
  /* -inf     */ [[ninf],    [nnorm],   [nSubMax], [nSubMin], [nz],      [pz],      [pSubMin], [pSubMax], [pnorm], [pinf], nans, nans, nans,    nans],
  /* -norm    */ [[nnorm],   [nnorm],   [nSubMax], [nSubMin], [nz],      [pz],      [pSubMin], [pSubMax], [pnorm], [pinf], nans, nans, nans,    nans],
  /* -subMax  */ [[nSubMax], [nSubMax], [nSubMax], [nSubMin], [nz],      [pz],      [pSubMin], [pSubMax], [pnorm], [pinf], nans, nans, nans,    nans],
  /* -subMin  */ [[nSubMin], [nSubMin], [nSubMin], [nSubMin], [nz],      [pz],      [pSubMin], [pSubMax], [pnorm], [pinf], nans, nans, nans,    nans],
  /* -0.0     */ [[nz],      [nz],      [nz],      [nz],      [nz],      [pz],      [pSubMin], [pSubMax], [pnorm], [pinf], nans, nans, nans,    nans],
  /* +0.0     */ [[pz],      [pz],      [pz],      [pz],      [pz],      [pz],      [pSubMin], [pSubMax], [pnorm], [pinf], nans, nans, nans,    nans],
  /* +subMin  */ [[pSubMin], [pSubMin], [pSubMin], [pSubMin], [pSubMin], [pSubMin], [pSubMin], [pSubMax], [pnorm], [pinf], nans, nans, nans,    nans],
  /* +subMax  */ [[pSubMax], [pSubMax], [pSubMax], [pSubMax], [pSubMax], [pSubMax], [pSubMax], [pSubMax], [pnorm], [pinf], nans, nans, nans,    nans],
  /* +norm    */ [[pnorm],   [pnorm],   [pnorm],   [pnorm],   [pnorm],   [pnorm],   [pnorm],   [pnorm],   [pnorm], [pinf], nans, nans, nans,    nans],
  /* +inf     */ [[pinf],    [pinf],    [pinf],    [pinf],    [pinf],    [pinf],    [pinf],    [pinf],    [pinf],  [pinf], nans, nans, nans,    nans],
  /* +NaN     */ [nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans,    nans],
  /* -NaN     */ [nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans,    nans],
  /* +qNaN.lo */ [nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans,    nans],
  /* +sNaN.lo */ [nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans,    nans],
];
// dart format on

// dart format off
final ieeeMinFloat32 = <List<List<Float32>>>[
  //                 -f32Inf   -f32Norm   -f32SubMax   -f32SubMin   -f32Zero     +f32Zero     +f32SubMin   +f32SubMax   +f32Norm     +f32Inf     +f32NaN -f32NaN +f32qNaN +f32sNaN
  /* -f32Inf    */ [[ninf32], [ninf32],  [ninf32],    [ninf32],    [ninf32],    [ninf32],    [ninf32],    [ninf32],    [ninf32],    [ninf32],    nans,   nans,   nans,    nans],
  /* -f32Norm   */ [[ninf32], [nnorm32], [nnorm32],   [nnorm32],   [nnorm32],   [nnorm32],   [nnorm32],   [nnorm32],   [nnorm32],   [nnorm32],   nans,   nans,   nans,    nans],
  /* -f32SubMax */ [[ninf32], [nnorm32], [nSubMax32], [nSubMax32], [nSubMax32], [nSubMax32], [nSubMax32], [nSubMax32], [nSubMax32], [nSubMax32], nans,   nans,   nans,    nans],
  /* -f32SubMin */ [[ninf32], [nnorm32], [nSubMax32], [nSubMin32], [nSubMin32], [nSubMin32], [nSubMin32], [nSubMin32], [nSubMin32], [nSubMin32], nans,   nans,   nans,    nans],
  /* -f32Zero   */ [[ninf32], [nnorm32], [nSubMax32], [nSubMin32], [nz32],      [nz32],      [nz32],      [nz32],      [nz32],      [nz32],      nans,   nans,   nans,    nans],
  /* +f32Zero   */ [[ninf32], [nnorm32], [nSubMax32], [nSubMin32], [nz32],      [pz32],      [pz32],      [pz32],      [pz32],      [pz32],      nans,   nans,   nans,    nans],
  /* +f32SubMin */ [[ninf32], [nnorm32], [nSubMax32], [nSubMin32], [nz32],      [pz32],      [pSubMin32], [pSubMin32], [pSubMin32], [pSubMin32], nans,   nans,   nans,    nans],
  /* +f32SubMax */ [[ninf32], [nnorm32], [nSubMax32], [nSubMin32], [nz32],      [pz32],      [pSubMin32], [pSubMax32], [pSubMax32], [pSubMax32], nans,   nans,   nans,    nans],
  /* +f32Norm   */ [[ninf32], [nnorm32], [nSubMax32], [nSubMin32], [nz32],      [pz32],      [pSubMin32], [pSubMax32], [pnorm32],   [pnorm32],   nans,   nans,   nans,    nans],
  /* +f32Inf    */ [[ninf32], [nnorm32], [nSubMax32], [nSubMin32], [nz32],      [pz32],      [pSubMin32], [pSubMax32], [pnorm32],   [pinf32],    nans,   nans,   nans,    nans],
  /* +f32NaN    */ [nans,     nans,      nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,   nans,   nans,    nans],
  /* -f32NaN    */ [nans,     nans,      nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,   nans,   nans,    nans],
  /* +f32qNaN   */ [nans,     nans,      nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,   nans,   nans,    nans],
  /* +f32sNaN   */ [nans,     nans,      nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,   nans,   nans,    nans],
];
// dart format on

// dart format off
final ieeeMaxFloat32 = <List<List<Float32>>>[
  //                 -f32Inf      -f32Norm     -f32SubMax   -f32SubMin   -f32Zero     +f32Zero     +f32SubMin   +f32SubMax   +f32Norm   +f32Inf  +f32NaN -f32NaN +f32qNaN +f32sNaN
  /* -f32Inf    */ [[ninf32],    [nnorm32],   [nSubMax32], [nSubMin32], [nz32],      [pz32],      [pSubMin32], [pSubMax32], [pnorm32], [pinf32], nans,   nans,   nans,    nans],
  /* -f32Norm   */ [[nnorm32],   [nnorm32],   [nSubMax32], [nSubMin32], [nz32],      [pz32],      [pSubMin32], [pSubMax32], [pnorm32], [pinf32], nans,   nans,   nans,    nans],
  /* -f32SubMax */ [[nSubMax32], [nSubMax32], [nSubMax32], [nSubMin32], [nz32],      [pz32],      [pSubMin32], [pSubMax32], [pnorm32], [pinf32], nans,   nans,   nans,    nans],
  /* -f32SubMin */ [[nSubMin32], [nSubMin32], [nSubMin32], [nSubMin32], [nz32],      [pz32],      [pSubMin32], [pSubMax32], [pnorm32], [pinf32], nans,   nans,   nans,    nans],
  /* -f32Zero   */ [[nz32],      [nz32],      [nz32],      [nz32],      [nz32],      [pz32],      [pSubMin32], [pSubMax32], [pnorm32], [pinf32], nans,   nans,   nans,    nans],
  /* +f32Zero   */ [[pz32],      [pz32],      [pz32],      [pz32],      [pz32],      [pz32],      [pSubMin32], [pSubMax32], [pnorm32], [pinf32], nans,   nans,   nans,    nans],
  /* +f32SubMin */ [[pSubMin32], [pSubMin32], [pSubMin32], [pSubMin32], [pSubMin32], [pSubMin32], [pSubMin32], [pSubMax32], [pnorm32], [pinf32], nans,   nans,   nans,    nans],
  /* +f32SubMax */ [[pSubMax32], [pSubMax32], [pSubMax32], [pSubMax32], [pSubMax32], [pSubMax32], [pSubMax32], [pSubMax32], [pnorm32], [pinf32], nans,   nans,   nans,    nans],
  /* +f32Norm   */ [[pnorm32],   [pnorm32],   [pnorm32],   [pnorm32],   [pnorm32],   [pnorm32],   [pnorm32],   [pnorm32],   [pnorm32], [pinf32], nans,   nans,   nans,    nans],
  /* +f32Inf    */ [[pinf32],    [pinf32],    [pinf32],    [pinf32],    [pinf32],    [pinf32],    [pinf32],    [pinf32],    [pinf32],  [pinf32], nans,   nans,   nans,    nans],
  /* +f32NaN    */ [nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,      nans,     nans,   nans,   nans,    nans],
  /* -f32NaN    */ [nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,      nans,     nans,   nans,   nans,    nans],
  /* +f32qNaN   */ [nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,      nans,     nans,   nans,   nans,    nans],
  /* +f32sNaN   */ [nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,        nans,      nans,     nans,   nans,   nans,    nans],
];
// dart format on

// dart format off
final float64Values = <Float64>[
  // -inf  -norm  -subMax  -subMin  -0.0 +0.0 +subMin  +subMax  +norm  +inf  +NaN  -NaN  +qNaN.lo +sNaN.lo
     ninf, nnorm, nSubMax, nSubMin, nz,  pz,  pSubMin, pSubMax, pnorm, pinf, pnan, nnan, qNanLo,  sNanLo,
];
// dart format on

final float64Special = (ninf: ninf, pinf: pinf, pnorm: pnorm, pnan: pnan);

// dart format off
final float32Values = <Float32>[
  // -f32Inf -f32Norm -f32SubMax -f32SubMin -f32Zero +f32Zero +f32SubMin +f32SubMax +f32Norm +f32Inf +f32NaN -f32NaN +f32qNaN +f32sNaN
     ninf32, nnorm32, nSubMax32, nSubMin32, nz32,    pz32,    pSubMin32, pSubMax32, pnorm32, pinf32, pnan32, nnan32, qNan32,  sNan32,
];
// dart format on

final float32Special = (
  ninf: ninf32,
  pinf: pinf32,
  pnorm: pnorm32,
  pnan: pnan32,
);

// Checks min and max against their Cayley tables.
void testIeeeTables<T extends FloatBits>(
  String name,
  T Function(T, T) min,
  T Function(T, T) max,
  List<T> values,
  List<List<List<T>>> ieeeMin,
  List<List<List<T>>> ieeeMax,
) {
  // An empty (`nans`) cell accepts any NaN. Other cells require an exact match.
  void check(String op, FloatBits got, List<FloatBits> allowed) {
    if (allowed.isEmpty) {
      Expect.isTrue(got.isNaN, '$name: $op was $got, expected a NaN');
    } else {
      Expect.isTrue(
        allowed.contains(got),
        '$name: $op was $got, expected one of $allowed',
      );
    }
  }

  for (final (i, a) in values.indexed) {
    for (final (j, b) in values.indexed) {
      check('min($a, $b)', min(a, b), ieeeMin[i][j]);
      check('max($a, $b)', max(a, b), ieeeMax[i][j]);
    }
  }
}

// Checks the algebraic properties of min and max. They are idempotent and
// commutative everywhere. +inf is the identity for min and the top that max
// saturates to. -inf is the identity for max and the bottom that min saturates
// to. The saturating bounds hold only for non-NaN inputs, since a NaN
// propagates and overrides them. On the non-NaN values min and max are also
// associative and absorptive, and each distributes over the other, so there
// they form a distributive lattice. Over NaNs only NaN-ness is compared.
void testAlgebra<T extends FloatBits>(
  String name,
  T Function(T, T) min,
  T Function(T, T) max,
  List<T> values,
  ({T ninf, T pinf, T pnorm, T pnan}) special,
) {
  final (:ninf, :pinf, :pnorm, :pnan) = special;
  // Compares bit for bit, but treats all NaNs as the same.
  bool same(FloatBits actual, FloatBits expected) =>
      (actual.isNaN && expected.isNaN) || actual == expected;

  final nonNan = values.where((v) => !v.isNaN).toList();

  for (final a in values) {
    // Idempotent.
    Expect.isTrue(same(min(a, a), a), '$name: min idempotent at $a');
    Expect.isTrue(same(max(a, a), a), '$name: max idempotent at $a');
    // Identity, +inf for min and -inf for max.
    Expect.isTrue(same(min(a, pinf), a), '$name: pinf is min identity at $a');
    Expect.isTrue(same(max(a, ninf), a), '$name: ninf is max identity at $a');
    // Saturating bound, off NaN only. A NaN propagates and overrides it.
    if (!a.isNaN) {
      Expect.isTrue(same(max(a, pinf), pinf), '$name: pinf max bound at $a');
      Expect.isTrue(same(min(a, ninf), ninf), '$name: ninf min bound at $a');
    }

    for (final b in values) {
      // Commutative.
      Expect.isTrue(
        same(min(a, b), min(b, a)),
        '$name: min commutative $a $b, '
        'min(a, b) was ${min(a, b)}, min(b, a) was ${min(b, a)}',
      );
      Expect.isTrue(
        same(max(a, b), max(b, a)),
        '$name: max commutative $a $b, '
        'max(a, b) was ${max(a, b)}, max(b, a) was ${max(b, a)}',
      );
    }
  }

  // On the non-NaN values min and max are associative and absorptive, so there
  // they form a bounded lattice. Associativity is checked bit for bit.
  for (final a in nonNan) {
    for (final b in nonNan) {
      Expect.isTrue(same(min(a, max(a, b)), a), '$name: absorption min $a $b');
      Expect.isTrue(same(max(a, min(a, b)), a), '$name: absorption max $a $b');
      for (final c in nonNan) {
        Expect.isTrue(
          same(min(min(a, b), c), min(a, min(b, c))),
          '$name: min associative $a $b $c',
        );
        Expect.isTrue(
          same(max(max(a, b), c), max(a, max(b, c))),
          '$name: max associative $a $b $c',
        );
      }
    }
  }

  // But a single NaN breaks absorption, so the full domain is not a lattice.
  Expect.isTrue(
    min(pnorm, max(pnorm, pnan)).isNaN,
    '$name: absorption is expected to break at NaN',
  );
  Expect.isFalse(
    same(min(pnorm, max(pnorm, pnan)), pnorm),
    '$name: min(a, max(a, NaN)) must not equal a',
  );

  // On the non-NaN values min and max distribute over each other, so the lattice
  // is distributive. Each law is checked bit for bit. A NaN breaks this the same
  // way it breaks absorption, so the distributive laws hold on the non-NaN
  // values only.
  for (final a in nonNan) {
    for (final b in nonNan) {
      for (final c in nonNan) {
        Expect.isTrue(
          same(min(a, max(b, c)), max(min(a, b), min(a, c))),
          '$name: min distributes over max $a $b $c',
        );
        Expect.isTrue(
          same(max(a, min(b, c)), min(max(a, b), max(a, c))),
          '$name: max distributes over min $a $b $c',
        );
      }
    }
  }
}

// Runs the tables and the algebraic properties for an implementation, on every
// lane.
void runTablesAndAlgebraExpectations<T extends FloatBits>(
  String name,
  int lanes,
  T Function(T, T, int) min,
  T Function(T, T, int) max,
  List<T> values,
  ({T ninf, T pinf, T pnorm, T pnan}) special,
  List<List<List<T>>> ieeeMin,
  List<List<List<T>>> ieeeMax,
) {
  for (var lane = 0; lane < lanes; lane++) {
    final tag = lanes > 1 ? '$name lane $lane' : name;
    T _min(T a, T b) => min(a, b, lane);
    T _max(T a, T b) => max(a, b, lane);
    testIeeeTables(tag, _min, _max, values, ieeeMin, ieeeMax);
    testAlgebra(tag, _min, _max, values, special);
  }
}

void main() {
  runTablesAndAlgebraExpectations(
    'dart:math',
    1,
    (a, b, _) => Float64.fromDouble(math.min(a.toDouble(), b.toDouble())),
    (a, b, _) => Float64.fromDouble(math.max(a.toDouble(), b.toDouble())),
    float64Values,
    float64Special,
    ieeeMinDouble,
    ieeeMaxDouble,
  );

  {
    // The lanes go in and out as bits, so no NaN is converted.
    Float32x4 f32(Float32 v, int lane) =>
        Float32x4.fromInt32x4Bits(switch (lane) {
          0 => Int32x4(v.bits, 0, 0, 0),
          1 => Int32x4(0, v.bits, 0, 0),
          2 => Int32x4(0, 0, v.bits, 0),
          _ => Int32x4(0, 0, 0, v.bits),
        });
    Float32 f32read(Float32x4 r, int lane) {
      final bits = Int32x4.fromFloat32x4Bits(r);
      return Float32([bits.x, bits.y, bits.z, bits.w][lane].toUnsigned(32));
    }

    runTablesAndAlgebraExpectations(
      'Float32x4',
      4,
      (a, b, l) => f32read(f32(a, l).min(f32(b, l)), l),
      (a, b, l) => f32read(f32(a, l).max(f32(b, l)), l),
      float32Values,
      float32Special,
      ieeeMinFloat32,
      ieeeMaxFloat32,
    );
  }

  {
    Float64x2 f64(double v, int lane) =>
        lane == 0 ? Float64x2(v, 0) : Float64x2(0, v);
    double f64read(Float64x2 r, int lane) => lane == 0 ? r.x : r.y;
    runTablesAndAlgebraExpectations(
      'Float64x2',
      2,
      (a, b, l) => Float64.fromDouble(
        f64read(f64(a.toDouble(), l).min(f64(b.toDouble(), l)), l),
      ),
      (a, b, l) => Float64.fromDouble(
        f64read(f64(a.toDouble(), l).max(f64(b.toDouble(), l)), l),
      ),
      float64Values,
      float64Special,
      ieeeMinDouble,
      ieeeMaxDouble,
    );
  }
}
