// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';
import 'dart:js_interop';

import 'package:expect/expect.dart';

@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 10)))
@pragma('wasm:export', 'memory')
external Memory get _memory;

@JS()
external void eval(String code);

@JS()
external int jsReadMemoryInt32(int byteOffset);

@JS()
external void jsWriteMemoryInt32(int byteOffset, int value);

void main() {
  _testSizeAndGrow();
  _testFill();

  _testFloat();
  _testInt();
  _testOffset();
  _testExport();
}

void _testSizeAndGrow() {
  Expect.equals(1, _memory.size);
  Expect.equals(1, _memory.grow(1));
  Expect.equals(2, _memory.size);

  Expect.equals(0, _memory.loadInt32(Memory.pageSize + 1).toIntSigned());

  Expect.equals(-1, _memory.grow(20));
}

void _testFill() {
  _memory.fill(WasmI32.fromInt(42), 0, 1024);
  for (var i = 0; i < 1024; i++) {
    Expect.equals(42, _memory.loadUint8(i).toIntSigned());
  }
}

void _testFloat() {
  _memory.storeFloat64(0, WasmF64.fromDouble(1.5));
  Expect.equals(1.5, _memory.loadFloat64(0).toDouble());

  _memory.storeFloat32(0, WasmF32.fromDouble(1.5));
  Expect.equals(1.5, _memory.loadFloat32(0).toDouble());
}

void _testInt() {
  _memory.storeInt8(0, WasmI32.fromInt(-1));
  Expect.equals(-1, _memory.loadInt8(0).toIntSigned());
  Expect.equals(255, _memory.loadUint8(0).toIntUnsigned());
}

void _testOffset() {
  _memory.storeInt32(0, WasmI32.fromInt(0x01020304));
  Expect.equals(0x01, _memory.loadInt8(0, offset: 3).toIntSigned());
  Expect.equals(0x02, _memory.loadInt8(0, offset: 2).toIntSigned());
  Expect.equals(0x03, _memory.loadInt8(0, offset: 1).toIntSigned());
  Expect.equals(0x04, _memory.loadInt8(0, offset: 0).toIntSigned());
}

void _testExport() {
  eval(r'''
    globalThis.jsReadMemoryInt32 = function(byteOffset) {
      const mem = globalThis.appInstanceForTesting.instantiatedModule.exports.memory;
      const view = new DataView(mem.buffer);
      return view.getInt32(byteOffset, true);
    };
    globalThis.jsWriteMemoryInt32 = function(byteOffset, value) {
      const mem = globalThis.appInstanceForTesting.instantiatedModule.exports.memory;
      const view = new DataView(mem.buffer);
      view.setInt32(byteOffset, value, true);
    };
  ''');

  _memory.storeInt32(16, WasmI32.fromInt(0x12345678));
  Expect.equals(0x12345678, jsReadMemoryInt32(16));

  jsWriteMemoryInt32(16, 0x07654321);
  Expect.equals(0x07654321, _memory.loadInt32(16).toIntSigned());
}
