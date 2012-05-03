// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AudioContextFactoryProvider {
  factory AudioContext() => _wrap(new dom.AudioContext());
}

class _IDBKeyRangeFactoryProvider {

  factory IDBKeyRange.only(/*IDBKey*/ value) =>
      _wrap(new dom.IDBKeyRange.only(_unwrap(value)));

  factory IDBKeyRange.lowerBound(/*IDBKey*/ bound, [bool open = false]) =>
      _wrap(new dom.IDBKeyRange.lowerBound(_unwrap(bound) open));

  factory IDBKeyRange.upperBound(/*IDBKey*/ bound, [bool open = false]) =>
      _wrap(new dom.IDBKeyRange.upperBound(_unwrap(bound) open));

  factory IDBKeyRange.bound(/*IDBKey*/ lower, /*IDBKey*/ upper,
                            [bool lowerOpen = false, bool upperOpen = false]) =>
      _wrap(new dom.IDBKeyRange.bound(_unwrap(lower), _unwrap(upper),
                                      lowerOpen, upperOpen));
}

class _TypedArrayFactoryProvider {

  factory Float32Array(int length) => _F32(length);
  factory Float32Array.fromList(List<num> list) => _F32_1(ensureNative(list));
  factory Float32Array.fromBuffer(ArrayBuffer buffer,
                                  [int byteOffset = 0, int length]) {
    if (length == null) return _F32_2(buffer, byteOffset);
    return _F32_3(buffer, byteOffset, length);
  }

  factory Float64Array(int length) => _F64(length);
  factory Float64Array.fromList(List<num> list) => _F64_1(ensureNative(list));
  factory Float64Array.fromBuffer(ArrayBuffer buffer,
                                  [int byteOffset = 0, int length]) {
    if (length == null) return _F64_2(buffer, byteOffset);
    return _F64_3(buffer, byteOffset, length);
  }

  factory Int8Array(int length) => _I8(length);
  factory Int8Array.fromList(List<num> list) => _I8_1(ensureNative(list));
  factory Int8Array.fromBuffer(ArrayBuffer buffer,
                               [int byteOffset = 0, int length]) {
    if (length == null) return _I8_2(buffer, byteOffset);
    return _I8_3(buffer, byteOffset, length);
  }

  factory Int16Array(int length) => _I16(length);
  factory Int16Array.fromList(List<num> list) => _I16_1(ensureNative(list));
  factory Int16Array.fromBuffer(ArrayBuffer buffer,
                                [int byteOffset = 0, int length]) {
    if (length == null) return _I16_2(buffer, byteOffset);
    return _I16_3(buffer, byteOffset, length);
  }

  factory Int32Array(int length) => _I32(length);
  factory Int32Array.fromList(List<num> list) => _I32_1(ensureNative(list));
  factory Int32Array.fromBuffer(ArrayBuffer buffer,
                                [int byteOffset = 0, int length]) {
    if (length == null) return _I32_2(buffer, byteOffset);
    return _I32_3(buffer, byteOffset, length);
  }

  factory Uint8Array(int length) => _U8(length);
  factory Uint8Array.fromList(List<num> list) => _U8_1(ensureNative(list));
  factory Uint8Array.fromBuffer(ArrayBuffer buffer,
                                [int byteOffset = 0, int length]) {
    if (length == null) return _U8_2(buffer, byteOffset);
    return _U8_3(buffer, byteOffset, length);
  }

  factory Uint16Array(int length) => _U16(length);
  factory Uint16Array.fromList(List<num> list) => _U16_1(ensureNative(list));
  factory Uint16Array.fromBuffer(ArrayBuffer buffer,
                                 [int byteOffset = 0, int length]) {
    if (length == null) return _U16_2(buffer, byteOffset);
    return _U16_3(buffer, byteOffset, length);
  }

  factory Uint32Array(int length) => _U32(length);
  factory Uint32Array.fromList(List<num> list) => _U32_1(ensureNative(list));
  factory Uint32Array.fromBuffer(ArrayBuffer buffer,
                                 [int byteOffset = 0, int length]) {
    if (length == null) return _U32_2(buffer, byteOffset);
    return _U32_3(buffer, byteOffset, length);
  }

  factory Uint8ClampedArray(int length) => _U8C(length);
  factory Uint8ClampedArray.fromList(List<num> list) => _U8C_1(ensureNative(list));
  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer,
                                       [int byteOffset = 0, int length]) {
    if (length == null) return _U8C_2(buffer, byteOffset);
    return _U8C_3(buffer, byteOffset, length);
  }

  static Float32Array _F32(arg) => _wrap(new dom.Float32Array(arg));
  static Float64Array _F64(arg) => _wrap(new dom.Float64Array(arg));
  static Int8Array _I8(arg) => _wrap(new dom.Int8Array(arg));
  static Int16Array _I16(arg) => _wrap(new dom.Int16Array(arg));
  static Int32Array _I32(arg) => _wrap(new dom.Int32Array(arg));
  static Uint8Array _U8(arg) => _wrap(new dom.Uint8Array(arg));
  static Uint16Array _U16(arg) => _wrap(new dom.Uint16Array(arg));
  static Uint32Array _U32(arg) => _wrap(new dom.Uint32Array(arg));
  static Uint8ClampedArray _U8C(arg) => _wrap(new dom.Uint8ClampedArray(arg));

  static Float32Array _F32_1(arg) => _wrap(new dom.Float32Array.fromList(arg));
  static Float64Array _F64_1(arg) => _wrap(new dom.Float64Array.fromList(arg));
  static Int8Array _I8_1(arg) => _wrap(new dom.Int8Array.fromList(arg));
  static Int16Array _I16_1(arg) => _wrap(new dom.Int16Array.fromList(arg));
  static Int32Array _I32_1(arg) => _wrap(new dom.Int32Array.fromList(arg));
  static Uint8Array _U8_1(arg) => _wrap(new dom.Uint8Array.fromList(arg));
  static Uint16Array _U16_1(arg) => _wrap(new dom.Uint16Array.fromList(arg));
  static Uint32Array _U32_1(arg) => _wrap(new dom.Uint32Array.fromList(arg));
  static Uint8ClampedArray _U8C_1(arg) => _wrap(new dom.Uint8ClampedArray.fromList(arg));

  static Float32Array _F32_2(buffer, byteOffset) => _wrap(new dom.Float32Array.fromBuffer(_unwrap(buffer), byteOffset));
  static Float64Array _F64_2(buffer, byteOffset) => _wrap(new dom.Float64Array.fromBuffer(_unwrap(buffer), byteOffset));
  static Int8Array _I8_2(buffer, byteOffset) => _wrap(new dom.Int8Array.fromBuffer(_unwrap(buffer), byteOffset));
  static Int16Array _I16_2(buffer, byteOffset) => _wrap(new dom.Int16Array.fromBuffer(_unwrap(buffer), byteOffset));
  static Int32Array _I32_2(buffer, byteOffset) => _wrap(new dom.Int32Array.fromBuffer(_unwrap(buffer), byteOffset));
  static Uint8Array _U8_2(buffer, byteOffset) => _wrap(new dom.Uint8Array.fromBuffer(_unwrap(buffer), byteOffset));
  static Uint16Array _U16_2(buffer, byteOffset) => _wrap(new dom.Uint16Array.fromBuffer(_unwrap(buffer), byteOffset));
  static Uint32Array _U32_2(buffer, byteOffset) => _wrap(new dom.Uint32Array.fromBuffer(_unwrap(buffer), byteOffset));
  static Uint8ClampedArray _U8C_2(buffer, byteOffset) => _wrap(new dom.Uint8ClampedArray.fromBuffer(_unwrap(buffer), byteOffset));

  static Float32Array _F32_3(buffer, byteOffset, length) => _wrap(new dom.Float32Array.fromBuffer(_unwrap(buffer), byteOffset, length));
  static Float64Array _F64_3(buffer, byteOffset, length) => _wrap(new dom.Float64Array.fromBuffer(_unwrap(buffer), byteOffset, length));
  static Int8Array _I8_3(buffer, byteOffset, length) => _wrap(new dom.Int8Array.fromBuffer(_unwrap(buffer), byteOffset, length));
  static Int16Array _I16_3(buffer, byteOffset, length) => _wrap(new dom.Int16Array.fromBuffer(_unwrap(buffer), byteOffset, length));
  static Int32Array _I32_3(buffer, byteOffset, length) => _wrap(new dom.Int32Array.fromBuffer(_unwrap(buffer), byteOffset, length));
  static Uint8Array _U8_3(buffer, byteOffset, length) => _wrap(new dom.Uint8Array.fromBuffer(_unwrap(buffer), byteOffset, length));
  static Uint16Array _U16_3(buffer, byteOffset, length) => _wrap(new dom.Uint16Array.fromBuffer(_unwrap(buffer), byteOffset, length));
  static Uint32Array _U32_3(buffer, byteOffset, length) => _wrap(new dom.Uint32Array.fromBuffer(_unwrap(buffer), byteOffset, length));
  static Uint8ClampedArray _U8C_3(buffer, byteOffset, length) => _wrap(new dom.Uint8ClampedArray.fromBuffer(_unwrap(buffer), byteOffset, length));

  static ensureNative(List list) => list;  // TODO: make sure.
}

class _PointFactoryProvider {

  factory Point(num x, num y) => _wrap(new dom.WebKitPoint(x, y));
}

class _WebSocketFactoryProvider {

  factory WebSocket(String url) => _wrap(new dom.WebSocket(url));
}

class _TextFactoryProvider {
  factory Text(String data) => _document.$dom_createTextNode(data);
}
