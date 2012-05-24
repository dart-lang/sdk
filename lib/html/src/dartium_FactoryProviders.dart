// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AudioContextFactoryProvider {
  factory AudioContext() => _wrap(_createAudioContext());
  static _createAudioContext() native "AudioContext_constructor_Callback";
}

class _IDBKeyRangeFactoryProvider {

  factory IDBKeyRange.only(/*IDBKey*/ value) =>
      _wrap(_IDBKeyRangeDOMImpl.only(_unwrap(value)));

  factory IDBKeyRange.lowerBound(/*IDBKey*/ bound, [bool open = false]) =>
      _wrap(_IDBKeyRangeDOMImpl.lowerBound(_unwrap(bound), open));

  factory IDBKeyRange.upperBound(/*IDBKey*/ bound, [bool open = false]) =>
      _wrap(_IDBKeyRangeDOMImpl.upperBound(_unwrap(bound), open));

  factory IDBKeyRange.bound(/*IDBKey*/ lower, /*IDBKey*/ upper,
                            [bool lowerOpen = false, bool upperOpen = false]) =>
      _wrap(_IDBKeyRangeDOMImpl.bound(_unwrap(lower), _unwrap(upper),
                                      lowerOpen, upperOpen));
}

class _TypedArrayFactoryProvider {
  factory Float32Array(int length) => _wrap(_F32(length));
  factory Float32Array.fromList(List<num> list) => _wrap(_F32(ensureNative(list)));
  factory Float32Array.fromBuffer(ArrayBuffer buffer,
                                  [int byteOffset = 0, int length]) =>
      _wrap(_F32(_unwrap(buffer), byteOffset, length));
  static _F32(_arg0, [_arg1, _arg2]) native "Float32Array_constructor_Callback";

  factory Float64Array(int length) => _wrap(_F64(length));
  factory Float64Array.fromList(List<num> list) => _wrap(_F64(ensureNative(list)));
  factory Float64Array.fromBuffer(ArrayBuffer buffer,
                                  [int byteOffset = 0, int length]) =>
      _wrap(_F64(_unwrap(buffer), byteOffset, length));
  static _F64(_arg0, [_arg1, _arg2]) native "Float64Array_constructor_Callback";

  factory Int8Array(int length) => _wrap(_I8(length));
  factory Int8Array.fromList(List<num> list) => _wrap(_I8(ensureNative(list)));
  factory Int8Array.fromBuffer(ArrayBuffer buffer,
                               [int byteOffset = 0, int length]) =>
      _wrap(_I8(_unwrap(buffer), byteOffset, length));
  static _I8(_arg0, [_arg1, _arg2]) native "Int8Array_constructor_Callback";

  factory Int16Array(int length) => _wrap(_I16(length));
  factory Int16Array.fromList(List<num> list) => _wrap(_I16(ensureNative(list)));
  factory Int16Array.fromBuffer(ArrayBuffer buffer,
                                [int byteOffset = 0, int length]) =>
      _wrap(_I16(_unwrap(buffer), byteOffset, length));
  static _I16(_arg0, [_arg1, _arg2]) native "Int16Array_constructor_Callback";

  factory Int32Array(int length) => _wrap(_I32(length));
  factory Int32Array.fromList(List<num> list) => _wrap(_I32(ensureNative(list)));
  factory Int32Array.fromBuffer(ArrayBuffer buffer,
                                [int byteOffset = 0, int length]) =>
      _wrap(_I32(_unwrap(buffer), byteOffset, length));
  static _I32(_arg0, [_arg1, _arg2]) native "Int32Array_constructor_Callback";

  factory Uint8Array(int length) => _wrap(_U8(length));
  factory Uint8Array.fromList(List<num> list) => _wrap(_U8(ensureNative(list)));
  factory Uint8Array.fromBuffer(ArrayBuffer buffer,
                                [int byteOffset = 0, int length]) =>
      _wrap(_U8(_unwrap(buffer), byteOffset, length));
  static _U8(_arg0, [_arg1, _arg2]) native "Uint8Array_constructor_Callback";

  factory Uint16Array(int length) => _wrap(_U16(length));
  factory Uint16Array.fromList(List<num> list) => _wrap(_U16(ensureNative(list)));
  factory Uint16Array.fromBuffer(ArrayBuffer buffer,
                                 [int byteOffset = 0, int length]) =>
      _wrap(_U16(_unwrap(buffer), byteOffset, length));
  static _U16(_arg0, [_arg1, _arg2]) native "Uint16Array_constructor_Callback";

  factory Uint32Array(int length) => _wrap(_U32(length));
  factory Uint32Array.fromList(List<num> list) => _wrap(_U32(ensureNative(list)));
  factory Uint32Array.fromBuffer(ArrayBuffer buffer,
                                 [int byteOffset = 0, int length]) =>
      _wrap(_U32(_unwrap(buffer), byteOffset, length));
  static _U32(_arg0, [_arg1, _arg2]) native "Uint32Array_constructor_Callback";

  factory Uint8ClampedArray(int length) => _wrap(_U8C(length));
  factory Uint8ClampedArray.fromList(List<num> list) => _wrap(_U8C(ensureNative(list)));
  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer,
                                       [int byteOffset = 0, int length]) =>
      _wrap(_U8C(_unwrap(buffer), byteOffset, length));
  static _U8C(_arg0, [_arg1, _arg2]) native "Uint8ClampedArray_constructor_Callback";

  static ensureNative(List list) => list;  // TODO: make sure.
}

class _PointFactoryProvider {
  factory Point(num x, num y) => _wrap(_createWebKitPoint(x, y));
  static _createWebKitPoint(num x, num y) native "WebKitPoint_constructor_Callback";
}

class _WebSocketFactoryProvider {
  factory WebSocket(String url) => _wrap(_createWebSocket(url));
  static _createWebSocket(String url) native "WebSocket_constructor_Callback";
}

class _TextFactoryProvider {
  factory Text(String data) => _document.$dom_createTextNode(data);
}
