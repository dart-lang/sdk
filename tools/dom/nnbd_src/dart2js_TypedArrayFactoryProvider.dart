// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class _TypedArrayFactoryProvider {
  static ByteData createByteData(int length) => _B8(length);
  static ByteData createByteData_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _B8_2(buffer, byteOffset);
    return _B8_3(buffer, byteOffset, length);
  }

  static Float32List createFloat32List(int length) => _F32(length);
  static Float32List createFloat32List_fromList(List<num> list) =>
      _F32(ensureNative(list));
  static Float32List createFloat32List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _F32_2(buffer, byteOffset);
    return _F32_3(buffer, byteOffset, length);
  }

  static Float64List createFloat64List(int length) => _F64(length);
  static Float64List createFloat64List_fromList(List<num> list) =>
      _F64(ensureNative(list));
  static Float64List createFloat64List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _F64_2(buffer, byteOffset);
    return _F64_3(buffer, byteOffset, length);
  }

  static Int8List createInt8List(int length) => _I8(length);
  static Int8List createInt8List_fromList(List<num> list) =>
      _I8(ensureNative(list));
  static Int8List createInt8List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I8_2(buffer, byteOffset);
    return _I8_3(buffer, byteOffset, length);
  }

  static Int16List createInt16List(int length) => _I16(length);
  static Int16List createInt16List_fromList(List<num> list) =>
      _I16(ensureNative(list));
  static Int16List createInt16List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I16_2(buffer, byteOffset);
    return _I16_3(buffer, byteOffset, length);
  }

  static Int32List createInt32List(int length) => _I32(length);
  static Int32List createInt32List_fromList(List<num> list) =>
      _I32(ensureNative(list));
  static Int32List createInt32List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I32_2(buffer, byteOffset);
    return _I32_3(buffer, byteOffset, length);
  }

  static Uint8List createUint8List(int length) => _U8(length);
  static Uint8List createUint8List_fromList(List<num> list) =>
      _U8(ensureNative(list));
  static Uint8List createUint8List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U8_2(buffer, byteOffset);
    return _U8_3(buffer, byteOffset, length);
  }

  static Uint16List createUint16List(int length) => _U16(length);
  static Uint16List createUint16List_fromList(List<num> list) =>
      _U16(ensureNative(list));
  static Uint16List createUint16List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U16_2(buffer, byteOffset);
    return _U16_3(buffer, byteOffset, length);
  }

  static Uint32List createUint32List(int length) => _U32(length);
  static Uint32List createUint32List_fromList(List<num> list) =>
      _U32(ensureNative(list));
  static Uint32List createUint32List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U32_2(buffer, byteOffset);
    return _U32_3(buffer, byteOffset, length);
  }

  static Uint8ClampedList createUint8ClampedList(int length) => _U8C(length);
  static Uint8ClampedList createUint8ClampedList_fromList(List<num> list) =>
      _U8C(ensureNative(list));
  static Uint8ClampedList createUint8ClampedList_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U8C_2(buffer, byteOffset);
    return _U8C_3(buffer, byteOffset, length);
  }

  static ByteData _B8(arg) =>
      JS('ByteData', 'new DataView(new ArrayBuffer(#))', arg);
  static Float32List _F32(arg) => JS('Float32List', 'new Float32Array(#)', arg);
  static Float64List _F64(arg) => JS('Float64List', 'new Float64Array(#)', arg);
  static Int8List _I8(arg) => JS('Int8List', 'new Int8Array(#)', arg);
  static Int16List _I16(arg) => JS('Int16List', 'new Int16Array(#)', arg);
  static Int32List _I32(arg) => JS('Int32List', 'new Int32Array(#)', arg);
  static Uint8List _U8(arg) => JS('Uint8List', 'new Uint8Array(#)', arg);
  static Uint16List _U16(arg) => JS('Uint16List', 'new Uint16Array(#)', arg);
  static Uint32List _U32(arg) => JS('Uint32List', 'new Uint32Array(#)', arg);
  static Uint8ClampedList _U8C(arg) =>
      JS('Uint8ClampedList', 'new Uint8ClampedArray(#)', arg);

  static ByteData _B8_2(arg1, arg2) =>
      JS('ByteData', 'new DataView(#, #)', arg1, arg2);
  static Float32List _F32_2(arg1, arg2) =>
      JS('Float32List', 'new Float32Array(#, #)', arg1, arg2);
  static Float64List _F64_2(arg1, arg2) =>
      JS('Float64List', 'new Float64Array(#, #)', arg1, arg2);
  static Int8List _I8_2(arg1, arg2) =>
      JS('Int8List', 'new Int8Array(#, #)', arg1, arg2);
  static Int16List _I16_2(arg1, arg2) =>
      JS('Int16List', 'new Int16Array(#, #)', arg1, arg2);
  static Int32List _I32_2(arg1, arg2) =>
      JS('Int32List', 'new Int32Array(#, #)', arg1, arg2);
  static Uint8List _U8_2(arg1, arg2) =>
      JS('Uint8List', 'new Uint8Array(#, #)', arg1, arg2);
  static Uint16List _U16_2(arg1, arg2) =>
      JS('Uint16List', 'new Uint16Array(#, #)', arg1, arg2);
  static Uint32List _U32_2(arg1, arg2) =>
      JS('Uint32List', 'new Uint32Array(#, #)', arg1, arg2);
  static Uint8ClampedList _U8C_2(arg1, arg2) =>
      JS('Uint8ClampedList', 'new Uint8ClampedArray(#, #)', arg1, arg2);

  static ByteData _B8_3(arg1, arg2, arg3) =>
      JS('ByteData', 'new DataView(#, #, #)', arg1, arg2, arg3);
  static Float32List _F32_3(arg1, arg2, arg3) =>
      JS('Float32List', 'new Float32Array(#, #, #)', arg1, arg2, arg3);
  static Float64List _F64_3(arg1, arg2, arg3) =>
      JS('Float64List', 'new Float64Array(#, #, #)', arg1, arg2, arg3);
  static Int8List _I8_3(arg1, arg2, arg3) =>
      JS('Int8List', 'new Int8Array(#, #, #)', arg1, arg2, arg3);
  static Int16List _I16_3(arg1, arg2, arg3) =>
      JS('Int16List', 'new Int16Array(#, #, #)', arg1, arg2, arg3);
  static Int32List _I32_3(arg1, arg2, arg3) =>
      JS('Int32List', 'new Int32Array(#, #, #)', arg1, arg2, arg3);
  static Uint8List _U8_3(arg1, arg2, arg3) =>
      JS('Uint8List', 'new Uint8Array(#, #, #)', arg1, arg2, arg3);
  static Uint16List _U16_3(arg1, arg2, arg3) =>
      JS('Uint16List', 'new Uint16Array(#, #, #)', arg1, arg2, arg3);
  static Uint32List _U32_3(arg1, arg2, arg3) =>
      JS('Uint32List', 'new Uint32Array(#, #, #)', arg1, arg2, arg3);
  static Uint8ClampedList _U8C_3(arg1, arg2, arg3) => JS(
      'Uint8ClampedList', 'new Uint8ClampedArray(#, #, #)', arg1, arg2, arg3);

  // Ensures that [list] is a JavaScript Array or a typed array.  If necessary,
  // copies the list.
  static ensureNative(List list) => list; // TODO: make sure.
}
