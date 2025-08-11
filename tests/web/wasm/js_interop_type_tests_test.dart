// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_js_helper';
import 'dart:_js_types';
import 'dart:_string';
import 'dart:_wasm';
import 'dart:js_interop' hide JS;
import 'dart:typed_data';

import 'package:expect/expect.dart';

void main() {
  Expect.throws<ArgumentError>(
    () =>
        JSInt8ArrayImpl.fromRef(JS<WasmExternRef?>('() => new Uint8Array(10)')),
  );
  Expect.throws<ArgumentError>(
    () =>
        JSUint8ArrayImpl.fromRef(JS<WasmExternRef?>('() => new Int8Array(10)')),
  );
  Expect.throws<ArgumentError>(
    () => JSUint8ClampedArrayImpl.fromRef(
      JS<WasmExternRef?>('() => new Uint8Array(10)'),
    ),
  );
  Expect.throws<ArgumentError>(
    () => JSInt16ArrayImpl.fromRef(
      JS<WasmExternRef?>('() => new Uint16Array(10)'),
    ),
  );
  Expect.throws<ArgumentError>(
    () => JSUint16ArrayImpl.fromRef(
      JS<WasmExternRef?>('() => new Int16Array(10)'),
    ),
  );
  Expect.throws<ArgumentError>(
    () => JSInt32ArrayImpl.fromRef(
      JS<WasmExternRef?>('() => new Uint32Array(10)'),
    ),
  );
  Expect.throws<ArgumentError>(
    () => JSUint32ArrayImpl.fromRef(
      JS<WasmExternRef?>('() => new Int32Array(10)'),
    ),
  );
  Expect.throws<ArgumentError>(
    () => JSFloat32ArrayImpl.fromRef(
      JS<WasmExternRef?>('() => new Float64Array(10)'),
    ),
  );
  Expect.throws<ArgumentError>(
    () => JSFloat64ArrayImpl.fromRef(
      JS<WasmExternRef?>('() => new Float32Array(10)'),
    ),
  );
  Expect.throws<ArgumentError>(
    () => JSArrayBufferImpl.fromRef(
      JS<WasmExternRef?>('() => new DataView(new ArrayBuffer(10))'),
    ),
  );
  Expect.throws<ArgumentError>(
    () =>
        JSDataViewImpl.fromRef(JS<WasmExternRef?>('() => new ArrayBuffer(10)')),
  );
  Expect.throws<ArgumentError>(
    () => JSStringImpl.fromRef(JS<WasmExternRef?>('() => new ArrayBuffer(10)')),
  );
  Expect.throws<ArgumentError>(
    () => JSArrayImpl.fromRef(JS<WasmExternRef?>('() => "hi"')),
  );

  final JSInt8Array jsInt8ArrayBox =
      JSValue(JS<WasmExternRef?>('() => new Uint8Array(10)')) as JSInt8Array;
  Expect.throws<ArgumentError>(() {
    final Int8List dartValue = jsInt8ArrayBox.toDart;
  });

  final JSUint8Array jsUint8ArrayBox =
      JSValue(JS<WasmExternRef?>('() => new Int8Array(10)')) as JSUint8Array;
  Expect.throws<ArgumentError>(() {
    final Uint8List dartValue = jsUint8ArrayBox.toDart;
  });

  final JSUint8ClampedArray jsUint8ClampedArrayBox =
      JSValue(JS<WasmExternRef?>('() => new Uint8Array(10)'))
          as JSUint8ClampedArray;
  Expect.throws<ArgumentError>(() {
    final Uint8ClampedList dartValue = jsUint8ClampedArrayBox.toDart;
  });

  final JSInt16Array jsInt16ArrayBox =
      JSValue(JS<WasmExternRef?>('() => new Uint16Array(10)')) as JSInt16Array;
  Expect.throws<ArgumentError>(() {
    final Int16List dartValue = jsInt16ArrayBox.toDart;
  });

  final JSUint16Array jsUint16ArrayBox =
      JSValue(JS<WasmExternRef?>('() => new Int16Array(10)')) as JSUint16Array;
  Expect.throws<ArgumentError>(() {
    final Uint16List dartValue = jsUint16ArrayBox.toDart;
  });

  final JSInt32Array jsInt32ArrayBox =
      JSValue(JS<WasmExternRef?>('() => new Uint32Array(10)')) as JSInt32Array;
  Expect.throws<ArgumentError>(() {
    final Int32List dartValue = jsInt32ArrayBox.toDart;
  });

  final JSUint32Array jsUint32ArrayBox =
      JSValue(JS<WasmExternRef?>('() => new Int32Array(10)')) as JSUint32Array;
  Expect.throws<ArgumentError>(() {
    final Uint32List dartValue = jsUint32ArrayBox.toDart;
  });

  final JSFloat32Array jsFloat32ArrayBox =
      JSValue(JS<WasmExternRef?>('() => new Float64Array(10)'))
          as JSFloat32Array;
  Expect.throws<ArgumentError>(() {
    final Float32List dartValue = jsFloat32ArrayBox.toDart;
  });

  final JSFloat64Array jsFloat64ArrayBox =
      JSValue(JS<WasmExternRef?>('() => new Float32Array(10)'))
          as JSFloat64Array;
  Expect.throws<ArgumentError>(() {
    final Float64List dartValue = jsFloat64ArrayBox.toDart;
  });

  final JSArrayBuffer jsArrayBufferBox =
      JSValue(JS<WasmExternRef?>('() => new DataView(new ArrayBuffer(10))'))
          as JSArrayBuffer;
  Expect.throws<ArgumentError>(() {
    final ByteBuffer dartValue = jsArrayBufferBox.toDart;
  });

  final JSDataView jsDataViewBox =
      JSValue(JS<WasmExternRef?>('() => new ArrayBuffer(10)')) as JSDataView;
  Expect.throws<ArgumentError>(() {
    final ByteData dartValue = jsDataViewBox.toDart;
  });

  final JSString jsStringBox =
      JSValue(JS<WasmExternRef?>('() => new ArrayBuffer(10)')) as JSString;
  Expect.throws<ArgumentError>(() {
    final String dartValue = jsStringBox.toDart;
  });

  final JSArray jsArrayBox =
      JSValue(JS<WasmExternRef?>('() => "hi"')) as JSArray;
  Expect.throws<ArgumentError>(() {
    final List dartValue = jsArrayBox.toDart;
  });
}
