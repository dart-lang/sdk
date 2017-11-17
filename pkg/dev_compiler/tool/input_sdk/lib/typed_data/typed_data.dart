// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Lists that efficiently handle fixed sized data
/// (for example, unsigned 8 byte integers) and SIMD numeric types.
///
/// To use this library in your code:
///
///     import 'dart:typed_data';
library dart.typed_data;

/**
 * A sequence of bytes underlying a typed data object.
 *
 * Used to process large quantities of binary or numerical data
 * more efficiently using a typed view.
 */
abstract class ByteBuffer {
  /**
   * Returns the length of this byte buffer, in bytes.
   */
  int get lengthInBytes;

  /**
   * Creates a [Uint8List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Uint8List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes] and contains [length] bytes.
   * If [length] is omitted, the range extends to the end of the buffer.
   *
   * The start index and length must describe a valid range of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `length` must not be negative, and
   * * `offsetInBytes + length` must not be greater than [lengthInBytes].
   */
  Uint8List asUint8List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Int8List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Int8List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes] and contains [length] bytes.
   * If [length] is omitted, the range extends to the end of the buffer.
   *
   * The start index and length must describe a valid range of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `length` must not be negative, and
   * * `offsetInBytes + length` must not be greater than [lengthInBytes].
   */
  Int8List asInt8List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Uint8ClampedList] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Uint8ClampedList` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes] and contains [length] bytes.
   * If [length] is omitted, the range extends to the end of the buffer.
   *
   * The start index and length must describe a valid range of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `length` must not be negative, and
   * * `offsetInBytes + length` must not be greater than [lengthInBytes].
   */
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Uint16List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Uint16List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 16-bit aligned,
   * and contains [length] 16-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not even, the last byte can't be part of the view.
   *
   * The start index and length must describe a valid 16-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by two,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 2` must not be greater than [lengthInBytes].
   */
  Uint16List asUint16List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Int16List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Int16List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 16-bit aligned,
   * and contains [length] 16-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not even, the last byte can't be part of the view.
   *
   * The start index and length must describe a valid 16-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by two,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 2` must not be greater than [lengthInBytes].
   */
  Int16List asInt16List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Uint32List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Uint32List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 32-bit aligned,
   * and contains [length] 32-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not divisible by four, the last bytes can't be part
   * of the view.
   *
   * The start index and length must describe a valid 32-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by four,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 4` must not be greater than [lengthInBytes].
   */
  Uint32List asUint32List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Int32List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Int32List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 32-bit aligned,
   * and contains [length] 32-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not divisible by four, the last bytes can't be part
   * of the view.
   *
   * The start index and length must describe a valid 32-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by four,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 4` must not be greater than [lengthInBytes].
   */
  Int32List asInt32List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Uint64List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Uint64List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 64-bit aligned,
   * and contains [length] 64-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not divisible by eight, the last bytes can't be part
   * of the view.
   *
   * The start index and length must describe a valid 64-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by eight,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 8` must not be greater than [lengthInBytes].
   */
  Uint64List asUint64List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Int64List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Int64List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 64-bit aligned,
   * and contains [length] 64-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not divisible by eight, the last bytes can't be part
   * of the view.
   *
   * The start index and length must describe a valid 64-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by eight,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 8` must not be greater than [lengthInBytes].
   */
  Int64List asInt64List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Int32x4List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Int32x4List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 128-bit aligned,
   * and contains [length] 128-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not divisible by 16, the last bytes can't be part
   * of the view.
   *
   * The start index and length must describe a valid 128-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by sixteen,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 16` must not be greater than [lengthInBytes].
   */
  Int32x4List asInt32x4List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Float32List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Float32List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 32-bit aligned,
   * and contains [length] 32-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not divisible by four, the last bytes can't be part
   * of the view.
   *
   * The start index and length must describe a valid 32-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by four,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 4` must not be greater than [lengthInBytes].
   */
  Float32List asFloat32List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Float64List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Float64List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 64-bit aligned,
   * and contains [length] 64-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not divisible by eight, the last bytes can't be part
   * of the view.
   *
   * The start index and length must describe a valid 64-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by eight,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 8` must not be greater than [lengthInBytes].
   */
  Float64List asFloat64List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Float32x4List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Float32x4List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 128-bit aligned,
   * and contains [length] 128-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not divisible by 16, the last bytes can't be part
   * of the view.
   *
   * The start index and length must describe a valid 128-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by sixteen,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 16` must not be greater than [lengthInBytes].
   */
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [Float64x2List] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `Float64x2List` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes], which must be 128-bit aligned,
   * and contains [length] 128-bit integers.
   * If [length] is omitted, the range extends as far towards the end of
   * the buffer as possible -
   * if [lengthInBytes] is not divisible by 16, the last bytes can't be part
   * of the view.
   *
   * The start index and length must describe a valid 128-bit aligned range
   * of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `offsetInBytes` must be divisible by sixteen,
   * * `length` must not be negative, and
   * * `offsetInBytes + length * 16` must not be greater than [lengthInBytes].
   */
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int length]);

  /**
   * Creates a [ByteData] _view_ of a region of this byte buffer.
   *
   * The view is backed by the bytes of this byte buffer.
   * Any changes made to the `ByteData` will also change the buffer,
   * and vice versa.
   *
   * The viewed region start at [offsetInBytes] and contains [length] bytes.
   * If [length] is omitted, the range extends to the end of the buffer.
   *
   * The start index and length must describe a valid range of the buffer:
   *
   * * `offsetInBytes` must not be negative,
   * * `length` must not be negative, and
   * * `offsetInBytes + length` must not be greater than [lengthInBytes].
   */
  ByteData asByteData([int offsetInBytes = 0, int length]);
}

/**
 * A typed view of a sequence of bytes.
 */
abstract class TypedData {
  /**
   * Returns the number of bytes in the representation of each element in this
   * list.
   */
  int get elementSizeInBytes;

  /**
   * Returns the offset in bytes into the underlying byte buffer of this view.
   */
  int get offsetInBytes;

  /**
   * Returns the length of this view, in bytes.
   */
  int get lengthInBytes;

  /**
   * Returns the byte buffer associated with this object.
   */
  ByteBuffer get buffer;
}

// TODO(lrn): Remove class for Dart 2.0.
/** Deprecated, use [Endian] instead. */
abstract class Endianness {
  Endianness._(); // prevent construction.
  /** Deprecated, use [Endian.big] instead. */
  static const Endian BIG_ENDIAN = Endian.big;
  /** Deprecated, use [Endian.little] instead. */
  static const Endian LITTLE_ENDIAN = Endian.little;
  /** Deprecated, use [Endian.host] instead. */
  static Endian get HOST_ENDIAN => Endian.host;
}

/**
 * Describes endianness to be used when accessing or updating a
 * sequence of bytes.
 */
class Endian implements Endianness {
  final bool _littleEndian;
  const Endian._(this._littleEndian);

  static const Endian big = const Endian._(false);
  static const Endian little = const Endian._(true);
  static final Endian host =
      (new ByteData.view(new Uint16List.fromList([1]).buffer)).getInt8(0) == 1
          ? little
          : big;
}

/**
 * A fixed-length, random-access sequence of bytes that also provides random
 * and unaligned access to the fixed-width integers and floating point
 * numbers represented by those bytes.
 *
 * `ByteData` may be used to pack and unpack data from external sources
 * (such as networks or files systems), and to process large quantities
 * of numerical data more efficiently than would be possible
 * with ordinary [List] implementations.
 * `ByteData` can save space, by eliminating the need for object headers,
 * and time, by eliminating the need for data copies.
 * Finally, `ByteData` may be used to intentionally reinterpret the bytes
 * representing one arithmetic type as another.
 * For example this code fragment determine what 32-bit signed integer
 * is represented by the bytes of a 32-bit floating point number:
 *
 *     var buffer = new Uint8List(8).buffer;
 *     var bdata = new ByteData.view(buffer);
 *     bdata.setFloat32(0, 3.04);
 *     int huh = bdata.getInt32(0);
 */
abstract class ByteData implements TypedData {
  /**
   * Creates a [ByteData] of the specified length (in elements), all of
   * whose bytes are initially zero.
   */
  external factory ByteData(int length);

  /**
   * Creates an [ByteData] _view_ of the specified region in [buffer].
   *
   * Changes in the [ByteData] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   */
  factory ByteData.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asByteData(offsetInBytes, length);
  }

  /**
   * Returns the (possibly negative) integer represented by the byte at the
   * specified [byteOffset] in this object, in two's complement binary
   * representation.
   *
   * The return value will be between -128 and 127, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  int getInt8(int byteOffset);

  /**
   * Sets the byte at the specified [byteOffset] in this object to the
   * two's complement binary representation of the specified [value], which
   * must fit in a single byte.
   *
   * In other words, [value] must be between -128 and 127, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  void setInt8(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the byte at the specified
   * [byteOffset] in this object, in unsigned binary form.
   *
   * The return value will be between 0 and 255, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  int getUint8(int byteOffset);

  /**
   * Sets the byte at the specified [byteOffset] in this object to the
   * unsigned binary representation of the specified [value], which must fit
   * in a single byte.
   *
   * In other words, [value] must be between 0 and 255, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative,
   * or greater than or equal to the length of this object.
   */
  void setUint8(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the two bytes at
   * the specified [byteOffset] in this object, in two's complement binary
   * form.
   *
   * The return value will be between -2<sup>15</sup> and 2<sup>15</sup> - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  int getInt16(int byteOffset, [Endian endian = Endian.big]);

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in two bytes.
   *
   * In other words, [value] must lie
   * between -2<sup>15</sup> and 2<sup>15</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]);

  /**
   * Returns the positive integer represented by the two bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   *
   * The return value will be between 0 and  2<sup>16</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  int getUint16(int byteOffset, [Endian endian = Endian.big]);

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in two bytes.
   *
   * In other words, [value] must be between
   * 0 and 2<sup>16</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]);

  /**
   * Returns the (possibly negative) integer represented by the four bytes at
   * the specified [byteOffset] in this object, in two's complement binary
   * form.
   *
   * The return value will be between -2<sup>31</sup> and 2<sup>31</sup> - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  int getInt32(int byteOffset, [Endian endian = Endian.big]);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in four bytes.
   *
   * In other words, [value] must lie
   * between -2<sup>31</sup> and 2<sup>31</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]);

  /**
   * Returns the positive integer represented by the four bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   *
   * The return value will be between 0 and  2<sup>32</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  int getUint32(int byteOffset, [Endian endian = Endian.big]);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in four bytes.
   *
   * In other words, [value] must be between
   * 0 and 2<sup>32</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]);

  /**
   * Returns the (possibly negative) integer represented by the eight bytes at
   * the specified [byteOffset] in this object, in two's complement binary
   * form.
   *
   * The return value will be between -2<sup>63</sup> and 2<sup>63</sup> - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  int getInt64(int byteOffset, [Endian endian = Endian.big]);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in eight bytes.
   *
   * In other words, [value] must lie
   * between -2<sup>63</sup> and 2<sup>63</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]);

  /**
   * Returns the positive integer represented by the eight bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   *
   * The return value will be between 0 and  2<sup>64</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  int getUint64(int byteOffset, [Endian endian = Endian.big]);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in eight bytes.
   *
   * In other words, [value] must be between
   * 0 and 2<sup>64</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]);

  /**
   * Returns the floating point number represented by the four bytes at
   * the specified [byteOffset] in this object, in IEEE 754
   * single-precision binary floating-point format (binary32).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  double getFloat32(int byteOffset, [Endian endian = Endian.big]);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this
   * object to the IEEE 754 single-precision binary floating-point
   * (binary32) representation of the specified [value].
   *
   * **Note that this method can lose precision.** The input [value] is
   * a 64-bit floating point value, which will be converted to 32-bit
   * floating point value by IEEE 754 rounding rules before it is stored.
   * If [value] cannot be represented exactly as a binary32, it will be
   * converted to the nearest binary32 value.  If two binary32 values are
   * equally close, the one whose least significant bit is zero will be used.
   * Note that finite (but large) values can be converted to infinity, and
   * small non-zero values can be converted to zero.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]);

  /**
   * Returns the floating point number represented by the eight bytes at
   * the specified [byteOffset] in this object, in IEEE 754
   * double-precision binary floating-point format (binary64).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  double getFloat64(int byteOffset, [Endian endian = Endian.big]);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * object to the IEEE 754 double-precision binary floating-point
   * (binary64) representation of the specified [value].
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]);
}

/**
 * A fixed-length list of 8-bit signed integers.
 *
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 *
 * Integers stored in the list are truncated to their low eight bits,
 * interpreted as a signed 8-bit two's complement integer with values in the
 * range -128 to +127.
 */
abstract class Int8List implements List<int>, TypedData {
  /**
   * Creates an [Int8List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int8List(int length);

  /**
   * Creates a [Int8List] with the same length as the [elements] list
   * and copies over the elements.
   *
   * Values are truncated to fit in the list when they are copied,
   * the same way storing values truncates them.
   */
  external factory Int8List.fromList(List<int> elements);

  /**
   * Creates an [Int8List] _view_ of the specified region in [buffer].
   *
   * Changes in the [Int8List] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   */
  factory Int8List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asInt8List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 1;
}

/**
 * A fixed-length list of 8-bit unsigned integers.
 *
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 *
 * Integers stored in the list are truncated to their low eight bits,
 * interpreted as an unsigned 8-bit integer with values in the
 * range 0 to 255.
 */
abstract class Uint8List implements List<int>, TypedData {
  /**
   * Creates a [Uint8List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Uint8List(int length);

  /**
   * Creates a [Uint8List] with the same length as the [elements] list
   * and copies over the elements.
   *
   * Values are truncated to fit in the list when they are copied,
   * the same way storing values truncates them.
   */
  external factory Uint8List.fromList(List<int> elements);

  /**
   * Creates a [Uint8List] _view_ of the specified region in [buffer].
   *
   * Changes in the [Uint8List] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   */
  factory Uint8List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asUint8List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 1;
}

/**
 * A fixed-length list of 8-bit unsigned integers.
 *
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 *
 * Integers stored in the list are clamped to an unsigned eight bit value.
 * That is, all values below zero are stored as zero
 * and all values above 255 are stored as 255.
 */
abstract class Uint8ClampedList implements List<int>, TypedData {
  /**
   * Creates a [Uint8ClampedList] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Uint8ClampedList(int length);

  /**
   * Creates a [Uint8ClampedList] of the same size as the [elements]
   * list and copies over the values clamping when needed.
   *
   * Values are clamped to fit in the list when they are copied,
   * the same way storing values clamps them.
   */
  external factory Uint8ClampedList.fromList(List<int> elements);

  /**
   * Creates a [Uint8ClampedList] _view_ of the specified region in the
   * specified byte [buffer].
   *
   * Changes in the [Uint8List] will be visible in the byte buffer
   * and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   */
  factory Uint8ClampedList.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asUint8ClampedList(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 1;
}

/**
 * A fixed-length list of 16-bit signed integers that is viewable as a
 * [TypedData].
 *
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 *
 * Integers stored in the list are truncated to their low 16 bits,
 * interpreted as a signed 16-bit two's complement integer with values in the
 * range -32768 to +32767.
 */
abstract class Int16List implements List<int>, TypedData {
  /**
   * Creates an [Int16List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int16List(int length);

  /**
   * Creates a [Int16List] with the same length as the [elements] list
   * and copies over the elements.
   *
   * Values are truncated to fit in the list when they are copied,
   * the same way storing values truncates them.
   */
  external factory Int16List.fromList(List<int> elements);

  /**
   * Creates an [Int16List] _view_ of the specified region in [buffer].
   *
   * Changes in the [Int16List] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Int16List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asInt16List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 2;
}

/**
 * A fixed-length list of 16-bit unsigned integers that is viewable as a
 * [TypedData].
 *
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 *
 * Integers stored in the list are truncated to their low 16 bits,
 * interpreted as an unsigned 16-bit integer with values in the
 * range 0 to 65536.
 */
abstract class Uint16List implements List<int>, TypedData {
  /**
   * Creates a [Uint16List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  external factory Uint16List(int length);

  /**
   * Creates a [Uint16List] with the same length as the [elements] list
   * and copies over the elements.
   *
   * Values are truncated to fit in the list when they are copied,
   * the same way storing values truncates them.
   */
  external factory Uint16List.fromList(List<int> elements);

  /**
   * Creates a [Uint16List] _view_ of the specified region in
   * the specified byte buffer.
   *
   * Changes in the [Uint16List] will be visible in the byte buffer
   * and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Uint16List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asUint16List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 2;
}

/**
 * A fixed-length list of 32-bit signed integers that is viewable as a
 * [TypedData].
 *
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 *
 * Integers stored in the list are truncated to their low 32 bits,
 * interpreted as a signed 32-bit two's complement integer with values in the
 * range -2147483648 to 2147483647.
 */
abstract class Int32List implements List<int>, TypedData {
  /**
   * Creates an [Int32List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int32List(int length);

  /**
   * Creates a [Int32List] with the same length as the [elements] list
   * and copies over the elements.
   *
   * Values are truncated to fit in the list when they are copied,
   * the same way storing values truncates them.
   */
  external factory Int32List.fromList(List<int> elements);

  /**
   * Creates an [Int32List] _view_ of the specified region in [buffer].
   *
   * Changes in the [Int32List] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Int32List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asInt32List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 4;
}

/**
 * A fixed-length list of 32-bit unsigned integers that is viewable as a
 * [TypedData].
 *
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 *
 * Integers stored in the list are truncated to their low 32 bits,
 * interpreted as an unsigned 32-bit integer with values in the
 * range 0 to 4294967295.
 */
abstract class Uint32List implements List<int>, TypedData {
  /**
   * Creates a [Uint32List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  external factory Uint32List(int length);

  /**
   * Creates a [Uint32List] with the same length as the [elements] list
   * and copies over the elements.
   *
   * Values are truncated to fit in the list when they are copied,
   * the same way storing values truncates them.
   */
  external factory Uint32List.fromList(List<int> elements);

  /**
   * Creates a [Uint32List] _view_ of the specified region in
   * the specified byte buffer.
   *
   * Changes in the [Uint32List] will be visible in the byte buffer
   * and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Uint32List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asUint32List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 4;
}

/**
 * A fixed-length list of 64-bit signed integers that is viewable as a
 * [TypedData].
 *
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 *
 * Integers stored in the list are truncated to their low 64 bits,
 * interpreted as a signed 64-bit two's complement integer with values in the
 * range -9223372036854775808 to +9223372036854775807.
 */
abstract class Int64List implements List<int>, TypedData {
  /**
   * Creates an [Int64List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int64List(int length);

  /**
   * Creates a [Int64List] with the same length as the [elements] list
   * and copies over the elements.
   *
   * Values are truncated to fit in the list when they are copied,
   * the same way storing values truncates them.
   */
  external factory Int64List.fromList(List<int> elements);

  /**
   * Creates an [Int64List] _view_ of the specified region in [buffer].
   *
   * Changes in the [Int64List] will be visible in the byte buffer
   * and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Int64List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asInt64List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 8;
}

/**
 * A fixed-length list of 64-bit unsigned integers that is viewable as a
 * [TypedData].
 *
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 *
 * Integers stored in the list are truncated to their low 64 bits,
 * interpreted as an unsigned 64-bit integer with values in the
 * range 0 to 18446744073709551616.
 */
abstract class Uint64List implements List<int>, TypedData {
  /**
   * Creates a [Uint64List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  external factory Uint64List(int length);

  /**
   * Creates a [Uint64List] with the same length as the [elements] list
   * and copies over the elements.
   *
   * Values are truncated to fit in the list when they are copied,
   * the same way storing values truncates them.
   */
  external factory Uint64List.fromList(List<int> elements);

  /**
   * Creates an [Uint64List] _view_ of the specified region in
   * the specified byte buffer.
   *
   * Changes in the [Uint64List] will be visible in the byte buffer
   * and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Uint64List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asUint64List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 8;
}

/**
 * A fixed-length list of IEEE 754 single-precision binary floating-point
 * numbers that is viewable as a [TypedData].
 *
 * For long lists, this
 * implementation can be considerably more space- and time-efficient than
 * the default [List] implementation.
 *
 * Double values stored in the list are converted to the nearest
 * single-precision value. Values read are converted to a double
 * value with the same value.
 */
abstract class Float32List implements List<double>, TypedData {
  /**
   * Creates a [Float32List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Float32List(int length);

  /**
   * Creates a [Float32List] with the same length as the [elements] list
   * and copies over the elements.
   *
   * Values are truncated to fit in the list when they are copied,
   * the same way storing values truncates them.
   */
  external factory Float32List.fromList(List<double> elements);

  /**
   * Creates a [Float32List] _view_ of the specified region in [buffer].
   *
   * Changes in the [Float32List] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Float32List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asFloat32List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 4;
}

/**
 * A fixed-length list of IEEE 754 double-precision binary floating-point
 * numbers  that is viewable as a [TypedData].
 *
 * For long lists, this
 * implementation can be considerably more space- and time-efficient than
 * the default [List] implementation.
 */
abstract class Float64List implements List<double>, TypedData {
  /**
   * Creates a [Float64List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Float64List(int length);

  /**
   * Creates a [Float64List] with the same length as the [elements] list
   * and copies over the elements.
   */
  external factory Float64List.fromList(List<double> elements);

  /**
   * Creates a [Float64List] _view_ of the specified region in [buffer].
   *
   * Changes in the [Float64List] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Float64List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asFloat64List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 8;
}

/**
 * A fixed-length list of Float32x4 numbers that is viewable as a
 * [TypedData].
 *
 * For long lists, this implementation will be considerably more
 * space- and time-efficient than the default [List] implementation.
 */
abstract class Float32x4List implements List<Float32x4>, TypedData {
  /**
   * Creates a [Float32x4List] of the specified length (in elements),
   * all of whose elements are initially zero.
   */
  external factory Float32x4List(int length);

  /**
   * Creates a [Float32x4List] with the same length as the [elements] list
   * and copies over the elements.
   */
  external factory Float32x4List.fromList(List<Float32x4> elements);

  /**
   * Creates a [Float32x4List] _view_ of the specified region in [buffer].
   *
   * Changes in the [Float32x4List] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Float32x4List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asFloat32x4List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 16;
}

/**
 * A fixed-length list of Int32x4 numbers that is viewable as a
 * [TypedData].
 *
 * For long lists, this implementation will be considerably more
 * space- and time-efficient than the default [List] implementation.
 */
abstract class Int32x4List implements List<Int32x4>, TypedData {
  /**
   * Creates a [Int32x4List] of the specified length (in elements),
   * all of whose elements are initially zero.
   */
  external factory Int32x4List(int length);

  /**
   * Creates a [Int32x4List] with the same length as the [elements] list
   * and copies over the elements.
   */
  external factory Int32x4List.fromList(List<Int32x4> elements);

  /**
   * Creates a [Int32x4List] _view_ of the specified region in [buffer].
   *
   * Changes in the [Int32x4List] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Int32x4List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asInt32x4List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 16;
}

/**
 * A fixed-length list of Float64x2 numbers that is viewable as a
 * [TypedData].
 *
 * For long lists, this implementation will be considerably more
 * space- and time-efficient than the default [List] implementation.
 */
abstract class Float64x2List implements List<Float64x2>, TypedData {
  /**
   * Creates a [Float64x2List] of the specified length (in elements),
   * all of whose elements have all lanes set to zero.
   */
  external factory Float64x2List(int length);

  /**
   * Creates a [Float64x2List] with the same length as the [elements] list
   * and copies over the elements.
   */
  external factory Float64x2List.fromList(List<Float64x2> elements);

  /**
   * Creates a [Float64x2List] _view_ of the specified region in [buffer].
   *
   * Changes in the [Float64x2List] will be visible in the byte
   * buffer and vice versa.
   * If the [offsetInBytes] index of the region is not specified,
   * it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to `null`,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * [bytesPerElement].
   */
  factory Float64x2List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int length]) {
    return buffer.asFloat64x2List(offsetInBytes, length);
  }

  /** Deprecated, use [bytesPerElement] instead. */
  static const int BYTES_PER_ELEMENT = bytesPerElement;
  static const int bytesPerElement = 16;
}

/**
 * Float32x4 immutable value type and operations.
 *
 * Float32x4 stores 4 32-bit floating point values in "lanes".
 * The lanes are "x", "y", "z", and "w" respectively.
 */
abstract class Float32x4 {
  external factory Float32x4(double x, double y, double z, double w);
  external factory Float32x4.splat(double v);
  external factory Float32x4.zero();
  external factory Float32x4.fromInt32x4Bits(Int32x4 x);

  /// Sets the x and y lanes to their respective values in [v] and sets the z
  /// and w lanes to 0.0.
  external factory Float32x4.fromFloat64x2(Float64x2 v);

  /// Addition operator.
  Float32x4 operator +(Float32x4 other);

  /// Negate operator.
  Float32x4 operator -();

  /// Subtraction operator.
  Float32x4 operator -(Float32x4 other);

  /// Multiplication operator.
  Float32x4 operator *(Float32x4 other);

  /// Division operator.
  Float32x4 operator /(Float32x4 other);

  /// Relational less than.
  Int32x4 lessThan(Float32x4 other);

  /// Relational less than or equal.
  Int32x4 lessThanOrEqual(Float32x4 other);

  /// Relational greater than.
  Int32x4 greaterThan(Float32x4 other);

  /// Relational greater than or equal.
  Int32x4 greaterThanOrEqual(Float32x4 other);

  /// Relational equal.
  Int32x4 equal(Float32x4 other);

  /// Relational not-equal.
  Int32x4 notEqual(Float32x4 other);

  /// Returns a copy of [this] each lane being scaled by [s].
  /// Equivalent to this * new Float32x4.splat(s)
  Float32x4 scale(double s);

  /// Returns the lane-wise absolute value of this [Float32x4].
  Float32x4 abs();

  /// Lane-wise clamp [this] to be in the range [lowerLimit]-[upperLimit].
  Float32x4 clamp(Float32x4 lowerLimit, Float32x4 upperLimit);

  /// Extracted x value.
  double get x;

  /// Extracted y value.
  double get y;

  /// Extracted z value.
  double get z;

  /// Extracted w value.
  double get w;

  /// Extract the sign bits from each lane return them in the first 4 bits.
  /// "x" lane is bit 0.
  /// "y" lane is bit 1.
  /// "z" lane is bit 2.
  /// "w" lane is bit 3.
  int get signMask;

  /// Mask passed to [shuffle] or [shuffleMix].
  static const int xxxx = 0x0;
  static const int xxxy = 0x40;
  static const int xxxz = 0x80;
  static const int xxxw = 0xC0;
  static const int xxyx = 0x10;
  static const int xxyy = 0x50;
  static const int xxyz = 0x90;
  static const int xxyw = 0xD0;
  static const int xxzx = 0x20;
  static const int xxzy = 0x60;
  static const int xxzz = 0xA0;
  static const int xxzw = 0xE0;
  static const int xxwx = 0x30;
  static const int xxwy = 0x70;
  static const int xxwz = 0xB0;
  static const int xxww = 0xF0;
  static const int xyxx = 0x4;
  static const int xyxy = 0x44;
  static const int xyxz = 0x84;
  static const int xyxw = 0xC4;
  static const int xyyx = 0x14;
  static const int xyyy = 0x54;
  static const int xyyz = 0x94;
  static const int xyyw = 0xD4;
  static const int xyzx = 0x24;
  static const int xyzy = 0x64;
  static const int xyzz = 0xA4;
  static const int xyzw = 0xE4;
  static const int xywx = 0x34;
  static const int xywy = 0x74;
  static const int xywz = 0xB4;
  static const int xyww = 0xF4;
  static const int xzxx = 0x8;
  static const int xzxy = 0x48;
  static const int xzxz = 0x88;
  static const int xzxw = 0xC8;
  static const int xzyx = 0x18;
  static const int xzyy = 0x58;
  static const int xzyz = 0x98;
  static const int xzyw = 0xD8;
  static const int xzzx = 0x28;
  static const int xzzy = 0x68;
  static const int xzzz = 0xA8;
  static const int xzzw = 0xE8;
  static const int xzwx = 0x38;
  static const int xzwy = 0x78;
  static const int xzwz = 0xB8;
  static const int xzww = 0xF8;
  static const int xwxx = 0xC;
  static const int xwxy = 0x4C;
  static const int xwxz = 0x8C;
  static const int xwxw = 0xCC;
  static const int xwyx = 0x1C;
  static const int xwyy = 0x5C;
  static const int xwyz = 0x9C;
  static const int xwyw = 0xDC;
  static const int xwzx = 0x2C;
  static const int xwzy = 0x6C;
  static const int xwzz = 0xAC;
  static const int xwzw = 0xEC;
  static const int xwwx = 0x3C;
  static const int xwwy = 0x7C;
  static const int xwwz = 0xBC;
  static const int xwww = 0xFC;
  static const int yxxx = 0x1;
  static const int yxxy = 0x41;
  static const int yxxz = 0x81;
  static const int yxxw = 0xC1;
  static const int yxyx = 0x11;
  static const int yxyy = 0x51;
  static const int yxyz = 0x91;
  static const int yxyw = 0xD1;
  static const int yxzx = 0x21;
  static const int yxzy = 0x61;
  static const int yxzz = 0xA1;
  static const int yxzw = 0xE1;
  static const int yxwx = 0x31;
  static const int yxwy = 0x71;
  static const int yxwz = 0xB1;
  static const int yxww = 0xF1;
  static const int yyxx = 0x5;
  static const int yyxy = 0x45;
  static const int yyxz = 0x85;
  static const int yyxw = 0xC5;
  static const int yyyx = 0x15;
  static const int yyyy = 0x55;
  static const int yyyz = 0x95;
  static const int yyyw = 0xD5;
  static const int yyzx = 0x25;
  static const int yyzy = 0x65;
  static const int yyzz = 0xA5;
  static const int yyzw = 0xE5;
  static const int yywx = 0x35;
  static const int yywy = 0x75;
  static const int yywz = 0xB5;
  static const int yyww = 0xF5;
  static const int yzxx = 0x9;
  static const int yzxy = 0x49;
  static const int yzxz = 0x89;
  static const int yzxw = 0xC9;
  static const int yzyx = 0x19;
  static const int yzyy = 0x59;
  static const int yzyz = 0x99;
  static const int yzyw = 0xD9;
  static const int yzzx = 0x29;
  static const int yzzy = 0x69;
  static const int yzzz = 0xA9;
  static const int yzzw = 0xE9;
  static const int yzwx = 0x39;
  static const int yzwy = 0x79;
  static const int yzwz = 0xB9;
  static const int yzww = 0xF9;
  static const int ywxx = 0xD;
  static const int ywxy = 0x4D;
  static const int ywxz = 0x8D;
  static const int ywxw = 0xCD;
  static const int ywyx = 0x1D;
  static const int ywyy = 0x5D;
  static const int ywyz = 0x9D;
  static const int ywyw = 0xDD;
  static const int ywzx = 0x2D;
  static const int ywzy = 0x6D;
  static const int ywzz = 0xAD;
  static const int ywzw = 0xED;
  static const int ywwx = 0x3D;
  static const int ywwy = 0x7D;
  static const int ywwz = 0xBD;
  static const int ywww = 0xFD;
  static const int zxxx = 0x2;
  static const int zxxy = 0x42;
  static const int zxxz = 0x82;
  static const int zxxw = 0xC2;
  static const int zxyx = 0x12;
  static const int zxyy = 0x52;
  static const int zxyz = 0x92;
  static const int zxyw = 0xD2;
  static const int zxzx = 0x22;
  static const int zxzy = 0x62;
  static const int zxzz = 0xA2;
  static const int zxzw = 0xE2;
  static const int zxwx = 0x32;
  static const int zxwy = 0x72;
  static const int zxwz = 0xB2;
  static const int zxww = 0xF2;
  static const int zyxx = 0x6;
  static const int zyxy = 0x46;
  static const int zyxz = 0x86;
  static const int zyxw = 0xC6;
  static const int zyyx = 0x16;
  static const int zyyy = 0x56;
  static const int zyyz = 0x96;
  static const int zyyw = 0xD6;
  static const int zyzx = 0x26;
  static const int zyzy = 0x66;
  static const int zyzz = 0xA6;
  static const int zyzw = 0xE6;
  static const int zywx = 0x36;
  static const int zywy = 0x76;
  static const int zywz = 0xB6;
  static const int zyww = 0xF6;
  static const int zzxx = 0xA;
  static const int zzxy = 0x4A;
  static const int zzxz = 0x8A;
  static const int zzxw = 0xCA;
  static const int zzyx = 0x1A;
  static const int zzyy = 0x5A;
  static const int zzyz = 0x9A;
  static const int zzyw = 0xDA;
  static const int zzzx = 0x2A;
  static const int zzzy = 0x6A;
  static const int zzzz = 0xAA;
  static const int zzzw = 0xEA;
  static const int zzwx = 0x3A;
  static const int zzwy = 0x7A;
  static const int zzwz = 0xBA;
  static const int zzww = 0xFA;
  static const int zwxx = 0xE;
  static const int zwxy = 0x4E;
  static const int zwxz = 0x8E;
  static const int zwxw = 0xCE;
  static const int zwyx = 0x1E;
  static const int zwyy = 0x5E;
  static const int zwyz = 0x9E;
  static const int zwyw = 0xDE;
  static const int zwzx = 0x2E;
  static const int zwzy = 0x6E;
  static const int zwzz = 0xAE;
  static const int zwzw = 0xEE;
  static const int zwwx = 0x3E;
  static const int zwwy = 0x7E;
  static const int zwwz = 0xBE;
  static const int zwww = 0xFE;
  static const int wxxx = 0x3;
  static const int wxxy = 0x43;
  static const int wxxz = 0x83;
  static const int wxxw = 0xC3;
  static const int wxyx = 0x13;
  static const int wxyy = 0x53;
  static const int wxyz = 0x93;
  static const int wxyw = 0xD3;
  static const int wxzx = 0x23;
  static const int wxzy = 0x63;
  static const int wxzz = 0xA3;
  static const int wxzw = 0xE3;
  static const int wxwx = 0x33;
  static const int wxwy = 0x73;
  static const int wxwz = 0xB3;
  static const int wxww = 0xF3;
  static const int wyxx = 0x7;
  static const int wyxy = 0x47;
  static const int wyxz = 0x87;
  static const int wyxw = 0xC7;
  static const int wyyx = 0x17;
  static const int wyyy = 0x57;
  static const int wyyz = 0x97;
  static const int wyyw = 0xD7;
  static const int wyzx = 0x27;
  static const int wyzy = 0x67;
  static const int wyzz = 0xA7;
  static const int wyzw = 0xE7;
  static const int wywx = 0x37;
  static const int wywy = 0x77;
  static const int wywz = 0xB7;
  static const int wyww = 0xF7;
  static const int wzxx = 0xB;
  static const int wzxy = 0x4B;
  static const int wzxz = 0x8B;
  static const int wzxw = 0xCB;
  static const int wzyx = 0x1B;
  static const int wzyy = 0x5B;
  static const int wzyz = 0x9B;
  static const int wzyw = 0xDB;
  static const int wzzx = 0x2B;
  static const int wzzy = 0x6B;
  static const int wzzz = 0xAB;
  static const int wzzw = 0xEB;
  static const int wzwx = 0x3B;
  static const int wzwy = 0x7B;
  static const int wzwz = 0xBB;
  static const int wzww = 0xFB;
  static const int wwxx = 0xF;
  static const int wwxy = 0x4F;
  static const int wwxz = 0x8F;
  static const int wwxw = 0xCF;
  static const int wwyx = 0x1F;
  static const int wwyy = 0x5F;
  static const int wwyz = 0x9F;
  static const int wwyw = 0xDF;
  static const int wwzx = 0x2F;
  static const int wwzy = 0x6F;
  static const int wwzz = 0xAF;
  static const int wwzw = 0xEF;
  static const int wwwx = 0x3F;
  static const int wwwy = 0x7F;
  static const int wwwz = 0xBF;
  static const int wwww = 0xFF;
  /** Deprecated, use [xxxx] instead. */
  static const int XXXX = xxxx;
  /** Deprecated, use [xxxy] instead. */
  static const int XXXY = xxxy;
  /** Deprecated, use [xxxz] instead. */
  static const int XXXZ = xxxz;
  /** Deprecated, use [xxxw] instead. */
  static const int XXXW = xxxw;
  /** Deprecated, use [xxyx] instead. */
  static const int XXYX = xxyx;
  /** Deprecated, use [xxyy] instead. */
  static const int XXYY = xxyy;
  /** Deprecated, use [xxyz] instead. */
  static const int XXYZ = xxyz;
  /** Deprecated, use [xxyw] instead. */
  static const int XXYW = xxyw;
  /** Deprecated, use [xxzx] instead. */
  static const int XXZX = xxzx;
  /** Deprecated, use [xxzy] instead. */
  static const int XXZY = xxzy;
  /** Deprecated, use [xxzz] instead. */
  static const int XXZZ = xxzz;
  /** Deprecated, use [xxzw] instead. */
  static const int XXZW = xxzw;
  /** Deprecated, use [xxwx] instead. */
  static const int XXWX = xxwx;
  /** Deprecated, use [xxwy] instead. */
  static const int XXWY = xxwy;
  /** Deprecated, use [xxwz] instead. */
  static const int XXWZ = xxwz;
  /** Deprecated, use [xxww] instead. */
  static const int XXWW = xxww;
  /** Deprecated, use [xyxx] instead. */
  static const int XYXX = xyxx;
  /** Deprecated, use [xyxy] instead. */
  static const int XYXY = xyxy;
  /** Deprecated, use [xyxz] instead. */
  static const int XYXZ = xyxz;
  /** Deprecated, use [xyxw] instead. */
  static const int XYXW = xyxw;
  /** Deprecated, use [xyyx] instead. */
  static const int XYYX = xyyx;
  /** Deprecated, use [xyyy] instead. */
  static const int XYYY = xyyy;
  /** Deprecated, use [xyyz] instead. */
  static const int XYYZ = xyyz;
  /** Deprecated, use [xyyw] instead. */
  static const int XYYW = xyyw;
  /** Deprecated, use [xyzx] instead. */
  static const int XYZX = xyzx;
  /** Deprecated, use [xyzy] instead. */
  static const int XYZY = xyzy;
  /** Deprecated, use [xyzz] instead. */
  static const int XYZZ = xyzz;
  /** Deprecated, use [xyzw] instead. */
  static const int XYZW = xyzw;
  /** Deprecated, use [xywx] instead. */
  static const int XYWX = xywx;
  /** Deprecated, use [xywy] instead. */
  static const int XYWY = xywy;
  /** Deprecated, use [xywz] instead. */
  static const int XYWZ = xywz;
  /** Deprecated, use [xyww] instead. */
  static const int XYWW = xyww;
  /** Deprecated, use [xzxx] instead. */
  static const int XZXX = xzxx;
  /** Deprecated, use [xzxy] instead. */
  static const int XZXY = xzxy;
  /** Deprecated, use [xzxz] instead. */
  static const int XZXZ = xzxz;
  /** Deprecated, use [xzxw] instead. */
  static const int XZXW = xzxw;
  /** Deprecated, use [xzyx] instead. */
  static const int XZYX = xzyx;
  /** Deprecated, use [xzyy] instead. */
  static const int XZYY = xzyy;
  /** Deprecated, use [xzyz] instead. */
  static const int XZYZ = xzyz;
  /** Deprecated, use [xzyw] instead. */
  static const int XZYW = xzyw;
  /** Deprecated, use [xzzx] instead. */
  static const int XZZX = xzzx;
  /** Deprecated, use [xzzy] instead. */
  static const int XZZY = xzzy;
  /** Deprecated, use [xzzz] instead. */
  static const int XZZZ = xzzz;
  /** Deprecated, use [xzzw] instead. */
  static const int XZZW = xzzw;
  /** Deprecated, use [xzwx] instead. */
  static const int XZWX = xzwx;
  /** Deprecated, use [xzwy] instead. */
  static const int XZWY = xzwy;
  /** Deprecated, use [xzwz] instead. */
  static const int XZWZ = xzwz;
  /** Deprecated, use [xzww] instead. */
  static const int XZWW = xzww;
  /** Deprecated, use [xwxx] instead. */
  static const int XWXX = xwxx;
  /** Deprecated, use [xwxy] instead. */
  static const int XWXY = xwxy;
  /** Deprecated, use [xwxz] instead. */
  static const int XWXZ = xwxz;
  /** Deprecated, use [xwxw] instead. */
  static const int XWXW = xwxw;
  /** Deprecated, use [xwyx] instead. */
  static const int XWYX = xwyx;
  /** Deprecated, use [xwyy] instead. */
  static const int XWYY = xwyy;
  /** Deprecated, use [xwyz] instead. */
  static const int XWYZ = xwyz;
  /** Deprecated, use [xwyw] instead. */
  static const int XWYW = xwyw;
  /** Deprecated, use [xwzx] instead. */
  static const int XWZX = xwzx;
  /** Deprecated, use [xwzy] instead. */
  static const int XWZY = xwzy;
  /** Deprecated, use [xwzz] instead. */
  static const int XWZZ = xwzz;
  /** Deprecated, use [xwzw] instead. */
  static const int XWZW = xwzw;
  /** Deprecated, use [xwwx] instead. */
  static const int XWWX = xwwx;
  /** Deprecated, use [xwwy] instead. */
  static const int XWWY = xwwy;
  /** Deprecated, use [xwwz] instead. */
  static const int XWWZ = xwwz;
  /** Deprecated, use [xwww] instead. */
  static const int XWWW = xwww;
  /** Deprecated, use [yxxx] instead. */
  static const int YXXX = yxxx;
  /** Deprecated, use [yxxy] instead. */
  static const int YXXY = yxxy;
  /** Deprecated, use [yxxz] instead. */
  static const int YXXZ = yxxz;
  /** Deprecated, use [yxxw] instead. */
  static const int YXXW = yxxw;
  /** Deprecated, use [yxyx] instead. */
  static const int YXYX = yxyx;
  /** Deprecated, use [yxyy] instead. */
  static const int YXYY = yxyy;
  /** Deprecated, use [yxyz] instead. */
  static const int YXYZ = yxyz;
  /** Deprecated, use [yxyw] instead. */
  static const int YXYW = yxyw;
  /** Deprecated, use [yxzx] instead. */
  static const int YXZX = yxzx;
  /** Deprecated, use [yxzy] instead. */
  static const int YXZY = yxzy;
  /** Deprecated, use [yxzz] instead. */
  static const int YXZZ = yxzz;
  /** Deprecated, use [yxzw] instead. */
  static const int YXZW = yxzw;
  /** Deprecated, use [yxwx] instead. */
  static const int YXWX = yxwx;
  /** Deprecated, use [yxwy] instead. */
  static const int YXWY = yxwy;
  /** Deprecated, use [yxwz] instead. */
  static const int YXWZ = yxwz;
  /** Deprecated, use [yxww] instead. */
  static const int YXWW = yxww;
  /** Deprecated, use [yyxx] instead. */
  static const int YYXX = yyxx;
  /** Deprecated, use [yyxy] instead. */
  static const int YYXY = yyxy;
  /** Deprecated, use [yyxz] instead. */
  static const int YYXZ = yyxz;
  /** Deprecated, use [yyxw] instead. */
  static const int YYXW = yyxw;
  /** Deprecated, use [yyyx] instead. */
  static const int YYYX = yyyx;
  /** Deprecated, use [yyyy] instead. */
  static const int YYYY = yyyy;
  /** Deprecated, use [yyyz] instead. */
  static const int YYYZ = yyyz;
  /** Deprecated, use [yyyw] instead. */
  static const int YYYW = yyyw;
  /** Deprecated, use [yyzx] instead. */
  static const int YYZX = yyzx;
  /** Deprecated, use [yyzy] instead. */
  static const int YYZY = yyzy;
  /** Deprecated, use [yyzz] instead. */
  static const int YYZZ = yyzz;
  /** Deprecated, use [yyzw] instead. */
  static const int YYZW = yyzw;
  /** Deprecated, use [yywx] instead. */
  static const int YYWX = yywx;
  /** Deprecated, use [yywy] instead. */
  static const int YYWY = yywy;
  /** Deprecated, use [yywz] instead. */
  static const int YYWZ = yywz;
  /** Deprecated, use [yyww] instead. */
  static const int YYWW = yyww;
  /** Deprecated, use [yzxx] instead. */
  static const int YZXX = yzxx;
  /** Deprecated, use [yzxy] instead. */
  static const int YZXY = yzxy;
  /** Deprecated, use [yzxz] instead. */
  static const int YZXZ = yzxz;
  /** Deprecated, use [yzxw] instead. */
  static const int YZXW = yzxw;
  /** Deprecated, use [yzyx] instead. */
  static const int YZYX = yzyx;
  /** Deprecated, use [yzyy] instead. */
  static const int YZYY = yzyy;
  /** Deprecated, use [yzyz] instead. */
  static const int YZYZ = yzyz;
  /** Deprecated, use [yzyw] instead. */
  static const int YZYW = yzyw;
  /** Deprecated, use [yzzx] instead. */
  static const int YZZX = yzzx;
  /** Deprecated, use [yzzy] instead. */
  static const int YZZY = yzzy;
  /** Deprecated, use [yzzz] instead. */
  static const int YZZZ = yzzz;
  /** Deprecated, use [yzzw] instead. */
  static const int YZZW = yzzw;
  /** Deprecated, use [yzwx] instead. */
  static const int YZWX = yzwx;
  /** Deprecated, use [yzwy] instead. */
  static const int YZWY = yzwy;
  /** Deprecated, use [yzwz] instead. */
  static const int YZWZ = yzwz;
  /** Deprecated, use [yzww] instead. */
  static const int YZWW = yzww;
  /** Deprecated, use [ywxx] instead. */
  static const int YWXX = ywxx;
  /** Deprecated, use [ywxy] instead. */
  static const int YWXY = ywxy;
  /** Deprecated, use [ywxz] instead. */
  static const int YWXZ = ywxz;
  /** Deprecated, use [ywxw] instead. */
  static const int YWXW = ywxw;
  /** Deprecated, use [ywyx] instead. */
  static const int YWYX = ywyx;
  /** Deprecated, use [ywyy] instead. */
  static const int YWYY = ywyy;
  /** Deprecated, use [ywyz] instead. */
  static const int YWYZ = ywyz;
  /** Deprecated, use [ywyw] instead. */
  static const int YWYW = ywyw;
  /** Deprecated, use [ywzx] instead. */
  static const int YWZX = ywzx;
  /** Deprecated, use [ywzy] instead. */
  static const int YWZY = ywzy;
  /** Deprecated, use [ywzz] instead. */
  static const int YWZZ = ywzz;
  /** Deprecated, use [ywzw] instead. */
  static const int YWZW = ywzw;
  /** Deprecated, use [ywwx] instead. */
  static const int YWWX = ywwx;
  /** Deprecated, use [ywwy] instead. */
  static const int YWWY = ywwy;
  /** Deprecated, use [ywwz] instead. */
  static const int YWWZ = ywwz;
  /** Deprecated, use [ywww] instead. */
  static const int YWWW = ywww;
  /** Deprecated, use [zxxx] instead. */
  static const int ZXXX = zxxx;
  /** Deprecated, use [zxxy] instead. */
  static const int ZXXY = zxxy;
  /** Deprecated, use [zxxz] instead. */
  static const int ZXXZ = zxxz;
  /** Deprecated, use [zxxw] instead. */
  static const int ZXXW = zxxw;
  /** Deprecated, use [zxyx] instead. */
  static const int ZXYX = zxyx;
  /** Deprecated, use [zxyy] instead. */
  static const int ZXYY = zxyy;
  /** Deprecated, use [zxyz] instead. */
  static const int ZXYZ = zxyz;
  /** Deprecated, use [zxyw] instead. */
  static const int ZXYW = zxyw;
  /** Deprecated, use [zxzx] instead. */
  static const int ZXZX = zxzx;
  /** Deprecated, use [zxzy] instead. */
  static const int ZXZY = zxzy;
  /** Deprecated, use [zxzz] instead. */
  static const int ZXZZ = zxzz;
  /** Deprecated, use [zxzw] instead. */
  static const int ZXZW = zxzw;
  /** Deprecated, use [zxwx] instead. */
  static const int ZXWX = zxwx;
  /** Deprecated, use [zxwy] instead. */
  static const int ZXWY = zxwy;
  /** Deprecated, use [zxwz] instead. */
  static const int ZXWZ = zxwz;
  /** Deprecated, use [zxww] instead. */
  static const int ZXWW = zxww;
  /** Deprecated, use [zyxx] instead. */
  static const int ZYXX = zyxx;
  /** Deprecated, use [zyxy] instead. */
  static const int ZYXY = zyxy;
  /** Deprecated, use [zyxz] instead. */
  static const int ZYXZ = zyxz;
  /** Deprecated, use [zyxw] instead. */
  static const int ZYXW = zyxw;
  /** Deprecated, use [zyyx] instead. */
  static const int ZYYX = zyyx;
  /** Deprecated, use [zyyy] instead. */
  static const int ZYYY = zyyy;
  /** Deprecated, use [zyyz] instead. */
  static const int ZYYZ = zyyz;
  /** Deprecated, use [zyyw] instead. */
  static const int ZYYW = zyyw;
  /** Deprecated, use [zyzx] instead. */
  static const int ZYZX = zyzx;
  /** Deprecated, use [zyzy] instead. */
  static const int ZYZY = zyzy;
  /** Deprecated, use [zyzz] instead. */
  static const int ZYZZ = zyzz;
  /** Deprecated, use [zyzw] instead. */
  static const int ZYZW = zyzw;
  /** Deprecated, use [zywx] instead. */
  static const int ZYWX = zywx;
  /** Deprecated, use [zywy] instead. */
  static const int ZYWY = zywy;
  /** Deprecated, use [zywz] instead. */
  static const int ZYWZ = zywz;
  /** Deprecated, use [zyww] instead. */
  static const int ZYWW = zyww;
  /** Deprecated, use [zzxx] instead. */
  static const int ZZXX = zzxx;
  /** Deprecated, use [zzxy] instead. */
  static const int ZZXY = zzxy;
  /** Deprecated, use [zzxz] instead. */
  static const int ZZXZ = zzxz;
  /** Deprecated, use [zzxw] instead. */
  static const int ZZXW = zzxw;
  /** Deprecated, use [zzyx] instead. */
  static const int ZZYX = zzyx;
  /** Deprecated, use [zzyy] instead. */
  static const int ZZYY = zzyy;
  /** Deprecated, use [zzyz] instead. */
  static const int ZZYZ = zzyz;
  /** Deprecated, use [zzyw] instead. */
  static const int ZZYW = zzyw;
  /** Deprecated, use [zzzx] instead. */
  static const int ZZZX = zzzx;
  /** Deprecated, use [zzzy] instead. */
  static const int ZZZY = zzzy;
  /** Deprecated, use [zzzz] instead. */
  static const int ZZZZ = zzzz;
  /** Deprecated, use [zzzw] instead. */
  static const int ZZZW = zzzw;
  /** Deprecated, use [zzwx] instead. */
  static const int ZZWX = zzwx;
  /** Deprecated, use [zzwy] instead. */
  static const int ZZWY = zzwy;
  /** Deprecated, use [zzwz] instead. */
  static const int ZZWZ = zzwz;
  /** Deprecated, use [zzww] instead. */
  static const int ZZWW = zzww;
  /** Deprecated, use [zwxx] instead. */
  static const int ZWXX = zwxx;
  /** Deprecated, use [zwxy] instead. */
  static const int ZWXY = zwxy;
  /** Deprecated, use [zwxz] instead. */
  static const int ZWXZ = zwxz;
  /** Deprecated, use [zwxw] instead. */
  static const int ZWXW = zwxw;
  /** Deprecated, use [zwyx] instead. */
  static const int ZWYX = zwyx;
  /** Deprecated, use [zwyy] instead. */
  static const int ZWYY = zwyy;
  /** Deprecated, use [zwyz] instead. */
  static const int ZWYZ = zwyz;
  /** Deprecated, use [zwyw] instead. */
  static const int ZWYW = zwyw;
  /** Deprecated, use [zwzx] instead. */
  static const int ZWZX = zwzx;
  /** Deprecated, use [zwzy] instead. */
  static const int ZWZY = zwzy;
  /** Deprecated, use [zwzz] instead. */
  static const int ZWZZ = zwzz;
  /** Deprecated, use [zwzw] instead. */
  static const int ZWZW = zwzw;
  /** Deprecated, use [zwwx] instead. */
  static const int ZWWX = zwwx;
  /** Deprecated, use [zwwy] instead. */
  static const int ZWWY = zwwy;
  /** Deprecated, use [zwwz] instead. */
  static const int ZWWZ = zwwz;
  /** Deprecated, use [zwww] instead. */
  static const int ZWWW = zwww;
  /** Deprecated, use [wxxx] instead. */
  static const int WXXX = wxxx;
  /** Deprecated, use [wxxy] instead. */
  static const int WXXY = wxxy;
  /** Deprecated, use [wxxz] instead. */
  static const int WXXZ = wxxz;
  /** Deprecated, use [wxxw] instead. */
  static const int WXXW = wxxw;
  /** Deprecated, use [wxyx] instead. */
  static const int WXYX = wxyx;
  /** Deprecated, use [wxyy] instead. */
  static const int WXYY = wxyy;
  /** Deprecated, use [wxyz] instead. */
  static const int WXYZ = wxyz;
  /** Deprecated, use [wxyw] instead. */
  static const int WXYW = wxyw;
  /** Deprecated, use [wxzx] instead. */
  static const int WXZX = wxzx;
  /** Deprecated, use [wxzy] instead. */
  static const int WXZY = wxzy;
  /** Deprecated, use [wxzz] instead. */
  static const int WXZZ = wxzz;
  /** Deprecated, use [wxzw] instead. */
  static const int WXZW = wxzw;
  /** Deprecated, use [wxwx] instead. */
  static const int WXWX = wxwx;
  /** Deprecated, use [wxwy] instead. */
  static const int WXWY = wxwy;
  /** Deprecated, use [wxwz] instead. */
  static const int WXWZ = wxwz;
  /** Deprecated, use [wxww] instead. */
  static const int WXWW = wxww;
  /** Deprecated, use [wyxx] instead. */
  static const int WYXX = wyxx;
  /** Deprecated, use [wyxy] instead. */
  static const int WYXY = wyxy;
  /** Deprecated, use [wyxz] instead. */
  static const int WYXZ = wyxz;
  /** Deprecated, use [wyxw] instead. */
  static const int WYXW = wyxw;
  /** Deprecated, use [wyyx] instead. */
  static const int WYYX = wyyx;
  /** Deprecated, use [wyyy] instead. */
  static const int WYYY = wyyy;
  /** Deprecated, use [wyyz] instead. */
  static const int WYYZ = wyyz;
  /** Deprecated, use [wyyw] instead. */
  static const int WYYW = wyyw;
  /** Deprecated, use [wyzx] instead. */
  static const int WYZX = wyzx;
  /** Deprecated, use [wyzy] instead. */
  static const int WYZY = wyzy;
  /** Deprecated, use [wyzz] instead. */
  static const int WYZZ = wyzz;
  /** Deprecated, use [wyzw] instead. */
  static const int WYZW = wyzw;
  /** Deprecated, use [wywx] instead. */
  static const int WYWX = wywx;
  /** Deprecated, use [wywy] instead. */
  static const int WYWY = wywy;
  /** Deprecated, use [wywz] instead. */
  static const int WYWZ = wywz;
  /** Deprecated, use [wyww] instead. */
  static const int WYWW = wyww;
  /** Deprecated, use [wzxx] instead. */
  static const int WZXX = wzxx;
  /** Deprecated, use [wzxy] instead. */
  static const int WZXY = wzxy;
  /** Deprecated, use [wzxz] instead. */
  static const int WZXZ = wzxz;
  /** Deprecated, use [wzxw] instead. */
  static const int WZXW = wzxw;
  /** Deprecated, use [wzyx] instead. */
  static const int WZYX = wzyx;
  /** Deprecated, use [wzyy] instead. */
  static const int WZYY = wzyy;
  /** Deprecated, use [wzyz] instead. */
  static const int WZYZ = wzyz;
  /** Deprecated, use [wzyw] instead. */
  static const int WZYW = wzyw;
  /** Deprecated, use [wzzx] instead. */
  static const int WZZX = wzzx;
  /** Deprecated, use [wzzy] instead. */
  static const int WZZY = wzzy;
  /** Deprecated, use [wzzz] instead. */
  static const int WZZZ = wzzz;
  /** Deprecated, use [wzzw] instead. */
  static const int WZZW = wzzw;
  /** Deprecated, use [wzwx] instead. */
  static const int WZWX = wzwx;
  /** Deprecated, use [wzwy] instead. */
  static const int WZWY = wzwy;
  /** Deprecated, use [wzwz] instead. */
  static const int WZWZ = wzwz;
  /** Deprecated, use [wzww] instead. */
  static const int WZWW = wzww;
  /** Deprecated, use [wwxx] instead. */
  static const int WWXX = wwxx;
  /** Deprecated, use [wwxy] instead. */
  static const int WWXY = wwxy;
  /** Deprecated, use [wwxz] instead. */
  static const int WWXZ = wwxz;
  /** Deprecated, use [wwxw] instead. */
  static const int WWXW = wwxw;
  /** Deprecated, use [wwyx] instead. */
  static const int WWYX = wwyx;
  /** Deprecated, use [wwyy] instead. */
  static const int WWYY = wwyy;
  /** Deprecated, use [wwyz] instead. */
  static const int WWYZ = wwyz;
  /** Deprecated, use [wwyw] instead. */
  static const int WWYW = wwyw;
  /** Deprecated, use [wwzx] instead. */
  static const int WWZX = wwzx;
  /** Deprecated, use [wwzy] instead. */
  static const int WWZY = wwzy;
  /** Deprecated, use [wwzz] instead. */
  static const int WWZZ = wwzz;
  /** Deprecated, use [wwzw] instead. */
  static const int WWZW = wwzw;
  /** Deprecated, use [wwwx] instead. */
  static const int WWWX = wwwx;
  /** Deprecated, use [wwwy] instead. */
  static const int WWWY = wwwy;
  /** Deprecated, use [wwwz] instead. */
  static const int WWWZ = wwwz;
  /** Deprecated, use [wwww] instead. */
  static const int WWWW = wwww;

  /// Shuffle the lane values. [mask] must be one of the 256 shuffle constants.
  Float32x4 shuffle(int mask);

  /// Shuffle the lane values in [this] and [other]. The returned
  /// Float32x4 will have XY lanes from [this] and ZW lanes from [other].
  /// Uses the same [mask] as [shuffle].
  Float32x4 shuffleMix(Float32x4 other, int mask);

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
}

/**
 * Int32x4 and operations.
 *
 * Int32x4 stores 4 32-bit bit-masks in "lanes".
 * The lanes are "x", "y", "z", and "w" respectively.
 */
abstract class Int32x4 {
  external factory Int32x4(int x, int y, int z, int w);
  external factory Int32x4.bool(bool x, bool y, bool z, bool w);
  external factory Int32x4.fromFloat32x4Bits(Float32x4 x);

  /// The bit-wise or operator.
  Int32x4 operator |(Int32x4 other);

  /// The bit-wise and operator.
  Int32x4 operator &(Int32x4 other);

  /// The bit-wise xor operator.
  Int32x4 operator ^(Int32x4 other);

  /// Addition operator.
  Int32x4 operator +(Int32x4 other);

  /// Subtraction operator.
  Int32x4 operator -(Int32x4 other);

  /// Extract 32-bit mask from x lane.
  int get x;

  /// Extract 32-bit mask from y lane.
  int get y;

  /// Extract 32-bit mask from z lane.
  int get z;

  /// Extract 32-bit mask from w lane.
  int get w;

  /// Extract the top bit from each lane return them in the first 4 bits.
  /// "x" lane is bit 0.
  /// "y" lane is bit 1.
  /// "z" lane is bit 2.
  /// "w" lane is bit 3.
  int get signMask;

  /// Mask passed to [shuffle] or [shuffleMix].
  static const int xxxx = 0x0;
  static const int xxxy = 0x40;
  static const int xxxz = 0x80;
  static const int xxxw = 0xC0;
  static const int xxyx = 0x10;
  static const int xxyy = 0x50;
  static const int xxyz = 0x90;
  static const int xxyw = 0xD0;
  static const int xxzx = 0x20;
  static const int xxzy = 0x60;
  static const int xxzz = 0xA0;
  static const int xxzw = 0xE0;
  static const int xxwx = 0x30;
  static const int xxwy = 0x70;
  static const int xxwz = 0xB0;
  static const int xxww = 0xF0;
  static const int xyxx = 0x4;
  static const int xyxy = 0x44;
  static const int xyxz = 0x84;
  static const int xyxw = 0xC4;
  static const int xyyx = 0x14;
  static const int xyyy = 0x54;
  static const int xyyz = 0x94;
  static const int xyyw = 0xD4;
  static const int xyzx = 0x24;
  static const int xyzy = 0x64;
  static const int xyzz = 0xA4;
  static const int xyzw = 0xE4;
  static const int xywx = 0x34;
  static const int xywy = 0x74;
  static const int xywz = 0xB4;
  static const int xyww = 0xF4;
  static const int xzxx = 0x8;
  static const int xzxy = 0x48;
  static const int xzxz = 0x88;
  static const int xzxw = 0xC8;
  static const int xzyx = 0x18;
  static const int xzyy = 0x58;
  static const int xzyz = 0x98;
  static const int xzyw = 0xD8;
  static const int xzzx = 0x28;
  static const int xzzy = 0x68;
  static const int xzzz = 0xA8;
  static const int xzzw = 0xE8;
  static const int xzwx = 0x38;
  static const int xzwy = 0x78;
  static const int xzwz = 0xB8;
  static const int xzww = 0xF8;
  static const int xwxx = 0xC;
  static const int xwxy = 0x4C;
  static const int xwxz = 0x8C;
  static const int xwxw = 0xCC;
  static const int xwyx = 0x1C;
  static const int xwyy = 0x5C;
  static const int xwyz = 0x9C;
  static const int xwyw = 0xDC;
  static const int xwzx = 0x2C;
  static const int xwzy = 0x6C;
  static const int xwzz = 0xAC;
  static const int xwzw = 0xEC;
  static const int xwwx = 0x3C;
  static const int xwwy = 0x7C;
  static const int xwwz = 0xBC;
  static const int xwww = 0xFC;
  static const int yxxx = 0x1;
  static const int yxxy = 0x41;
  static const int yxxz = 0x81;
  static const int yxxw = 0xC1;
  static const int yxyx = 0x11;
  static const int yxyy = 0x51;
  static const int yxyz = 0x91;
  static const int yxyw = 0xD1;
  static const int yxzx = 0x21;
  static const int yxzy = 0x61;
  static const int yxzz = 0xA1;
  static const int yxzw = 0xE1;
  static const int yxwx = 0x31;
  static const int yxwy = 0x71;
  static const int yxwz = 0xB1;
  static const int yxww = 0xF1;
  static const int yyxx = 0x5;
  static const int yyxy = 0x45;
  static const int yyxz = 0x85;
  static const int yyxw = 0xC5;
  static const int yyyx = 0x15;
  static const int yyyy = 0x55;
  static const int yyyz = 0x95;
  static const int yyyw = 0xD5;
  static const int yyzx = 0x25;
  static const int yyzy = 0x65;
  static const int yyzz = 0xA5;
  static const int yyzw = 0xE5;
  static const int yywx = 0x35;
  static const int yywy = 0x75;
  static const int yywz = 0xB5;
  static const int yyww = 0xF5;
  static const int yzxx = 0x9;
  static const int yzxy = 0x49;
  static const int yzxz = 0x89;
  static const int yzxw = 0xC9;
  static const int yzyx = 0x19;
  static const int yzyy = 0x59;
  static const int yzyz = 0x99;
  static const int yzyw = 0xD9;
  static const int yzzx = 0x29;
  static const int yzzy = 0x69;
  static const int yzzz = 0xA9;
  static const int yzzw = 0xE9;
  static const int yzwx = 0x39;
  static const int yzwy = 0x79;
  static const int yzwz = 0xB9;
  static const int yzww = 0xF9;
  static const int ywxx = 0xD;
  static const int ywxy = 0x4D;
  static const int ywxz = 0x8D;
  static const int ywxw = 0xCD;
  static const int ywyx = 0x1D;
  static const int ywyy = 0x5D;
  static const int ywyz = 0x9D;
  static const int ywyw = 0xDD;
  static const int ywzx = 0x2D;
  static const int ywzy = 0x6D;
  static const int ywzz = 0xAD;
  static const int ywzw = 0xED;
  static const int ywwx = 0x3D;
  static const int ywwy = 0x7D;
  static const int ywwz = 0xBD;
  static const int ywww = 0xFD;
  static const int zxxx = 0x2;
  static const int zxxy = 0x42;
  static const int zxxz = 0x82;
  static const int zxxw = 0xC2;
  static const int zxyx = 0x12;
  static const int zxyy = 0x52;
  static const int zxyz = 0x92;
  static const int zxyw = 0xD2;
  static const int zxzx = 0x22;
  static const int zxzy = 0x62;
  static const int zxzz = 0xA2;
  static const int zxzw = 0xE2;
  static const int zxwx = 0x32;
  static const int zxwy = 0x72;
  static const int zxwz = 0xB2;
  static const int zxww = 0xF2;
  static const int zyxx = 0x6;
  static const int zyxy = 0x46;
  static const int zyxz = 0x86;
  static const int zyxw = 0xC6;
  static const int zyyx = 0x16;
  static const int zyyy = 0x56;
  static const int zyyz = 0x96;
  static const int zyyw = 0xD6;
  static const int zyzx = 0x26;
  static const int zyzy = 0x66;
  static const int zyzz = 0xA6;
  static const int zyzw = 0xE6;
  static const int zywx = 0x36;
  static const int zywy = 0x76;
  static const int zywz = 0xB6;
  static const int zyww = 0xF6;
  static const int zzxx = 0xA;
  static const int zzxy = 0x4A;
  static const int zzxz = 0x8A;
  static const int zzxw = 0xCA;
  static const int zzyx = 0x1A;
  static const int zzyy = 0x5A;
  static const int zzyz = 0x9A;
  static const int zzyw = 0xDA;
  static const int zzzx = 0x2A;
  static const int zzzy = 0x6A;
  static const int zzzz = 0xAA;
  static const int zzzw = 0xEA;
  static const int zzwx = 0x3A;
  static const int zzwy = 0x7A;
  static const int zzwz = 0xBA;
  static const int zzww = 0xFA;
  static const int zwxx = 0xE;
  static const int zwxy = 0x4E;
  static const int zwxz = 0x8E;
  static const int zwxw = 0xCE;
  static const int zwyx = 0x1E;
  static const int zwyy = 0x5E;
  static const int zwyz = 0x9E;
  static const int zwyw = 0xDE;
  static const int zwzx = 0x2E;
  static const int zwzy = 0x6E;
  static const int zwzz = 0xAE;
  static const int zwzw = 0xEE;
  static const int zwwx = 0x3E;
  static const int zwwy = 0x7E;
  static const int zwwz = 0xBE;
  static const int zwww = 0xFE;
  static const int wxxx = 0x3;
  static const int wxxy = 0x43;
  static const int wxxz = 0x83;
  static const int wxxw = 0xC3;
  static const int wxyx = 0x13;
  static const int wxyy = 0x53;
  static const int wxyz = 0x93;
  static const int wxyw = 0xD3;
  static const int wxzx = 0x23;
  static const int wxzy = 0x63;
  static const int wxzz = 0xA3;
  static const int wxzw = 0xE3;
  static const int wxwx = 0x33;
  static const int wxwy = 0x73;
  static const int wxwz = 0xB3;
  static const int wxww = 0xF3;
  static const int wyxx = 0x7;
  static const int wyxy = 0x47;
  static const int wyxz = 0x87;
  static const int wyxw = 0xC7;
  static const int wyyx = 0x17;
  static const int wyyy = 0x57;
  static const int wyyz = 0x97;
  static const int wyyw = 0xD7;
  static const int wyzx = 0x27;
  static const int wyzy = 0x67;
  static const int wyzz = 0xA7;
  static const int wyzw = 0xE7;
  static const int wywx = 0x37;
  static const int wywy = 0x77;
  static const int wywz = 0xB7;
  static const int wyww = 0xF7;
  static const int wzxx = 0xB;
  static const int wzxy = 0x4B;
  static const int wzxz = 0x8B;
  static const int wzxw = 0xCB;
  static const int wzyx = 0x1B;
  static const int wzyy = 0x5B;
  static const int wzyz = 0x9B;
  static const int wzyw = 0xDB;
  static const int wzzx = 0x2B;
  static const int wzzy = 0x6B;
  static const int wzzz = 0xAB;
  static const int wzzw = 0xEB;
  static const int wzwx = 0x3B;
  static const int wzwy = 0x7B;
  static const int wzwz = 0xBB;
  static const int wzww = 0xFB;
  static const int wwxx = 0xF;
  static const int wwxy = 0x4F;
  static const int wwxz = 0x8F;
  static const int wwxw = 0xCF;
  static const int wwyx = 0x1F;
  static const int wwyy = 0x5F;
  static const int wwyz = 0x9F;
  static const int wwyw = 0xDF;
  static const int wwzx = 0x2F;
  static const int wwzy = 0x6F;
  static const int wwzz = 0xAF;
  static const int wwzw = 0xEF;
  static const int wwwx = 0x3F;
  static const int wwwy = 0x7F;
  static const int wwwz = 0xBF;
  static const int wwww = 0xFF;
  /** Deprecated, use [xxxx] instead. */
  static const int XXXX = xxxx;
  /** Deprecated, use [xxxy] instead. */
  static const int XXXY = xxxy;
  /** Deprecated, use [xxxz] instead. */
  static const int XXXZ = xxxz;
  /** Deprecated, use [xxxw] instead. */
  static const int XXXW = xxxw;
  /** Deprecated, use [xxyx] instead. */
  static const int XXYX = xxyx;
  /** Deprecated, use [xxyy] instead. */
  static const int XXYY = xxyy;
  /** Deprecated, use [xxyz] instead. */
  static const int XXYZ = xxyz;
  /** Deprecated, use [xxyw] instead. */
  static const int XXYW = xxyw;
  /** Deprecated, use [xxzx] instead. */
  static const int XXZX = xxzx;
  /** Deprecated, use [xxzy] instead. */
  static const int XXZY = xxzy;
  /** Deprecated, use [xxzz] instead. */
  static const int XXZZ = xxzz;
  /** Deprecated, use [xxzw] instead. */
  static const int XXZW = xxzw;
  /** Deprecated, use [xxwx] instead. */
  static const int XXWX = xxwx;
  /** Deprecated, use [xxwy] instead. */
  static const int XXWY = xxwy;
  /** Deprecated, use [xxwz] instead. */
  static const int XXWZ = xxwz;
  /** Deprecated, use [xxww] instead. */
  static const int XXWW = xxww;
  /** Deprecated, use [xyxx] instead. */
  static const int XYXX = xyxx;
  /** Deprecated, use [xyxy] instead. */
  static const int XYXY = xyxy;
  /** Deprecated, use [xyxz] instead. */
  static const int XYXZ = xyxz;
  /** Deprecated, use [xyxw] instead. */
  static const int XYXW = xyxw;
  /** Deprecated, use [xyyx] instead. */
  static const int XYYX = xyyx;
  /** Deprecated, use [xyyy] instead. */
  static const int XYYY = xyyy;
  /** Deprecated, use [xyyz] instead. */
  static const int XYYZ = xyyz;
  /** Deprecated, use [xyyw] instead. */
  static const int XYYW = xyyw;
  /** Deprecated, use [xyzx] instead. */
  static const int XYZX = xyzx;
  /** Deprecated, use [xyzy] instead. */
  static const int XYZY = xyzy;
  /** Deprecated, use [xyzz] instead. */
  static const int XYZZ = xyzz;
  /** Deprecated, use [xyzw] instead. */
  static const int XYZW = xyzw;
  /** Deprecated, use [xywx] instead. */
  static const int XYWX = xywx;
  /** Deprecated, use [xywy] instead. */
  static const int XYWY = xywy;
  /** Deprecated, use [xywz] instead. */
  static const int XYWZ = xywz;
  /** Deprecated, use [xyww] instead. */
  static const int XYWW = xyww;
  /** Deprecated, use [xzxx] instead. */
  static const int XZXX = xzxx;
  /** Deprecated, use [xzxy] instead. */
  static const int XZXY = xzxy;
  /** Deprecated, use [xzxz] instead. */
  static const int XZXZ = xzxz;
  /** Deprecated, use [xzxw] instead. */
  static const int XZXW = xzxw;
  /** Deprecated, use [xzyx] instead. */
  static const int XZYX = xzyx;
  /** Deprecated, use [xzyy] instead. */
  static const int XZYY = xzyy;
  /** Deprecated, use [xzyz] instead. */
  static const int XZYZ = xzyz;
  /** Deprecated, use [xzyw] instead. */
  static const int XZYW = xzyw;
  /** Deprecated, use [xzzx] instead. */
  static const int XZZX = xzzx;
  /** Deprecated, use [xzzy] instead. */
  static const int XZZY = xzzy;
  /** Deprecated, use [xzzz] instead. */
  static const int XZZZ = xzzz;
  /** Deprecated, use [xzzw] instead. */
  static const int XZZW = xzzw;
  /** Deprecated, use [xzwx] instead. */
  static const int XZWX = xzwx;
  /** Deprecated, use [xzwy] instead. */
  static const int XZWY = xzwy;
  /** Deprecated, use [xzwz] instead. */
  static const int XZWZ = xzwz;
  /** Deprecated, use [xzww] instead. */
  static const int XZWW = xzww;
  /** Deprecated, use [xwxx] instead. */
  static const int XWXX = xwxx;
  /** Deprecated, use [xwxy] instead. */
  static const int XWXY = xwxy;
  /** Deprecated, use [xwxz] instead. */
  static const int XWXZ = xwxz;
  /** Deprecated, use [xwxw] instead. */
  static const int XWXW = xwxw;
  /** Deprecated, use [xwyx] instead. */
  static const int XWYX = xwyx;
  /** Deprecated, use [xwyy] instead. */
  static const int XWYY = xwyy;
  /** Deprecated, use [xwyz] instead. */
  static const int XWYZ = xwyz;
  /** Deprecated, use [xwyw] instead. */
  static const int XWYW = xwyw;
  /** Deprecated, use [xwzx] instead. */
  static const int XWZX = xwzx;
  /** Deprecated, use [xwzy] instead. */
  static const int XWZY = xwzy;
  /** Deprecated, use [xwzz] instead. */
  static const int XWZZ = xwzz;
  /** Deprecated, use [xwzw] instead. */
  static const int XWZW = xwzw;
  /** Deprecated, use [xwwx] instead. */
  static const int XWWX = xwwx;
  /** Deprecated, use [xwwy] instead. */
  static const int XWWY = xwwy;
  /** Deprecated, use [xwwz] instead. */
  static const int XWWZ = xwwz;
  /** Deprecated, use [xwww] instead. */
  static const int XWWW = xwww;
  /** Deprecated, use [yxxx] instead. */
  static const int YXXX = yxxx;
  /** Deprecated, use [yxxy] instead. */
  static const int YXXY = yxxy;
  /** Deprecated, use [yxxz] instead. */
  static const int YXXZ = yxxz;
  /** Deprecated, use [yxxw] instead. */
  static const int YXXW = yxxw;
  /** Deprecated, use [yxyx] instead. */
  static const int YXYX = yxyx;
  /** Deprecated, use [yxyy] instead. */
  static const int YXYY = yxyy;
  /** Deprecated, use [yxyz] instead. */
  static const int YXYZ = yxyz;
  /** Deprecated, use [yxyw] instead. */
  static const int YXYW = yxyw;
  /** Deprecated, use [yxzx] instead. */
  static const int YXZX = yxzx;
  /** Deprecated, use [yxzy] instead. */
  static const int YXZY = yxzy;
  /** Deprecated, use [yxzz] instead. */
  static const int YXZZ = yxzz;
  /** Deprecated, use [yxzw] instead. */
  static const int YXZW = yxzw;
  /** Deprecated, use [yxwx] instead. */
  static const int YXWX = yxwx;
  /** Deprecated, use [yxwy] instead. */
  static const int YXWY = yxwy;
  /** Deprecated, use [yxwz] instead. */
  static const int YXWZ = yxwz;
  /** Deprecated, use [yxww] instead. */
  static const int YXWW = yxww;
  /** Deprecated, use [yyxx] instead. */
  static const int YYXX = yyxx;
  /** Deprecated, use [yyxy] instead. */
  static const int YYXY = yyxy;
  /** Deprecated, use [yyxz] instead. */
  static const int YYXZ = yyxz;
  /** Deprecated, use [yyxw] instead. */
  static const int YYXW = yyxw;
  /** Deprecated, use [yyyx] instead. */
  static const int YYYX = yyyx;
  /** Deprecated, use [yyyy] instead. */
  static const int YYYY = yyyy;
  /** Deprecated, use [yyyz] instead. */
  static const int YYYZ = yyyz;
  /** Deprecated, use [yyyw] instead. */
  static const int YYYW = yyyw;
  /** Deprecated, use [yyzx] instead. */
  static const int YYZX = yyzx;
  /** Deprecated, use [yyzy] instead. */
  static const int YYZY = yyzy;
  /** Deprecated, use [yyzz] instead. */
  static const int YYZZ = yyzz;
  /** Deprecated, use [yyzw] instead. */
  static const int YYZW = yyzw;
  /** Deprecated, use [yywx] instead. */
  static const int YYWX = yywx;
  /** Deprecated, use [yywy] instead. */
  static const int YYWY = yywy;
  /** Deprecated, use [yywz] instead. */
  static const int YYWZ = yywz;
  /** Deprecated, use [yyww] instead. */
  static const int YYWW = yyww;
  /** Deprecated, use [yzxx] instead. */
  static const int YZXX = yzxx;
  /** Deprecated, use [yzxy] instead. */
  static const int YZXY = yzxy;
  /** Deprecated, use [yzxz] instead. */
  static const int YZXZ = yzxz;
  /** Deprecated, use [yzxw] instead. */
  static const int YZXW = yzxw;
  /** Deprecated, use [yzyx] instead. */
  static const int YZYX = yzyx;
  /** Deprecated, use [yzyy] instead. */
  static const int YZYY = yzyy;
  /** Deprecated, use [yzyz] instead. */
  static const int YZYZ = yzyz;
  /** Deprecated, use [yzyw] instead. */
  static const int YZYW = yzyw;
  /** Deprecated, use [yzzx] instead. */
  static const int YZZX = yzzx;
  /** Deprecated, use [yzzy] instead. */
  static const int YZZY = yzzy;
  /** Deprecated, use [yzzz] instead. */
  static const int YZZZ = yzzz;
  /** Deprecated, use [yzzw] instead. */
  static const int YZZW = yzzw;
  /** Deprecated, use [yzwx] instead. */
  static const int YZWX = yzwx;
  /** Deprecated, use [yzwy] instead. */
  static const int YZWY = yzwy;
  /** Deprecated, use [yzwz] instead. */
  static const int YZWZ = yzwz;
  /** Deprecated, use [yzww] instead. */
  static const int YZWW = yzww;
  /** Deprecated, use [ywxx] instead. */
  static const int YWXX = ywxx;
  /** Deprecated, use [ywxy] instead. */
  static const int YWXY = ywxy;
  /** Deprecated, use [ywxz] instead. */
  static const int YWXZ = ywxz;
  /** Deprecated, use [ywxw] instead. */
  static const int YWXW = ywxw;
  /** Deprecated, use [ywyx] instead. */
  static const int YWYX = ywyx;
  /** Deprecated, use [ywyy] instead. */
  static const int YWYY = ywyy;
  /** Deprecated, use [ywyz] instead. */
  static const int YWYZ = ywyz;
  /** Deprecated, use [ywyw] instead. */
  static const int YWYW = ywyw;
  /** Deprecated, use [ywzx] instead. */
  static const int YWZX = ywzx;
  /** Deprecated, use [ywzy] instead. */
  static const int YWZY = ywzy;
  /** Deprecated, use [ywzz] instead. */
  static const int YWZZ = ywzz;
  /** Deprecated, use [ywzw] instead. */
  static const int YWZW = ywzw;
  /** Deprecated, use [ywwx] instead. */
  static const int YWWX = ywwx;
  /** Deprecated, use [ywwy] instead. */
  static const int YWWY = ywwy;
  /** Deprecated, use [ywwz] instead. */
  static const int YWWZ = ywwz;
  /** Deprecated, use [ywww] instead. */
  static const int YWWW = ywww;
  /** Deprecated, use [zxxx] instead. */
  static const int ZXXX = zxxx;
  /** Deprecated, use [zxxy] instead. */
  static const int ZXXY = zxxy;
  /** Deprecated, use [zxxz] instead. */
  static const int ZXXZ = zxxz;
  /** Deprecated, use [zxxw] instead. */
  static const int ZXXW = zxxw;
  /** Deprecated, use [zxyx] instead. */
  static const int ZXYX = zxyx;
  /** Deprecated, use [zxyy] instead. */
  static const int ZXYY = zxyy;
  /** Deprecated, use [zxyz] instead. */
  static const int ZXYZ = zxyz;
  /** Deprecated, use [zxyw] instead. */
  static const int ZXYW = zxyw;
  /** Deprecated, use [zxzx] instead. */
  static const int ZXZX = zxzx;
  /** Deprecated, use [zxzy] instead. */
  static const int ZXZY = zxzy;
  /** Deprecated, use [zxzz] instead. */
  static const int ZXZZ = zxzz;
  /** Deprecated, use [zxzw] instead. */
  static const int ZXZW = zxzw;
  /** Deprecated, use [zxwx] instead. */
  static const int ZXWX = zxwx;
  /** Deprecated, use [zxwy] instead. */
  static const int ZXWY = zxwy;
  /** Deprecated, use [zxwz] instead. */
  static const int ZXWZ = zxwz;
  /** Deprecated, use [zxww] instead. */
  static const int ZXWW = zxww;
  /** Deprecated, use [zyxx] instead. */
  static const int ZYXX = zyxx;
  /** Deprecated, use [zyxy] instead. */
  static const int ZYXY = zyxy;
  /** Deprecated, use [zyxz] instead. */
  static const int ZYXZ = zyxz;
  /** Deprecated, use [zyxw] instead. */
  static const int ZYXW = zyxw;
  /** Deprecated, use [zyyx] instead. */
  static const int ZYYX = zyyx;
  /** Deprecated, use [zyyy] instead. */
  static const int ZYYY = zyyy;
  /** Deprecated, use [zyyz] instead. */
  static const int ZYYZ = zyyz;
  /** Deprecated, use [zyyw] instead. */
  static const int ZYYW = zyyw;
  /** Deprecated, use [zyzx] instead. */
  static const int ZYZX = zyzx;
  /** Deprecated, use [zyzy] instead. */
  static const int ZYZY = zyzy;
  /** Deprecated, use [zyzz] instead. */
  static const int ZYZZ = zyzz;
  /** Deprecated, use [zyzw] instead. */
  static const int ZYZW = zyzw;
  /** Deprecated, use [zywx] instead. */
  static const int ZYWX = zywx;
  /** Deprecated, use [zywy] instead. */
  static const int ZYWY = zywy;
  /** Deprecated, use [zywz] instead. */
  static const int ZYWZ = zywz;
  /** Deprecated, use [zyww] instead. */
  static const int ZYWW = zyww;
  /** Deprecated, use [zzxx] instead. */
  static const int ZZXX = zzxx;
  /** Deprecated, use [zzxy] instead. */
  static const int ZZXY = zzxy;
  /** Deprecated, use [zzxz] instead. */
  static const int ZZXZ = zzxz;
  /** Deprecated, use [zzxw] instead. */
  static const int ZZXW = zzxw;
  /** Deprecated, use [zzyx] instead. */
  static const int ZZYX = zzyx;
  /** Deprecated, use [zzyy] instead. */
  static const int ZZYY = zzyy;
  /** Deprecated, use [zzyz] instead. */
  static const int ZZYZ = zzyz;
  /** Deprecated, use [zzyw] instead. */
  static const int ZZYW = zzyw;
  /** Deprecated, use [zzzx] instead. */
  static const int ZZZX = zzzx;
  /** Deprecated, use [zzzy] instead. */
  static const int ZZZY = zzzy;
  /** Deprecated, use [zzzz] instead. */
  static const int ZZZZ = zzzz;
  /** Deprecated, use [zzzw] instead. */
  static const int ZZZW = zzzw;
  /** Deprecated, use [zzwx] instead. */
  static const int ZZWX = zzwx;
  /** Deprecated, use [zzwy] instead. */
  static const int ZZWY = zzwy;
  /** Deprecated, use [zzwz] instead. */
  static const int ZZWZ = zzwz;
  /** Deprecated, use [zzww] instead. */
  static const int ZZWW = zzww;
  /** Deprecated, use [zwxx] instead. */
  static const int ZWXX = zwxx;
  /** Deprecated, use [zwxy] instead. */
  static const int ZWXY = zwxy;
  /** Deprecated, use [zwxz] instead. */
  static const int ZWXZ = zwxz;
  /** Deprecated, use [zwxw] instead. */
  static const int ZWXW = zwxw;
  /** Deprecated, use [zwyx] instead. */
  static const int ZWYX = zwyx;
  /** Deprecated, use [zwyy] instead. */
  static const int ZWYY = zwyy;
  /** Deprecated, use [zwyz] instead. */
  static const int ZWYZ = zwyz;
  /** Deprecated, use [zwyw] instead. */
  static const int ZWYW = zwyw;
  /** Deprecated, use [zwzx] instead. */
  static const int ZWZX = zwzx;
  /** Deprecated, use [zwzy] instead. */
  static const int ZWZY = zwzy;
  /** Deprecated, use [zwzz] instead. */
  static const int ZWZZ = zwzz;
  /** Deprecated, use [zwzw] instead. */
  static const int ZWZW = zwzw;
  /** Deprecated, use [zwwx] instead. */
  static const int ZWWX = zwwx;
  /** Deprecated, use [zwwy] instead. */
  static const int ZWWY = zwwy;
  /** Deprecated, use [zwwz] instead. */
  static const int ZWWZ = zwwz;
  /** Deprecated, use [zwww] instead. */
  static const int ZWWW = zwww;
  /** Deprecated, use [wxxx] instead. */
  static const int WXXX = wxxx;
  /** Deprecated, use [wxxy] instead. */
  static const int WXXY = wxxy;
  /** Deprecated, use [wxxz] instead. */
  static const int WXXZ = wxxz;
  /** Deprecated, use [wxxw] instead. */
  static const int WXXW = wxxw;
  /** Deprecated, use [wxyx] instead. */
  static const int WXYX = wxyx;
  /** Deprecated, use [wxyy] instead. */
  static const int WXYY = wxyy;
  /** Deprecated, use [wxyz] instead. */
  static const int WXYZ = wxyz;
  /** Deprecated, use [wxyw] instead. */
  static const int WXYW = wxyw;
  /** Deprecated, use [wxzx] instead. */
  static const int WXZX = wxzx;
  /** Deprecated, use [wxzy] instead. */
  static const int WXZY = wxzy;
  /** Deprecated, use [wxzz] instead. */
  static const int WXZZ = wxzz;
  /** Deprecated, use [wxzw] instead. */
  static const int WXZW = wxzw;
  /** Deprecated, use [wxwx] instead. */
  static const int WXWX = wxwx;
  /** Deprecated, use [wxwy] instead. */
  static const int WXWY = wxwy;
  /** Deprecated, use [wxwz] instead. */
  static const int WXWZ = wxwz;
  /** Deprecated, use [wxww] instead. */
  static const int WXWW = wxww;
  /** Deprecated, use [wyxx] instead. */
  static const int WYXX = wyxx;
  /** Deprecated, use [wyxy] instead. */
  static const int WYXY = wyxy;
  /** Deprecated, use [wyxz] instead. */
  static const int WYXZ = wyxz;
  /** Deprecated, use [wyxw] instead. */
  static const int WYXW = wyxw;
  /** Deprecated, use [wyyx] instead. */
  static const int WYYX = wyyx;
  /** Deprecated, use [wyyy] instead. */
  static const int WYYY = wyyy;
  /** Deprecated, use [wyyz] instead. */
  static const int WYYZ = wyyz;
  /** Deprecated, use [wyyw] instead. */
  static const int WYYW = wyyw;
  /** Deprecated, use [wyzx] instead. */
  static const int WYZX = wyzx;
  /** Deprecated, use [wyzy] instead. */
  static const int WYZY = wyzy;
  /** Deprecated, use [wyzz] instead. */
  static const int WYZZ = wyzz;
  /** Deprecated, use [wyzw] instead. */
  static const int WYZW = wyzw;
  /** Deprecated, use [wywx] instead. */
  static const int WYWX = wywx;
  /** Deprecated, use [wywy] instead. */
  static const int WYWY = wywy;
  /** Deprecated, use [wywz] instead. */
  static const int WYWZ = wywz;
  /** Deprecated, use [wyww] instead. */
  static const int WYWW = wyww;
  /** Deprecated, use [wzxx] instead. */
  static const int WZXX = wzxx;
  /** Deprecated, use [wzxy] instead. */
  static const int WZXY = wzxy;
  /** Deprecated, use [wzxz] instead. */
  static const int WZXZ = wzxz;
  /** Deprecated, use [wzxw] instead. */
  static const int WZXW = wzxw;
  /** Deprecated, use [wzyx] instead. */
  static const int WZYX = wzyx;
  /** Deprecated, use [wzyy] instead. */
  static const int WZYY = wzyy;
  /** Deprecated, use [wzyz] instead. */
  static const int WZYZ = wzyz;
  /** Deprecated, use [wzyw] instead. */
  static const int WZYW = wzyw;
  /** Deprecated, use [wzzx] instead. */
  static const int WZZX = wzzx;
  /** Deprecated, use [wzzy] instead. */
  static const int WZZY = wzzy;
  /** Deprecated, use [wzzz] instead. */
  static const int WZZZ = wzzz;
  /** Deprecated, use [wzzw] instead. */
  static const int WZZW = wzzw;
  /** Deprecated, use [wzwx] instead. */
  static const int WZWX = wzwx;
  /** Deprecated, use [wzwy] instead. */
  static const int WZWY = wzwy;
  /** Deprecated, use [wzwz] instead. */
  static const int WZWZ = wzwz;
  /** Deprecated, use [wzww] instead. */
  static const int WZWW = wzww;
  /** Deprecated, use [wwxx] instead. */
  static const int WWXX = wwxx;
  /** Deprecated, use [wwxy] instead. */
  static const int WWXY = wwxy;
  /** Deprecated, use [wwxz] instead. */
  static const int WWXZ = wwxz;
  /** Deprecated, use [wwxw] instead. */
  static const int WWXW = wwxw;
  /** Deprecated, use [wwyx] instead. */
  static const int WWYX = wwyx;
  /** Deprecated, use [wwyy] instead. */
  static const int WWYY = wwyy;
  /** Deprecated, use [wwyz] instead. */
  static const int WWYZ = wwyz;
  /** Deprecated, use [wwyw] instead. */
  static const int WWYW = wwyw;
  /** Deprecated, use [wwzx] instead. */
  static const int WWZX = wwzx;
  /** Deprecated, use [wwzy] instead. */
  static const int WWZY = wwzy;
  /** Deprecated, use [wwzz] instead. */
  static const int WWZZ = wwzz;
  /** Deprecated, use [wwzw] instead. */
  static const int WWZW = wwzw;
  /** Deprecated, use [wwwx] instead. */
  static const int WWWX = wwwx;
  /** Deprecated, use [wwwy] instead. */
  static const int WWWY = wwwy;
  /** Deprecated, use [wwwz] instead. */
  static const int WWWZ = wwwz;
  /** Deprecated, use [wwww] instead. */
  static const int WWWW = wwww;

  /// Shuffle the lane values. [mask] must be one of the 256 shuffle constants.
  Int32x4 shuffle(int mask);

  /// Shuffle the lane values in [this] and [other]. The returned
  /// Int32x4 will have XY lanes from [this] and ZW lanes from [other].
  /// Uses the same [mask] as [shuffle].
  Int32x4 shuffleMix(Int32x4 other, int mask);

  /// Returns a new [Int32x4] copied from [this] with a new x value.
  Int32x4 withX(int x);

  /// Returns a new [Int32x4] copied from [this] with a new y value.
  Int32x4 withY(int y);

  /// Returns a new [Int32x4] copied from [this] with a new z value.
  Int32x4 withZ(int z);

  /// Returns a new [Int32x4] copied from [this] with a new w value.
  Int32x4 withW(int w);

  /// Extracted x value. Returns false for 0, true for any other value.
  bool get flagX;

  /// Extracted y value. Returns false for 0, true for any other value.
  bool get flagY;

  /// Extracted z value. Returns false for 0, true for any other value.
  bool get flagZ;

  /// Extracted w value. Returns false for 0, true for any other value.
  bool get flagW;

  /// Returns a new [Int32x4] copied from [this] with a new x value.
  Int32x4 withFlagX(bool x);

  /// Returns a new [Int32x4] copied from [this] with a new y value.
  Int32x4 withFlagY(bool y);

  /// Returns a new [Int32x4] copied from [this] with a new z value.
  Int32x4 withFlagZ(bool z);

  /// Returns a new [Int32x4] copied from [this] with a new w value.
  Int32x4 withFlagW(bool w);

  /// Merge [trueValue] and [falseValue] based on [this]' bit mask:
  /// Select bit from [trueValue] when bit in [this] is on.
  /// Select bit from [falseValue] when bit in [this] is off.
  Float32x4 select(Float32x4 trueValue, Float32x4 falseValue);
}

/**
 * Float64x2 immutable value type and operations.
 *
 * Float64x2 stores 2 64-bit floating point values in "lanes".
 * The lanes are "x" and "y" respectively.
 */
abstract class Float64x2 {
  external factory Float64x2(double x, double y);
  external factory Float64x2.splat(double v);
  external factory Float64x2.zero();

  /// Uses the "x" and "y" lanes from [v].
  external factory Float64x2.fromFloat32x4(Float32x4 v);

  /// Addition operator.
  Float64x2 operator +(Float64x2 other);

  /// Negate operator.
  Float64x2 operator -();

  /// Subtraction operator.
  Float64x2 operator -(Float64x2 other);

  /// Multiplication operator.
  Float64x2 operator *(Float64x2 other);

  /// Division operator.
  Float64x2 operator /(Float64x2 other);

  /// Returns a copy of [this] each lane being scaled by [s].
  /// Equivalent to this * new Float64x2.splat(s)
  Float64x2 scale(double s);

  /// Returns the lane-wise absolute value of this [Float64x2].
  Float64x2 abs();

  /// Lane-wise clamp [this] to be in the range [lowerLimit]-[upperLimit].
  Float64x2 clamp(Float64x2 lowerLimit, Float64x2 upperLimit);

  /// Extracted x value.
  double get x;

  /// Extracted y value.
  double get y;

  /// Extract the sign bits from each lane return them in the first 2 bits.
  /// "x" lane is bit 0.
  /// "y" lane is bit 1.
  int get signMask;

  /// Returns a new [Float64x2] copied from [this] with a new x value.
  Float64x2 withX(double x);

  /// Returns a new [Float64x2] copied from [this] with a new y value.
  Float64x2 withY(double y);

  /// Returns the lane-wise minimum value in [this] or [other].
  Float64x2 min(Float64x2 other);

  /// Returns the lane-wise maximum value in [this] or [other].
  Float64x2 max(Float64x2 other);

  /// Returns the lane-wise square root of [this].
  Float64x2 sqrt();
}
