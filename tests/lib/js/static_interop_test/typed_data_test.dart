// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the JS types that are intercepted by `@Native` typed_data classes
// are interoperable using static interop.

@JS()
library typed_data_test;

import 'dart:js_interop';

@JS()
external void eval(String code);

// dart:js_interop top-levels do return-type checks so if the call to these
// getters succeed, it's enough to know they can be interoperable.

@JS()
external JSObject get arrayBuffer;

@JS()
external JSObject get dataView;

@JS()
external JSObject get float32Array;

@JS()
external JSObject get float64Array;

@JS()
external JSObject get int8Array;

@JS()
external JSObject get int16Array;

@JS()
external JSObject get int32Array;

@JS()
external JSObject get uint8Array;

@JS()
external JSObject get uint8ClampedArray;

@JS()
external JSObject get uint16Array;

@JS()
external JSObject get uint32Array;

void main() {
  eval('''
    globalThis.arrayBuffer = new ArrayBuffer(1);
    globalThis.dataView = new DataView(globalThis.arrayBuffer);
    globalThis.float32Array = new Float32Array(1);
    globalThis.float64Array = new Float64Array(1);
    globalThis.int8Array = new Int8Array(1);
    globalThis.int16Array = new Int16Array(1);
    globalThis.int32Array = new Int32Array(1);
    globalThis.uint8Array = new Uint8Array(1);
    globalThis.uint8ClampedArray = new Uint8ClampedArray(1);
    globalThis.uint16Array = new Uint16Array(1);
    globalThis.uint32Array = new Uint32Array(1);
  ''');
  arrayBuffer;
  dataView;
  float32Array;
  float64Array;
  int8Array;
  int16Array;
  int32Array;
  uint8Array;
  uint8ClampedArray;
  uint16Array;
  uint32Array;
}
