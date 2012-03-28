// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AudioContextFactoryProvider {
  factory AudioContext() => _wrap(new dom.AudioContext());
}

class _TypedArrayFactoryProvider {

  factory Float32Array(int length) => _F32(length);
  factory Float32Array.fromList(List<num> list) => _F32(ensureNative(list));
  factory Float32Array.fromBuffer(ArrayBuffer buffer) => _F32(buffer);

  factory Float64Array(int length) => _F64(length);
  factory Float64Array.fromList(List<num> list) => _F64(ensureNative(list));
  factory Float64Array.fromBuffer(ArrayBuffer buffer) => _F64(buffer);

  factory Int8Array(int length) => _I8(length);
  factory Int8Array.fromList(List<num> list) => _I8(ensureNative(list));
  factory Int8Array.fromBuffer(ArrayBuffer buffer) => _I8(buffer);

  factory Int16Array(int length) => _I16(length);
  factory Int16Array.fromList(List<num> list) => _I16(ensureNative(list));
  factory Int16Array.fromBuffer(ArrayBuffer buffer) => _I16(buffer);

  factory Int32Array(int length) => _I32(length);
  factory Int32Array.fromList(List<num> list) => _I32(ensureNative(list));
  factory Int32Array.fromBuffer(ArrayBuffer buffer) => _I32(buffer);

  factory Uint8Array(int length) => _U8(length);
  factory Uint8Array.fromList(List<num> list) => _U8(ensureNative(list));
  factory Uint8Array.fromBuffer(ArrayBuffer buffer) => _U8(buffer);

  factory Uint16Array(int length) => _U16(length);
  factory Uint16Array.fromList(List<num> list) => _U16(ensureNative(list));
  factory Uint16Array.fromBuffer(ArrayBuffer buffer) => _U16(buffer);

  factory Uint32Array(int length) => _U32(length);
  factory Uint32Array.fromList(List<num> list) => _U32(ensureNative(list));
  factory Uint32Array.fromBuffer(ArrayBuffer buffer) => _U32(buffer);

  factory Uint8ClampedArray(int length) => _U8C(length);
  factory Uint8ClampedArray.fromList(List<num> list) => _U8C(ensureNative(list));
  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer) => _U8C(buffer);

  static Float32Array _F32(arg) => _wrap(new dom.Float32Array(arg));
  static Float64Array _F64(arg) => _wrap(new dom.Float64Array(arg));
  static Int8Array _I8(arg) => _wrap(new dom.Int8Array(arg));
  static Int16Array _I16(arg) => _wrap(new dom.Int16Array(arg));
  static Int32Array _I32(arg) => _wrap(new dom.Int32Array(arg));
  static Uint8Array _U8(arg) => _wrap(new dom.Uint8Array(arg));
  static Uint16Array _U16(arg) => _wrap(new dom.Uint16Array(arg));
  static Uint32Array _U32(arg) => _wrap(new dom.Uint32Array(arg));
  static Uint8ClampedArray _U8C(arg) => _wrap(new dom.Uint8ClampedArray(arg));

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
