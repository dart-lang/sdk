// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The Dart TypedData library.
library dart.typed_data;

import 'dart:collection';
import 'dart:_collection-dev';
import 'dart:_js_helper' show Creates, JavaScriptIndexingBehavior, JSName, Null, Returns;
import 'dart:_foreign_helper' show JS;

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
    _checkIndex(start, length);
    if (end == null) return length;
    _checkIndex(end, length);
    if (start > end) throw new RangeError.value(end);
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

  num operator[](int index) {
    _checkIndex(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
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

  num operator[](int index) {
    _checkIndex(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
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

  num operator[](int index) {
    _checkIndex(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
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

  num operator[](int index) {
    _checkIndex(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
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

  num operator[](int index) {
    _checkIndex(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
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

  num operator[](int index) {
    _checkIndex(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
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

  num operator[](int index) {
    _checkIndex(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
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


abstract class Float32x4List implements List<Float32x4>, TypedData {
  factory Float32x4List(int length) {
    throw new UnsupportedError("Float32x4List not supported by dart2js.");
  }

  factory Float32x4List.view(ByteBuffer buffer,
                             [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError("Float32x4List not supported by dart2js.");
  }

  static const int BYTES_PER_ELEMENT = 16;
}


abstract class Float32x4 {
  factory Float32x4(double x, double y, double z, double w) {
    throw new UnsupportedError("Float32x4 not supported by dart2js.");
  }
  factory Float32x4.splat(double v) {
    throw new UnsupportedError("Float32x4 not supported by dart2js.");
  }
  factory Float32x4.zero() {
    throw new UnsupportedError("Float32x4 not supported by dart2js.");
  }
}


abstract class Uint32x4 {
  factory Uint32x4(int x, int y, int z, int w) {
    throw new UnsupportedError("Uint32x4 not supported by dart2js.");
  }
  factory Uint32x4.bool(bool x, bool y, bool z, bool w) {
    throw new UnsupportedError("Uint32x4 not supported by dart2js.");
  }
}
