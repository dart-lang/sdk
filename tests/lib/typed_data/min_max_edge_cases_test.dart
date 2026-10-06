// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An exhaustive edge-case test for min and max across the scalar dart:math
// functions and the Float32x4 and Float64x2 value-type implementations.

import "package:expect/expect.dart";
import "package:expect/variations.dart" show jsNumbers;

import 'dart:math' as math;
import 'dart:typed_data';

const double ninf = double.negativeInfinity;
const double pinf = double.infinity;
// Canonical quiet NaN: exponent all 1s, quiet (top mantissa) bit set, no
// payload. Bits 0x7FF8_0000_0000_0000.
final double pnan =
    (ByteData(8)
          ..setUint32(0, 0x7FF80000, Endian.big)
          ..setUint32(4, 0x00000000, Endian.big))
        .getFloat64(0, Endian.big);
// Canonical quiet NaN with the sign bit set (-NaN): exponent all 1s, quiet
// (top mantissa) bit set, no payload. Bits 0xFFF8_0000_0000_0000.
final double nnan =
    (ByteData(8)
          ..setUint32(0, 0xFFF80000, Endian.big)
          ..setUint32(4, 0x00000000, Endian.big))
        .getFloat64(0, Endian.big);
const double nz = -0.0;
const double pz = 0.0;
const double nnorm = -1.25;
const double pnorm = 1.25;

// The smallest positive subnormal double. Bits 0x0000_0000_0000_0001.
const double dSubMin = 5e-324;
// The largest positive subnormal double. Bits 0x000F_FFFF_FFFF_FFFF.
const double dSubMax = 2.225073858507201e-308;
// The smallest positive subnormal float32. Bits 0x36A0_0000_0000_0000.
const double fSubMin = 1.401298464324817e-45;
// The largest positive subnormal float32. Bits 0x380F_FFFF_C000_0000.
const double fSubMax = 1.1754942106924411e-38;

// A non-canonical quiet NaN with a payload in its low byte. It is a NaN, so
// min/max must yield a NaN. Not `const` because a double cannot be
// bit-constructed at compile time. Bits 0x7FF8_0000_0000_00FF.
final double nanb1 =
    (ByteData(8)
          ..setUint32(0, 0x7FF80000, Endian.big)
          ..setUint32(4, 0x000000FF, Endian.big))
        .getFloat64(0, Endian.big);
// A non-canonical signaling NaN (quiet bit clear) with a payload one byte up.
// It is a NaN, so min/max must yield a NaN. Not `const` because a double cannot
// be bit-constructed at compile time. Bits 0x7FF0_0000_0000_FF00.
// nanb1 & nanb2 is +infinity.
final double nanb2 =
    (ByteData(8)
          ..setUint32(0, 0x7FF00000, Endian.big)
          ..setUint32(4, 0x0000FF00, Endian.big))
        .getFloat64(0, Endian.big);
// A non-canonical quiet NaN whose payload sits in the top mantissa bits, so it
// survives the double -> float32 conversion (it stays non-canonical as float32,
// 0x7FE0_0000). Bits 0x7FFC_0000_0000_0000.
final double nanb3 =
    (ByteData(8)
          ..setUint32(0, 0x7FFC0000, Endian.big)
          ..setUint32(4, 0x00000000, Endian.big))
        .getFloat64(0, Endian.big);
// A non-canonical signaling NaN (quiet bit clear) whose payload sits in the top
// mantissa bits, so it survives the double -> float32 conversion (as float32,
// quieted, it is 0x7FD0_0000). Bits 0x7FF2_0000_0000_0000.
// nanb3 & nanb4 is +infinity.
final double nanb4 =
    (ByteData(8)
          ..setUint32(0, 0x7FF20000, Endian.big)
          ..setUint32(4, 0x00000000, Endian.big))
        .getFloat64(0, Endian.big);

// A table cell. Empty means the result is a NaN of unspecified payload and
// sign, which are not portable across the VM, dart2wasm, dart2js, and float32,
// so only NaN-ness is checked. A non-empty cell lists the acceptable results,
// each matched bit for bit.
const nans = <double>[];

const _labelsCommon = <String>[
  '-inf',
  '-norm',
  '-subMax',
  '-subMin',
  '-0.0',
  '+0.0',
  '+subMin',
  '+subMax',
  '+norm',
  '+inf',
  '+NaN',
  '-NaN',
];
const labelsDouble = <String>[..._labelsCommon, 'nanb1', 'nanb2'];
const labelsFloat32 = <String>[..._labelsCommon, 'nanb3', 'nanb4'];

// The operands for the double-width implementations, the finite values in
// ascending order followed by the NaNs.
final valuesDouble = <double>[
  ninf,
  nnorm,
  -dSubMax,
  -dSubMin,
  nz,
  pz,
  dSubMin,
  dSubMax,
  pnorm,
  pinf,
  pnan,
  nnan,
  nanb1,
  nanb2,
];
// The operands for Float32x4, using float32 subnormals in place of the double
// subnormals, which flush to zero in float32, and nanb3/nanb4, whose payloads
// survive the float32 conversion.
final valuesFloat32 = <double>[
  ninf,
  nnorm,
  -fSubMax,
  -fSubMin,
  nz,
  pz,
  fSubMin,
  fSubMax,
  pnorm,
  pinf,
  pnan,
  nnan,
  nanb3,
  nanb4,
];

// Identical 64-bit representations, compared as two 32-bit halves so this also
// works on the web where 64-bit integers are unavailable.
bool bitEqual(double x, double y) {
  final bx = ByteData(8)..setFloat64(0, x, Endian.big);
  final by = ByteData(8)..setFloat64(0, y, Endian.big);
  return bx.getUint32(0, Endian.big) == by.getUint32(0, Endian.big) &&
      bx.getUint32(4, Endian.big) == by.getUint32(4, Endian.big);
}

// Confirms every representative constant really has the bit pattern we intend.
void testBitPatterns() {
  int hi(double d) =>
      (ByteData(8)..setFloat64(0, d, Endian.big)).getUint32(0, Endian.big);
  int lo(double d) =>
      (ByteData(8)..setFloat64(0, d, Endian.big)).getUint32(4, Endian.big);
  void bits(double d, int high, int low) {
    Expect.equals(high, hi(d));
    Expect.equals(low, lo(d));
  }

  // The double whose bits are the bitwise AND of a's and b's bits.
  double andBits(double a, double b) =>
      (ByteData(8)
            ..setUint32(0, hi(a) & hi(b), Endian.big)
            ..setUint32(4, lo(a) & lo(b), Endian.big))
          .getFloat64(0, Endian.big);

  bool negativeSign(double d) => hi(d) >= 0x80000000;

  bits(ninf, 0xFFF00000, 0);
  bits(pinf, 0x7FF00000, 0);
  bits(pz, 0x00000000, 0);
  bits(dSubMin, 0x00000000, 0x00000001);
  bits(dSubMax, 0x000FFFFF, 0xFFFFFFFF);
  bits(fSubMin, 0x36A00000, 0x00000000);
  bits(fSubMax, 0x380FFFFF, 0xC0000000);

  if (jsNumbers) {
    // A NaN's bit pattern is implementation-defined on JS, so we use isNaN.
    Expect.isTrue(pnan.isNaN);
    Expect.isTrue(nnan.isNaN);
    Expect.isTrue(nanb1.isNaN);
    Expect.isTrue(nanb2.isNaN);
    Expect.isTrue(nanb3.isNaN);
    Expect.isTrue(nanb4.isNaN);
  } else {
    // Non-JS targets keep the exact -0.0 and NaN bits.
    bits(nz, 0x80000000, 0);
    bits(pnan, 0x7FF80000, 0);
    bits(nnan, 0xFFF80000, 0);
    bits(nanb1, 0x7FF80000, 0x000000FF);
    bits(nanb2, 0x7FF00000, 0x0000FF00);
    bits(nanb3, 0x7FFC0000, 0);
    bits(nanb4, 0x7FF20000, 0);
    // Each pair's bits AND to +infinity.
    Expect.isTrue(bitEqual(andBits(nanb1, nanb2), pinf));
    Expect.isTrue(bitEqual(andBits(nanb3, nanb4), pinf));
  }

  Expect.isTrue(nnorm.isFinite && nnorm != 0.0);
  Expect.isTrue(negativeSign(nnorm));
  Expect.isTrue(pnorm.isFinite && pnorm != 0.0);
  Expect.isFalse(negativeSign(pnorm));
}

// Cayley table of IEEE min(row, col) for dart:math and Float64x2.
// dart format off
const ieeeMinDouble = <List<List<double>>>[
  //             -inf    -norm    -subMax     -subMin     -0.0        +0.0        +subMin     +subMax     +norm       +inf        +NaN  -NaN  nanb1 nanb2
  /* -inf    */ [[ninf], [ninf],  [ninf],     [ninf],     [ninf],     [ninf],     [ninf],     [ninf],     [ninf],     [ninf],     nans, nans, nans, nans],
  /* -norm   */ [[ninf], [nnorm], [nnorm],    [nnorm],    [nnorm],    [nnorm],    [nnorm],    [nnorm],    [nnorm],    [nnorm],    nans, nans, nans, nans],
  /* -subMax */ [[ninf], [nnorm], [-dSubMax], [-dSubMax], [-dSubMax], [-dSubMax], [-dSubMax], [-dSubMax], [-dSubMax], [-dSubMax], nans, nans, nans, nans],
  /* -subMin */ [[ninf], [nnorm], [-dSubMax], [-dSubMin], [-dSubMin], [-dSubMin], [-dSubMin], [-dSubMin], [-dSubMin], [-dSubMin], nans, nans, nans, nans],
  /* -0.0    */ [[ninf], [nnorm], [-dSubMax], [-dSubMin], [nz],       [nz],       [nz],       [nz],       [nz],       [nz],       nans, nans, nans, nans],
  /* +0.0    */ [[ninf], [nnorm], [-dSubMax], [-dSubMin], [nz],       [pz],       [pz],       [pz],       [pz],       [pz],       nans, nans, nans, nans],
  /* +subMin */ [[ninf], [nnorm], [-dSubMax], [-dSubMin], [nz],       [pz],       [dSubMin],  [dSubMin],  [dSubMin],  [dSubMin],  nans, nans, nans, nans],
  /* +subMax */ [[ninf], [nnorm], [-dSubMax], [-dSubMin], [nz],       [pz],       [dSubMin],  [dSubMax],  [dSubMax],  [dSubMax],  nans, nans, nans, nans],
  /* +norm   */ [[ninf], [nnorm], [-dSubMax], [-dSubMin], [nz],       [pz],       [dSubMin],  [dSubMax],  [pnorm],    [pnorm],    nans, nans, nans, nans],
  /* +inf    */ [[ninf], [nnorm], [-dSubMax], [-dSubMin], [nz],       [pz],       [dSubMin],  [dSubMax],  [pnorm],    [pinf],     nans, nans, nans, nans],
  /* +NaN    */ [nans,   nans,    nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans, nans, nans, nans],
  /* -NaN    */ [nans,   nans,    nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans, nans, nans, nans],
  /* nanb1   */ [nans,   nans,    nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans, nans, nans, nans],
  /* nanb2   */ [nans,   nans,    nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans, nans, nans, nans],
];
// dart format on

// Cayley table of IEEE max(row, col) for dart:math and Float64x2.
// dart format off
const ieeeMaxDouble = <List<List<double>>>[
  //             -inf        -norm       -subMax     -subMin     -0.0       +0.0       +subMin    +subMax    +norm    +inf    +NaN  -NaN  nanb1 nanb2
  /* -inf    */ [[ninf],     [nnorm],    [-dSubMax], [-dSubMin], [nz],      [pz],      [dSubMin], [dSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* -norm   */ [[nnorm],    [nnorm],    [-dSubMax], [-dSubMin], [nz],      [pz],      [dSubMin], [dSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* -subMax */ [[-dSubMax], [-dSubMax], [-dSubMax], [-dSubMin], [nz],      [pz],      [dSubMin], [dSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* -subMin */ [[-dSubMin], [-dSubMin], [-dSubMin], [-dSubMin], [nz],      [pz],      [dSubMin], [dSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* -0.0    */ [[nz],       [nz],       [nz],       [nz],       [nz],      [pz],      [dSubMin], [dSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* +0.0    */ [[pz],       [pz],       [pz],       [pz],       [pz],      [pz],      [dSubMin], [dSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* +subMin */ [[dSubMin],  [dSubMin],  [dSubMin],  [dSubMin],  [dSubMin], [dSubMin], [dSubMin], [dSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* +subMax */ [[dSubMax],  [dSubMax],  [dSubMax],  [dSubMax],  [dSubMax], [dSubMax], [dSubMax], [dSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* +norm   */ [[pnorm],    [pnorm],    [pnorm],    [pnorm],    [pnorm],   [pnorm],   [pnorm],   [pnorm],   [pnorm], [pinf], nans, nans, nans, nans],
  /* +inf    */ [[pinf],     [pinf],     [pinf],     [pinf],     [pinf],    [pinf],    [pinf],    [pinf],    [pinf],  [pinf], nans, nans, nans, nans],
  /* +NaN    */ [nans,       nans,       nans,       nans,       nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans, nans],
  /* -NaN    */ [nans,       nans,       nans,       nans,       nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans, nans],
  /* nanb1   */ [nans,       nans,       nans,       nans,       nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans, nans],
  /* nanb2   */ [nans,       nans,       nans,       nans,       nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans, nans],
];
// dart format on

// Cayley table of IEEE min(row, col) for Float32x4.
// dart format off
const ieeeMinFloat32 = <List<List<double>>>[
  //             -inf    -norm    -subMax     -subMin     -0.0        +0.0        +subMin     +subMax     +norm       +inf        +NaN  -NaN  nanb3 nanb4
  /* -inf    */ [[ninf], [ninf],  [ninf],     [ninf],     [ninf],     [ninf],     [ninf],     [ninf],     [ninf],     [ninf],     nans, nans, nans, nans],
  /* -norm   */ [[ninf], [nnorm], [nnorm],    [nnorm],    [nnorm],    [nnorm],    [nnorm],    [nnorm],    [nnorm],    [nnorm],    nans, nans, nans, nans],
  /* -subMax */ [[ninf], [nnorm], [-fSubMax], [-fSubMax], [-fSubMax], [-fSubMax], [-fSubMax], [-fSubMax], [-fSubMax], [-fSubMax], nans, nans, nans, nans],
  /* -subMin */ [[ninf], [nnorm], [-fSubMax], [-fSubMin], [-fSubMin], [-fSubMin], [-fSubMin], [-fSubMin], [-fSubMin], [-fSubMin], nans, nans, nans, nans],
  /* -0.0    */ [[ninf], [nnorm], [-fSubMax], [-fSubMin], [nz],       [nz],       [nz],       [nz],       [nz],       [nz],       nans, nans, nans, nans],
  /* +0.0    */ [[ninf], [nnorm], [-fSubMax], [-fSubMin], [nz],       [pz],       [pz],       [pz],       [pz],       [pz],       nans, nans, nans, nans],
  /* +subMin */ [[ninf], [nnorm], [-fSubMax], [-fSubMin], [nz],       [pz],       [fSubMin],  [fSubMin],  [fSubMin],  [fSubMin],  nans, nans, nans, nans],
  /* +subMax */ [[ninf], [nnorm], [-fSubMax], [-fSubMin], [nz],       [pz],       [fSubMin],  [fSubMax],  [fSubMax],  [fSubMax],  nans, nans, nans, nans],
  /* +norm   */ [[ninf], [nnorm], [-fSubMax], [-fSubMin], [nz],       [pz],       [fSubMin],  [fSubMax],  [pnorm],    [pnorm],    nans, nans, nans, nans],
  /* +inf    */ [[ninf], [nnorm], [-fSubMax], [-fSubMin], [nz],       [pz],       [fSubMin],  [fSubMax],  [pnorm],    [pinf],     nans, nans, nans, nans],
  /* +NaN    */ [nans,   nans,    nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans, nans, nans, nans],
  /* -NaN    */ [nans,   nans,    nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans, nans, nans, nans],
  /* nanb3   */ [nans,   nans,    nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans, nans, nans, nans],
  /* nanb4   */ [nans,   nans,    nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans,       nans, nans, nans, nans],
];
// dart format on

// Cayley table of IEEE max(row, col) for Float32x4.
// dart format off
const ieeeMaxFloat32 = <List<List<double>>>[
  //             -inf        -norm       -subMax     -subMin     -0.0       +0.0       +subMin    +subMax    +norm    +inf    +NaN  -NaN  nanb3 nanb4
  /* -inf    */ [[ninf],     [nnorm],    [-fSubMax], [-fSubMin], [nz],      [pz],      [fSubMin], [fSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* -norm   */ [[nnorm],    [nnorm],    [-fSubMax], [-fSubMin], [nz],      [pz],      [fSubMin], [fSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* -subMax */ [[-fSubMax], [-fSubMax], [-fSubMax], [-fSubMin], [nz],      [pz],      [fSubMin], [fSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* -subMin */ [[-fSubMin], [-fSubMin], [-fSubMin], [-fSubMin], [nz],      [pz],      [fSubMin], [fSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* -0.0    */ [[nz],       [nz],       [nz],       [nz],       [nz],      [pz],      [fSubMin], [fSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* +0.0    */ [[pz],       [pz],       [pz],       [pz],       [pz],      [pz],      [fSubMin], [fSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* +subMin */ [[fSubMin],  [fSubMin],  [fSubMin],  [fSubMin],  [fSubMin], [fSubMin], [fSubMin], [fSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* +subMax */ [[fSubMax],  [fSubMax],  [fSubMax],  [fSubMax],  [fSubMax], [fSubMax], [fSubMax], [fSubMax], [pnorm], [pinf], nans, nans, nans, nans],
  /* +norm   */ [[pnorm],    [pnorm],    [pnorm],    [pnorm],    [pnorm],   [pnorm],   [pnorm],   [pnorm],   [pnorm], [pinf], nans, nans, nans, nans],
  /* +inf    */ [[pinf],     [pinf],     [pinf],     [pinf],     [pinf],    [pinf],    [pinf],    [pinf],    [pinf],  [pinf], nans, nans, nans, nans],
  /* +NaN    */ [nans,       nans,       nans,       nans,       nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans, nans],
  /* -NaN    */ [nans,       nans,       nans,       nans,       nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans, nans],
  /* nanb3   */ [nans,       nans,       nans,       nans,       nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans, nans],
  /* nanb4   */ [nans,       nans,       nans,       nans,       nans,      nans,      nans,      nans,      nans,    nans,   nans, nans, nans, nans],
];
// dart format on

void testIeeeTables(
  String name,
  double Function(double, double) min,
  double Function(double, double) max,
  List<double> values,
  List<String> labels,
  List<List<List<double>>> ieeeMin,
  List<List<List<double>>> ieeeMax,
) {
  // An empty (`nans`) cell accepts any NaN. Other cells require an exact match.
  void check(String op, double got, List<double> allowed) {
    if (allowed.isEmpty) {
      Expect.isTrue(got.isNaN, '$name: $op was $got, expected a NaN');
    } else {
      Expect.isTrue(
        allowed.any((e) => bitEqual(got, e)),
        '$name: $op was $got, expected one of $allowed',
      );
    }
  }

  for (final (i, a) in values.indexed) {
    for (final (j, b) in values.indexed) {
      check('min(${labels[i]}, ${labels[j]})', min(a, b), ieeeMin[i][j]);
      check('max(${labels[i]}, ${labels[j]})', max(a, b), ieeeMax[i][j]);
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
void testAlgebra(
  String name,
  double Function(double, double) min,
  double Function(double, double) max,
  List<double> values,
) {
  // Like bitEqual, but treats all NaNs as the same.
  bool same(double actual, double expected) {
    if (actual.isNaN && expected.isNaN) return true;
    return bitEqual(actual, expected);
  }

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

// Runs the tables and the algebraic laws for an implementation, on every lane.
void runTablesAndAlgebraExpectations(
  String name,
  int lanes,
  double Function(double, double, int) min,
  double Function(double, double, int) max,
  List<double> values,
  List<String> labels,
  List<List<List<double>>> ieeeMin,
  List<List<List<double>>> ieeeMax,
) {
  for (var lane = 0; lane < lanes; lane++) {
    final tag = lanes > 1 ? '$name lane $lane' : name;
    double _min(double a, double b) => min(a, b, lane);
    double _max(double a, double b) => max(a, b, lane);
    testIeeeTables(tag, _min, _max, values, labels, ieeeMin, ieeeMax);
    testAlgebra(tag, _min, _max, values);
  }
}

void main() {
  testBitPatterns();

  runTablesAndAlgebraExpectations(
    'dart:math',
    1,
    (a, b, _) => math.min(a, b),
    (a, b, _) => math.max(a, b),
    valuesDouble,
    labelsDouble,
    ieeeMinDouble,
    ieeeMaxDouble,
  );

  {
    Float32x4 f32(double v, int lane) => switch (lane) {
      0 => Float32x4(v, 0, 0, 0),
      1 => Float32x4(0, v, 0, 0),
      2 => Float32x4(0, 0, v, 0),
      _ => Float32x4(0, 0, 0, v),
    };
    double f32read(Float32x4 r, int lane) => switch (lane) {
      0 => r.x,
      1 => r.y,
      2 => r.z,
      _ => r.w,
    };
    runTablesAndAlgebraExpectations(
      'Float32x4',
      4,
      (a, b, l) => f32read(f32(a, l).min(f32(b, l)), l),
      (a, b, l) => f32read(f32(a, l).max(f32(b, l)), l),
      valuesFloat32,
      labelsFloat32,
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
      (a, b, l) => f64read(f64(a, l).min(f64(b, l)), l),
      (a, b, l) => f64read(f64(a, l).max(f64(b, l)), l),
      valuesDouble,
      labelsDouble,
      ieeeMinDouble,
      ieeeMaxDouble,
    );
  }
}
