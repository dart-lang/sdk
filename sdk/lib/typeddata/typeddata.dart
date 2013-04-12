// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.typeddata;

import 'dart:collection';
import 'dart:_collection-dev';

/**
 * A sequence of bytes underlying a typed data object.
 * Used to process large quantities of binary or numerical data
 * more efficiently using a typed view.
 */
abstract class ByteBuffer {
  /**
   * Returns the length of this byte buffer, in bytes.
   */
  int get lengthInBytes;

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


/**
 * A fixed-length, random-access sequence of bytes that also provides random
 * and unaligned access to the fixed-width integers and floating point
 * numbers represented by those bytes.
 * ByteData may be used to pack and unpack data from external sources
 * (such as networks or files systems), and to process large quantities
 * of numerical data more efficiently than would be possible
 * with ordinary [List] implementations. ByteData can save space, by
 * eliminating the need for object headers, and time, by eliminating the
 * need for data copies. Finally, ByteData may be used to intentionally
 * reinterpret the bytes representing one arithmetic type as another.
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
   * whose elements are initially zero.
   */
  external factory ByteData(int length);

  /**
   * Creates an [ByteData] _view_ of the specified region in the specified
   * byte buffer. Changes in the [ByteData] will be visible in the byte
   * buffer and vice versa. If the [offsetInBytes] index of the region is not
   * specified, it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to null, which indicates
   * that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   */
  external factory ByteData.view(ByteBuffer buffer,
                                 [int offsetInBytes = 0, int length]);

  /**
   * Returns the (possibly negative) integer represented by the byte at the
   * specified [byteOffset] in this object, in two's complement binary
   * representation. The return value will be between -128 and 127, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  int getInt8(int byteOffset);

  /**
   * Sets the byte at the specified [byteOffset] in this object to the
   * two's complement binary representation of the specified [value], which
   * must fit in a single byte. In other words, [value] must be between
   * -128 and 127, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  void setInt8(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the byte at the specified
   * [byteOffset] in this object, in unsigned binary form. The
   * return value will be between 0 and 255, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  int getUint8(int byteOffset);

  /**
   * Sets the byte at the specified [byteOffset] in this object to the
   * unsigned binary representation of the specified [value], which must fit
   * in a single byte. in other words, [value] must be between 0 and 255,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative,
   * or greater than or equal to the length of this object.
   */
  void setUint8(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the two bytes at
   * the specified [byteOffset] in this object, in two's complement binary
   * form.
   * The return value will be between 2<sup>15</sup> and 2<sup>15</sup> - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  int getInt16(int byteOffset);

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in two bytes. In other words, [value] must lie
   * between 2<sup>15</sup> and 2<sup>15</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  void setInt16(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the two bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   * The return value will be between 0 and  2<sup>16</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  int getUint16(int byteOffset);

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in two bytes. in other words, [value] must be between
   * 0 and 2<sup>16</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  void setUint16(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the four bytes at
   * the specified [byteOffset] in this object, in two's complement binary
   * form.
   * The return value will be between 2<sup>31</sup> and 2<sup>31</sup> - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  int getInt32(int byteOffset);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in four bytes. In other words, [value] must lie
   * between 2<sup>31</sup> and 2<sup>31</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setInt32(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the four bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   * The return value will be between 0 and  2<sup>32</sup> - 1, inclusive.
   *
   */
  int getUint32(int byteOffset);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in four bytes. in other words, [value] must be between
   * 0 and 2<sup>32</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setUint32(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the eight bytes at
   * the specified [byteOffset] in this object, in two's complement binary
   * form.
   * The return value will be between 2<sup>63</sup> and 2<sup>63</sup> - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  int getInt64(int byteOffset);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in eight bytes. In other words, [value] must lie
   * between 2<sup>63</sup> and 2<sup>63</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setInt64(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the eight bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   * The return value will be between 0 and  2<sup>64</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  int getUint64(int byteOffset);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in eight bytes. in other words, [value] must be between
   * 0 and 2<sup>64</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setUint64(int byteOffset, int value);

  /**
   * Returns the floating point number represented by the four bytes at
   * the specified [byteOffset] in this object, in IEEE 754
   * single-precision binary floating-point format (binary32).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  double getFloat32(int byteOffset);

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
  void setFloat32(int byteOffset, double value);

  /**
   * Returns the floating point number represented by the eight bytes at
   * the specified [byteOffset] in this object, in IEEE 754
   * double-precision binary floating-point format (binary64).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  double getFloat64(int byteOffset);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * object to the IEEE 754 double-precision binary floating-point
   * (binary64) representation of the specified [value].
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setFloat64(int byteOffset, double value);
}


/**
 * A fixed-length list of 8-bit signed integers.
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Int8List implements List<int>, TypedData {
  /**
   * Creates an [Int8List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int8List(int length);

  /**
   * Creates a [Int8List] with the same size as the [elements] list
   * and copies over the elements.
   */
  external factory Int8List.fromList(List<int> elements);

  /**
   * Creates an [Int8List] _view_ of the specified region in the specified
   * byte buffer. Changes in the [Int8List] will be visible in the byte
   * buffer and vice versa. If the [offsetInBytes] index of the region is not
   * specified, it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to null, which indicates
   * that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   */
  external factory Int8List.view(ByteBuffer buffer,
                                 [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 1;
}


/**
 * A fixed-length list of 8-bit unsigned integers.
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Uint8List implements List<int>, TypedData {
  /**
   * Creates a [Uint8List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Uint8List(int length);

  /**
   * Creates a [Uint8List] with the same size as the [elements] list
   * and copies over the elements.
   */
  external factory Uint8List.fromList(List<int> elements);

  /**
   * Creates a [Uint8List] _view_ of the specified region in the specified
   * byte buffer. Changes in the [Uint8List] will be visible in the byte
   * buffer and vice versa. If the [offsetInBytes] index of the region is not
   * specified, it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to null, which indicates
   * that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   */
  external factory Uint8List.view(ByteBuffer buffer,
                                  [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 1;
}


/**
 * A fixed-length list of 8-bit unsigned integers.
 * For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 * Indexed store clamps the value to range 0..0xFF.
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
   */
  external factory Uint8ClampedList.fromList(List<int> elements);

  /**
   * Creates a [Uint8ClampedList] _view_ of the specified region in the
   * specified byte [buffer]. Changes in the [Uint8List] will be visible in the
   * byte buffer and vice versa. If the [offsetInBytes] index of the region is
   * not specified, it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to null, which indicates that
   * the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   */
  external factory Uint8ClampedList.view(ByteBuffer buffer,
                                         [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 1;
}


/**
 * A fixed-length list of 16-bit signed integers that is viewable as a
 * [TypedData]. For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Int16List implements List<int>, TypedData {
  /**
   * Creates an [Int16List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int16List(int length);

  /**
   * Creates a [Int16List] with the same size as the [elements] list
   * and copies over the elements.
   */
  external factory Int16List.fromList(List<int> elements);

  /**
   * Creates an [Int16List] _view_ of the specified region in the specified
   * byte buffer. Changes in the [Int16List] will be visible in the byte
   * buffer and vice versa. If the [offsetInBytes] index of the region is not
   * specified, it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to null, which indicates
   * that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * BYTES_PER_ELEMENT.
   */
  external factory Int16List.view(ByteBuffer buffer,
                                  [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 2;
}


/**
 * A fixed-length list of 16-bit unsigned integers that is viewable as a
 * [TypedData]. For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Uint16List implements List<int>, TypedData {
  /**
   * Creates a [Uint16List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  external factory Uint16List(int length);

  /**
   * Creates a [Uint16List] with the same size as the [elements] list
   * and copies over the elements.
   */
  external factory Uint16List.fromList(List<int> elements);

  /**
   * Creates a [Uint16List] _view_ of the specified region in
   * the specified byte buffer. Changes in the [Uint16List] will be
   * visible in the byte buffer and vice versa. If the [offsetInBytes] index
   * of the region is not specified, it defaults to zero (the first byte in
   * the byte buffer). If the length is not specified, it defaults to null,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * BYTES_PER_ELEMENT.
   */
  external factory Uint16List.view(ByteBuffer buffer,
                                   [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 2;
}


/**
 * A fixed-length list of 32-bit signed integers that is viewable as a
 * [TypedData]. For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Int32List implements List<int>, TypedData {
  /**
   * Creates an [Int32List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int32List(int length);

  /**
   * Creates a [Int32List] with the same size as the [elements] list
   * and copies over the elements.
   */
  external factory Int32List.fromList(List<int> elements);

  /**
   * Creates an [Int32List] _view_ of the specified region in the specified
   * byte buffer. Changes in the [Int32List] will be visible in the byte
   * buffer and vice versa. If the [offsetInBytes] index of the region is not
   * specified, it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to null, which indicates
   * that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * BYTES_PER_ELEMENT.
   */
  external factory Int32List.view(ByteBuffer buffer,
                                  [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 4;
}


/**
 * A fixed-length list of 32-bit unsigned integers that is viewable as a
 * [TypedData]. For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Uint32List implements List<int>, TypedData {
  /**
   * Creates a [Uint32List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  external factory Uint32List(int length);

  /**
   * Creates a [Uint32List] with the same size as the [elements] list
   * and copies over the elements.
   */
  external factory Uint32List.fromList(List<int> elements);

  /**
   * Creates a [Uint32List] _view_ of the specified region in
   * the specified byte buffer. Changes in the [Uint32] will be
   * visible in the byte buffer and vice versa. If the [offsetInBytes] index
   * of the region is not specified, it defaults to zero (the first byte in
   * the byte buffer). If the length is not specified, it defaults to null,
   * which indicates that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * BYTES_PER_ELEMENT.
   */
  external factory Uint32List.view(ByteBuffer buffer,
                                   [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 4;
}


/**
 * A fixed-length list of 64-bit signed integers that is viewable as a
 * [TypedData]. For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Int64List implements List<int>, TypedData {
  /**
   * Creates an [Int64List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int64List(int length);

  /**
   * Creates a [Int64List] with the same size as the [elements] list
   * and copies over the elements.
   */
  external factory Int64List.fromList(List<int> elements);

  /**
   * Creates an [Int64List] _view_ of the specified region in the specified
   * byte buffer. Changes in the [Int64List] will be visible in the byte buffer
   * and vice versa. If the [offsetInBytes] index of the region is not
   * specified, it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to null, which indicates that
   * the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * BYTES_PER_ELEMENT.
   */
  external factory Int64List.view(ByteBuffer buffer,
                                  [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 8;
}


/**
 * A fixed-length list of 64-bit unsigned integers that is viewable as a
 * [TypedData]. For long lists, this implementation can be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Uint64List implements List<int>, TypedData {
  /**
   * Creates a [Uint64List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  external factory Uint64List(int length);

  /**
   * Creates a [Uint64List] with the same size as the [elements] list
   * and copies over the elements.
   */
  external factory Uint64List.fromList(List<int> elements);

  /**
   * Creates an [Uint64List] _view_ of the specified region in
   * the specified byte buffer. Changes in the [Uint64List] will be
   * visible in the byte buffer and vice versa. If the [offsetInBytes]
   * index of the region is not specified, it defaults to zero (the first
   * byte in the byte buffer). If the length is not specified, it defaults
   * to null, which indicates that the view extends to the end of the byte
   * buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * BYTES_PER_ELEMENT.
   */
  external factory Uint64List.view(ByteBuffer buffer,
                                   [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 8;
}


/**
 * A fixed-length list of IEEE 754 single-precision binary floating-point
 * numbers  that is viewable as a [TypedData]. For long lists, this
 * implementation can be considerably more space- and time-efficient than
 * the default [List] implementation.
 */
abstract class Float32List implements List<double>, TypedData {
  /**
   * Creates a [Float32List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Float32List(int length);

  /**
   * Creates a [Float32List] with the same size as the [elements] list
   * and copies over the elements.
   */
  external factory Float32List.fromList(List<double> elements);

  /**
   * Creates a [Float32List] _view_ of the specified region in the specified
   * byte buffer. Changes in the [Float32List] will be visible in the byte
   * buffer and vice versa. If the [offsetInBytes] index of the region is not
   * specified, it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to null, which indicates
   * that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * BYTES_PER_ELEMENT.
   */
  external factory Float32List.view(ByteBuffer buffer,
                                    [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 4;
}


/**
 * A fixed-length list of IEEE 754 double-precision binary floating-point
 * numbers  that is viewable as a [TypedData]. For long lists, this
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
   * Creates a [Float64List] with the same size as the [elements] list
   * and copies over the elements.
   */
  external factory Float64List.fromList(List<double> elements);

  /**
   * Creates a [Float64List] _view_ of the specified region in the specified
   * byte buffer. Changes in the [Float64List] will be visible in the byte
   * buffer and vice versa. If the [offsetInBytes] index of the region is not
   * specified, it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to null, which indicates
   * that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * BYTES_PER_ELEMENT.
   */
  external factory Float64List.view(ByteBuffer buffer,
                                    [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 8;
}


/**
 * A fixed-length list of Float32x4 numbers that is viewable as a
 * [TypedData]. For long lists, this implementation will be considerably more
 * space- and time-efficient than the default [List] implementation.
 */
abstract class Float32x4List implements List<Float32x4>, TypedData {
  /**
   * Creates a [Float32x4List] of the specified length (in elements),
   * all of whose elements are initially zero.
   */
  external factory Float32x4List(int length);

  /**
   * Creates a [Float32x4List] _view_ of the specified region in the specified
   * byte buffer. Changes in the [Float32x4List] will be visible in the byte
   * buffer and vice versa. If the [offsetInBytes] index of the region is not
   * specified, it defaults to zero (the first byte in the byte buffer).
   * If the length is not specified, it defaults to null, which indicates
   * that the view extends to the end of the byte buffer.
   *
   * Throws [RangeError] if [offsetInBytes] or [length] are negative, or
   * if [offsetInBytes] + ([length] * elementSizeInBytes) is greater than
   * the length of [buffer].
   *
   * Throws [ArgumentError] if [offsetInBytes] is not a multiple of
   * BYTES_PER_ELEMENT.
   */
  external factory Float32x4List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]);

  static const int BYTES_PER_ELEMENT = 16;
}


/**
 * Interface of Dart Float32x4 immutable value type and operations.
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
  /// Returns the absolute value of this [Float32x4].
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
  Float32x4 select(Float32x4 trueValue, Float32x4 falseValue);

  /// Returns a bit-wise copy of [this] as a [Float32x4].
  Float32x4 toFloat32x4();
}
