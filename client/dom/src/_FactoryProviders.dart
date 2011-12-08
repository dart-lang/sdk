// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// These factory methods could all live in one factory provider class but dartc
// has a bug (5399939) preventing that.

class _FileReaderFactoryProvider {

  factory FileReader() { return create(); }

  static FileReader create() native;
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


  static Float32Array _F32(arg) native;
  static Float32Array _F64(arg) native;
  static Float32Array _I8(arg) native;
  static Float32Array _I16(arg) native;
  static Float32Array _I32(arg) native;
  static Float32Array _U8(arg) native;
  static Float32Array _U16(arg) native;
  static Float32Array _U32(arg) native;

  static ensureNative(List list) => list;  // TODO: make sure.
}

class _WebKitCSSMatrixFactoryProvider {

  factory WebKitCSSMatrix([String spec = '']) { return create(spec); }

  static WebKitCSSMatrix create(spec) native;
}

class _WebKitPointFactoryProvider {

  factory WebKitPoint(num x, num y) { return create(x, y); }

  static WebKitPoint create(x, y) native;
}

class _XMLHttpRequestFactoryProvider {

  factory XMLHttpRequest() { return create(); }

  static XMLHttpRequest create() native;
}
