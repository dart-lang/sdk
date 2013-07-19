// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.typed_data;

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
 * Describes endianness to be used when accessing or updating a
 * sequence of bytes.
 */
class Endianness {
  const Endianness._(this._littleEndian);

  static const Endianness BIG_ENDIAN = const Endianness._(false);
  static const Endianness LITTLE_ENDIAN = const Endianness._(true);
  static final Endianness HOST_ENDIAN =
    (new ByteData.view(new Uint16List.fromList([1]).buffer)).getInt8(0) == 1 ?
    LITTLE_ENDIAN : BIG_ENDIAN;

  final bool _littleEndian;
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
  int getInt16(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in two bytes. In other words, [value] must lie
   * between 2<sup>15</sup> and 2<sup>15</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  void setInt16(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the positive integer represented by the two bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   * The return value will be between 0 and  2<sup>16</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  int getUint16(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in two bytes. in other words, [value] must be between
   * 0 and 2<sup>16</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  void setUint16(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]);

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
  int getInt32(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in four bytes. In other words, [value] must lie
   * between 2<sup>31</sup> and 2<sup>31</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setInt32(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the positive integer represented by the four bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   * The return value will be between 0 and  2<sup>32</sup> - 1, inclusive.
   *
   */
  int getUint32(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in four bytes. in other words, [value] must be between
   * 0 and 2<sup>32</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setUint32(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]);

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
  int getInt64(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in eight bytes. In other words, [value] must lie
   * between 2<sup>63</sup> and 2<sup>63</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setInt64(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the positive integer represented by the eight bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   * The return value will be between 0 and  2<sup>64</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  int getUint64(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in eight bytes. in other words, [value] must be between
   * 0 and 2<sup>64</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setUint64(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the floating point number represented by the four bytes at
   * the specified [byteOffset] in this object, in IEEE 754
   * single-precision binary floating-point format (binary32).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  double getFloat32(int byteOffset,
                    [Endianness endian = Endianness.BIG_ENDIAN]);

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
  void setFloat32(int byteOffset,
                  double value,
                  [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Returns the floating point number represented by the eight bytes at
   * the specified [byteOffset] in this object, in IEEE 754
   * double-precision binary floating-point format (binary64).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  double getFloat64(int byteOffset,
                    [Endianness endian = Endianness.BIG_ENDIAN]);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * object to the IEEE 754 double-precision binary floating-point
   * (binary64) representation of the specified [value].
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setFloat64(int byteOffset,
                  double value,
                  [Endianness endian = Endianness.BIG_ENDIAN]);
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
abstract class Uint8ClampedList implements Uint8List {
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
  external factory Float32x4.splat(double v);
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

  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xxww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xywx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xywy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xywz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xyww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xzww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get xwww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yxww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yywx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yywy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yywz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yyww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get yzww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get ywww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zxww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zywx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zywy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zywz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zyww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zzww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get zwww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wxww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wywx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wywy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wywz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wyww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wzww;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwxx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwxy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwxz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwxw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwyx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwyy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwyz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwyw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwzx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwzy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwzz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwzw;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwwx;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwwy;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwwz;
  /// Returns a new [Float32x4] with lane values reordered.
  Float32x4 get wwww;

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
