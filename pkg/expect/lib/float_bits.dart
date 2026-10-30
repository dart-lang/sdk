// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// IEEE-754 bit patterns for numeric tests.
library;

import 'dart:typed_data';

/// An IEEE-754 bit pattern of some width, [Float64] or [Float32].
///
/// Two bit patterns are equal when they have the same width and the same bits,
/// so `-0.0` differs from `0.0` and NaN payloads count.
sealed class FloatBits {
  /// Materializes these bits as a Dart [double].
  double toDouble();

  /// Whether all exponent bits are set and the fraction is not zero, which is
  /// how IEEE-754 defines a NaN.
  bool get isNaN;

  /// The short name of the constant with these bits, or the bits if there is
  /// none, since `-0.0` against `0.0` and one NaN against another print the
  /// same way as a [double].
  @override
  String toString();
}

/// An IEEE-754 binary64 bit pattern, as two 32-bit halves, high half first,
/// because 64-bit integers are not available on the web.
final class const Float64(final int high, final int low) implements FloatBits {
  /// Negative infinity.
  static const negativeInfinity = Float64(0xFFF00000, 0);

  /// Positive infinity.
  static const positiveInfinity = Float64(0x7FF00000, 0);

  /// Negative zero.
  static const negativeZero = Float64(0x80000000, 0);

  /// Positive zero.
  static const positiveZero = Float64(0x00000000, 0);

  /// A normal value, -1.25.
  static const negativeNormal = Float64(0xBFF40000, 0);

  /// A normal value, 1.25.
  static const positiveNormal = Float64(0x3FF40000, 0);

  /// The canonical quiet NaN with the sign bit set.
  static const negativeQuietNan = Float64(0xFFF80000, 0);

  /// The canonical quiet NaN, with only the exponent bits and the quiet bit
  /// set.
  static const positiveQuietNan = Float64(0x7FF80000, 0);

  /// The negation of [positiveSmallestSubnormal].
  static const negativeSmallestSubnormal = Float64(0x80000000, 0x00000001);

  /// The smallest positive subnormal.
  static const positiveSmallestSubnormal = Float64(0x00000000, 0x00000001);

  /// The negation of [positiveLargestSubnormal].
  static const negativeLargestSubnormal = Float64(0x800FFFFF, 0xFFFFFFFF);

  /// The largest positive subnormal.
  static const positiveLargestSubnormal = Float64(0x000FFFFF, 0xFFFFFFFF);

  /// The negation of [positiveQuietNanLowPayload].
  static const negativeQuietNanLowPayload = Float64(0xFFF80000, 0x000000FF);

  /// A non-canonical quiet NaN with a payload in its low byte.
  static const positiveQuietNanLowPayload = Float64(0x7FF80000, 0x000000FF);

  /// A signaling NaN with a payload one byte up. Its quiet bit is clear.
  ///
  /// It shares only the exponent bits with [positiveQuietNanLowPayload], so
  /// an implementation that returns the bitwise AND or OR of its operands
  /// gives neither of them.
  static const positiveSignalingNanLowPayload = Float64(0x7FF00000, 0x0000FF00);

  /// The negation of [positiveSignalingNanLowPayload].
  static const negativeSignalingNanLowPayload = Float64(0xFFF00000, 0x0000FF00);

  /// Every constant above.
  static const List<Float64> values = [
    negativeInfinity,
    positiveInfinity,
    negativeZero,
    positiveZero,
    negativeNormal,
    positiveNormal,
    negativeQuietNan,
    positiveQuietNan,
    negativeSmallestSubnormal,
    positiveSmallestSubnormal,
    negativeLargestSubnormal,
    positiveLargestSubnormal,
    negativeQuietNanLowPayload,
    positiveQuietNanLowPayload,
    negativeSignalingNanLowPayload,
    positiveSignalingNanLowPayload,
  ];

  /// The bits of [value].
  factory fromDouble(double value) {
    final data = ByteData(8)..setFloat64(0, value, .little);
    return Float64(data.getUint32(4, .little), data.getUint32(0, .little));
  }

  @override
  double toDouble() =>
      (ByteData(8)
            ..setUint32(4, high, .little)
            ..setUint32(0, low, .little))
          .getFloat64(0, .little);

  @override
  bool get isNaN {
    // A NaN has all 11 exponent bits set.
    final exponentAllOnes = (high & 0x7FF00000) == 0x7FF00000;
    // A nonzero fraction tells it apart from an infinity.
    final fractionNonZero = ((high & 0x000FFFFF) | low) != 0;
    return exponentAllOnes && fractionNonZero;
  }

  @override
  bool operator ==(Object other) =>
      other is Float64 && other.high == high && other.low == low;

  @override
  int get hashCode => Object.hash(high, low);

  @override
  String toString() => switch (this) {
    negativeInfinity => '-inf',
    positiveInfinity => '+inf',
    negativeZero => '-0.0',
    positiveZero => '+0.0',
    negativeNormal => '-norm',
    positiveNormal => '+norm',
    negativeQuietNan => '-NaN',
    positiveQuietNan => '+NaN',
    negativeSmallestSubnormal => '-subMin',
    positiveSmallestSubnormal => '+subMin',
    negativeLargestSubnormal => '-subMax',
    positiveLargestSubnormal => '+subMax',
    negativeQuietNanLowPayload => '-qNaN.lo',
    positiveQuietNanLowPayload => '+qNaN.lo',
    negativeSignalingNanLowPayload => '-sNaN.lo',
    positiveSignalingNanLowPayload => '+sNaN.lo',
    _ => '0x${_hex8(high)}_${_hex8(low)}',
  };
}

/// An IEEE-754 binary32 bit pattern, as held by a [Float32List] element or a
/// [Float32x4] lane.
final class const Float32(final int bits) implements FloatBits {
  /// Negative infinity.
  static const negativeInfinity = Float32(0xFF800000);

  /// Positive infinity.
  static const positiveInfinity = Float32(0x7F800000);

  /// Negative zero.
  static const negativeZero = Float32(0x80000000);

  /// Positive zero.
  static const positiveZero = Float32(0x00000000);

  /// A normal value, -1.25.
  static const negativeNormal = Float32(0xBFA00000);

  /// A normal value, 1.25.
  static const positiveNormal = Float32(0x3FA00000);

  /// The negation of [positiveSmallestSubnormal].
  static const negativeSmallestSubnormal = Float32(0x80000001);

  /// The smallest positive subnormal.
  static const positiveSmallestSubnormal = Float32(0x00000001);

  /// The negation of [positiveLargestSubnormal].
  static const negativeLargestSubnormal = Float32(0x807FFFFF);

  /// The largest positive subnormal.
  static const positiveLargestSubnormal = Float32(0x007FFFFF);

  /// The canonical quiet NaN with the sign bit set.
  static const negativeQuietNan = Float32(0xFFC00000);

  /// The canonical quiet NaN, with only the exponent bits and the quiet bit
  /// set.
  static const positiveQuietNan = Float32(0x7FC00000);

  /// The negation of [positiveQuietNanPayload].
  static const negativeQuietNanPayload = Float32(0xFFE00000);

  /// A non-canonical quiet NaN with a payload.
  static const positiveQuietNanPayload = Float32(0x7FE00000);

  /// A signaling NaN with a payload. Its quiet bit is clear.
  ///
  /// It shares only the exponent bits with [positiveQuietNanPayload], so an
  /// implementation that returns the bitwise AND or OR of its operands gives
  /// neither of them.
  ///
  /// Converting it to a [double] quiets it, so [toDouble] gives `0x7FD00000`
  /// widened.
  static const positiveSignalingNanPayload = Float32(0x7F900000);

  /// The negation of [positiveSignalingNanPayload].
  static const negativeSignalingNanPayload = Float32(0xFF900000);

  /// Every constant above.
  static const List<Float32> values = [
    negativeInfinity,
    positiveInfinity,
    negativeZero,
    positiveZero,
    negativeNormal,
    positiveNormal,
    negativeSmallestSubnormal,
    positiveSmallestSubnormal,
    negativeLargestSubnormal,
    positiveLargestSubnormal,
    negativeQuietNan,
    positiveQuietNan,
    negativeQuietNanPayload,
    positiveQuietNanPayload,
    negativeSignalingNanPayload,
    positiveSignalingNanPayload,
  ];

  /// The bits of [value] narrowed to binary32.
  factory fromDouble(double value) => Float32(
    (ByteData(4)..setFloat32(0, value, .little)).getUint32(0, .little),
  );

  @override
  double toDouble() =>
      (ByteData(4)..setUint32(0, bits, .little)).getFloat32(0, .little);

  @override
  bool get isNaN {
    // A NaN has all 8 exponent bits set.
    final exponentAllOnes = (bits & 0x7F800000) == 0x7F800000;
    // A nonzero fraction tells it apart from an infinity.
    final fractionNonZero = (bits & 0x007FFFFF) != 0;
    return exponentAllOnes && fractionNonZero;
  }

  @override
  bool operator ==(Object other) => other is Float32 && other.bits == bits;

  @override
  int get hashCode => bits.hashCode;

  @override
  String toString() => switch (this) {
    negativeInfinity => '-f32Inf',
    positiveInfinity => '+f32Inf',
    negativeZero => '-f32Zero',
    positiveZero => '+f32Zero',
    negativeNormal => '-f32Norm',
    positiveNormal => '+f32Norm',
    negativeSmallestSubnormal => '-f32SubMin',
    positiveSmallestSubnormal => '+f32SubMin',
    negativeLargestSubnormal => '-f32SubMax',
    positiveLargestSubnormal => '+f32SubMax',
    negativeQuietNan => '-f32NaN',
    positiveQuietNan => '+f32NaN',
    negativeQuietNanPayload => '-f32qNaN',
    positiveQuietNanPayload => '+f32qNaN',
    negativeSignalingNanPayload => '-f32sNaN',
    positiveSignalingNanPayload => '+f32sNaN',
    _ => 'f32 0x${_hex8(bits)}',
  };
}

/// [bits] as eight hex digits, grouped in fours.
String _hex8(int bits) {
  final hex = bits.toRadixString(16).padLeft(8, '0').toUpperCase();
  return '${hex.substring(0, 4)}_${hex.substring(4)}';
}
