// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Specialized integers and floating point numbers,
 * with SIMD support and efficient lists.
 */
library dart.typed_data.implementation;

import 'dart:collection';
import 'dart:_internal';
import 'dart:_interceptors' show JSIndexable, JSUInt32, JSUInt31;
import 'dart:_js_helper'
    show Creates, JavaScriptIndexingBehavior, JSName, Null, Returns;
import 'dart:_foreign_helper' show JS;
import 'dart:math' as Math;

import 'dart:typed_data';

/**
 * Describes endianness to be used when accessing a sequence of bytes.
 */
class Endianness {
  const Endianness._(this._littleEndian);

  static const Endianness BIG_ENDIAN = const Endianness._(false);
  static const Endianness LITTLE_ENDIAN = const Endianness._(true);
  static final Endianness HOST_ENDIAN =
    (new ByteData.view(new Int16List.fromList([1]).buffer)).getInt8(0) == 1
      ? LITTLE_ENDIAN
      : BIG_ENDIAN;

  final bool _littleEndian;
}


class NativeByteBuffer implements ByteBuffer native "ArrayBuffer" {
  @JSName('byteLength')
  final int lengthInBytes;

  Type get runtimeType => ByteBuffer;

  Uint8List asUint8List([int offsetInBytes = 0, int length]) {
    return new NativeUint8List.view(this, offsetInBytes, length);
  }
  Int8List asInt8List([int offsetInBytes = 0, int length]) {
    return new NativeInt8List.view(this, offsetInBytes, length);
  }
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int length]) {
    return new NativeUint8ClampedList.view(this, offsetInBytes, length);
  }
  Uint16List asUint16List([int offsetInBytes = 0, int length]) {
    return new NativeUint16List.view(this, offsetInBytes, length);
  }
  Int16List asInt16List([int offsetInBytes = 0, int length]) {
    return new NativeInt16List.view(this, offsetInBytes, length);
  }
  Uint32List asUint32List([int offsetInBytes = 0, int length]) {
    return new NativeUint32List.view(this, offsetInBytes, length);
  }
  Int32List asInt32List([int offsetInBytes = 0, int length]) {
    return new NativeInt32List.view(this, offsetInBytes, length);
  }
  Uint64List asUint64List([int offsetInBytes = 0, int length]) {
    throw new UnsupportedError("Uint64List not supported by dart2js.");
  }
  Int64List asInt64List([int offsetInBytes = 0, int length]) {
    throw new UnsupportedError("Int64List not supported by dart2js.");
  }
  Int32x4List asInt32x4List([int offsetInBytes = 0, int length]) {
    return new NativeInt32x4List.view(this, offsetInBytes, length);
  }
  Float32List asFloat32List([int offsetInBytes = 0, int length]) {
    return new NativeFloat32List.view(this, offsetInBytes, length);
  }
  Float64List asFloat64List([int offsetInBytes = 0, int length]) {
    return new NativeFloat64List.view(this, offsetInBytes, length);
  }
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int length]) {
    return new NativeFloat32x4List.view(this, offsetInBytes, length);
  }
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int length]) {
    return new NativeFloat64x2List.view(this, offsetInBytes, length);
  }
  ByteData asByteData([int offsetInBytes = 0, int length]) {
    return new NativeByteData.view(this, offsetInBytes, length);
  }
}

class NativeTypedData implements TypedData native "ArrayBufferView" {
  /**
   * Returns the byte buffer associated with this object.
   */
  @Creates('NativeByteBuffer')
  // May be Null for IE's CanvasPixelArray.
  @Returns('NativeByteBuffer|Null')
  final ByteBuffer buffer;

  /**
   * Returns the length of this view, in bytes.
   */
  @JSName('byteLength')
  final int lengthInBytes;

  /**
   * Returns the offset in bytes into the underlying byte buffer of this view.
   */
  @JSName('byteOffset')
  final int offsetInBytes;

  /**
   * Returns the number of bytes in the representation of each element in this
   * list.
   */
  @JSName('BYTES_PER_ELEMENT')
  final int elementSizeInBytes;

  void _invalidIndex(int index, int length) {
    if (index < 0 || index >= length) {
      throw new RangeError.range(index, 0, length);
    } else {
      throw new ArgumentError('Invalid list index $index');
    }
  }

  void _checkIndex(int index, int length) {
    if (JS('bool', '(# >>> 0) !== #', index, index) ||
        JS('int', '#', index) >= length) {  // 'int' guaranteed by above test.
      _invalidIndex(index, length);
    }
  }

  int _checkSublistArguments(int start, int end, int length) {
    // For `sublist` the [start] and [end] indices are allowed to be equal to
    // [length]. However, [_checkIndex] only allows indices in the range
    // 0 .. length - 1. We therefore increment the [length] argument by one
    // for the [_checkIndex] checks.
    _checkIndex(start, length + 1);
    if (end == null) return length;
    _checkIndex(end, length + 1);
    if (start > end) throw new RangeError.range(start, 0, end);
    return end;
  }
}


// Validates the unnamed constructor length argument.  Checking is necessary
// because passing unvalidated values to the native constructors can cause
// conversions or create views.
int _checkLength(length) {
  if (length is! int) throw new ArgumentError('Invalid length $length');
  return length;
}

// Validates `.view` constructor arguments.  Checking is necessary because
// passing unvalidated values to the native constructors can cause conversions
// (e.g. String arguments) or create typed data objects that are not actually
// views of the input.
void _checkViewArguments(buffer, offsetInBytes, length) {
  if (buffer is! NativeByteBuffer) {
    throw new ArgumentError('Invalid view buffer');
  }
  if (offsetInBytes is! int) {
    throw new ArgumentError('Invalid view offsetInBytes $offsetInBytes');
  }
  if (length != null && length is! int) {
    throw new ArgumentError('Invalid view length $length');
  }
}

// Ensures that [list] is a JavaScript Array or a typed array.  If necessary,
// returns a copy of the list.
List _ensureNativeList(List list) {
  if (list is JSIndexable) return list;
  List result = new List(list.length);
  for (int i = 0; i < list.length; i++) {
    result[i] = list[i];
  }
  return result;
}


class NativeByteData extends NativeTypedData implements ByteData
    native "DataView" {
  /**
   * Creates a [ByteData] of the specified length (in elements), all of
   * whose elements are initially zero.
   */
  factory NativeByteData(int length) => _create1(_checkLength(length));

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
  factory NativeByteData.view(ByteBuffer buffer,
                              [int offsetInBytes = 0, int length]) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => ByteData;

  int get elementSizeInBytes => 1;

  /**
   * Returns the floating point number represented by the four bytes at
   * the specified [byteOffset] in this object, in IEEE 754
   * single-precision binary floating-point format (binary32).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  num getFloat32(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getFloat32(byteOffset, endian._littleEndian);

  @JSName('getFloat32')
  @Returns('num')
  num _getFloat32(int byteOffset, [bool littleEndian]) native;

  /**
   * Returns the floating point number represented by the eight bytes at
   * the specified [byteOffset] in this object, in IEEE 754
   * double-precision binary floating-point format (binary64).
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  num getFloat64(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getFloat64(byteOffset, endian._littleEndian);

  @JSName('getFloat64')
  @Returns('num')
  num _getFloat64(int byteOffset, [bool littleEndian]) native;

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
  int getInt16(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getInt16(byteOffset, endian._littleEndian);

  @JSName('getInt16')
  @Returns('int')
  int _getInt16(int byteOffset, [bool littleEndian]) native;

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
  int getInt32(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getInt32(byteOffset, endian._littleEndian);

  @JSName('getInt32')
  @Returns('int')
  int _getInt32(int byteOffset, [bool littleEndian]) native;

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
  int getInt64(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError('Int64 accessor not supported by dart2js.');
  }

  /**
   * Returns the (possibly negative) integer represented by the byte at the
   * specified [byteOffset] in this object, in two's complement binary
   * representation. The return value will be between -128 and 127, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  int getInt8(int byteOffset) native;

  /**
   * Returns the positive integer represented by the two bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   * The return value will be between 0 and  2<sup>16</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  int getUint16(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getUint16(byteOffset, endian._littleEndian);

  @JSName('getUint16')
  @Returns('JSUInt31')
  int _getUint16(int byteOffset, [bool littleEndian]) native;

  /**
   * Returns the positive integer represented by the four bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   * The return value will be between 0 and  2<sup>32</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  int getUint32(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getUint32(byteOffset, endian._littleEndian);

  @JSName('getUint32')
  @Returns('JSUInt32')
  int _getUint32(int byteOffset, [bool littleEndian]) native;

  /**
   * Returns the positive integer represented by the eight bytes starting
   * at the specified [byteOffset] in this object, in unsigned binary
   * form.
   * The return value will be between 0 and  2<sup>64</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  int getUint64(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError('Uint64 accessor not supported by dart2js.');
  }

  /**
   * Returns the positive integer represented by the byte at the specified
   * [byteOffset] in this object, in unsigned binary form. The
   * return value will be between 0 and 255, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  int getUint8(int byteOffset) native;

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
  void setFloat32(int byteOffset, num value,
                  [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setFloat32(byteOffset, value, endian._littleEndian);

  @JSName('setFloat32')
  void _setFloat32(int byteOffset, num value, [bool littleEndian]) native;

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * object to the IEEE 754 double-precision binary floating-point
   * (binary64) representation of the specified [value].
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setFloat64(int byteOffset, num value,
                  [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setFloat64(byteOffset, value, endian._littleEndian);

  @JSName('setFloat64')
  void _setFloat64(int byteOffset, num value, [bool littleEndian]) native;

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in two bytes. In other words, [value] must lie
   * between 2<sup>15</sup> and 2<sup>15</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  void setInt16(int byteOffset, int value,
                [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setInt16(byteOffset, value, endian._littleEndian);

  @JSName('setInt16')
  void _setInt16(int byteOffset, int value, [bool littleEndian]) native;

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in four bytes. In other words, [value] must lie
   * between 2<sup>31</sup> and 2<sup>31</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setInt32(int byteOffset, int value,
                [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setInt32(byteOffset, value, endian._littleEndian);

  @JSName('setInt32')
  void _setInt32(int byteOffset, int value, [bool littleEndian]) native;

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this
   * object to the two's complement binary representation of the specified
   * [value], which must fit in eight bytes. In other words, [value] must lie
   * between 2<sup>63</sup> and 2<sup>63</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setInt64(int byteOffset, int value,
                [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError('Int64 accessor not supported by dart2js.');
  }

  /**
   * Sets the byte at the specified [byteOffset] in this object to the
   * two's complement binary representation of the specified [value], which
   * must fit in a single byte. In other words, [value] must be between
   * -128 and 127, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * greater than or equal to the length of this object.
   */
  void setInt8(int byteOffset, int value) native;

  /**
   * Sets the two bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in two bytes. in other words, [value] must be between
   * 0 and 2<sup>16</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 2` is greater than the length of this object.
   */
  void setUint16(int byteOffset, int value,
                 [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setUint16(byteOffset, value, endian._littleEndian);

  @JSName('setUint16')
  void _setUint16(int byteOffset, int value, [bool littleEndian]) native;

  /**
   * Sets the four bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in four bytes. in other words, [value] must be between
   * 0 and 2<sup>32</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 4` is greater than the length of this object.
   */
  void setUint32(int byteOffset, int value,
                 [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setUint32(byteOffset, value, endian._littleEndian);

  @JSName('setUint32')
  void _setUint32(int byteOffset, int value, [bool littleEndian]) native;

  /**
   * Sets the eight bytes starting at the specified [byteOffset] in this object
   * to the unsigned binary representation of the specified [value],
   * which must fit in eight bytes. in other words, [value] must be between
   * 0 and 2<sup>64</sup> - 1, inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative, or
   * `byteOffset + 8` is greater than the length of this object.
   */
  void setUint64(int byteOffset, int value,
                 [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError('Uint64 accessor not supported by dart2js.');
  }

  /**
   * Sets the byte at the specified [byteOffset] in this object to the
   * unsigned binary representation of the specified [value], which must fit
   * in a single byte. in other words, [value] must be between 0 and 255,
   * inclusive.
   *
   * Throws [RangeError] if [byteOffset] is negative,
   * or greater than or equal to the length of this object.
   */
  void setUint8(int byteOffset, int value) native;

  static NativeByteData _create1(arg) =>
      JS('NativeByteData', 'new DataView(new ArrayBuffer(#))', arg);

  static NativeByteData _create2(arg1, arg2) =>
      JS('NativeByteData', 'new DataView(#, #)', arg1, arg2);

  static NativeByteData _create3(arg1, arg2, arg3) =>
      JS('NativeByteData', 'new DataView(#, #, #)', arg1, arg2, arg3);
}


abstract class NativeTypedArray extends NativeTypedData
    implements JavaScriptIndexingBehavior {
  int get length => JS('JSUInt32', '#.length', this);

  bool _setRangeFast(int start, int end,
      NativeTypedArray source, int skipCount) {
    int targetLength = this.length;
    _checkIndex(start, targetLength + 1);
    _checkIndex(end, targetLength + 1);
    if (start > end) throw new RangeError.range(start, 0, end);
    int count = end - start;

    if (skipCount < 0) throw new ArgumentError(skipCount);

    int sourceLength = source.length;
    if (sourceLength - skipCount < count)  {
      throw new StateError('Not enough elements');
    }

    if (skipCount != 0 || sourceLength != count) {
      // Create a view of the exact subrange that is copied from the source.
      source = JS('', '#.subarray(#, #)',
          source, skipCount, skipCount + count);
    }
    JS('void', '#.set(#, #)', this, source, start);
  }
}

abstract class NativeTypedArrayOfDouble
    extends NativeTypedArray
        with ListMixin<double>, FixedLengthListMixin<double>
    implements List<double> {

  num operator[](int index) {
    _checkIndex(index, length);
    return JS('num', '#[#]', this, index);
  }

  void operator[]=(int index, num value) {
    _checkIndex(index, length);
    JS('void', '#[#] = #', this, index, value);
  }

  void setRange(int start, int end, Iterable<double> iterable,
                [int skipCount = 0]) {
    if (iterable is NativeTypedArrayOfDouble) {
      _setRangeFast(start, end, iterable, skipCount);
      return;
    }
    super.setRange(start, end, iterable, skipCount);
  }
}

abstract class NativeTypedArrayOfInt
    extends NativeTypedArray
        with ListMixin<int>, FixedLengthListMixin<int>
    implements List<int> {

  // operator[]() is not here since different versions have different return
  // types

  void operator[]=(int index, int value) {
    _checkIndex(index, length);
    JS('void', '#[#] = #', this, index, value);
  }

  void setRange(int start, int end, Iterable<int> iterable,
                [int skipCount = 0]) {
    if (iterable is NativeTypedArrayOfInt) {
      _setRangeFast(start, end, iterable, skipCount);
      return;
    }
    super.setRange(start, end, iterable, skipCount);
  }
}


class NativeFloat32List
    extends NativeTypedArrayOfDouble
    implements Float32List
    native "Float32Array" {

  factory NativeFloat32List(int length) => _create1(_checkLength(length));

  factory NativeFloat32List.fromList(List<double> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeFloat32List.view(ByteBuffer buffer,
                                 int offsetInBytes, int length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Float32List;

  List<double> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('NativeFloat32List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static NativeFloat32List _create1(arg) =>
      JS('NativeFloat32List', 'new Float32Array(#)', arg);

  static NativeFloat32List _create2(arg1, arg2) =>
      JS('NativeFloat32List', 'new Float32Array(#, #)', arg1, arg2);

  static NativeFloat32List _create3(arg1, arg2, arg3) =>
      JS('NativeFloat32List', 'new Float32Array(#, #, #)', arg1, arg2, arg3);
}


class NativeFloat64List
    extends NativeTypedArrayOfDouble
    implements Float64List
    native "Float64Array" {

  factory NativeFloat64List(int length) => _create1(_checkLength(length));

  factory NativeFloat64List.fromList(List<double> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeFloat64List.view(ByteBuffer buffer,
                                  int offsetInBytes, int length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Float64List;

  List<double> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('NativeFloat64List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static NativeFloat64List _create1(arg) =>
      JS('NativeFloat64List', 'new Float64Array(#)', arg);

  static NativeFloat64List _create2(arg1, arg2) =>
      JS('NativeFloat64List', 'new Float64Array(#, #)', arg1, arg2);

  static NativeFloat64List _create3(arg1, arg2, arg3) =>
      JS('NativeFloat64List', 'new Float64Array(#, #, #)', arg1, arg2, arg3);
}


class NativeInt16List
    extends NativeTypedArrayOfInt
    implements Int16List
    native "Int16Array" {

  factory NativeInt16List(int length) => _create1(_checkLength(length));

  factory NativeInt16List.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeInt16List.view(ByteBuffer buffer,
                                [int offsetInBytes = 0, int length]) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Int16List;

  int operator[](int index) {
    _checkIndex(index, length);
    return JS('int', '#[#]', this, index);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('NativeInt16List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static NativeInt16List _create1(arg) =>
      JS('NativeInt16List', 'new Int16Array(#)', arg);

  static NativeInt16List _create2(arg1, arg2) =>
      JS('NativeInt16List', 'new Int16Array(#, #)', arg1, arg2);

  static NativeInt16List _create3(arg1, arg2, arg3) =>
      JS('NativeInt16List', 'new Int16Array(#, #, #)', arg1, arg2, arg3);
}


class NativeInt32List
    extends NativeTypedArrayOfInt
    implements Int32List
    native "Int32Array" {

  factory NativeInt32List(int length) => _create1(_checkLength(length));

  factory NativeInt32List.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeInt32List.view(ByteBuffer buffer,
                                int offsetInBytes, int length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Int32List;

  int operator[](int index) {
    _checkIndex(index, length);
    return JS('int', '#[#]', this, index);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('NativeInt32List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static NativeInt32List _create1(arg) =>
      JS('NativeInt32List', 'new Int32Array(#)', arg);

  static NativeInt32List _create2(arg1, arg2) =>
      JS('NativeInt32List', 'new Int32Array(#, #)', arg1, arg2);

  static NativeInt32List _create3(arg1, arg2, arg3) =>
      JS('NativeInt32List', 'new Int32Array(#, #, #)', arg1, arg2, arg3);
}


class NativeInt8List
    extends NativeTypedArrayOfInt
    implements Int8List
    native "Int8Array" {

  factory NativeInt8List(int length) => _create1(_checkLength(length));

  factory NativeInt8List.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeInt8List.view(ByteBuffer buffer,
                               int offsetInBytes, int length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Int8List;

  int operator[](int index) {
    _checkIndex(index, length);
    return JS('int', '#[#]', this, index);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('NativeInt8List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static NativeInt8List _create1(arg) =>
      JS('NativeInt8List', 'new Int8Array(#)', arg);

  static NativeInt8List _create2(arg1, arg2) =>
      JS('NativeInt8List', 'new Int8Array(#, #)', arg1, arg2);

  static Int8List _create3(arg1, arg2, arg3) =>
      JS('NativeInt8List', 'new Int8Array(#, #, #)', arg1, arg2, arg3);
}


class NativeUint16List
    extends NativeTypedArrayOfInt
    implements Uint16List
    native "Uint16Array" {

  factory NativeUint16List(int length) => _create1(_checkLength(length));

  factory NativeUint16List.fromList(List<int> list) =>
      _create1(_ensureNativeList(list));

  factory NativeUint16List.view(ByteBuffer buffer,
                                 int offsetInBytes, int length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Uint16List;

  int operator[](int index) {
    _checkIndex(index, length);
    return JS('JSUInt31', '#[#]', this, index);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('NativeUint16List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static NativeUint16List _create1(arg) =>
      JS('NativeUint16List', 'new Uint16Array(#)', arg);

  static NativeUint16List _create2(arg1, arg2) =>
      JS('NativeUint16List', 'new Uint16Array(#, #)', arg1, arg2);

  static NativeUint16List _create3(arg1, arg2, arg3) =>
      JS('NativeUint16List', 'new Uint16Array(#, #, #)', arg1, arg2, arg3);
}


class NativeUint32List
    extends NativeTypedArrayOfInt
    implements Uint32List
    native "Uint32Array" {

  factory NativeUint32List(int length) => _create1(_checkLength(length));

  factory NativeUint32List.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeUint32List.view(ByteBuffer buffer,
                                 int offsetInBytes, int length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Uint32List;

  int operator[](int index) {
    _checkIndex(index, length);
    return JS('JSUInt32', '#[#]', this, index);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('NativeUint32List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static NativeUint32List _create1(arg) =>
      JS('NativeUint32List', 'new Uint32Array(#)', arg);

  static NativeUint32List _create2(arg1, arg2) =>
      JS('NativeUint32List', 'new Uint32Array(#, #)', arg1, arg2);

  static NativeUint32List _create3(arg1, arg2, arg3) =>
      JS('NativeUint32List', 'new Uint32Array(#, #, #)', arg1, arg2, arg3);
}


class NativeUint8ClampedList
    extends NativeTypedArrayOfInt
    implements Uint8ClampedList
    native "Uint8ClampedArray,CanvasPixelArray" {

  factory NativeUint8ClampedList(int length) => _create1(_checkLength(length));

  factory NativeUint8ClampedList.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeUint8ClampedList.view(ByteBuffer buffer,
                                       int offsetInBytes, int length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Uint8ClampedList;

  int get length => JS('JSUInt32', '#.length', this);

  int operator[](int index) {
    _checkIndex(index, length);
    return JS('JSUInt31', '#[#]', this, index);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('NativeUint8ClampedList', '#.subarray(#, #)',
        this, start, end);
    return _create1(source);
  }

  static NativeUint8ClampedList _create1(arg) =>
      JS('NativeUint8ClampedList', 'new Uint8ClampedArray(#)', arg);

  static NativeUint8ClampedList _create2(arg1, arg2) =>
      JS('NativeUint8ClampedList', 'new Uint8ClampedArray(#, #)', arg1, arg2);

  static NativeUint8ClampedList _create3(arg1, arg2, arg3) =>
      JS('NativeUint8ClampedList', 'new Uint8ClampedArray(#, #, #)',
         arg1, arg2, arg3);
}


class NativeUint8List
    extends NativeTypedArrayOfInt
    implements Uint8List
    // On some browsers Uint8ClampedArray is a subtype of Uint8Array.  Marking
    // Uint8List as !nonleaf ensures that the native dispatch correctly handles
    // the potential for Uint8ClampedArray to 'accidentally' pick up the
    // dispatch record for Uint8List.
    native "Uint8Array,!nonleaf" {

  factory NativeUint8List(int length) => _create1(_checkLength(length));

  factory NativeUint8List.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeUint8List.view(ByteBuffer buffer,
                                int offsetInBytes, int length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Uint8List;

  int get length => JS('JSUInt32', '#.length', this);

  int operator[](int index) {
    _checkIndex(index, length);
    return JS('JSUInt31', '#[#]', this, index);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('NativeUint8List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static NativeUint8List _create1(arg) =>
      JS('NativeUint8List', 'new Uint8Array(#)', arg);

  static NativeUint8List _create2(arg1, arg2) =>
      JS('NativeUint8List', 'new Uint8Array(#, #)', arg1, arg2);

  static NativeUint8List _create3(arg1, arg2, arg3) =>
      JS('NativeUint8List', 'new Uint8Array(#, #, #)', arg1, arg2, arg3);
}
