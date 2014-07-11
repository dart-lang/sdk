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
    NativeUint32List storage =
        this.asUint32List(offsetInBytes, length != null ? length * 4 : null);
    return new NativeInt32x4List._externalStorage(storage);
  }

  Float32List asFloat32List([int offsetInBytes = 0, int length]) {
    return new NativeFloat32List.view(this, offsetInBytes, length);
  }

  Float64List asFloat64List([int offsetInBytes = 0, int length]) {
    return new NativeFloat64List.view(this, offsetInBytes, length);
  }

  Float32x4List asFloat32x4List([int offsetInBytes = 0, int length]) {
    NativeFloat32List storage =
        this.asFloat32List(offsetInBytes, length != null ? length * 4 : null);
    return new NativeFloat32x4List._externalStorage(storage);
  }

  Float64x2List asFloat64x2List([int offsetInBytes = 0, int length]) {
    NativeFloat64List storage =
        this.asFloat64List(offsetInBytes, length != null ? length * 2 : null);
    return new NativeFloat64x2List._externalStorage(storage);
  }

  ByteData asByteData([int offsetInBytes = 0, int length]) {
    return new NativeByteData.view(this, offsetInBytes, length);
  }
}



/**
 * A fixed-length list of Float32x4 numbers that is viewable as a
 * [TypedData]. For long lists, this implementation will be considerably more
 * space- and time-efficient than the default [List] implementation.
 */
class NativeFloat32x4List
    extends Object with ListMixin<Float32x4>, FixedLengthListMixin<Float32x4>
    implements Float32x4List {

  final NativeFloat32List _storage;

  /**
   * Creates a [Float32x4List] of the specified length (in elements),
   * all of whose elements are initially zero.
   */
  NativeFloat32x4List(int length)
      : _storage = new NativeFloat32List(length * 4);

  NativeFloat32x4List._externalStorage(this._storage);

  NativeFloat32x4List._slowFromList(List<Float32x4> list)
      : _storage = new NativeFloat32List(list.length * 4) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 4) + 0] = e.x;
      _storage[(i * 4) + 1] = e.y;
      _storage[(i * 4) + 2] = e.z;
      _storage[(i * 4) + 3] = e.w;
    }
  }

  Type get runtimeType => Float32x4List;

  /**
   * Creates a [Float32x4List] with the same size as the [elements] list
   * and copies over the elements.
   */
  factory NativeFloat32x4List.fromList(List<Float32x4> list) {
    if (list is NativeFloat32x4List) {
      return new NativeFloat32x4List._externalStorage(
          new NativeFloat32List.fromList(list._storage));
    } else {
      return new NativeFloat32x4List._slowFromList(list);
    }
  }

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Float32x4List.BYTES_PER_ELEMENT;

  void _invalidIndex(int index, int length) {
    if (index < 0 || index >= length) {
      throw new RangeError.range(index, 0, length);
    } else {
      throw new ArgumentError('Invalid list index $index');
    }
  }

  void _checkIndex(int index, int length) {
    if (JS('bool', '(# >>> 0 != #)', index, index) || index >= length) {
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

  int get length => _storage.length ~/ 4;

  Float32x4 operator[](int index) {
    _checkIndex(index, length);
    double _x = _storage[(index * 4) + 0];
    double _y = _storage[(index * 4) + 1];
    double _z = _storage[(index * 4) + 2];
    double _w = _storage[(index * 4) + 3];
    return new Float32x4(_x, _y, _z, _w);
  }

  void operator[]=(int index, NativeFloat32x4 value) {
    _checkIndex(index, length);
    _storage[(index * 4) + 0] = value._storage[0];
    _storage[(index * 4) + 1] = value._storage[1];
    _storage[(index * 4) + 2] = value._storage[2];
    _storage[(index * 4) + 3] = value._storage[3];
  }

  List<Float32x4> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    return new NativeFloat32x4List._externalStorage(
        _storage.sublist(start * 4, end * 4));
  }
}


/**
 * A fixed-length list of Int32x4 numbers that is viewable as a
 * [TypedData]. For long lists, this implementation will be considerably more
 * space- and time-efficient than the default [List] implementation.
 */
class NativeInt32x4List
    extends Object with ListMixin<Int32x4>, FixedLengthListMixin<Int32x4>
    implements Int32x4List {

  final Uint32List _storage;

  /**
   * Creates a [Int32x4List] of the specified length (in elements),
   * all of whose elements are initially zero.
   */
  NativeInt32x4List(int length) : _storage = new NativeUint32List(length * 4);

  NativeInt32x4List._externalStorage(Uint32List storage) : _storage = storage;

  NativeInt32x4List._slowFromList(List<Int32x4> list)
      : _storage = new NativeUint32List(list.length * 4) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 4) + 0] = e.x;
      _storage[(i * 4) + 1] = e.y;
      _storage[(i * 4) + 2] = e.z;
      _storage[(i * 4) + 3] = e.w;
    }
  }

  Type get runtimeType => Int32x4List;

  /**
   * Creates a [Int32x4List] with the same size as the [elements] list
   * and copies over the elements.
   */
  factory NativeInt32x4List.fromList(List<Int32x4> list) {
    if (list is NativeInt32x4List) {
      return new NativeInt32x4List._externalStorage(
          new NativeUint32List.fromList(list._storage));
    } else {
      return new NativeInt32x4List._slowFromList(list);
    }
  }

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Int32x4List.BYTES_PER_ELEMENT;

  void _invalidIndex(int index, int length) {
    if (index < 0 || index >= length) {
      throw new RangeError.range(index, 0, length);
    } else {
      throw new ArgumentError('Invalid list index $index');
    }
  }

  void _checkIndex(int index, int length) {
    if (JS('bool', '(# >>> 0 != #)', index, index)
        || JS('bool', '# >= #', index, length)) {
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

  int get length => _storage.length ~/ 4;

  Int32x4 operator[](int index) {
    _checkIndex(index, length);
    int _x = _storage[(index * 4) + 0];
    int _y = _storage[(index * 4) + 1];
    int _z = _storage[(index * 4) + 2];
    int _w = _storage[(index * 4) + 3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  void operator[]=(int index, NativeInt32x4 value) {
    _checkIndex(index, length);
    _storage[(index * 4) + 0] = value._storage[0];
    _storage[(index * 4) + 1] = value._storage[1];
    _storage[(index * 4) + 2] = value._storage[2];
    _storage[(index * 4) + 3] = value._storage[3];
  }

  List<Int32x4> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    return new NativeInt32x4List._externalStorage(
        _storage.sublist(start * 4, end * 4));
  }
}


/**
 * A fixed-length list of Float64x2 numbers that is viewable as a
 * [TypedData]. For long lists, this implementation will be considerably more
 * space- and time-efficient than the default [List] implementation.
 */
class NativeFloat64x2List
    extends Object with ListMixin<Float64x2>, FixedLengthListMixin<Float64x2>
    implements Float64x2List {

  final NativeFloat64List _storage;

  /**
   * Creates a [Float64x2List] of the specified length (in elements),
   * all of whose elements are initially zero.
   */
  NativeFloat64x2List(int length)
      : _storage = new NativeFloat64List(length * 2);

  NativeFloat64x2List._externalStorage(this._storage);

  NativeFloat64x2List._slowFromList(List<Float64x2> list)
      : _storage = new NativeFloat64List(list.length * 2) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 2) + 0] = e.x;
      _storage[(i * 2) + 1] = e.y;
    }
  }

  /**
   * Creates a [Float64x2List] with the same size as the [elements] list
   * and copies over the elements.
   */
  factory NativeFloat64x2List.fromList(List<Float64x2> list) {
    if (list is NativeFloat64x2List) {
      return new NativeFloat64x2List._externalStorage(
          new NativeFloat64List.fromList(list._storage));
    } else {
      return new NativeFloat64x2List._slowFromList(list);
    }
  }

  Type get runtimeType => Float64x2List;

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Float64x2List.BYTES_PER_ELEMENT;

  void _invalidIndex(int index, int length) {
    if (index < 0 || index >= length) {
      throw new RangeError.range(index, 0, length);
    } else {
      throw new ArgumentError('Invalid list index $index');
    }
  }

  void _checkIndex(int index, int length) {
    if (JS('bool', '(# >>> 0 != #)', index, index) || index >= length) {
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

  int get length => _storage.length ~/ 2;

  Float64x2 operator[](int index) {
    _checkIndex(index, length);
    double _x = _storage[(index * 2) + 0];
    double _y = _storage[(index * 2) + 1];
    return new Float64x2(_x, _y);
  }

  void operator[]=(int index, NativeFloat64x2 value) {
    _checkIndex(index, length);
    _storage[(index * 2) + 0] = value._storage[0];
    _storage[(index * 2) + 1] = value._storage[1];
  }

  List<Float64x2> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    return new NativeFloat64x2List._externalStorage(
        _storage.sublist(start * 2, end * 2));
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
                              int offsetInBytes, int length) {
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
      _getFloat32(byteOffset, Endianness.LITTLE_ENDIAN == endian);

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
      _getFloat64(byteOffset, Endianness.LITTLE_ENDIAN == endian);

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
      _getInt16(byteOffset, Endianness.LITTLE_ENDIAN == endian);

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
      _getInt32(byteOffset, Endianness.LITTLE_ENDIAN == endian);

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
      _getUint16(byteOffset, Endianness.LITTLE_ENDIAN == endian);

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
      _getUint32(byteOffset, Endianness.LITTLE_ENDIAN == endian);

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
      _setFloat32(byteOffset, value, Endianness.LITTLE_ENDIAN == endian);

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
      _setFloat64(byteOffset, value, Endianness.LITTLE_ENDIAN == endian);

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
      _setInt16(byteOffset, value, Endianness.LITTLE_ENDIAN == endian);

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
      _setInt32(byteOffset, value, Endianness.LITTLE_ENDIAN == endian);

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
      _setUint16(byteOffset, value, Endianness.LITTLE_ENDIAN == endian);

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
      _setUint32(byteOffset, value, Endianness.LITTLE_ENDIAN == endian);

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
        with ListMixin<double>, FixedLengthListMixin<double> {

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

  factory NativeInt16List.view(NativeByteBuffer buffer,
                               int offsetInBytes, int length) {
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


/**
 * Implementation of Dart Float32x4 immutable value type and operations.
 * Float32x4 stores 4 32-bit floating point values in "lanes".
 * The lanes are "x", "y", "z", and "w" respectively.
 */
class NativeFloat32x4 implements Float32x4 {
  final _storage = new Float32List(4);

  NativeFloat32x4(double x, double y, double z, double w) {
    _storage[0] = x;
    _storage[1] = y;
    _storage[2] = z;
    _storage[3] = w;
  }

  NativeFloat32x4.splat(double v) {
    _storage[0] = v;
    _storage[1] = v;
    _storage[2] = v;
    _storage[3] = v;
  }

  NativeFloat32x4.zero();
  /// Returns a bit-wise copy of [x] as a Float32x4.

  NativeFloat32x4.fromInt32x4Bits(NativeInt32x4 x) {
    var view = x._storage.buffer.asFloat32List();
    _storage[0] = view[0];
    _storage[1] = view[1];
    _storage[2] = view[2];
    _storage[3] = view[3];
  }

  NativeFloat32x4.fromFloat64x2(NativeFloat64x2 v) {
    _storage[0] = v._storage[0];
    _storage[1] = v._storage[1];
  }

  String toString() {
    return '[${_storage[0]}, ${_storage[1]}, ${_storage[2]}, ${_storage[3]}]';
  }

   /// Addition operator.
  Float32x4 operator+(NativeFloat32x4 other) {
    double _x = _storage[0] + other._storage[0];
    double _y = _storage[1] + other._storage[1];
    double _z = _storage[2] + other._storage[2];
    double _w = _storage[3] + other._storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Negate operator.
  Float32x4 operator-() {
    double _x = -_storage[0];
    double _y = -_storage[1];
    double _z = -_storage[2];
    double _w = -_storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Subtraction operator.
  Float32x4 operator-(NativeFloat32x4 other) {
    double _x = _storage[0] - other._storage[0];
    double _y = _storage[1] - other._storage[1];
    double _z = _storage[2] - other._storage[2];
    double _w = _storage[3] - other._storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Multiplication operator.
  Float32x4 operator*(NativeFloat32x4 other) {
    double _x = _storage[0] * other._storage[0];
    double _y = _storage[1] * other._storage[1];
    double _z = _storage[2] * other._storage[2];
    double _w = _storage[3] * other._storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Division operator.
  Float32x4 operator/(NativeFloat32x4 other) {
    double _x = _storage[0] / other._storage[0];
    double _y = _storage[1] / other._storage[1];
    double _z = _storage[2] / other._storage[2];
    double _w = _storage[3] / other._storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Relational less than.
  Int32x4 lessThan(NativeFloat32x4 other) {
    bool _cx = _storage[0] < other._storage[0];
    bool _cy = _storage[1] < other._storage[1];
    bool _cz = _storage[2] < other._storage[2];
    bool _cw = _storage[3] < other._storage[3];
    return new NativeInt32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Relational less than or equal.
  Int32x4 lessThanOrEqual(NativeFloat32x4 other) {
    bool _cx = _storage[0] <= other._storage[0];
    bool _cy = _storage[1] <= other._storage[1];
    bool _cz = _storage[2] <= other._storage[2];
    bool _cw = _storage[3] <= other._storage[3];
    return new NativeInt32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Relational greater than.
  Int32x4 greaterThan(NativeFloat32x4 other) {
    bool _cx = _storage[0] > other._storage[0];
    bool _cy = _storage[1] > other._storage[1];
    bool _cz = _storage[2] > other._storage[2];
    bool _cw = _storage[3] > other._storage[3];
    return new NativeInt32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Relational greater than or equal.
  Int32x4 greaterThanOrEqual(NativeFloat32x4 other) {
    bool _cx = _storage[0] >= other._storage[0];
    bool _cy = _storage[1] >= other._storage[1];
    bool _cz = _storage[2] >= other._storage[2];
    bool _cw = _storage[3] >= other._storage[3];
    return new NativeInt32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Relational equal.
  Int32x4 equal(NativeFloat32x4 other) {
    bool _cx = _storage[0] == other._storage[0];
    bool _cy = _storage[1] == other._storage[1];
    bool _cz = _storage[2] == other._storage[2];
    bool _cw = _storage[3] == other._storage[3];
    return new NativeInt32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Relational not-equal.
  Int32x4 notEqual(NativeFloat32x4 other) {
    bool _cx = _storage[0] != other._storage[0];
    bool _cy = _storage[1] != other._storage[1];
    bool _cz = _storage[2] != other._storage[2];
    bool _cw = _storage[3] != other._storage[3];
    return new NativeInt32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Returns a copy of [this] each lane being scaled by [s].
  Float32x4 scale(double s) {
    double _x = s * _storage[0];
    double _y = s * _storage[1];
    double _z = s * _storage[2];
    double _w = s * _storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Returns the absolute value of this [Float32x4].
  Float32x4 abs() {
    double _x = _storage[0].abs();
    double _y = _storage[1].abs();
    double _z = _storage[2].abs();
    double _w = _storage[3].abs();
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Clamps [this] to be in the range [lowerLimit]-[upperLimit].
  NativeFloat32x4 clamp(NativeFloat32x4 lowerLimit,
                        NativeFloat32x4 upperLimit) {
    double _lx = lowerLimit._storage[0];
    double _ly = lowerLimit._storage[1];
    double _lz = lowerLimit._storage[2];
    double _lw = lowerLimit._storage[3];
    double _ux = upperLimit._storage[0];
    double _uy = upperLimit._storage[1];
    double _uz = upperLimit._storage[2];
    double _uw = upperLimit._storage[3];
    double _x = _storage[0];
    double _y = _storage[1];
    double _z = _storage[2];
    double _w = _storage[3];
    // MAX(MIN(self, upper), lower).
    _x = _x > _ux ? _ux : _x;
    _y = _y > _uy ? _uy : _y;
    _z = _z > _uz ? _uz : _z;
    _w = _w > _uw ? _uw : _w;
    _x = _x < _lx ? _lx : _x;
    _y = _y < _ly ? _ly : _y;
    _z = _z < _lz ? _lz : _z;
    _w = _w < _lw ? _lw : _w;
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Extracted x value.
  double get x => _storage[0];
  /// Extracted y value.
  double get y => _storage[1];
  /// Extracted z value.
  double get z => _storage[2];
  /// Extracted w value.
  double get w => _storage[3];

  /// Extract the sign bit from each lane return them in the first 4 bits.
  int get signMask {
    var view = new NativeUint32List.view(_storage.buffer, 0, null);
    var mx = (view[0] & 0x80000000) >> 31;
    var my = (view[1] & 0x80000000) >> 31;
    var mz = (view[2] & 0x80000000) >> 31;
    var mw = (view[3] & 0x80000000) >> 31;
    return mx | my << 1 | mz << 2 | mw << 3;
  }

  /// Shuffle the lane values. [mask] must be one of the 256 shuffle constants.
  Float32x4 shuffle(int m) {
    if ((m < 0) || (m > 255)) {
      throw new RangeError('mask $m must be in the range [0..256)');
    }
    double _x = _storage[m & 0x3];
    double _y = _storage[(m >> 2) & 0x3];
    double _z = _storage[(m >> 4) & 0x3];
    double _w = _storage[(m >> 6) & 0x3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Shuffle the lane values in [this] and [other]. The returned
  /// Float32x4 will have XY lanes from [this] and ZW lanes from [other].
  /// Uses the same [mask] as [shuffle].
  Float32x4 shuffleMix(NativeFloat32x4 other, int m) {
    if ((m < 0) || (m > 255)) {
      throw new RangeError('mask $m must be in the range [0..256)');
    }
    double _x = _storage[m & 0x3];
    double _y = _storage[(m >> 2) & 0x3];
    double _z = other._storage[(m >> 4) & 0x3];
    double _w = other._storage[(m >> 6) & 0x3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Copy [this] and replace the [x] lane.
  Float32x4 withX(double x) {
    double _x = x;
    double _y = _storage[1];
    double _z = _storage[2];
    double _w = _storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Copy [this] and replace the [y] lane.
  Float32x4 withY(double y) {
    double _x = _storage[0];
    double _y = y;
    double _z = _storage[2];
    double _w = _storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Copy [this] and replace the [z] lane.
  Float32x4 withZ(double z) {
    double _x = _storage[0];
    double _y = _storage[1];
    double _z = z;
    double _w = _storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Copy [this] and replace the [w] lane.
  Float32x4 withW(double w) {
    double _x = _storage[0];
    double _y = _storage[1];
    double _z = _storage[2];
    double _w = w;
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Returns the lane-wise minimum value in [this] or [other].
  Float32x4 min(NativeFloat32x4 other) {
    double _x = _storage[0] < other._storage[0] ?
        _storage[0] : other._storage[0];
    double _y = _storage[1] < other._storage[1] ?
        _storage[1] : other._storage[1];
    double _z = _storage[2] < other._storage[2] ?
        _storage[2] : other._storage[2];
    double _w = _storage[3] < other._storage[3] ?
        _storage[3] : other._storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Returns the lane-wise maximum value in [this] or [other].
  Float32x4 max(NativeFloat32x4 other) {
    double _x = _storage[0] > other._storage[0] ?
        _storage[0] : other._storage[0];
    double _y = _storage[1] > other._storage[1] ?
        _storage[1] : other._storage[1];
    double _z = _storage[2] > other._storage[2] ?
        _storage[2] : other._storage[2];
    double _w = _storage[3] > other._storage[3] ?
        _storage[3] : other._storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Returns the square root of [this].
  Float32x4 sqrt() {
    double _x = Math.sqrt(_storage[0]);
    double _y = Math.sqrt(_storage[1]);
    double _z = Math.sqrt(_storage[2]);
    double _w = Math.sqrt(_storage[3]);
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Returns the reciprocal of [this].
  Float32x4 reciprocal() {
    double _x = 1.0 / _storage[0];
    double _y = 1.0 / _storage[1];
    double _z = 1.0 / _storage[2];
    double _w = 1.0 / _storage[3];
    return new NativeFloat32x4(_x, _y, _z, _w);
  }

  /// Returns the square root of the reciprocal of [this].
  Float32x4 reciprocalSqrt() {
    double _x = Math.sqrt(1.0 / _storage[0]);
    double _y = Math.sqrt(1.0 / _storage[1]);
    double _z = Math.sqrt(1.0 / _storage[2]);
    double _w = Math.sqrt(1.0 / _storage[3]);
    return new NativeFloat32x4(_x, _y, _z, _w);
  }
}


/**
 * Interface of Dart Int32x4 and operations.
 * Int32x4 stores 4 32-bit bit-masks in "lanes".
 * The lanes are "x", "y", "z", and "w" respectively.
 */
class NativeInt32x4 implements Int32x4 {
  final _storage = new NativeInt32List(4);

  NativeInt32x4(int x, int y, int z, int w) {
    _storage[0] = x;
    _storage[1] = y;
    _storage[2] = z;
    _storage[3] = w;
  }

  NativeInt32x4.bool(bool x, bool y, bool z, bool w) {
    _storage[0] = x == true ? 0xFFFFFFFF : 0x0;
    _storage[1] = y == true ? 0xFFFFFFFF : 0x0;
    _storage[2] = z == true ? 0xFFFFFFFF : 0x0;
    _storage[3] = w == true ? 0xFFFFFFFF : 0x0;
  }

  /// Returns a bit-wise copy of [x] as a Int32x4.
  NativeInt32x4.fromFloat32x4Bits(NativeFloat32x4 x) {
    var view = new NativeUint32List.view(x._storage.buffer, 0, null);
    _storage[0] = view[0];
    _storage[1] = view[1];
    _storage[2] = view[2];
    _storage[3] = view[3];
  }

  String toString() {
    return '[${_storage[0]}, ${_storage[1]}, ${_storage[2]}, ${_storage[3]}]';
  }

  /// The bit-wise or operator.
  Int32x4 operator|(NativeInt32x4 other) {
    int _x = _storage[0] | other._storage[0];
    int _y = _storage[1] | other._storage[1];
    int _z = _storage[2] | other._storage[2];
    int _w = _storage[3] | other._storage[3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// The bit-wise and operator.
  Int32x4 operator&(NativeInt32x4 other) {
    int _x = _storage[0] & other._storage[0];
    int _y = _storage[1] & other._storage[1];
    int _z = _storage[2] & other._storage[2];
    int _w = _storage[3] & other._storage[3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// The bit-wise xor operator.
  Int32x4 operator^(NativeInt32x4 other) {
    int _x = _storage[0] ^ other._storage[0];
    int _y = _storage[1] ^ other._storage[1];
    int _z = _storage[2] ^ other._storage[2];
    int _w = _storage[3] ^ other._storage[3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  Int32x4 operator+(NativeInt32x4 other) {
    var r = new NativeInt32x4(0, 0, 0, 0);
    r._storage[0] = (_storage[0] + other._storage[0]);
    r._storage[1] = (_storage[1] + other._storage[1]);
    r._storage[2] = (_storage[2] + other._storage[2]);
    r._storage[3] = (_storage[3] + other._storage[3]);
    return r;
  }

  Int32x4 operator-(NativeInt32x4 other) {
    var r = new NativeInt32x4(0, 0, 0, 0);
    r._storage[0] = (_storage[0] - other._storage[0]);
    r._storage[1] = (_storage[1] - other._storage[1]);
    r._storage[2] = (_storage[2] - other._storage[2]);
    r._storage[3] = (_storage[3] - other._storage[3]);
    return r;
  }

  /// Extract 32-bit mask from x lane.
  int get x => _storage[0];
  /// Extract 32-bit mask from y lane.
  int get y => _storage[1];
  /// Extract 32-bit mask from z lane.
  int get z => _storage[2];
  /// Extract 32-bit mask from w lane.
  int get w => _storage[3];

  /// Extract the top bit from each lane return them in the first 4 bits.
  int get signMask {
    int mx = (_storage[0] & 0x80000000) >> 31;
    int my = (_storage[1] & 0x80000000) >> 31;
    int mz = (_storage[2] & 0x80000000) >> 31;
    int mw = (_storage[3] & 0x80000000) >> 31;
    return mx | my << 1 | mz << 2 | mw << 3;
  }

  /// Shuffle the lane values. [mask] must be one of the 256 shuffle constants.
  Int32x4 shuffle(int mask) {
    if ((mask < 0) || (mask > 255)) {
      throw new RangeError('mask $mask must be in the range [0..256)');
    }
    int _x = _storage[mask & 0x3];
    int _y = _storage[(mask >> 2) & 0x3];
    int _z = _storage[(mask >> 4) & 0x3];
    int _w = _storage[(mask >> 6) & 0x3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// Shuffle the lane values in [this] and [other]. The returned
  /// Int32x4 will have XY lanes from [this] and ZW lanes from [other].
  /// Uses the same [mask] as [shuffle].
  Int32x4 shuffleMix(NativeInt32x4 other, int mask) {
    if ((mask < 0) || (mask > 255)) {
      throw new RangeError('mask $mask must be in the range [0..256)');
    }
    int _x = _storage[mask & 0x3];
    int _y = _storage[(mask >> 2) & 0x3];
    int _z = other._storage[(mask >> 4) & 0x3];
    int _w = other._storage[(mask >> 6) & 0x3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Int32x4] copied from [this] with a new x value.
  Int32x4 withX(int x) {
    int _x = x;
    int _y = _storage[1];
    int _z = _storage[2];
    int _w = _storage[3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Int32x4] copied from [this] with a new y value.
  Int32x4 withY(int y) {
    int _x = _storage[0];
    int _y = y;
    int _z = _storage[2];
    int _w = _storage[3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Int32x4] copied from [this] with a new z value.
  Int32x4 withZ(int z) {
    int _x = _storage[0];
    int _y = _storage[1];
    int _z = z;
    int _w = _storage[3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Int32x4] copied from [this] with a new w value.
  Int32x4 withW(int w) {
    int _x = _storage[0];
    int _y = _storage[1];
    int _z = _storage[2];
    int _w = w;
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// Extracted x value. Returns false for 0, true for any other value.
  bool get flagX => _storage[0] != 0x0;
  /// Extracted y value. Returns false for 0, true for any other value.
  bool get flagY => _storage[1] != 0x0;
  /// Extracted z value. Returns false for 0, true for any other value.
  bool get flagZ => _storage[2] != 0x0;
  /// Extracted w value. Returns false for 0, true for any other value.
  bool get flagW => _storage[3] != 0x0;

  /// Returns a new [Int32x4] copied from [this] with a new x value.
  Int32x4 withFlagX(bool x) {
    int _x = x == true ? 0xFFFFFFFF : 0x0;
    int _y = _storage[1];
    int _z = _storage[2];
    int _w = _storage[3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Int32x4] copied from [this] with a new y value.
  Int32x4 withFlagY(bool y) {
    int _x = _storage[0];
    int _y = y == true ? 0xFFFFFFFF : 0x0;
    int _z = _storage[2];
    int _w = _storage[3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Int32x4] copied from [this] with a new z value.
  Int32x4 withFlagZ(bool z) {
    int _x = _storage[0];
    int _y = _storage[1];
    int _z = z == true ? 0xFFFFFFFF : 0x0;
    int _w = _storage[3];
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Int32x4] copied from [this] with a new w value.
  Int32x4 withFlagW(bool w) {
    int _x = _storage[0];
    int _y = _storage[1];
    int _z = _storage[2];
    int _w = w == true ? 0xFFFFFFFF : 0x0;
    return new NativeInt32x4(_x, _y, _z, _w);
  }

  /// Merge [trueValue] and [falseValue] based on [this]' bit mask:
  /// Select bit from [trueValue] when bit in [this] is on.
  /// Select bit from [falseValue] when bit in [this] is off.
  Float32x4 select(NativeFloat32x4 trueValue, NativeFloat32x4 falseValue) {
    var trueView = trueValue._storage.buffer.asInt32List();
    var falseView = falseValue._storage.buffer.asInt32List();
    int cmx = _storage[0];
    int cmy = _storage[1];
    int cmz = _storage[2];
    int cmw = _storage[3];
    int stx = trueView[0];
    int sty = trueView[1];
    int stz = trueView[2];
    int stw = trueView[3];
    int sfx = falseView[0];
    int sfy = falseView[1];
    int sfz = falseView[2];
    int sfw = falseView[3];
    int _x = (cmx & stx) | (~cmx & sfx);
    int _y = (cmy & sty) | (~cmy & sfy);
    int _z = (cmz & stz) | (~cmz & sfz);
    int _w = (cmw & stw) | (~cmw & sfw);
    var r = new NativeFloat32x4(0.0, 0.0, 0.0, 0.0);
    var rView = r._storage.buffer.asInt32List();
    rView[0] = _x;
    rView[1] = _y;
    rView[2] = _z;
    rView[3] = _w;
    return r;
  }
}

class NativeFloat64x2 implements Float64x2 {
  final _storage = new Float64List(2);

  NativeFloat64x2(double x, double y) {
    _storage[0] = x;
    _storage[1] = y;
  }

  NativeFloat64x2.splat(double v) {
    _storage[0] = v;
    _storage[1] = v;
  }

  NativeFloat64x2.zero();

  NativeFloat64x2.fromFloat32x4(NativeFloat32x4 v) {
    _storage[0] = v._storage[0];
    _storage[1] = v._storage[1];
  }

  String toString() {
    return '[${_storage[0]}, ${_storage[1]}]';
  }

  /// Addition operator.
  Float64x2 operator+(NativeFloat64x2 other) {
    return new NativeFloat64x2(_storage[0] + other._storage[0],
                               _storage[1] + other._storage[1]);
  }

  /// Negate operator.
  Float64x2 operator-() {
    return new NativeFloat64x2(-_storage[0], -_storage[1]);
  }

  /// Subtraction operator.
  Float64x2 operator-(NativeFloat64x2 other) {
    return new NativeFloat64x2(_storage[0] - other._storage[0],
                               _storage[1] - other._storage[1]);
  }
  /// Multiplication operator.
  Float64x2 operator*(NativeFloat64x2 other) {
    return new NativeFloat64x2(_storage[0] * other._storage[0],
                          _storage[1] * other._storage[1]);
  }
  /// Division operator.
  Float64x2 operator/(NativeFloat64x2 other) {
    return new NativeFloat64x2(_storage[0] / other._storage[0],
                          _storage[1] / other._storage[1]);
  }

  /// Returns a copy of [this] each lane being scaled by [s].
  Float64x2 scale(double s) {
    return new NativeFloat64x2(_storage[0] * s, _storage[1] * s);
  }

  /// Returns the absolute value of this [Float64x2].
  Float64x2 abs() {
    return new NativeFloat64x2(_storage[0].abs(), _storage[1].abs());
  }

  /// Clamps [this] to be in the range [lowerLimit]-[upperLimit].
  Float64x2 clamp(NativeFloat64x2 lowerLimit,
                  NativeFloat64x2 upperLimit) {
    double _lx = lowerLimit._storage[0];
    double _ly = lowerLimit._storage[1];
    double _ux = upperLimit._storage[0];
    double _uy = upperLimit._storage[1];
    double _x = _storage[0];
    double _y = _storage[1];
    // MAX(MIN(self, upper), lower).
    _x = _x > _ux ? _ux : _x;
    _y = _y > _uy ? _uy : _y;
    _x = _x < _lx ? _lx : _x;
    _y = _y < _ly ? _ly : _y;
    return new NativeFloat64x2(_x, _y);
  }

  /// Extracted x value.
  double get x => _storage[0];
  /// Extracted y value.
  double get y => _storage[1];

  /// Extract the sign bits from each lane return them in the first 2 bits.
  int get signMask {
    var view = _storage.buffer.asUint32List();
    var mx = (view[1] & 0x80000000) >> 31;
    var my = (view[3] & 0x80000000) >> 31;
    return mx | my << 1;
  }

  /// Returns a new [Float64x2] copied from [this] with a new x value.
  Float64x2 withX(double x) {
    return new NativeFloat64x2(x, _storage[1]);
  }

  /// Returns a new [Float64x2] copied from [this] with a new y value.
  Float64x2 withY(double y) {
    return new NativeFloat64x2(_storage[0], y);
  }

  /// Returns the lane-wise minimum value in [this] or [other].
  Float64x2 min(NativeFloat64x2 other) {
    return new NativeFloat64x2(
        _storage[0] < other._storage[0] ? _storage[0] : other._storage[0],
        _storage[1] < other._storage[1] ? _storage[1] : other._storage[1]);

  }

  /// Returns the lane-wise maximum value in [this] or [other].
  Float64x2 max(NativeFloat64x2 other) {
    return new NativeFloat64x2(
        _storage[0] > other._storage[0] ? _storage[0] : other._storage[0],
        _storage[1] > other._storage[1] ? _storage[1] : other._storage[1]);
  }

  /// Returns the lane-wise square root of [this].
  Float64x2 sqrt() {
    return new NativeFloat64x2(Math.sqrt(_storage[0]), Math.sqrt(_storage[1]));
  }
}
