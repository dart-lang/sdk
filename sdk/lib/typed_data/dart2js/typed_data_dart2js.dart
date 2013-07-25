// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The Dart TypedData library.
library dart.typed_data;

import 'dart:collection';
import 'dart:_collection-dev';
import 'dart:_js_helper' show Creates, JavaScriptIndexingBehavior, JSName, Null, Returns;
import 'dart:_foreign_helper' show JS;
import 'dart:math' as Math;

/**
 * Describes endianness to be used when accessing a sequence of bytes.
 */
class Endianness {
  const Endianness(this._littleEndian);

  static const Endianness BIG_ENDIAN = const Endianness(false);
  static const Endianness LITTLE_ENDIAN = const Endianness(true);
  static final Endianness HOST_ENDIAN =
    (new ByteData.view(new Int16List.fromList([1]).buffer)).getInt8(0) == 1 ?
    LITTLE_ENDIAN : BIG_ENDIAN;

  final bool _littleEndian;
}


class ByteBuffer native "ArrayBuffer" {
  @JSName('byteLength')
  final int lengthInBytes;
}


class TypedData native "ArrayBufferView" {
  @Creates('ByteBuffer')
  @Returns('ByteBuffer|Null')
  final ByteBuffer buffer;

  @JSName('byteLength')
  final int lengthInBytes;

  @JSName('byteOffset')
  final int offsetInBytes;

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
    if (JS('bool', '(# >>> 0 != #)', index, index) || index >= length) {
      _invalidIndex(index, length);
    }
  }

  int _checkSublistArguments(int start, int end, int length) {
    // For `sublist` the [start] and [end] indices are allowed to be equal to
    // [length]. However, [_checkIndex] only allows incides in the range
    // 0 .. length - 1. We therefore increment the [length] argument by one
    // for the [_checkIndex] checks.
    _checkIndex(start, length + 1);
    if (end == null) return length;
    _checkIndex(end, length + 1);
    if (start > end) throw new RangeError.range(start, 0, end);
    return end;
  }
}


// Ensures that [list] is a JavaScript Array or a typed array.  If necessary,
// returns a copy of the list.
List _ensureNativeList(List list) {
  return list;  // TODO: make sure.
}


class ByteData extends TypedData native "DataView" {
  factory ByteData(int length) => _create1(length);

  factory ByteData.view(ByteBuffer buffer,
                        [int byteOffset = 0, int byteLength]) =>
      byteLength == null
          ? _create2(buffer, byteOffset)
          : _create3(buffer, byteOffset, byteLength);

  num getFloat32(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getFloat32(byteOffset, endian._littleEndian);

  @JSName('getFloat32')
  @Returns('num')
  num _getFloat32(int byteOffset, [bool littleEndian]) native;

  num getFloat64(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getFloat64(byteOffset, endian._littleEndian);

  @JSName('getFloat64')
  @Returns('num')
  num _getFloat64(int byteOffset, [bool littleEndian]) native;

  int getInt16(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getInt16(byteOffset, endian._littleEndian);

  @JSName('getInt16')
  @Returns('int')
  int _getInt16(int byteOffset, [bool littleEndian]) native;

  int getInt32(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getInt32(byteOffset, endian._littleEndian);

  @JSName('getInt32')
  @Returns('int')
  int _getInt32(int byteOffset, [bool littleEndian]) native;

  int getInt64(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError("Int64 accessor not supported by dart2js.");
  }

  int getInt8(int byteOffset) native;

  int getUint16(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getUint16(byteOffset, endian._littleEndian);

  @JSName('getUint16')
  @Returns('int')
  int _getUint16(int byteOffset, [bool littleEndian]) native;

  int getUint32(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getUint32(byteOffset, endian._littleEndian);

  @JSName('getUint32')
  @Returns('int')
  int _getUint32(int byteOffset, [bool littleEndian]) native;

  int getUint64(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError("Uint64 accessor not supported by dart2js.");
  }

  int getUint8(int byteOffset) native;

  void setFloat32(int byteOffset, num value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setFloat32(byteOffset, value, endian._littleEndian);

  @JSName('setFloat32')
  void _setFloat32(int byteOffset, num value, [bool littleEndian]) native;

  void setFloat64(int byteOffset, num value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setFloat64(byteOffset, value, endian._littleEndian);

  @JSName('setFloat64')
  void _setFloat64(int byteOffset, num value, [bool littleEndian]) native;

  void setInt16(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setInt16(byteOffset, value, endian._littleEndian);

  @JSName('setInt16')
  void _setInt16(int byteOffset, int value, [bool littleEndian]) native;

  void setInt32(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setInt32(byteOffset, value, endian._littleEndian);

  @JSName('setInt32')
  void _setInt32(int byteOffset, int value, [bool littleEndian]) native;

  void setInt64(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError("Int64 accessor not supported by dart2js.");
  }

  void setInt8(int byteOffset, int value) native;

  void setUint16(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setUint16(byteOffset, value, endian._littleEndian);

  @JSName('setUint16')
  void _setUint16(int byteOffset, int value, [bool littleEndian]) native;

  void setUint32(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setUint32(byteOffset, value, endian._littleEndian);

  @JSName('setUint32')
  void _setUint32(int byteOffset, int value, [bool littleEndian]) native;

  void setUint64(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError("Uint64 accessor not supported by dart2js.");
  }

  void setUint8(int byteOffset, int value) native;

  static ByteData _create1(arg) =>
      JS('ByteData', 'new DataView(new ArrayBuffer(#))', arg);

  static ByteData _create2(arg1, arg2) =>
      JS('ByteData', 'new DataView(#, #)', arg1, arg2);

  static ByteData _create3(arg1, arg2, arg3) =>
      JS('ByteData', 'new DataView(#, #, #)', arg1, arg2, arg3);
}


class Float32List
    extends TypedData with ListMixin<double>, FixedLengthListMixin<double>
    implements JavaScriptIndexingBehavior, List<double>
    native "Float32Array" {
  factory Float32List(int length) => _create1(length);

  factory Float32List.fromList(List<num> list) =>
      _create1(_ensureNativeList(list));

  factory Float32List.view(ByteBuffer buffer,
                           [int byteOffset = 0, int length]) =>
      length == null
          ? _create2(buffer, byteOffset)
          : _create3(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  int get length => JS("int", "#.length", this);

  num operator[](int index) {
    _checkIndex(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
    _checkIndex(index, length);
    JS("void", "#[#] = #", this, index, value);
  }

  List<double> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('Float32List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static Float32List _create1(arg) =>
      JS('Float32List', 'new Float32Array(#)', arg);

  static Float32List _create2(arg1, arg2) =>
      JS('Float32List', 'new Float32Array(#, #)', arg1, arg2);

  static Float32List _create3(arg1, arg2, arg3) =>
      JS('Float32List', 'new Float32Array(#, #, #)', arg1, arg2, arg3);
}


class Float64List
    extends TypedData with ListMixin<double>, FixedLengthListMixin<double>
    implements JavaScriptIndexingBehavior, List<double>
    native "Float64Array" {
  factory Float64List(int length) => _create1(length);

  factory Float64List.fromList(List<num> list) =>
      _create1(_ensureNativeList(list));

  factory Float64List.view(ByteBuffer buffer,
                           [int byteOffset = 0, int length]) =>
      length == null
          ? _create2(buffer, byteOffset)
          : _create3(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 8;

  int get length => JS("int", "#.length", this);

  num operator[](int index) {
    _checkIndex(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
    _checkIndex(index, length);
    JS("void", "#[#] = #", this, index, value);
  }

  List<double> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('Float64List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static Float64List _create1(arg) =>
      JS('Float64List', 'new Float64Array(#)', arg);

  static Float64List _create2(arg1, arg2) =>
      JS('Float64List', 'new Float64Array(#, #)', arg1, arg2);

  static Float64List _create3(arg1, arg2, arg3) =>
      JS('Float64List', 'new Float64Array(#, #, #)', arg1, arg2, arg3);
}


class Int16List
    extends TypedData with ListMixin<int>, FixedLengthListMixin<int>
    implements JavaScriptIndexingBehavior, List<int>
    native "Int16Array" {
  factory Int16List(int length) => _create1(length);

  factory Int16List.fromList(List<num> list) =>
      _create1(_ensureNativeList(list));

  factory Int16List.view(ByteBuffer buffer, [int byteOffset = 0, int length]) =>
      length == null
          ? _create2(buffer, byteOffset)
          : _create3(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 2;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkIndex(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkIndex(index, length);
    JS("void", "#[#] = #", this, index, value);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('Int16List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static Int16List _create1(arg) =>
      JS('Int16List', 'new Int16Array(#)', arg);

  static Int16List _create2(arg1, arg2) =>
      JS('Int16List', 'new Int16Array(#, #)', arg1, arg2);

  static Int16List _create3(arg1, arg2, arg3) =>
      JS('Int16List', 'new Int16Array(#, #, #)', arg1, arg2, arg3);
}


class Int32List
    extends TypedData with ListMixin<int>, FixedLengthListMixin<int>
    implements JavaScriptIndexingBehavior, List<int>
    native "Int32Array" {
  factory Int32List(int length) => _create1(length);

  factory Int32List.fromList(List<num> list) =>
      _create1(_ensureNativeList(list));

  factory Int32List.view(ByteBuffer buffer, [int byteOffset = 0, int length]) =>
      length == null
          ? _create2(buffer, byteOffset)
          : _create3(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkIndex(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkIndex(index, length);
    JS("void", "#[#] = #", this, index, value);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('Int32List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static Int32List _create1(arg) =>
      JS('Int32List', 'new Int32Array(#)', arg);

  static Int32List _create2(arg1, arg2) =>
      JS('Int32List', 'new Int32Array(#, #)', arg1, arg2);

  static Int32List _create3(arg1, arg2, arg3) =>
      JS('Int32List', 'new Int32Array(#, #, #)', arg1, arg2, arg3);
}


class Int8List
    extends TypedData with ListMixin<int>, FixedLengthListMixin<int>
    implements JavaScriptIndexingBehavior, List<int>
    native "Int8Array" {
  factory Int8List(int length) => _create1(length);

  factory Int8List.fromList(List<num> list) =>
      _create1(_ensureNativeList(list));

  factory Int8List.view(ByteBuffer buffer, [int byteOffset = 0, int length]) =>
      length == null
          ? _create2(buffer, byteOffset)
          : _create3(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 1;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkIndex(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkIndex(index, length);
    JS("void", "#[#] = #", this, index, value);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('Int8List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static Int8List _create1(arg) =>
      JS('Int8List', 'new Int8Array(#)', arg);

  static Int8List _create2(arg1, arg2) =>
      JS('Int8List', 'new Int8Array(#, #)', arg1, arg2);

  static Int8List _create3(arg1, arg2, arg3) =>
      JS('Int8List', 'new Int8Array(#, #, #)', arg1, arg2, arg3);
}


class Uint16List
    extends TypedData with ListMixin<int>, FixedLengthListMixin<int>
    implements JavaScriptIndexingBehavior, List<int>
    native "Uint16Array" {
  factory Uint16List(int length) => _create1(length);

  factory Uint16List.fromList(List<num> list) =>
      _create1(_ensureNativeList(list));

  factory Uint16List.view(ByteBuffer buffer,
                          [int byteOffset = 0, int length]) =>
      length == null
          ? _create2(buffer, byteOffset)
          : _create3(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 2;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkIndex(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkIndex(index, length);
    JS("void", "#[#] = #", this, index, value);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('Uint16List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static Uint16List _create1(arg) =>
      JS('Uint16List', 'new Uint16Array(#)', arg);

  static Uint16List _create2(arg1, arg2) =>
      JS('Uint16List', 'new Uint16Array(#, #)', arg1, arg2);

  static Uint16List _create3(arg1, arg2, arg3) =>
      JS('Uint16List', 'new Uint16Array(#, #, #)', arg1, arg2, arg3);
}


class Uint32List
    extends TypedData with ListMixin<int>, FixedLengthListMixin<int>
    implements JavaScriptIndexingBehavior, List<int>
    native "Uint32Array" {
  factory Uint32List(int length) => _create1(length);

  factory Uint32List.fromList(List<num> list) =>
      _create1(_ensureNativeList(list));

  factory Uint32List.view(ByteBuffer buffer,
                          [int byteOffset = 0, int length]) =>
      length == null
          ? _create2(buffer, byteOffset)
          : _create3(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkIndex(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkIndex(index, length);
    JS("void", "#[#] = #", this, index, value);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('Uint32List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static Uint32List _create1(arg) =>
      JS('Uint32List', 'new Uint32Array(#)', arg);

  static Uint32List _create2(arg1, arg2) =>
      JS('Uint32List', 'new Uint32Array(#, #)', arg1, arg2);

  static Uint32List _create3(arg1, arg2, arg3) =>
      JS('Uint32List', 'new Uint32Array(#, #, #)', arg1, arg2, arg3);
}


class Uint8ClampedList extends Uint8List
    native "Uint8ClampedArray,CanvasPixelArray" {
  factory Uint8ClampedList(int length) => _create1(length);

  factory Uint8ClampedList.fromList(List<num> list) =>
      _create1(_ensureNativeList(list));

  factory Uint8ClampedList.view(ByteBuffer buffer,
                                [int byteOffset = 0, int length]) =>
      length == null
          ? _create2(buffer, byteOffset)
          : _create3(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 1;

  // Use implementation from Uint8List
  // final int length;

  int operator[](int index) {
    _checkIndex(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkIndex(index, length);
    JS("void", "#[#] = #", this, index, value);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('Uint8ClampedList', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static Uint8ClampedList _create1(arg) =>
      JS('Uint8ClampedList', 'new Uint8ClampedArray(#)', arg);

  static Uint8ClampedList _create2(arg1, arg2) =>
      JS('Uint8ClampedList', 'new Uint8ClampedArray(#, #)', arg1, arg2);

  static Uint8ClampedList _create3(arg1, arg2, arg3) =>
      JS('Uint8ClampedList', 'new Uint8ClampedArray(#, #, #)', arg1, arg2, arg3);
}


class Uint8List
    extends TypedData with ListMixin<int>, FixedLengthListMixin<int>
    implements JavaScriptIndexingBehavior, List<int>
    native "Uint8Array" {
  factory Uint8List(int length) => _create1(length);

  factory Uint8List.fromList(List<num> list) =>
      _create1(_ensureNativeList(list));

  factory Uint8List.view(ByteBuffer buffer,
                         [int byteOffset = 0, int length]) =>
      length == null
          ? _create2(buffer, byteOffset)
          : _create3(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 1;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkIndex(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkIndex(index, length);
    JS("void", "#[#] = #", this, index, value);
  }

  List<int> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    var source = JS('Uint8List', '#.subarray(#, #)', this, start, end);
    return _create1(source);
  }

  static Uint8List _create1(arg) =>
      JS('Uint8List', 'new Uint8Array(#)', arg);

  static Uint8List _create2(arg1, arg2) =>
      JS('Uint8List', 'new Uint8Array(#, #)', arg1, arg2);

  static Uint8List _create3(arg1, arg2, arg3) =>
      JS('Uint8List', 'new Uint8Array(#, #, #)', arg1, arg2, arg3);
}


class Int64List extends TypedData implements JavaScriptIndexingBehavior, List<int> {
  factory Int64List(int length) {
    throw new UnsupportedError("Int64List not supported by dart2js.");
  }

  factory Int64List.fromList(List<int> list) {
    throw new UnsupportedError("Int64List not supported by dart2js.");
  }

  factory Int64List.view(ByteBuffer buffer, [int byteOffset, int length]) {
    throw new UnsupportedError("Int64List not supported by dart2js.");
  }

  static const int BYTES_PER_ELEMENT = 8;
}


class Uint64List extends TypedData implements JavaScriptIndexingBehavior, List<int> {
  factory Uint64List(int length) {
    throw new UnsupportedError("Uint64List not supported by dart2js.");
  }

  factory Uint64List.fromList(List<int> list) {
    throw new UnsupportedError("Uint64List not supported by dart2js.");
  }

  factory Uint64List.view(ByteBuffer buffer, [int byteOffset, int length]) {
    throw new UnsupportedError("Uint64List not supported by dart2js.");
  }

  static const int BYTES_PER_ELEMENT = 8;
}


class Float32x4List
    extends Object with ListMixin<Float32x4>, FixedLengthListMixin<Float32x4>
    implements List<Float32x4>, TypedData {

  final Float32List _storage;

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  final int elementSizeInBytes = 16;

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
    // [length]. However, [_checkIndex] only allows incides in the range
    // 0 .. length - 1. We therefore increment the [length] argument by one
    // for the [_checkIndex] checks.
    _checkIndex(start, length + 1);
    if (end == null) return length;
    _checkIndex(end, length + 1);
    if (start > end) throw new RangeError.range(start, 0, end);
    return end;
  }

  Float32x4List(int length) : _storage = new Float32List(length*4);

  Float32x4List._externalStorage(Float32List storage) : _storage = storage;

  Float32x4List._slowFromList(List<Float32x4> list)
      : _storage = new Float32List(list.length * 4) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i*4)+0] = e.x;
      _storage[(i*4)+1] = e.y;
      _storage[(i*4)+2] = e.z;
      _storage[(i*4)+3] = e.w;
    }
  }

  factory Float32x4List.fromList(List<Float32x4> list) {
    if (list is Float32x4List) {
      return new Float32x4List._externalStorage(
          new Float32List.fromList(list._storage));
    } else {
      return new Float32x4List._slowFromList(list);
    }
  }

  Float32x4List.view(ByteBuffer buffer,
                     [int byteOffset = 0, int length])
      : _storage = new Float32List.view(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 16;

  int get length => _storage.length ~/ 4;

  Float32x4 operator[](int index) {
    _checkIndex(index, length);
    double _x = _storage[(index*4)+0];
    double _y = _storage[(index*4)+1];
    double _z = _storage[(index*4)+2];
    double _w = _storage[(index*4)+3];
    return new Float32x4(_x, _y, _z, _w);
  }

  void operator[]=(int index, Float32x4 value) {
    _checkIndex(index, length);
    _storage[(index*4)+0] = value._storage[0];
    _storage[(index*4)+1] = value._storage[1];
    _storage[(index*4)+2] = value._storage[2];
    _storage[(index*4)+3] = value._storage[3];
  }

  List<Float32x4> sublist(int start, [int end]) {
    end = _checkSublistArguments(start, end, length);
    return new Float32x4List._externalStorage(_storage.sublist(start*4, end*4));
  }
}


class Float32x4 {
  final _storage = new Float32List(4);

  Float32x4(double x, double y, double z, double w) {
    _storage[0] = x;
    _storage[1] = y;
    _storage[2] = z;
    _storage[3] = w;
  }
  Float32x4.splat(double v) {
    _storage[0] = v;
    _storage[1] = v;
    _storage[2] = v;
    _storage[3] = v;
  }
  Float32x4.zero();

   /// Addition operator.
  Float32x4 operator+(Float32x4 other) {
    double _x = _storage[0] + other._storage[0];
    double _y = _storage[1] + other._storage[1];
    double _z = _storage[2] + other._storage[2];
    double _w = _storage[3] + other._storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Negate operator.
  Float32x4 operator-() {
    double _x = -_storage[0];
    double _y = -_storage[1];
    double _z = -_storage[2];
    double _w = -_storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Subtraction operator.
  Float32x4 operator-(Float32x4 other) {
    double _x = _storage[0] - other._storage[0];
    double _y = _storage[1] - other._storage[1];
    double _z = _storage[2] - other._storage[2];
    double _w = _storage[3] - other._storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Multiplication operator.
  Float32x4 operator*(Float32x4 other) {
    double _x = _storage[0] * other._storage[0];
    double _y = _storage[1] * other._storage[1];
    double _z = _storage[2] * other._storage[2];
    double _w = _storage[3] * other._storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Division operator.
  Float32x4 operator/(Float32x4 other) {
    double _x = _storage[0] / other._storage[0];
    double _y = _storage[1] / other._storage[1];
    double _z = _storage[2] / other._storage[2];
    double _w = _storage[3] / other._storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Relational less than.
  Uint32x4 lessThan(Float32x4 other) {
    bool _cx = _storage[0] < other._storage[0];
    bool _cy = _storage[1] < other._storage[1];
    bool _cz = _storage[2] < other._storage[2];
    bool _cw = _storage[3] < other._storage[3];
    return new Uint32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Relational less than or equal.
  Uint32x4 lessThanOrEqual(Float32x4 other) {
    bool _cx = _storage[0] <= other._storage[0];
    bool _cy = _storage[1] <= other._storage[1];
    bool _cz = _storage[2] <= other._storage[2];
    bool _cw = _storage[3] <= other._storage[3];
    return new Uint32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Relational greater than.
  Uint32x4 greaterThan(Float32x4 other) {
    bool _cx = _storage[0] > other._storage[0];
    bool _cy = _storage[1] > other._storage[1];
    bool _cz = _storage[2] > other._storage[2];
    bool _cw = _storage[3] > other._storage[3];
    return new Uint32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Relational greater than or equal.
  Uint32x4 greaterThanOrEqual(Float32x4 other) {
    bool _cx = _storage[0] >= other._storage[0];
    bool _cy = _storage[1] >= other._storage[1];
    bool _cz = _storage[2] >= other._storage[2];
    bool _cw = _storage[3] >= other._storage[3];
    return new Uint32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Relational equal.
  Uint32x4 equal(Float32x4 other) {
    bool _cx = _storage[0] == other._storage[0];
    bool _cy = _storage[1] == other._storage[1];
    bool _cz = _storage[2] == other._storage[2];
    bool _cw = _storage[3] == other._storage[3];
    return new Uint32x4(_cx == true ? 0xFFFFFFFF : 0x0,
                        _cy == true ? 0xFFFFFFFF : 0x0,
                        _cz == true ? 0xFFFFFFFF : 0x0,
                        _cw == true ? 0xFFFFFFFF : 0x0);
  }

  /// Relational not-equal.
  Uint32x4 notEqual(Float32x4 other) {
    bool _cx = _storage[0] != other._storage[0];
    bool _cy = _storage[1] != other._storage[1];
    bool _cz = _storage[2] != other._storage[2];
    bool _cw = _storage[3] != other._storage[3];
    return new Uint32x4(_cx == true ? 0xFFFFFFFF : 0x0,
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
    return new Float32x4(_x, _y, _z, _w);
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
  Float32x4 clamp(Float32x4 lowerLimit, Float32x4 upperLimit) {
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
    _x = _x < _lx ? _lx : _x;
    _x = _x > _ux ? _ux : _x;
    _y = _y < _ly ? _ly : _y;
    _y = _y > _uy ? _uy : _y;
    _z = _z < _lz ? _lz : _z;
    _z = _z > _uz ? _uz : _z;
    _w = _w < _lw ? _lw : _w;
    _w = _w > _uw ? _uw : _w;
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

  Float32x4 get xxxx => _shuffle(0x0);
  Float32x4 get xxxy => _shuffle(0x40);
  Float32x4 get xxxz => _shuffle(0x80);
  Float32x4 get xxxw => _shuffle(0xC0);
  Float32x4 get xxyx => _shuffle(0x10);
  Float32x4 get xxyy => _shuffle(0x50);
  Float32x4 get xxyz => _shuffle(0x90);
  Float32x4 get xxyw => _shuffle(0xD0);
  Float32x4 get xxzx => _shuffle(0x20);
  Float32x4 get xxzy => _shuffle(0x60);
  Float32x4 get xxzz => _shuffle(0xA0);
  Float32x4 get xxzw => _shuffle(0xE0);
  Float32x4 get xxwx => _shuffle(0x30);
  Float32x4 get xxwy => _shuffle(0x70);
  Float32x4 get xxwz => _shuffle(0xB0);
  Float32x4 get xxww => _shuffle(0xF0);
  Float32x4 get xyxx => _shuffle(0x4);
  Float32x4 get xyxy => _shuffle(0x44);
  Float32x4 get xyxz => _shuffle(0x84);
  Float32x4 get xyxw => _shuffle(0xC4);
  Float32x4 get xyyx => _shuffle(0x14);
  Float32x4 get xyyy => _shuffle(0x54);
  Float32x4 get xyyz => _shuffle(0x94);
  Float32x4 get xyyw => _shuffle(0xD4);
  Float32x4 get xyzx => _shuffle(0x24);
  Float32x4 get xyzy => _shuffle(0x64);
  Float32x4 get xyzz => _shuffle(0xA4);
  Float32x4 get xyzw => _shuffle(0xE4);
  Float32x4 get xywx => _shuffle(0x34);
  Float32x4 get xywy => _shuffle(0x74);
  Float32x4 get xywz => _shuffle(0xB4);
  Float32x4 get xyww => _shuffle(0xF4);
  Float32x4 get xzxx => _shuffle(0x8);
  Float32x4 get xzxy => _shuffle(0x48);
  Float32x4 get xzxz => _shuffle(0x88);
  Float32x4 get xzxw => _shuffle(0xC8);
  Float32x4 get xzyx => _shuffle(0x18);
  Float32x4 get xzyy => _shuffle(0x58);
  Float32x4 get xzyz => _shuffle(0x98);
  Float32x4 get xzyw => _shuffle(0xD8);
  Float32x4 get xzzx => _shuffle(0x28);
  Float32x4 get xzzy => _shuffle(0x68);
  Float32x4 get xzzz => _shuffle(0xA8);
  Float32x4 get xzzw => _shuffle(0xE8);
  Float32x4 get xzwx => _shuffle(0x38);
  Float32x4 get xzwy => _shuffle(0x78);
  Float32x4 get xzwz => _shuffle(0xB8);
  Float32x4 get xzww => _shuffle(0xF8);
  Float32x4 get xwxx => _shuffle(0xC);
  Float32x4 get xwxy => _shuffle(0x4C);
  Float32x4 get xwxz => _shuffle(0x8C);
  Float32x4 get xwxw => _shuffle(0xCC);
  Float32x4 get xwyx => _shuffle(0x1C);
  Float32x4 get xwyy => _shuffle(0x5C);
  Float32x4 get xwyz => _shuffle(0x9C);
  Float32x4 get xwyw => _shuffle(0xDC);
  Float32x4 get xwzx => _shuffle(0x2C);
  Float32x4 get xwzy => _shuffle(0x6C);
  Float32x4 get xwzz => _shuffle(0xAC);
  Float32x4 get xwzw => _shuffle(0xEC);
  Float32x4 get xwwx => _shuffle(0x3C);
  Float32x4 get xwwy => _shuffle(0x7C);
  Float32x4 get xwwz => _shuffle(0xBC);
  Float32x4 get xwww => _shuffle(0xFC);
  Float32x4 get yxxx => _shuffle(0x1);
  Float32x4 get yxxy => _shuffle(0x41);
  Float32x4 get yxxz => _shuffle(0x81);
  Float32x4 get yxxw => _shuffle(0xC1);
  Float32x4 get yxyx => _shuffle(0x11);
  Float32x4 get yxyy => _shuffle(0x51);
  Float32x4 get yxyz => _shuffle(0x91);
  Float32x4 get yxyw => _shuffle(0xD1);
  Float32x4 get yxzx => _shuffle(0x21);
  Float32x4 get yxzy => _shuffle(0x61);
  Float32x4 get yxzz => _shuffle(0xA1);
  Float32x4 get yxzw => _shuffle(0xE1);
  Float32x4 get yxwx => _shuffle(0x31);
  Float32x4 get yxwy => _shuffle(0x71);
  Float32x4 get yxwz => _shuffle(0xB1);
  Float32x4 get yxww => _shuffle(0xF1);
  Float32x4 get yyxx => _shuffle(0x5);
  Float32x4 get yyxy => _shuffle(0x45);
  Float32x4 get yyxz => _shuffle(0x85);
  Float32x4 get yyxw => _shuffle(0xC5);
  Float32x4 get yyyx => _shuffle(0x15);
  Float32x4 get yyyy => _shuffle(0x55);
  Float32x4 get yyyz => _shuffle(0x95);
  Float32x4 get yyyw => _shuffle(0xD5);
  Float32x4 get yyzx => _shuffle(0x25);
  Float32x4 get yyzy => _shuffle(0x65);
  Float32x4 get yyzz => _shuffle(0xA5);
  Float32x4 get yyzw => _shuffle(0xE5);
  Float32x4 get yywx => _shuffle(0x35);
  Float32x4 get yywy => _shuffle(0x75);
  Float32x4 get yywz => _shuffle(0xB5);
  Float32x4 get yyww => _shuffle(0xF5);
  Float32x4 get yzxx => _shuffle(0x9);
  Float32x4 get yzxy => _shuffle(0x49);
  Float32x4 get yzxz => _shuffle(0x89);
  Float32x4 get yzxw => _shuffle(0xC9);
  Float32x4 get yzyx => _shuffle(0x19);
  Float32x4 get yzyy => _shuffle(0x59);
  Float32x4 get yzyz => _shuffle(0x99);
  Float32x4 get yzyw => _shuffle(0xD9);
  Float32x4 get yzzx => _shuffle(0x29);
  Float32x4 get yzzy => _shuffle(0x69);
  Float32x4 get yzzz => _shuffle(0xA9);
  Float32x4 get yzzw => _shuffle(0xE9);
  Float32x4 get yzwx => _shuffle(0x39);
  Float32x4 get yzwy => _shuffle(0x79);
  Float32x4 get yzwz => _shuffle(0xB9);
  Float32x4 get yzww => _shuffle(0xF9);
  Float32x4 get ywxx => _shuffle(0xD);
  Float32x4 get ywxy => _shuffle(0x4D);
  Float32x4 get ywxz => _shuffle(0x8D);
  Float32x4 get ywxw => _shuffle(0xCD);
  Float32x4 get ywyx => _shuffle(0x1D);
  Float32x4 get ywyy => _shuffle(0x5D);
  Float32x4 get ywyz => _shuffle(0x9D);
  Float32x4 get ywyw => _shuffle(0xDD);
  Float32x4 get ywzx => _shuffle(0x2D);
  Float32x4 get ywzy => _shuffle(0x6D);
  Float32x4 get ywzz => _shuffle(0xAD);
  Float32x4 get ywzw => _shuffle(0xED);
  Float32x4 get ywwx => _shuffle(0x3D);
  Float32x4 get ywwy => _shuffle(0x7D);
  Float32x4 get ywwz => _shuffle(0xBD);
  Float32x4 get ywww => _shuffle(0xFD);
  Float32x4 get zxxx => _shuffle(0x2);
  Float32x4 get zxxy => _shuffle(0x42);
  Float32x4 get zxxz => _shuffle(0x82);
  Float32x4 get zxxw => _shuffle(0xC2);
  Float32x4 get zxyx => _shuffle(0x12);
  Float32x4 get zxyy => _shuffle(0x52);
  Float32x4 get zxyz => _shuffle(0x92);
  Float32x4 get zxyw => _shuffle(0xD2);
  Float32x4 get zxzx => _shuffle(0x22);
  Float32x4 get zxzy => _shuffle(0x62);
  Float32x4 get zxzz => _shuffle(0xA2);
  Float32x4 get zxzw => _shuffle(0xE2);
  Float32x4 get zxwx => _shuffle(0x32);
  Float32x4 get zxwy => _shuffle(0x72);
  Float32x4 get zxwz => _shuffle(0xB2);
  Float32x4 get zxww => _shuffle(0xF2);
  Float32x4 get zyxx => _shuffle(0x6);
  Float32x4 get zyxy => _shuffle(0x46);
  Float32x4 get zyxz => _shuffle(0x86);
  Float32x4 get zyxw => _shuffle(0xC6);
  Float32x4 get zyyx => _shuffle(0x16);
  Float32x4 get zyyy => _shuffle(0x56);
  Float32x4 get zyyz => _shuffle(0x96);
  Float32x4 get zyyw => _shuffle(0xD6);
  Float32x4 get zyzx => _shuffle(0x26);
  Float32x4 get zyzy => _shuffle(0x66);
  Float32x4 get zyzz => _shuffle(0xA6);
  Float32x4 get zyzw => _shuffle(0xE6);
  Float32x4 get zywx => _shuffle(0x36);
  Float32x4 get zywy => _shuffle(0x76);
  Float32x4 get zywz => _shuffle(0xB6);
  Float32x4 get zyww => _shuffle(0xF6);
  Float32x4 get zzxx => _shuffle(0xA);
  Float32x4 get zzxy => _shuffle(0x4A);
  Float32x4 get zzxz => _shuffle(0x8A);
  Float32x4 get zzxw => _shuffle(0xCA);
  Float32x4 get zzyx => _shuffle(0x1A);
  Float32x4 get zzyy => _shuffle(0x5A);
  Float32x4 get zzyz => _shuffle(0x9A);
  Float32x4 get zzyw => _shuffle(0xDA);
  Float32x4 get zzzx => _shuffle(0x2A);
  Float32x4 get zzzy => _shuffle(0x6A);
  Float32x4 get zzzz => _shuffle(0xAA);
  Float32x4 get zzzw => _shuffle(0xEA);
  Float32x4 get zzwx => _shuffle(0x3A);
  Float32x4 get zzwy => _shuffle(0x7A);
  Float32x4 get zzwz => _shuffle(0xBA);
  Float32x4 get zzww => _shuffle(0xFA);
  Float32x4 get zwxx => _shuffle(0xE);
  Float32x4 get zwxy => _shuffle(0x4E);
  Float32x4 get zwxz => _shuffle(0x8E);
  Float32x4 get zwxw => _shuffle(0xCE);
  Float32x4 get zwyx => _shuffle(0x1E);
  Float32x4 get zwyy => _shuffle(0x5E);
  Float32x4 get zwyz => _shuffle(0x9E);
  Float32x4 get zwyw => _shuffle(0xDE);
  Float32x4 get zwzx => _shuffle(0x2E);
  Float32x4 get zwzy => _shuffle(0x6E);
  Float32x4 get zwzz => _shuffle(0xAE);
  Float32x4 get zwzw => _shuffle(0xEE);
  Float32x4 get zwwx => _shuffle(0x3E);
  Float32x4 get zwwy => _shuffle(0x7E);
  Float32x4 get zwwz => _shuffle(0xBE);
  Float32x4 get zwww => _shuffle(0xFE);
  Float32x4 get wxxx => _shuffle(0x3);
  Float32x4 get wxxy => _shuffle(0x43);
  Float32x4 get wxxz => _shuffle(0x83);
  Float32x4 get wxxw => _shuffle(0xC3);
  Float32x4 get wxyx => _shuffle(0x13);
  Float32x4 get wxyy => _shuffle(0x53);
  Float32x4 get wxyz => _shuffle(0x93);
  Float32x4 get wxyw => _shuffle(0xD3);
  Float32x4 get wxzx => _shuffle(0x23);
  Float32x4 get wxzy => _shuffle(0x63);
  Float32x4 get wxzz => _shuffle(0xA3);
  Float32x4 get wxzw => _shuffle(0xE3);
  Float32x4 get wxwx => _shuffle(0x33);
  Float32x4 get wxwy => _shuffle(0x73);
  Float32x4 get wxwz => _shuffle(0xB3);
  Float32x4 get wxww => _shuffle(0xF3);
  Float32x4 get wyxx => _shuffle(0x7);
  Float32x4 get wyxy => _shuffle(0x47);
  Float32x4 get wyxz => _shuffle(0x87);
  Float32x4 get wyxw => _shuffle(0xC7);
  Float32x4 get wyyx => _shuffle(0x17);
  Float32x4 get wyyy => _shuffle(0x57);
  Float32x4 get wyyz => _shuffle(0x97);
  Float32x4 get wyyw => _shuffle(0xD7);
  Float32x4 get wyzx => _shuffle(0x27);
  Float32x4 get wyzy => _shuffle(0x67);
  Float32x4 get wyzz => _shuffle(0xA7);
  Float32x4 get wyzw => _shuffle(0xE7);
  Float32x4 get wywx => _shuffle(0x37);
  Float32x4 get wywy => _shuffle(0x77);
  Float32x4 get wywz => _shuffle(0xB7);
  Float32x4 get wyww => _shuffle(0xF7);
  Float32x4 get wzxx => _shuffle(0xB);
  Float32x4 get wzxy => _shuffle(0x4B);
  Float32x4 get wzxz => _shuffle(0x8B);
  Float32x4 get wzxw => _shuffle(0xCB);
  Float32x4 get wzyx => _shuffle(0x1B);
  Float32x4 get wzyy => _shuffle(0x5B);
  Float32x4 get wzyz => _shuffle(0x9B);
  Float32x4 get wzyw => _shuffle(0xDB);
  Float32x4 get wzzx => _shuffle(0x2B);
  Float32x4 get wzzy => _shuffle(0x6B);
  Float32x4 get wzzz => _shuffle(0xAB);
  Float32x4 get wzzw => _shuffle(0xEB);
  Float32x4 get wzwx => _shuffle(0x3B);
  Float32x4 get wzwy => _shuffle(0x7B);
  Float32x4 get wzwz => _shuffle(0xBB);
  Float32x4 get wzww => _shuffle(0xFB);
  Float32x4 get wwxx => _shuffle(0xF);
  Float32x4 get wwxy => _shuffle(0x4F);
  Float32x4 get wwxz => _shuffle(0x8F);
  Float32x4 get wwxw => _shuffle(0xCF);
  Float32x4 get wwyx => _shuffle(0x1F);
  Float32x4 get wwyy => _shuffle(0x5F);
  Float32x4 get wwyz => _shuffle(0x9F);
  Float32x4 get wwyw => _shuffle(0xDF);
  Float32x4 get wwzx => _shuffle(0x2F);
  Float32x4 get wwzy => _shuffle(0x6F);
  Float32x4 get wwzz => _shuffle(0xAF);
  Float32x4 get wwzw => _shuffle(0xEF);
  Float32x4 get wwwx => _shuffle(0x3F);
  Float32x4 get wwwy => _shuffle(0x7F);
  Float32x4 get wwwz => _shuffle(0xBF);
  Float32x4 get wwww => _shuffle(0xFF);

  Float32x4 _shuffle(int m) {
    double _x = _storage[m & 0x3];
    double _y = _storage[(m >> 2) & 0x3];
    double _z = _storage[(m >> 4) & 0x3];
    double _w = _storage[(m >> 6) & 0x3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Float32x4] with values in the X and Y lanes
  /// replaced with the values in the Z and W lanes of [other].
  Float32x4 withZWInXY(Float32x4 other) {
    double _x = other._storage[2];
    double _y = other._storage[3];
    double _z = _storage[2];
    double _w = _storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Float32x4] with the X and Y lane values
  /// from [this] and [other] interleaved.
  Float32x4 interleaveXY(Float32x4 other) {
    double _x = _storage[0];
    double _y = other._storage[0];
    double _z = _storage[1];
    double _w = other._storage[1];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Float32x4] with the Z and W lane values
  /// from [this] and [other] interleaved.
  Float32x4 interleaveZW(Float32x4 other) {
    double _x = _storage[2];
    double _y = other._storage[2];
    double _z = _storage[3];
    double _w = other._storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Float32x4] with the X and Y lane value pairs
  /// from [this] and [other] interleaved.
  Float32x4 interleaveXYPairs(Float32x4 other) {
    double _x = _storage[0];
    double _y = _storage[1];
    double _z = other._storage[0];
    double _w = other._storage[1];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Float32x4] with the Z and W lane value pairs
  /// from [this] and [other] interleaved.
  Float32x4 interleaveZWPairs(Float32x4 other) {
    double _x = _storage[2];
    double _y = _storage[3];
    double _z = other._storage[2];
    double _w = other._storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  Float32x4 withX(double x) {
    double _x = x;
    double _y = _storage[1];
    double _z = _storage[2];
    double _w = _storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  Float32x4 withY(double y) {
    double _x = _storage[0];
    double _y = y;
    double _z = _storage[2];
    double _w = _storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  Float32x4 withZ(double z) {
    double _x = _storage[0];
    double _y = _storage[1];
    double _z = z;
    double _w = _storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  Float32x4 withW(double w) {
    double _x = _storage[0];
    double _y = _storage[1];
    double _z = _storage[2];
    double _w = w;
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns the lane-wise minimum value in [this] or [other].
  Float32x4 min(Float32x4 other) {
    double _x = _storage[0] < other._storage[0] ?
        _storage[0] : other._storage[0];
    double _y = _storage[1] < other._storage[1] ?
        _storage[1] : other._storage[1];
    double _z = _storage[2] < other._storage[2] ?
        _storage[2] : other._storage[2];
    double _w = _storage[3] < other._storage[3] ?
        _storage[3] : other._storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns the lane-wise maximum value in [this] or [other].
  Float32x4 max(Float32x4 other) {
    double _x = _storage[0] > other._storage[0] ?
        _storage[0] : other._storage[0];
    double _y = _storage[1] > other._storage[1] ?
        _storage[1] : other._storage[1];
    double _z = _storage[2] > other._storage[2] ?
        _storage[2] : other._storage[2];
    double _w = _storage[3] > other._storage[3] ?
        _storage[3] : other._storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns the square root of [this].
  Float32x4 sqrt() {
    double _x = Math.sqrt(_storage[0]);
    double _y = Math.sqrt(_storage[1]);
    double _z = Math.sqrt(_storage[2]);
    double _w = Math.sqrt(_storage[3]);
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns the reciprocal of [this].
  Float32x4 reciprocal() {
    double _x = 1.0 / _storage[0];
    double _y = 1.0 / _storage[1];
    double _z = 1.0 / _storage[2];
    double _w = 1.0 / _storage[3];
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns the square root of the reciprocal of [this].
  Float32x4 reciprocalSqrt() {
    double _x = Math.sqrt(1.0 / _storage[0]);
    double _y = Math.sqrt(1.0 / _storage[1]);
    double _z = Math.sqrt(1.0 / _storage[2]);
    double _w = Math.sqrt(1.0 / _storage[3]);
    return new Float32x4(_x, _y, _z, _w);
  }

  /// Returns a bit-wise copy of [this] as a [Uint32x4].
  Uint32x4 toUint32x4() {
    var view = new Uint32List.view(_storage.buffer);
    return new Uint32x4(view[0], view[1], view[2], view[3]);
  }
}


class Uint32x4 {
  final _storage = new Uint32List(4);

  Uint32x4(int x, int y, int z, int w) {
    _storage[0] = x;
    _storage[1] = y;
    _storage[2] = z;
    _storage[3] = w;
  }

  Uint32x4.bool(bool x, bool y, bool z, bool w) {
    _storage[0] = x == true ? 0xFFFFFFFF : 0x0;
    _storage[1] = y == true ? 0xFFFFFFFF : 0x0;
    _storage[2] = z == true ? 0xFFFFFFFF : 0x0;
    _storage[3] = w == true ? 0xFFFFFFFF : 0x0;
  }

  /// The bit-wise or operator.
  Uint32x4 operator|(Uint32x4 other) {
    int _x = _storage[0] | other._storage[0];
    int _y = _storage[1] | other._storage[1];
    int _z = _storage[2] | other._storage[2];
    int _w = _storage[3] | other._storage[3];
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// The bit-wise and operator.
  Uint32x4 operator&(Uint32x4 other) {
    int _x = _storage[0] & other._storage[0];
    int _y = _storage[1] & other._storage[1];
    int _z = _storage[2] & other._storage[2];
    int _w = _storage[3] & other._storage[3];
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// The bit-wise xor operator.
  Uint32x4 operator^(Uint32x4 other) {
    int _x = _storage[0] ^ other._storage[0];
    int _y = _storage[1] ^ other._storage[1];
    int _z = _storage[2] ^ other._storage[2];
    int _w = _storage[3] ^ other._storage[3];
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// Extract 32-bit mask from x lane.
  int get x => _storage[0];
  /// Extract 32-bit mask from y lane.
  int get y => _storage[1];
  /// Extract 32-bit mask from z lane.
  int get z => _storage[2];
  /// Extract 32-bit mask from w lane.
  int get w => _storage[3];

  /// Returns a new [Uint32x4] copied from [this] with a new x value.
  Uint32x4 withX(int x) {
    int _x = x;
    int _y = _storage[1];
    int _z = _storage[2];
    int _w = _storage[3];
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Uint32x4] copied from [this] with a new y value.
  Uint32x4 withY(int y) {
    int _x = _storage[0];
    int _y = y;
    int _z = _storage[2];
    int _w = _storage[3];
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Uint32x4] copied from [this] with a new z value.
  Uint32x4 withZ(int z) {
    int _x = _storage[0];
    int _y = _storage[1];
    int _z = z;
    int _w = _storage[3];
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Uint32x4] copied from [this] with a new w value.
  Uint32x4 withW(int w) {
    int _x = _storage[0];
    int _y = _storage[1];
    int _z = _storage[2];
    int _w = w;
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// Extracted x value. Returns false for 0, true for any other value.
  bool get flagX => _storage[0] != 0x0;
  /// Extracted y value. Returns false for 0, true for any other value.
  bool get flagY => _storage[1] != 0x0;
  /// Extracted z value. Returns false for 0, true for any other value.
  bool get flagZ => _storage[2] != 0x0;
  /// Extracted w value. Returns false for 0, true for any other value.
  bool get flagW => _storage[3] != 0x0;

  /// Returns a new [Uint32x4] copied from [this] with a new x value.
  Uint32x4 withFlagX(bool x) {
    int _x = x == true ? 0xFFFFFFFF : 0x0;
    int _y = _storage[1];
    int _z = _storage[2];
    int _w = _storage[3];
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Uint32x4] copied from [this] with a new y value.
  Uint32x4 withFlagY(bool y) {
    int _x = _storage[0];
    int _y = y == true ? 0xFFFFFFFF : 0x0;
    int _z = _storage[2];
    int _w = _storage[3];
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Uint32x4] copied from [this] with a new z value.
  Uint32x4 withFlagZ(bool z) {
    int _x = _storage[0];
    int _y = _storage[1];
    int _z = z == true ? 0xFFFFFFFF : 0x0;
    int _w = _storage[3];
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// Returns a new [Uint32x4] copied from [this] with a new w value.
  Uint32x4 withFlagW(bool w) {
    int _x = _storage[0];
    int _y = _storage[1];
    int _z = _storage[2];
    int _w = w == true ? 0xFFFFFFFF : 0x0;
    return new Uint32x4(_x, _y, _z, _w);
  }

  /// Merge [trueValue] and [falseValue] based on [this]' bit mask:
  /// Select bit from [trueValue] when bit in [this] is on.
  /// Select bit from [falseValue] when bit in [this] is off.
  Float32x4 select(Float32x4 trueValue, Float32x4 falseValue) {
    var trueView = new Uint32List.view(trueValue._storage.buffer);
    var falseView = new Uint32List.view(falseValue._storage.buffer);
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
    var r = new Float32x4(0.0, 0.0, 0.0, 0.0);
    var rView = new Uint32List.view(r._storage.buffer);
    rView[0] = _x;
    rView[1] = _y;
    rView[2] = _z;
    rView[3] = _w;
    return r;
  }

  /// Returns a bit-wise copy of [this] as a [Float32x4].
  Float32x4 toFloat32x4() {
    var view = new Float32List.view(_storage.buffer);
    return new Float32x4(view[0], view[1], view[2], view[3]);
  }
}
