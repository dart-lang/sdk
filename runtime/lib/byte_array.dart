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
interface ByteArray {
  /**
   * Returns the length of this byte array, in bytes.
   */
  int lengthInBytes();

  /**
   * Returns a [ByteArray] _view_ of a portion of this byte array.
   * The returned byte array consists of [length] bytes starting
   * at position [start] in this byte array. The returned byte array
   * is backed by the same data as this byte array. In other words,
   * changes to the returned byte array are visible in this byte array
   * and vice-versa.
   *
   * Throws [IndexOutOfRangeException] if [start] is negative, or if
   * `start + length` is greater than the length of this byte array.
   *
   * Throws [IllegalArgumentException] if [length] is negative.
   */
  ByteArray subByteArray([int start, int length]);

  /**
   * Returns the (possibly negative) integer represented by the byte at the
   * specified [byteOffset] in this byte array, in two's complement binary
   * representation. The return value will be between -128 and 127, inclusive.
   *
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
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
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
   * greater than or equal to the length of this byte array.
   *
   * Throws [IllegalArgumentException] if [value] is less than -128 or
   * greater than 127.
   */
  int setInt8(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the byte at the specified
   * [byteOffset] in this byte array, in unsigned binary form. The
   * return value will be between 0 and 255, inclusive.
   *
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
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
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative,
   * or greater than or equal to the length of this byte array.
   *
   * Throws [IllegalArgumentException] if [value] is negative or
   * greater than 255.
   */
  int setUint8(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the two bytes at
   * the specified [byteOffset] in this byte array, in two's complement binary
   * form. The return value will be between 2<sup>15</sup> and 2<sup>15 - 1,
   * inclusive.
   *
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
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
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this byte array.
   *
   * Throws [IllegalArgumentException] if [value] is less than 2<sup>15</sup>
   * or greater than 2<sup>15 - 1.
   */
  int setInt16(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the two bytes starting
   * at the specified [byteOffset] in this byte array, in unsigned binary
   * form. The return value will be between 0 and  2<sup>16 - 1, inclusive.
   *
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
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
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this byte array.
   *
   * Throws [IllegalArgumentException] if [value] is negative or
   * greater than 2<sup>16 - 1.
   */
  int setUint16(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the four bytes at
   * the specified [byteOffset] in this byte array, in two's complement binary
   * form. The return value will be between 2<sup>31</sup> and 2<sup>31 - 1,
   * inclusive.
   *
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
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
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this byte array.
   *
   * Throws [IllegalArgumentException] if [value] is less than 2<sup>31</sup>
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
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this byte array.
   *
   * Throws [IllegalArgumentException] if [value] is negative or
   * greater than 2<sup>32 - 1.
   */
  int setUint32(int byteOffset, int value);

  /**
   * Returns the (possibly negative) integer represented by the eight bytes at
   * the specified [byteOffset] in this byte array, in two's complement binary
   * form. The return value will be between 2<sup>63</sup> and 2<sup>63 - 1,
   * inclusive.
   *
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
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
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this byte array.
   *
   * Throws [IllegalArgumentException] if [value] is less than 2<sup>63</sup>
   * or greater than 2<sup>63 - 1.
   */
  int setInt64(int byteOffset, int value);

  /**
   * Returns the positive integer represented by the eight bytes starting
   * at the specified [byteOffset] in this byte array, in unsigned binary
   * form. The return value will be between 0 and  2<sup>64 - 1, inclusive.
   *
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
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
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this byte array.
   *
   * Throws [IllegalArgumentException] if [value] is negative or
   * greater than 2<sup>64 - 1.
   */
  int setUint64(int byteOffset, int value);

  /**
   * Returns the floating point number represented by the four bytes at
   * the specified [byteOffset] in this byte array, in IEEE 754
   * single-precision binary floating-point format (binary32).
   *
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
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
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this byte array.
   */
  int setFloat32(int byteOffset, double value);

  /**
   * Returns the floating point number represented by the eight bytes at
   * the specified [byteOffset] in this byte array, in IEEE 754
   * double-precision binary floating-point format (binary64).
   *
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
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
   * Throws [IndexOutOfRangeException] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this byte array.
   */
  int setFloat64(int byteOffset, double value);
}

/**
 * A "mixin" interface that allows a type, typically but not necessarily
 * a [List], to be viewed as a [ByteArray].
 */
interface ByteArrayViewable {
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
interface Int8List extends List<int>, ByteArrayViewable
    default _Int8ArrayFactory {
  /**
   * Creates an [Int8List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  Int8List(int length);

  /**
   * Creates an [Int8List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Int8List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   */
  Int8List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 8-bit unsigned integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
interface Uint8List extends List<int>, ByteArrayViewable
    default _Uint8ArrayFactory {
  /**
   * Creates a [Uint8List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  Uint8List(int length);

  /**
   * Creates a [Uint8List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Uint8List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   */
  Uint8List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 16-bit signed integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
interface Int16List extends List<int>, ByteArrayViewable
    default _Int16ArrayFactory {
  /**
   * Creates an [Int16List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  Int16List(int length);

  /**
   * Creates an [Int16List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Int16List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   *
   * Throws [IllegalArgumentException] if the length of the specified region
   * is not divisible by 2 (the size of an "int16" in bytes), or if the
   * [start] of the region is not divisible by 2. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [IllegalArgumentException] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 2. In plain terms,
   * this constructor throws [IllegalArgumentException] if the specified
   * region does not contain an integral number of "int16s," or if it
   * is not "int16-aligned."
   */
  Int16List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 16-bit unsigned integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
interface Uint16List extends List<int>, ByteArrayViewable
    default _Uint16ArrayFactory {
  /**
   * Creates a [Uint16List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  Uint16List(int length);

  /**
   * Creates a [Uint16List] _view_ of the specified region in
   * the specified byte [array]. Changes in the [Uint16List] will be
   * visible in the byte array and vice versa. If the [start] index of the
   * region is not specified, it defaults to zero (the first byte in the byte
   * array). If the length is not specified, it defaults to null, which
   * indicates that the view extends to the end of the byte array.
   *
   * Throws [IllegalArgumentException] if the length of the specified region
   * is not divisible by 2 (the size of a "uint16" in bytes), or if the
   * [start] of the region is not divisible by 2. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [IllegalArgumentException] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 2. In plain terms,
   * this constructor throws [IllegalArgumentException] if the specified
   * region does not contain an integral number of "uint16s," or if it
   * is not "uint16-aligned."
   */
  Uint16List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 32-bit signed integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
interface Int32List extends List<int>, ByteArrayViewable
    default _Int32ArrayFactory {
  /**
   * Creates an [Int32List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  Int32List(int length);

  /**
   * Creates an [Int32List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Int32List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   *
   * Throws [IllegalArgumentException] if the length of the specified region
   * is not divisible by 4 (the size of an "int32" in bytes), or if the
   * [start] of the region is not divisible by 4. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [IllegalArgumentException] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 4. In plain terms,
   * this constructor throws [IllegalArgumentException] if the specified
   * region does not contain an integral number of "int32s," or if it
   * is not "int32-aligned."
   */
  Int32List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 32-bit unsigned integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
interface Uint32List extends List<int>, ByteArrayViewable
    default _Uint32ArrayFactory {
  /**
   * Creates a [Uint32List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  Uint32List(int length);

  /**
   * Creates a [Uint32List] _view_ of the specified region in
   * the specified byte [array]. Changes in the [Uint32] will be
   * visible in the byte array and vice versa. If the [start] index of the
   * region is not specified, it defaults to zero (the first byte in the byte
   * array). If the length is not specified, it defaults to null, which
   * indicates that the view extends to the end of the byte array.
   *
   * Throws [IllegalArgumentException] if the length of the specified region
   * is not divisible by 4 (the size of a "uint32" in bytes), or if the
   * [start] of the region is not divisible by 4. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [IllegalArgumentException] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 4. In plain terms,
   * this constructor throws [IllegalArgumentException] if the specified
   * region does not contain an integral number of "uint32s," or if it
   * is not "uint32-aligned."
   */
  Uint32List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 64-bit signed integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
interface Int64List extends List<int>, ByteArrayViewable
    default _Int64ArrayFactory {
  /**
   * Creates an [Int64List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  Int64List(int length);

  /**
   * Creates an [Int64List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Int64List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   *
   * Throws [IllegalArgumentException] if the length of the specified region
   * is not divisible by 8 (the size of an "int64" in bytes), or if the
   * [start] of the region is not divisible by 8. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [IllegalArgumentException] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 8. In plain terms,
   * this constructor throws [IllegalArgumentException] if the specified
   * region does not contain an integral number of "int64s," or if it
   * is not "int64-aligned."
   */
  Int64List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of 64-bit unsigned integers that is viewable as a
 * [ByteArray]. For long lists, this implementation will be considerably
 * more space- and time-efficient than the default [List] implementation.
 */
interface Uint64List extends List<int>, ByteArrayViewable
    default _Uint64ArrayFactory {
  /**
   * Creates a [Uint64List] of the specified length (in elements), all
   * of whose elements are initially zero.
   */
  Uint64List(int length);

  /**
   * Creates an [Uint64List] _view_ of the specified region in
   * the specified byte [array]. Changes in the [Uint64List] will be
   * visible in the byte array and vice versa. If the [start] index of the
   * region is not specified, it defaults to zero (the first byte in the byte
   * array). If the length is not specified, it defaults to null, which
   * indicates that the view extends to the end of the byte array.
   *
   * Throws [IllegalArgumentException] if the length of the specified region
   * is not divisible by 8 (the size of a "uint64" in bytes), or if the
   * [start] of the region is not divisible by 8. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [IllegalArgumentException] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 8. In plain terms,
   * this constructor throws [IllegalArgumentException] if the specified
   * region does not contain an integral number of "uint64s," or if it
   * is not "uint64-aligned."
   */
  Uint64List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of IEEE 754 single-precision binary floating-point
 * numbers  that is viewable as a [ByteArray]. For long lists, this
 * implementation will be considerably more space- and time-efficient than
 * the default [List] implementation.
 */
interface Float32List extends List<double>, ByteArrayViewable
    default _Float32ArrayFactory {
  /**
   * Creates a [Float32List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  Float32List(int length);

  /**
   * Creates a [Float32List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Float32List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   *
   * Throws [IllegalArgumentException] if the length of the specified region
   * is not divisible by 4 (the size of a "float32" in bytes), or if the
   * [start] of the region is not divisible by 4. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [IllegalArgumentException] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 4. In plain terms,
   * this constructor throws [IllegalArgumentException] if the specified
   * region does not contain an integral number of "float32s," or if it
   * is not "float32-aligned."
   */
  Float32List.view(ByteArray array, [int start, int length]);
}


/**
 * A fixed-length list of IEEE 754 double-precision binary floating-point
 * numbers  that is viewable as a [ByteArray]. For long lists, this
 * implementation will be considerably more space- and time-efficient than
 * the default [List] implementation.
 */
interface Float64List extends List<double>, ByteArrayViewable
    default _Float64ArrayFactory {
  /**
   * Creates a [Float64List] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  Float64List(int length);

  /**
   * Creates a [Float64List] _view_ of the specified region in the specified
   * byte [array]. Changes in the [Float64List] will be visible in the byte
   * array and vice versa. If the [start] index of the region is not specified,
   * it defaults to zero (the first byte in the byte array). If the length is
   * not specified, it defaults to null, which indicates that the view extends
   * to the end of the byte array.
   *
   * Throws [IllegalArgumentException] if the length of the specified region
   * is not divisible by 8 (the size of a "float64" in bytes), or if the
   * [start] of the region is not divisible by 8. If, however, [array]
   * is a view of another byte array, this constructor will throw
   * [IllegalArgumentException] if the implicit starting position in the
   * "ultimately backing" byte array is not divisible by 8. In plain terms,
   * this constructor throws [IllegalArgumentException] if the specified
   * region does not contain an integral number of "float64s," or if it
   * is not "float64-aligned."
   */
  Float64List.view(ByteArray array, [int start, int length]);
}


class _Int8ArrayFactory {
  factory Int8List(int length) {
    return new _Int8Array(length);
  }

  factory Int8List.view(ByteArray array, [int start = 0, int length]) {
    return new _Int8ArrayView(array, start, length);
  }
}


class _Uint8ArrayFactory {
  factory Uint8List(int length) {
    return new _Uint8Array(length);
  }

  factory Uint8List.view(ByteArray array, [int start = 0, int length]) {
    return new _Uint8ArrayView(array, start, length);
  }
}


class _Int16ArrayFactory {
  factory Int16List(int length) {
    return new _Int16Array(length);
  }

  factory Int16List.view(ByteArray array, [int start = 0, int length]) {
    return new _Int16ArrayView(array, start, length);
  }
}


class _Uint16ArrayFactory {
  factory Uint16List(int length) {
    return new _Uint16Array(length);
  }

  factory Uint16List.view(ByteArray array, [int start = 0, int length]) {
    return new _Uint16ArrayView(array, start, length);
  }
}


class _Int32ArrayFactory {
  factory Int32List(int length) {
    return new _Int32Array(length);
  }

  factory Int32List.view(ByteArray array, [int start = 0, int length]) {
    return new _Int32ArrayView(array, start, length);
  }
}


class _Uint32ArrayFactory {
  factory Uint32List(int length) {
    return new _Uint32Array(length);
  }

  factory Uint32List.view(ByteArray array, [int start = 0, int length]) {
    return new _Uint32ArrayView(array, start, length);
  }
}


class _Int64ArrayFactory {
  factory Int64List(int length) {
    return new _Int64Array(length);
  }

  factory Int64List.view(ByteArray array, [int start = 0, int length]) {
    return new _Int64ArrayView(array, start, length);
  }
}


class _Uint64ArrayFactory {
  factory Uint64List(int length) {
    return new _Uint64Array(length);
  }

  factory Uint64List.view(ByteArray array, [int start = 0, int length]) {
    return new _Uint64ArrayView(array, start, length);
  }
}


class _Float32ArrayFactory {
  factory Float32List(int length) {
    return new _Float32Array(length);
  }

  factory Float32List.view(ByteArray array, [int start = 0, int length]) {
    return new _Float32ArrayView(array, start, length);
  }
}


class _Float64ArrayFactory {
  factory Float64List(int length) {
    return new _Float64Array(length);
  }

  factory Float64List.view(ByteArray array, [int start = 0, int length]) {
    return new _Float64ArrayView(array, start, length);
  }
}


abstract class _ByteArrayBase {
  abstract int lengthInBytes();

  abstract int bytesPerElement();

  abstract operator[](int index);

  // Methods implementing the Collection interface.

  void forEach(void f(element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  Collection map(f(element)) {
    return Collections.map(this,
                           new GrowableObjectArray.withCapacity(length),
                           f);
  }

  Dynamic reduce(Dynamic initialValue,
                 Dynamic combine(Dynamic initialValue, element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  Collection filter(bool f(element)) {
    return Collections.filter(this, new GrowableObjectArray(), f);
  }

  bool every(bool f(element)) {
    return Collections.every(this, f);
  }

  bool some(bool f(element)) {
    return Collections.some(this, f);
  }

  bool isEmpty() {
    return this.length === 0;
  }

  int get length() {
    return _length();
  }

  // Methods implementing the List interface.

  set length(newLength) {
    throw const UnsupportedOperationException(
        "Cannot resize a non-extendable array");
  }

  void add(value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void addLast(value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void addAll(Collection value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void sort(int compare(a, b)) {
    DualPivotQuicksort.sort(this, compare);
  }

  int indexOf(element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(element, [int start = null]) {
    if (start === null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  void clear() {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  int removeLast() {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  last() {
    return this[length - 1];
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  void insertRange(int start, int length, [initialValue]) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length === null) {
      length = this.length;
    }
    _rangeCheck(this.length, start, length);
    return new _ByteArrayView(this,
                              start * this.bytesPerElement(),
                              length * this.bytesPerElement());
  }

  int _length() native "ByteArray_getLength";

  void _setRange(int startInBytes, int lengthInBytes,
                 _ByteArrayBase from, int startFromInBytes)
      native "ByteArray_setRange";

  int _getInt8(int byteOffset) native "ByteArray_getInt8";
  int _setInt8(int byteOffset, int value) native "ByteArray_setInt8";

  int _getUint8(int byteOffset) native "ByteArray_getUint8";
  int _setUint8(int byteOffset, int value) native "ByteArray_setUint8";

  int _getInt16(int byteOffset) native "ByteArray_getInt16";
  int _setInt16(int byteOffset, int value) native "ByteArray_setInt16";

  int _getUint16(int byteOffset) native "ByteArray_getUint16";
  int _setUint16(int byteOffset, int value) native "ByteArray_setUint16";

  int _getInt32(int byteOffset) native "ByteArray_getInt32";
  int _setInt32(int byteOffset, int value) native "ByteArray_setInt32";

  int _getUint32(int byteOffset) native "ByteArray_getUint32";
  int _setUint32(int byteOffset, int value) native "ByteArray_setUint32";

  int _getInt64(int byteOffset) native "ByteArray_getInt64";
  int _setInt64(int byteOffset, int value) native "ByteArray_setInt64";

  int _getUint64(int byteOffset) native "ByteArray_getUint64";
  int _setUint64(int byteOffset, int value) native "ByteArray_setUint64";

  double _getFloat32(int byteOffset) native "ByteArray_getFloat32";
  int _setFloat32(int byteOffset, double value) native "ByteArray_setFloat32";

  double _getFloat64(int byteOffset) native "ByteArray_getFloat64";
  int _setFloat64(int byteOffset, double value) native "ByteArray_setFloat64";
}


int _toInt(int value, int mask) {
  value &= mask;
  if (value > (mask >> 1)) value -= mask + 1;
  return value;
}

int _toInt8(int value) {
  return _toInt(value, 0xFF);
}
int _toUint8(int value) {
  return value & 0xFF;
}


int _toInt16(int value) {
  return _toInt(value, 0xFFFF);
}
int _toUint16(int value) {
  return value & 0xFFFF;
}


int _toInt32(int value) {
  return _toInt(value, 0xFFFFFFFF);
}
int _toUint32(int value) {
  return value & 0xFFFFFFFF;
}


int _toInt64(int value) {
  return _toInt(value, 0xFFFFFFFFFFFFFFFF);
}
int _toUint64(int value) {
  return value & 0xFFFFFFFFFFFFFFFF;
}


void _rangeCheck(int listLength, int start, int length) {
  if (length < 0) {
    throw new IndexOutOfRangeException(length);
  }
  if (start < 0) {
    throw new IndexOutOfRangeException(start);
  }
  if (start + length > listLength) {
    throw new IndexOutOfRangeException(start + length);
  }
}


int _requireInteger(object) {
  if (object is int) {
    return object;
  }
  throw new IllegalArgumentException("$object is not an integer");
}


int _requireIntegerOrNull(object, value) {
  if (object is int) {
    return object;
  }
  if (object === null) {
    return _requireInteger(value);
  }
  throw new IllegalArgumentException("$object is not an integer or null");
}


class _Int8Array extends _ByteArrayBase implements Int8List {
  factory _Int8Array(int length) {
    return _new(length);
  }

  factory _Int8Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = array.lengthInBytes();
    }
    return new _Int8ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int8Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 1;

  static _Int8Array _new(int length) native "Int8Array_new";

  int _getIndexed(int index) native "Int8Array_getIndexed";
  int _setIndexed(int index, int value) native "Int8Array_setIndexed";
}


class _Uint8Array extends _ByteArrayBase implements Uint8List {
  factory _Uint8Array(int length) {
    return _new(length);
  }

  factory _Uint8Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = array.lengthInBytes();
    }
    return new _Uint8ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint8Array || from is _ExternalUint8Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 1;

  static _Uint8Array _new(int length) native "Uint8Array_new";

  int _getIndexed(int index) native "Uint8Array_getIndexed";
  int _setIndexed(int index, int value) native "Uint8Array_setIndexed";
}


class _Int16Array extends _ByteArrayBase implements Int16List {
  factory _Int16Array(int length) {
    return _new(length);
  }

  factory _Int16Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Int16ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int16Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 2;

  static _Int16Array _new(int length) native "Int16Array_new";

  int _getIndexed(int index) native "Int16Array_getIndexed";
  int _setIndexed(int index, int value) native "Int16Array_setIndexed";
}


class _Uint16Array extends _ByteArrayBase implements Uint16List {
  factory _Uint16Array(int length) {
    return _new(length);
  }

  factory _Uint16Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Uint16ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint16Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 2;

  static _Uint16Array _new(int length) native "Uint16Array_new";

  int _getIndexed(int index) native "Uint16Array_getIndexed";
  int _setIndexed(int index, int value) native "Uint16Array_setIndexed";
}


class _Int32Array extends _ByteArrayBase implements Int32List {
  factory _Int32Array(int length) {
    return _new(length);
  }

  factory _Int32Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Int32ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  static _Int32Array _new(int length) native "Int32Array_new";

  int _getIndexed(int index) native "Int32Array_getIndexed";
  int _setIndexed(int index, int value) native "Int32Array_setIndexed";
}


class _Uint32Array extends _ByteArrayBase implements Uint32List {
  factory _Uint32Array(int length) {
    return _new(length);
  }

  factory _Uint32Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Uint32ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  static _Uint32Array _new(int length) native "Uint32Array_new";

  int _getIndexed(int index) native "Uint32Array_getIndexed";
  int _setIndexed(int index, int value) native "Uint32Array_setIndexed";
}


class _Int64Array extends _ByteArrayBase implements Int64List {
  factory _Int64Array(int length) {
    return _new(length);
  }

  factory _Int64Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Int64ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  static _Int64Array _new(int length) native "Int64Array_new";

  int _getIndexed(int index) native "Int64Array_getIndexed";
  int _setIndexed(int index, int value) native "Int64Array_setIndexed";
}


class _Uint64Array extends _ByteArrayBase implements Uint64List {
  factory _Uint64Array(int length) {
    return _new(length);
  }

  factory _Uint64Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Uint64ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  static _Uint64Array _new(int length) native "Uint64Array_new";

  int _getIndexed(int index) native "Uint64Array_getIndexed";
  int _setIndexed(int index, int value) native "Uint64Array_setIndexed";
}


class _Float32Array extends _ByteArrayBase implements Float32List {
  factory _Float32Array(int length) {
    return _new(length);
  }

  factory _Float32Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Float32ArrayView(array, start, length);
  }

  double operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    if (from is _Float32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  static _Float32Array _new(int length) native "Float32Array_new";

  double _getIndexed(int index) native "Float32Array_getIndexed";
  int _setIndexed(int index, double value) native "Float32Array_setIndexed";
}


class _Float64Array extends _ByteArrayBase implements Float64List {
  factory _Float64Array(int length) {
    return _new(length);
  }

  factory _Float64Array.view(ByteArray array, [int start = 0, int length]) {
    if (length === null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Float64ArrayView(array, start, length);
  }

  double operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    if (from is _Float64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  static _Float64Array _new(int length) native "Float64Array_new";

  double _getIndexed(int index) native "Float64Array_getIndexed";
  int _setIndexed(int index, double value) native "Float64Array_setIndexed";
}


class _ExternalInt8Array extends _ByteArrayBase implements Int8List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt8Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 1;

  int _getIndexed(int index) native "ExternalInt8Array_getIndexed";
  int _setIndexed(int index, int value) native "ExternalInt8Array_setIndexed";
}


class _ExternalUint8Array extends _ByteArrayBase implements Uint8List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint8Array || from is _Uint8Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 1;

  int _getIndexed(int index) native "ExternalUint8Array_getIndexed";
  int _setIndexed(int index, int value) native "ExternalUint8Array_setIndexed";
}


class _ExternalInt16Array extends _ByteArrayBase implements Int16List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int16List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt16Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 2;

  int _getIndexed(int index) native "ExternalInt16Array_getIndexed";
  int _setIndexed(int index, int value) native "ExternalInt16Array_setIndexed";
}


class _ExternalUint16Array extends _ByteArrayBase implements Uint16List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint16List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint16Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 2;

  int _getIndexed(int index)
      native "ExternalUint16Array_getIndexed";
  int _setIndexed(int index, int value)
      native "ExternalUint16Array_setIndexed";
}


class _ExternalInt32Array extends _ByteArrayBase implements Int32List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  int _getIndexed(int index)
      native "ExternalInt32Array_getIndexed";
  int _setIndexed(int index, int value)
      native "ExternalInt32Array_setIndexed";
}


class _ExternalUint32Array extends _ByteArrayBase implements Uint32List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  int _getIndexed(int index)
      native "ExternalUint32Array_getIndexed";
  int _setIndexed(int index, int value)
      native "ExternalUint32Array_setIndexed";
}


class _ExternalInt64Array extends _ByteArrayBase implements Int64List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  int _getIndexed(int index)
      native "ExternalInt64Array_getIndexed";
  int _setIndexed(int index, int value)
      native "ExternalInt64Array_setIndexed";
}


class _ExternalUint64Array extends _ByteArrayBase implements Uint64List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  int _getIndexed(int index)
      native "ExternalUint64Array_getIndexed";
  int _setIndexed(int index, int value)
      native "ExternalUint64Array_setIndexed";
}


class _ExternalFloat32Array extends _ByteArrayBase implements Float32List {
  double operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = new Float32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    if (from is _ExternalFloat32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  double _getIndexed(int index)
      native "ExternalFloat32Array_getIndexed";
  int _setIndexed(int index, double value)
      native "ExternalFloat32Array_setIndexed";
}


class _ExternalFloat64Array extends _ByteArrayBase implements Float64List {
  double operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = new Float64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    if (from is _ExternalFloat64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  double _getIndexed(int index)
      native "ExternalFloat64Array_getIndexed";
  int _setIndexed(int index, double value)
      native "ExternalFloat64Array_setIndexed";
}


class _ByteArrayIterator<E> implements Iterator<E> {
  _ByteArrayIterator(List array)
    : _array = array, _length = array.length, _pos = 0 {
    assert(array is _ByteArrayBase || array is _ByteArrayViewBase);
  }

  bool hasNext() {
   return _length > _pos;
  }

  E next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _array[_pos++];
  }

  final List<E> _array;
  final int _length;
  int _pos;
}


class _ByteArrayView implements ByteArray {
  _ByteArrayView(this._array, this._offset, this._length) {
    _rangeCheck(_array.lengthInBytes(), _offset, _length);
  }

  int lengthInBytes() {
    return _length;
  }

  ByteArray subByteArray([int start = 0, int length]) {
    if (length === null) {
      length = this.lengthInBytes();
    }
    return new _ByteArrayView(_array, _offset + start, length);
  }

  int getInt8(int byteOffset) {
    return _array._getInt8(_offset + byteOffset);
  }
  int setInt8(int byteOffset, int value) {
    return _array._setInt8(_offset + byteOffset, value);
  }

  int getUint8(int byteOffset) {
    return _array._getUint8(_offset + byteOffset);
  }
  int setUint8(int byteOffset, int value) {
    return _array._setUint8(_offset + byteOffset, value);
  }

  int getInt16(int byteOffset) {
    return _array._getInt16(_offset + byteOffset);
  }
  int setInt16(int byteOffset, int value) {
    return _array._setInt16(_offset + byteOffset, value);
  }

  int getUint16(int byteOffset) {
    return _array._getUint16(_offset + byteOffset);
  }
  int setUint16(int byteOffset, int value) {
    return _array._setUint16(_offset + byteOffset, value);
  }

  int getInt32(int byteOffset) {
    return _array._getInt32(_offset + byteOffset);
  }
  int setInt32(int byteOffset, int value) {
    return _array._setInt32(_offset + byteOffset, value);
  }

  int getUint32(int byteOffset) {
    return _array._getUint32(_offset + byteOffset);
  }
  int setUint32(int byteOffset, int value) {
    return _array._setUint32(_offset + byteOffset, value);
  }

  int getInt64(int byteOffset) {
    return _array._getInt64(_offset + byteOffset);
  }
  int setInt64(int byteOffset, int value) {
    return _array._setInt64(_offset + byteOffset, value);
  }

  int getUint64(int byteOffset) {
    return _array._getUint64(_offset + byteOffset);
  }
  int setUint64(int byteOffset, int value) {
    return _array._setUint64(_offset + byteOffset, value);
  }

  double getFloat32(int byteOffset) {
    return _array._getFloat32(_offset + byteOffset);
  }
  int setFloat32(int byteOffset, double value) {
    return _array._setFloat32(_offset + byteOffset, value);
  }

  double getFloat64(int byteOffset) {
    return _array._getFloat64(_offset + byteOffset);
  }
  int setFloat64(int byteOffset, double value) {
    return _array._setFloat64(_offset + byteOffset, value);
  }

  final _ByteArrayBase _array;
  final int _offset;
  final int _length;
}


class _ByteArrayViewBase {
  abstract num operator[](int index);

  // Methods implementing the Collection interface.

  void forEach(void f(element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  Collection map(f(element)) {
    return Collections.map(this,
                           new GrowableObjectArray.withCapacity(length),
                           f);
  }

  Dynamic reduce(Dynamic initialValue,
                 Dynamic combine(Dynamic initialValue, element)) {
    return Collections.reduce(this, initialValue, combine);
  }

  Collection filter(bool f(element)) {
    return Collections.filter(this, new GrowableObjectArray(), f);
  }

  bool every(bool f(element)) {
    return Collections.every(this, f);
  }

  bool some(bool f(element)) {
    return Collections.some(this, f);;
  }

  bool isEmpty() {
    return this.length === 0;
  }

  abstract int get length();

  // Methods implementing the List interface.

  set length(newLength) {
    throw const UnsupportedOperationException(
        "Cannot resize a non-extendable array");
  }

  void add(value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void addLast(value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void addAll(Collection value) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }

  void sort(int compare(a, b)) {
    DualPivotQuicksort.sort(this, compare);
  }

  int indexOf(element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(element, [int start = null]) {
    if (start === null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  void clear() {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  int removeLast() {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  last() {
    return this[length - 1];
  }

  void removeRange(int start, int length) {
    throw const UnsupportedOperationException(
        "Cannot remove from a non-extendable array");
  }

  void insertRange(int start, int length, [initialValue]) {
    throw const UnsupportedOperationException(
        "Cannot add to a non-extendable array");
  }
}


class _Int8ArrayView extends _ByteArrayViewBase implements Int8List {
  _Int8ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = _requireInteger(offsetInBytes),
      _length = _requireIntegerOrNull(
        length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT)) {
    _rangeCheck(array.lengthInBytes(), _offset, _length * _BYTES_PER_ELEMENT);
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    return _array.getInt8(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    _array.setInt8(_offset + (index * _BYTES_PER_ELEMENT), _toInt8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 1;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Uint8ArrayView extends _ByteArrayViewBase implements Uint8List {
  _Uint8ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = _requireInteger(offsetInBytes),
      _length = _requireIntegerOrNull(
        length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT)) {
    _rangeCheck(array.lengthInBytes(), _offset, _length * _BYTES_PER_ELEMENT);
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    return _array.getUint8(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    _array.setUint8(_offset + (index * _BYTES_PER_ELEMENT), _toUint8(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 1;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Int16ArrayView extends _ByteArrayViewBase implements Int16List {
  _Int16ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = _requireInteger(offsetInBytes),
      _length = _requireIntegerOrNull(
        length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT)) {
    _rangeCheck(array.lengthInBytes(), _offset, _length * _BYTES_PER_ELEMENT);
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    return _array.getInt16(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    _array.setInt16(_offset + (index * _BYTES_PER_ELEMENT), _toInt16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int16List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 2;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Uint16ArrayView extends _ByteArrayViewBase implements Uint16List {
  _Uint16ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = _requireInteger(offsetInBytes),
      _length = _requireIntegerOrNull(
        length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT)) {
    _rangeCheck(array.lengthInBytes(), _offset, _length * _BYTES_PER_ELEMENT);
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    return _array.getUint16(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    _array.setUint16(_offset + (index * _BYTES_PER_ELEMENT), _toUint16(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint16List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 2;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Int32ArrayView extends _ByteArrayViewBase implements Int32List {
  _Int32ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = _requireInteger(offsetInBytes),
      _length = _requireIntegerOrNull(
        length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT)) {
    _rangeCheck(array.lengthInBytes(), _offset, _length * _BYTES_PER_ELEMENT);
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    return _array.getInt32(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    _array.setInt32(_offset + (index * _BYTES_PER_ELEMENT), _toInt32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 4;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Uint32ArrayView extends _ByteArrayViewBase implements Uint32List {
  _Uint32ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = _requireInteger(offsetInBytes),
      _length = _requireIntegerOrNull(
        length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT)) {
    _rangeCheck(array.lengthInBytes(), _offset, _length * _BYTES_PER_ELEMENT);
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    return _array.getUint32(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    _array.setUint32(_offset + (index * _BYTES_PER_ELEMENT), _toUint32(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 4;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Int64ArrayView extends _ByteArrayViewBase implements Int64List {
  _Int64ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = _requireInteger(offsetInBytes),
      _length = _requireIntegerOrNull(
        length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT)) {
    _rangeCheck(array.lengthInBytes(), _offset, _length * _BYTES_PER_ELEMENT);
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    return _array.getInt64(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    _array.setInt64(_offset + (index * _BYTES_PER_ELEMENT), _toInt64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 8;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Uint64ArrayView extends _ByteArrayViewBase implements Uint64List {
  _Uint64ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = _requireInteger(offsetInBytes),
      _length = _requireIntegerOrNull(
        length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT)) {
    _rangeCheck(array.lengthInBytes(), _offset, _length * _BYTES_PER_ELEMENT);
  }

  get length() {
    return _length;
  }

  int operator[](int index) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    return _array.getUint64(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    _array.setUint64(_offset + (index * _BYTES_PER_ELEMENT), _toUint64(value));
  }

  Iterator<int> iterator() {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 8;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Float32ArrayView extends _ByteArrayViewBase implements Float32List {
  _Float32ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = _requireInteger(offsetInBytes),
      _length = _requireIntegerOrNull(
        length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT)) {
    _rangeCheck(array.lengthInBytes(), _offset, _length * _BYTES_PER_ELEMENT);
  }

  get length() {
    return _length;
  }

  double operator[](int index) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    return _array.getFloat32(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    _array.setFloat32(_offset + (index * _BYTES_PER_ELEMENT), value);
  }

  Iterator<double> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = new Float32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 4;
  final ByteArray _array;
  final int _offset;
  final int _length;
}


class _Float64ArrayView extends _ByteArrayViewBase implements Float64List {
  _Float64ArrayView(ByteArray array, [int offsetInBytes = 0, int length])
    : _array = array,
      _offset = _requireInteger(offsetInBytes),
      _length = _requireIntegerOrNull(
        length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT)) {
    _rangeCheck(array.lengthInBytes(), _offset, _length * _BYTES_PER_ELEMENT);
  }

  get length() {
    return _length;
  }

  double operator[](int index) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    return _array.getFloat64(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= _length) {
      String message = "$index must be in the range [0..$_length)";
      throw new IndexOutOfRangeException(message);
    }
    _array.setFloat64(_offset + (index * _BYTES_PER_ELEMENT), value);
  }

  Iterator<double> iterator() {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = new Float64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 8;
  final ByteArray _array;
  final int _offset;
  final int _length;
}
