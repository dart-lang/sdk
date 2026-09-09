// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

import 'package:expect/expect.dart';

@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 2), shared: true))
external Memory get shared;

@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 2)))
external Memory get unshared;

void main() {
  shared.storeInt32(0, WasmI32.fromInt(42));
  Expect.equals(42, shared.loadInt32(0).toIntSigned());
  Expect.equals(0, unshared.loadInt32(0).toIntSigned());

  shared.fill(WasmI32.fromInt(127), 32, 8);
  Expect.equals(127, shared.loadUint8(39).toIntUnsigned());
  Expect.equals(0, unshared.loadUint8(39).toIntUnsigned());

  Expect.equals(1, shared.grow(1));
  Expect.equals(2, shared.size);
  Expect.equals(1, unshared.size);
  shared.storeFloat64(Memory.pageSize, WasmF64.fromDouble(42.5));
  Expect.equals(42.5, shared.loadFloat64(Memory.pageSize).toDouble());
  Expect.equals(-1, shared.grow(1));
  Expect.equals(42, shared.loadInt32(0).toIntSigned());
}
