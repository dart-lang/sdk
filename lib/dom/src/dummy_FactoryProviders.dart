// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


_dummy() {
  throw const NotImplementedException();
}

class _AudioContextFactoryProvider {

  factory AudioContext() => _dummy();
}

class _TypedArrayFactoryProvider {

  factory Float32Array(int length) => _dummy();
  factory Float32Array.fromList(List<num> list) => _dummy();
  factory Float32Array.fromBuffer(ArrayBuffer buffer) => _dummy();

  factory Float64Array(int length) => _dummy();
  factory Float64Array.fromList(List<num> list) => _dummy();
  factory Float64Array.fromBuffer(ArrayBuffer buffer) => _dummy();

  factory Int8Array(int length) => _dummy();
  factory Int8Array.fromList(List<num> list) => _dummy();
  factory Int8Array.fromBuffer(ArrayBuffer buffer) => _dummy();

  factory Int16Array(int length) => _dummy();
  factory Int16Array.fromList(List<num> list) => _dummy();
  factory Int16Array.fromBuffer(ArrayBuffer buffer) => _dummy();

  factory Int32Array(int length) => _dummy();
  factory Int32Array.fromList(List<num> list) => _dummy();
  factory Int32Array.fromBuffer(ArrayBuffer buffer) => _dummy();

  factory Uint8Array(int length) => _dummy();
  factory Uint8Array.fromList(List<num> list) => _dummy();
  factory Uint8Array.fromBuffer(ArrayBuffer buffer) => _dummy();

  factory Uint16Array(int length) => _dummy();
  factory Uint16Array.fromList(List<num> list) => _dummy();
  factory Uint16Array.fromBuffer(ArrayBuffer buffer) => _dummy();

  factory Uint32Array(int length) => _dummy();
  factory Uint32Array.fromList(List<num> list) => _dummy();
  factory Uint32Array.fromBuffer(ArrayBuffer buffer) => _dummy();

  factory Uint8ClampedArray(int length) => _dummy();
  factory Uint8ClampedArray.fromList(List<num> list) => _dummy();
  factory Uint8ClampedArray.fromBuffer(ArrayBuffer buffer) => _dummy();
}

class _WebKitPointFactoryProvider {

  factory WebKitPoint(num x, num y) => _dummy();
}

class _WebSocketFactoryProvider {

  factory WebSocket(String url) => _dummy();
}
