// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.typeddata;

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
