// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

import 'package:expect/expect.dart';

@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 2)))
external Memory get first;

@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 2)))
external Memory get second;

void main() {
  // A nonzero offset must not be interpreted as another memory index.
  second.storeFloat64(16, WasmF64.fromDouble(42.5), offset: 258);
  Expect.equals(42.5, second.loadFloat64(16, offset: 258).toDouble());
  Expect.equals(0.0, first.loadFloat64(16, offset: 258).toDouble());

  second.fill(WasmI32.fromInt(127), 32, 8);
  Expect.equals(127, second.loadUint8(39).toIntUnsigned());
  Expect.equals(0, first.loadUint8(39).toIntUnsigned());

  Expect.equals(1, second.grow(1));
  Expect.equals(2, second.size);
  Expect.equals(1, first.size);
  second.storeInt64(Memory.pageSize, WasmI64.fromInt(9007199254740993));
  Expect.equals(9007199254740993, second.loadInt64(Memory.pageSize).toInt());
  Expect.equals(0, first.loadInt32(0).toIntUnsigned());
}
