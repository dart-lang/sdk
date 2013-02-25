// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.scalarlist;

/**
 * Interface of Dart Float32x4 and operations.
 * Float32x4 stores 4 32-bit floating point values in "lanes".
 * The lanes are "x", "y", "z", and "w" respectively.
 */
abstract class Float32x4 {
  external factory Float32x4(double x, double y, double z, double w);
  external factory Float32x4.zero();

  /// Addition operator.
  Float32x4 operator+(Float32x4 other);
  /// Negate operator.
  Float32x4 operator-();
  /// Subtraction operator.
  Float32x4 operator-(Float32x4 other);
  /// Multiplication operator.
  Float32x4 operator*(Float32x4 other);
  /// Division operator.
  Float32x4 operator/(Float32x4 other);

  /// Relational less than.
  Uint32x4 lessThan(Float32x4 other);
  /// Relational less than or equal.
  Uint32x4 lessThanOrEqual(Float32x4 other);
  /// Relational greater than.
  Uint32x4 greaterThan(Float32x4 other);
  /// Relational greater than or equal.
  Uint32x4 greaterThanOrEqual(Float32x4 other);
  /// Relational equal.
  Uint32x4 equal(Float32x4 other);
  /// Relational not-equal.
  Uint32x4 notEqual(Float32x4 other);

  /// Returns a copy of [this] each lane being scaled by [s].
  Float32x4 scale(double s);
  /// Returns the absolute value of this [Simd128Float32].
  Float32x4 abs();
  /// Clamps [this] to be in the range [lowerLimit]-[upperLimit].
  Float32x4 clamp(Float32x4 lowerLimit,
                         Float32x4 upperLimit);

  /// Extracted x value.
  double get x;
  /// Extracted y value.
  double get y;
  /// Extracted z value.
  double get z;
  /// Extracted w value.
  double get w;

  /// Returns a new [Float32x4] with [this]' x value in all four lanes.
  Float32x4 get xxxx;
  /// Returns a new [Float32x4] with [this]' y value in all four lanes.
  Float32x4 get yyyy;
  /// Returns a new [Float32x4] with [this]' z value in all four lanes.
  Float32x4 get zzzz;
  /// Returns a new [Float32x4] with [this]' w value in all four lanes.
  Float32x4 get wwww;
  // TODO(johnmccutchan): Add all 256 possible combinations.

  /// Returns a new [Float32x4] copied from [this] with a new x value.
  Float32x4 withX(double x);
  /// Returns a new [Float32x4] copied from [this] with a new y value.
  Float32x4 withY(double y);
  /// Returns a new [Float32x4] copied from [this] with a new z value.
  Float32x4 withZ(double z);
  /// Returns a new [Float32x4] copied from [this] with a new w value.
  Float32x4 withW(double w);

  /// Returns the lane-wise minimum value in [this] or [other].
  Float32x4 min(Float32x4 other);

  /// Returns the lane-wise maximum value in [this] or [other].
  Float32x4 max(Float32x4 other);

  /// Returns the square root of [this].
  Float32x4 sqrt();

  /// Returns the reciprocal of [this].
  Float32x4 reciprocal();

  /// Returns the square root of the reciprocal of [this].
  Float32x4 reciprocalSqrt();

  /// Returns a bit-wise copy of [this] as a [Uint32x4].
  Uint32x4 toUint32x4();
}

/**
 * Interface of Dart Uint32x4 and operations.
 * Uint32x4 stores 4 32-bit bit-masks in "lanes".
 * The lanes are "x", "y", "z", and "w" respectively.
 */
abstract class Uint32x4 {
  external factory Uint32x4(int x, int y, int z, int w);
  external factory Uint32x4.bool(bool x, bool y, bool z, bool w);

  /// The bit-wise or operator.
  Uint32x4 operator|(Uint32x4 other);
  /// The bit-wise and operator.
  Uint32x4 operator&(Uint32x4 other);
  /// The bit-wise xor operator.
  Uint32x4 operator^(Uint32x4 other);

  /// Extract 32-bit mask from x lane.
  int get x;
  /// Extract 32-bit mask from y lane.
  int get y;
  /// Extract 32-bit mask from z lane.
  int get z;
  /// Extract 32-bit mask from w lane.
  int get w;

  /// Returns a new [Uint32x4] copied from [this] with a new x value.
  Uint32x4 withX(int x);
  /// Returns a new [Uint32x4] copied from [this] with a new y value.
  Uint32x4 withY(int y);
  /// Returns a new [Uint32x4] copied from [this] with a new z value.
  Uint32x4 withZ(int z);
  /// Returns a new [Uint32x4] copied from [this] with a new w value.
  Uint32x4 withW(int w);

  /// Extracted x value. Returns false for 0, true for any other value.
  bool get flagX;
  /// Extracted y value. Returns false for 0, true for any other value.
  bool get flagY;
  /// Extracted z value. Returns false for 0, true for any other value.
  bool get flagZ;
  /// Extracted w value. Returns false for 0, true for any other value.
  bool get flagW;

  /// Returns a new [Uint32x4] copied from [this] with a new x value.
  Uint32x4 withFlagX(bool x);
  /// Returns a new [Uint32x4] copied from [this] with a new y value.
  Uint32x4 withFlagY(bool y);
  /// Returns a new [Uint32x4] copied from [this] with a new z value.
  Uint32x4 withFlagZ(bool z);
  /// Returns a new [Uint32x4] copied from [this] with a new w value.
  Uint32x4 withFlagW(bool w);

  /// Merge [trueValue] and [falseValue] based on [this]' bit mask:
  /// Select bit from [trueValue] when bit in [this] is on.
  /// Select bit from [falseValue] when bit in [this] is off.
  Float32x4 select(Float32x4 trueValue,
                          Float32x4 falseValue);

  /// Returns a bit-wise copy of [this] as a [Float32x4].
  Float32x4 toFloat32x4();
}

/**
 * A fixed-length list of Float32x4 numbers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably more
 * space- and time-efficient than the default [List] implementation.
 */
abstract class Float32x4List implements List<Float32x4>,
    ByteArrayViewable {
  /**
   * Creates a [Simd128Float32List] of the specified length (in elements),
   * all of whose elements are initially zero.
   */
  external factory Float32x4List(int length);

  /**
   * Creates a [Float32x4List] _view_ of the specified region in the
   * specified byte [array]. Changes in the [Float32x4List] will be
   * visible in the byte array and vice versa. If the [start] index of the
   * region is not specified, it defaults to zero (the first byte in the byte
   * array). If the length is not specified, it defaults to null, which
   * indicates that the view extends to the end of the byte array.
   *
   * Throws [ArgumentError] if the length of the specified region is not
   * divisible by 16 (the size of a "Float32x4" in bytes), or if the
   * [start] of the region is not divisible by 16. If, however, [array] is a
   * view of another byte array, this constructor will throw [ArgumentError]
   * if the implicit starting position in the "ultimately backing" byte array
   * is not divisible by 16. In plain terms, this constructor throws
   * [ArgumentError] if the specified region does not contain an integral
   * number of "Float32x4s," or if it is not "Float32x4-aligned."
   */
  external factory Float32x4List.view(ByteArray array,
                                             [int start = 0, int length]);
}
