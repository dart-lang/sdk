// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class _AudioContextFactoryProvider {
  static AudioContext createAudioContext() => _createAudioContext();
  static _createAudioContext([int numberOfChannels,
                              int numberOfFrames,
                              int sampleRate])
      native "AudioContext_constructor_Callback";
}

class _IDBKeyRangeFactoryProvider {

  static IDBKeyRange createIDBKeyRange_only(/*IDBKey*/ value) =>
      IDBKeyRange.only_(value);

  static IDBKeyRange createIDBKeyRange_lowerBound(
      /*IDBKey*/ bound, [bool open = false]) =>
      IDBKeyRange.lowerBound_(bound, open);

  static IDBKeyRange createIDBKeyRange_upperBound(
      /*IDBKey*/ bound, [bool open = false]) =>
      IDBKeyRange.upperBound_(bound, open);

  static IDBKeyRange createIDBKeyRange_bound(
      /*IDBKey*/ lower, /*IDBKey*/ upper,
      [bool lowerOpen = false, bool upperOpen = false]) =>
      IDBKeyRange.bound_(lower, upper, lowerOpen, upperOpen);
}

class _TypedArrayFactoryProvider {
  static Float32Array createFloat32Array(int length) => _F32(length);
  static Float32Array createFloat32Array_fromList(List<num> list) =>
      _F32(ensureNative(list));
  static Float32Array createFloat32Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _F32(buffer, byteOffset, length);
  static _F32(arg0, [arg1, arg2]) native "Float32Array_constructor_Callback";

  static Float64Array createFloat64Array(int length) => _F64(length);
  static Float64Array createFloat64Array_fromList(List<num> list) =>
      _F64(ensureNative(list));
  static Float64Array createFloat64Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _F64(buffer, byteOffset, length);
  static _F64(arg0, [arg1, arg2]) native "Float64Array_constructor_Callback";

  static Int8Array createInt8Array(int length) => _I8(length);
  static Int8Array createInt8Array_fromList(List<num> list) =>
      _I8(ensureNative(list));
  static Int8Array createInt8Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _I8(buffer, byteOffset, length);
  static _I8(arg0, [arg1, arg2]) native "Int8Array_constructor_Callback";

  static Int16Array createInt16Array(int length) => _I16(length);
  static Int16Array createInt16Array_fromList(List<num> list) =>
      _I16(ensureNative(list));
  static Int16Array createInt16Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _I16(buffer, byteOffset, length);
  static _I16(arg0, [arg1, arg2]) native "Int16Array_constructor_Callback";

  static Int32Array createInt32Array(int length) => _I32(length);
  static Int32Array createInt32Array_fromList(List<num> list) =>
      _I32(ensureNative(list));
  static Int32Array createInt32Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _I32(buffer, byteOffset, length);
  static _I32(arg0, [arg1, arg2]) native "Int32Array_constructor_Callback";

  static Uint8Array createUint8Array(int length) => _U8(length);
  static Uint8Array createUint8Array_fromList(List<num> list) =>
      _U8(ensureNative(list));
  static Uint8Array createUint8Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _U8(buffer, byteOffset, length);
  static _U8(arg0, [arg1, arg2]) native "Uint8Array_constructor_Callback";

  static Uint16Array createUint16Array(int length) => _U16(length);
  static Uint16Array createUint16Array_fromList(List<num> list) =>
      _U16(ensureNative(list));
  static Uint16Array createUint16Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _U16(buffer, byteOffset, length);
  static _U16(arg0, [arg1, arg2]) native "Uint16Array_constructor_Callback";

  static Uint32Array createUint32Array(int length) => _U32(length);
  static Uint32Array createUint32Array_fromList(List<num> list) =>
      _U32(ensureNative(list));
  static Uint32Array createUint32Array_fromBuffer(ArrayBuffer buffer,
      [int byteOffset = 0, int length]) => _U32(buffer, byteOffset, length);
  static _U32(arg0, [arg1, arg2]) native "Uint32Array_constructor_Callback";

  static Uint8ClampedArray createUint8ClampedArray(int length) => _U8C(length);
  static Uint8ClampedArray createUint8ClampedArray_fromList(
      List<num> list) => _U8C(ensureNative(list));
  static Uint8ClampedArray createUint8ClampedArray_fromBuffer(
      ArrayBuffer buffer, [int byteOffset = 0, int length]) =>
      _U8C(buffer, byteOffset, length);
  static _U8C(arg0, [arg1, arg2]) native "Uint8ClampedArray_constructor_Callback";

  static ensureNative(List list) => list;  // TODO: make sure.
}

class _PointFactoryProvider {
  static Point createPoint(num x, num y) => _createWebKitPoint(x, y);
  static _createWebKitPoint(num x, num y) native "WebKitPoint_constructor_Callback";
}

class _WebSocketFactoryProvider {
  static WebSocket createWebSocket(String url) => _createWebSocket(url);
  static _createWebSocket(String url) native "WebSocket_constructor_Callback";
}

class _TextFactoryProvider {
  static Text createText(String data) => document.$dom_createTextNode(data);
}
