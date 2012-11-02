// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A random-access sequence of bytes that also provides random access to
 * the fixed-width integers and floating point numbers represented by
 * those bytes. Byte arrays may be used to pack and unpack data from
 * external sources (such as networks or files systems), and to process
 * large quantities of numerical data more efficiently than would be possible
 * with ordinary [List] implementations. Byte arrays can save space, by
 * eliminating the need for object headers, and time, by eliminating the
 * need for data copies. Finally, Byte arrays may be used to intentionally
 * reinterpret the bytes representing one arithmetic type as another.
 * For example this code fragment determine what 64-bit signed integer
 * is represented by the bytes of a 64-bit floating point number:
 *
 *    var ba = new ByteArray(8);
 *    ba.setFloat64(0, 3.14159265358979323846);
 *    int huh = ba.getInt64(0);
 */
abstract class ByteArray {
  /**
   * Returns the length of this byte array, in bytes.
   */
  int lengthInBytes();

  // TODO(lrn): Change the signature to match String.substring.
  /**
   * Returns a [ByteArray] _view_ of a portion of this byte array.
   * The returned byte array consists of [length] bytes starting
   * at position [start] in this byte array. The returned byte array
   * is backed by the same data as this byte array. In other words,
   * changes to the returned byte array are visible in this byte array
   * and vice-versa.
   *
   * Throws [RangeError] if [start] or [length] are negative, or
   * if `start + length` is greater than the length of this byte array.
   *
   * Throws [ArgumentError] if [length] is negative.
   */
  ByteArray subByteArray([int start, int length]);

  /**
   * Returns the (possibly negative) integer represented by the byte at the
   * specified [byteOffset] in this byte array, in two's complement binary
   * representation. The return value will be between -128 and 127, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this byte array.
   */
  int getInt8(int byteOffset);

  /**
   * Sets the byte at the specified [byteOffset] in this byte array to the
   * two's complement binary representation of the specified [value], which
   * must fit in a single byte. In other words, [value] must be between
   * -128 and 127, inclusive.
   *
   * Returns `byteOffset + 1`, which is the offset of the first byte in the
   * array after the byte that was set by this call. This return value can
   * be passed as the [byteOffset] parameter to a subsequent `setXxx` call.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this byte array.
   *
   * Throws [ArgumentError] if [value] is less than -128 or
   * greater than 127.
   */
  int setInt8(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the byte at the specified
   * [byteOffset] in this byte array, in unsigned binary form. The
   * return value will be between 0 and 255, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this byte array.
   */
  int getUint8(int byteOffset);

  /**
   * Sets the byte at the specified [byteOffset] in this byte array to the
   * unsigned binary representation of the specified [value], which must fit
   * in a single byte. in other words, [value] must be between 0 and 255,
   * inclusive.
   *
   * Returns `byteOffset + 1`, which is the offset of the first byte in the
   * array after the byte that was set by this call. This return value can
   * be passed as the [byteOffset] parameter to a subsequent `setXxx` call.
   *
   * Throws [RangeError] if [byteOffset] is negative,
   * or greater than or equal to the length of this byte array.
   *
   * Throws [ArgumentError] if [value] is negative or
   * greater than 255.
   */
  int setUint8(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the two bytes at
   * the specified [byteOffset] in this byte array, in two's complement binary
   * form. The return value will be between 2<sup>15</sup> and 2<sup>15 - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this byte array.
   */
  int getInt16(int byteOffset);

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this
   * byte array to the two's complement binary representation of the specified
   * [value], which must fit in two bytes. In other words, [value] must lie
   * between 2<sup>15</sup> and 2<sup>15 - 1, inclusive.
   *
   * Returns `byteOffset + 2`, which is the offset of the first byte in the
   * array after the last byte that was set by this call. This return value can
   * be passed as the [byteOffset] parameter to a subsequent `setXxx` call.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this byte array.
   *
   * Throws [ArgumentError] if [value] is less than 2<sup>15</sup>
   * or greater than 2<sup>15 - 1.
   */
  int setInt16(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the two bytes starting
   * at the specified [byteOffset] in this byte array, in unsigned binary
   * form. The return value will be between 0 and  2<sup>16 - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this byte array.
   */
  int getUint16(int byteOffset);

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this byte
   * array to the unsigned binary representation of the specified [value],
   * which must fit in two bytes. in other words, [value] must be between
   * 0 and 2<sup>16 - 1, inclusive.
   *
   * Returns `byteOffset + 2`, which is the offset of the first byte in the
   * array after the last byte that was set by this call. This return value can
   * be passed as the [byteOffset] parameter to a subsequent `setXxx` call.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this byte array.
   *
   * Throws [ArgumentError] if [value] is negative or
   * greater than 2<sup>16 - 1.
   */
  int setUint16(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the four bytes at
   * the specified [byteOffset] in this byte array, in two's complement binary
   * form. The return value will be between 2<sup>31</sup> and 2<sup>31 - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this byte array.
   */
  int getInt32(int byteOffset);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this
   * byte array to the two's complement binary representation of the specified
   * [value], which must fit in four bytes. In other words, [value] must lie
   * between 2<sup>31</sup> and 2<sup>31 - 1, inclusive.
   *
   * Returns `byteOffset + 4`, which is the offset of the first byte in the
   * array after the last byte that was set by this call. This return value can
   * be passed as the [byteOffset] parameter to a subsequent `setXxx` call.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this byte array.
   *
   * Throws [ArgumentError] if [value] is less than 2<sup>31</sup>
   * or greater than 2<sup>31 - 1.
   */
  int setInt32(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the four bytes starting
   * at the specified [byteOffset] in this byte array, in unsigned binary
   * form. The return value will be between 0 and  2<sup>32 - 1, inclusive.
   *
   */
  int getUint32(int byteOffset);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this byte
   * array to the unsigned binary representation of the specified [value],
   * which must fit in four bytes. in other words, [value] must be between
   * 0 and 2<sup>32 - 1, inclusive.
   *
   * Returns `byteOffset + 4`, which is the offset of the first byte in the
   * array after the last byte that was set by this call. This return value can
   * be passed as the [byteOffset] parameter to a subsequent `setXxx` call.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this byte array.
   *
   * Throws [ArgumentError] if [value] is negative or
   * greater than 2<sup>32 - 1.
   */
  int setUint32(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the eight bytes at
   * the specified [byteOffset] in this byte array, in two's complement binary
   * form. The return value will be between 2<sup>63</sup> and 2<sup>63 - 1,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this byte array.
   */
  int getInt64(int byteOffset);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * byte array to the two's complement binary representation of the specified
   * [value], which must fit in eight bytes. In other words, [value] must lie
   * between 2<sup>63</sup> and 2<sup>63 - 1, inclusive.
   *
   * Returns `byteOffset + 8`, which is the offset of the first byte in the
   * array after the last byte that was set by this call. This return value can
   * be passed as the [byteOffset] parameter to a subsequent `setXxx` call.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this byte array.
   *
   * Throws [ArgumentError] if [value] is less than 2<sup>63</sup>
   * or greater than 2<sup>63 - 1.
   */
  int setInt64(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the eight bytes starting
   * at the specified [byteOffset] in this byte array, in unsigned binary
   * form. The return value will be between 0 and  2<sup>64 - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this byte array.
   */
  int getUint64(int byteOffset);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this byte
   * array to the unsigned binary representation of the specified [value],
   * which must fit in eight bytes. in other words, [value] must be between
   * 0 and 2<sup>64 - 1, inclusive.
   *
   * Returns `byteOffset + 8`, which is the offset of the first byte in the
   * array after the last byte that was set by this call. This return value can
   * be passed as the [byteOffset] parameter to a subsequent `setXxx` call.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this byte array.
   *
   * Throws [ArgumentError] if [value] is negative or
   * greater than 2<sup>64 - 1.
   */
  int setUint64(int byteOffset, int value);

  /**
   * Returns the floating point number represented by the four bytes at
   * the specified [byteOffset] in this byte array, in IEEE 754
   * single-precision binary floating-point format (binary32).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this byte array.
   */
  double getFloat32(int byteOffset);

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this
   * byte array to the IEEE 754 single-precision binary floating-point
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
   * Returns `byteOffset + 4`, which is the offset of the first byte in the
   * array after the last byte that was set by this call. This return value can
   * be passed as the [byteOffset] parameter to a subsequent `setXxx` call.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this byte array.
   */
  int setFloat32(int byteOffset, double value);

  /**
   * Returns the floating point number represented by the eight bytes at
   * the specified [byteOffset] in this byte array, in IEEE 754
   * double-precision binary floating-point format (binary64).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this byte array.
   */
  double getFloat64(int byteOffset);

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * byte array to the IEEE 754 double-precision binary floating-point
   * (binary64) representation of the specified [value].
   *
   * Returns `byteOffset + 8`, which is the offset of the first byte in the
   * array after the last byte that was set by this call. This return value can
   * be passed as the [byteOffset] parameter to a subsequent `setXxx` call.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this byte array.
   */
  int setFloat64(int byteOffset, double value);
}

/**
 * A "mixin interface" that allows a type, typically but not necessarily
 * a [List], to be viewed as a [ByteArray].
 */
abstract class ByteArrayViewable {
  /**
   * Returns the number of bytes in the representation of each element in
   * this list, or the number bytes in the representation of the entire
   * object if it is not a list.
   */
  int bytesPerElement();

  /**
   * Returns the length of this view, in bytes.
   */
  int lengthInBytes();

  /**
   * Returns the byte array view of this object. This view allows the
   * byte representation of the object to be read and written directly.
   */
  ByteArray asByteArray([int start, int length]);
}


/**
 * A fixed-length list of 8-bit signed integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Int8List implements List<int>, ByteArrayViewable {
  /**
   * Creates an [Int8List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int8List(int length);

  /**
   * Creates an [Int8List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Int8List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   */
  external factory Int8List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 8-bit unsigned integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Uint8List implements List<int>, ByteArrayViewable {
  /**
   * Creates a [Uint8List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Uint8List(int length);

  /**
   * Creates a [Uint8List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Uint8List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   */
  external factory Uint8List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 16-bit signed integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Int16List implements List<int>, ByteArrayViewable {
  /**
   * Creates an [Int16List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int16List(int length);

  /**
   * Creates an [Int16List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Int16List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   *
   * Throws [ArgumentError] if the length of the specified region
   * is not divisible by 2 (the size of an "int16" in bytes), or if the
   * [start] of the region is not divisible by 2. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [ArgumentError] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 2. In plain terms,
   * this constructor throws [ArgumentError] if the specified
   * region does not contain an integral number of "int16s," or if it
   * is not "int16-aligned."
   */
  external factory Int16List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 16-bit unsigned integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Uint16List implements List<int>, ByteArrayViewable {
  /**
   * Creates a [Uint16List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  external factory Uint16List(int length);

  /**
   * Creates a [Uint16List] _view_ of the specified region in
   * the specified byte [array]. Changes in the [Uint16List] will be
   * visible in the byte array and vice versa. If the [start] index of the
   * region is not specified, it defaults to zero (the first byte in the byte
   * array). If the length is not specified, it defaults to null, which
   * indicates that the view extends to the end of the byte array.
   *
   * Throws [ArgumentError] if the length of the specified region
   * is not divisible by 2 (the size of a "uint16" in bytes), or if the
   * [start] of the region is not divisible by 2. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [ArgumentError] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 2. In plain terms,
   * this constructor throws [ArgumentError] if the specified
   * region does not contain an integral number of "uint16s," or if it
   * is not "uint16-aligned."
   */
  external factory Uint16List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 32-bit signed integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Int32List implements List<int>, ByteArrayViewable {
  /**
   * Creates an [Int32List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int32List(int length);

  /**
   * Creates an [Int32List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Int32List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   *
   * Throws [ArgumentError] if the length of the specified region
   * is not divisible by 4 (the size of an "int32" in bytes), or if the
   * [start] of the region is not divisible by 4. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [ArgumentError] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 4. In plain terms,
   * this constructor throws [ArgumentError] if the specified
   * region does not contain an integral number of "int32s," or if it
   * is not "int32-aligned."
   */
  external factory Int32List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 32-bit unsigned integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Uint32List implements List<int>, ByteArrayViewable {
  /**
   * Creates a [Uint32List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  external factory Uint32List(int length);

  /**
   * Creates a [Uint32List] _view_ of the specified region in
   * the specified byte [array]. Changes in the [Uint32] will be
   * visible in the byte array and vice versa. If the [start] index of the
   * region is not specified, it defaults to zero (the first byte in the byte
   * array). If the length is not specified, it defaults to null, which
   * indicates that the view extends to the end of the byte array.
   *
   * Throws [ArgumentError] if the length of the specified region
   * is not divisible by 4 (the size of a "uint32" in bytes), or if the
   * [start] of the region is not divisible by 4. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [ArgumentError] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 4. In plain terms,
   * this constructor throws [ArgumentError] if the specified
   * region does not contain an integral number of "uint32s," or if it
   * is not "uint32-aligned."
   */
  external factory Uint32List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 64-bit signed integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Int64List implements List<int>, ByteArrayViewable {
  /**
   * Creates an [Int64List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Int64List(int length);

  /**
   * Creates an [Int64List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Int64List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   *
   * Throws [ArgumentError] if the length of the specified region
   * is not divisible by 8 (the size of an "int64" in bytes), or if the
   * [start] of the region is not divisible by 8. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [ArgumentError] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 8. In plain terms,
   * this constructor throws [ArgumentError] if the specified
   * region does not contain an integral number of "int64s," or if it
   * is not "int64-aligned."
   */
  external factory Int64List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 64-bit unsigned integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
abstract class Uint64List implements List<int>, ByteArrayViewable {
  /**
   * Creates a [Uint64List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  external factory Uint64List(int length);

  /**
   * Creates an [Uint64List] _view_ of the specified region in
   * the specified byte [array]. Changes in the [Uint64List] will be
   * visible in the byte array and vice versa. If the [start] index of the
   * region is not specified, it defaults to zero (the first byte in the byte
   * array). If the length is not specified, it defaults to null, which
   * indicates that the view extends to the end of the byte array.
   *
   * Throws [ArgumentError] if the length of the specified region
   * is not divisible by 8 (the size of a "uint64" in bytes), or if the
   * [start] of the region is not divisible by 8. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [ArgumentError] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 8. In plain terms,
   * this constructor throws [ArgumentError] if the specified
   * region does not contain an integral number of "uint64s," or if it
   * is not "uint64-aligned."
   */
  external factory Uint64List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of IEEE 754 single-precision binary floating-point
 * numbers  that is viewable as a [ByteArray]. For long lists, this
 * implementation will be considerably more space- and time-efficient than
 * the default [List] implementation.
 */
abstract class Float32List implements List<double>, ByteArrayViewable {
  /**
   * Creates a [Float32List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Float32List(int length);

  /**
   * Creates a [Float32List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Float32List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   *
   * Throws [ArgumentError] if the length of the specified region
   * is not divisible by 4 (the size of a "float32" in bytes), or if the
   * [start] of the region is not divisible by 4. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [ArgumentError] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 4. In plain terms,
   * this constructor throws [ArgumentError] if the specified
   * region does not contain an integral number of "float32s," or if it
   * is not "float32-aligned."
   */
  external factory Float32List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of IEEE 754 double-precision binary floating-point
 * numbers  that is viewable as a [ByteArray]. For long lists, this
 * implementation will be considerably more space- and time-efficient than
 * the default [List] implementation.
 */
abstract class Float64List implements List<double>, ByteArrayViewable {
  /**
   * Creates a [Float64List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  external factory Float64List(int length);

  /**
   * Creates a [Float64List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Float64List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   *
   * Throws [ArgumentError] if the length of the specified region
   * is not divisible by 8 (the size of a "float64" in bytes), or if the
   * [start] of the region is not divisible by 8. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [ArgumentError] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 8. In plain terms,
   * this constructor throws [ArgumentError] if the specified
   * region does not contain an integral number of "float64s," or if it
   * is not "float64-aligned."
   */
  external factory Float64List.view(ByteArray array, [int start, int length]);
}
