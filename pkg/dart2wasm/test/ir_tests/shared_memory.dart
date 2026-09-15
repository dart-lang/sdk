// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=main
// compilerOption=--no-minify

import 'dart:_wasm';

@pragma('wasm:import', 'host.memory')
@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 2), shared: true))
external Memory get imported;

@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 2), shared: true))
external Memory get defined;

@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 2)))
external Memory get unshared;

@pragma('wasm:never-inline')
void main() {
  imported.storeInt32(imported.size, WasmI32.fromInt(42), offset: 258);
  defined.storeFloat64(defined.size, WasmF64.fromDouble(42.5), offset: 258);
  unshared.storeInt32(unshared.size, WasmI32.fromInt(1), offset: 258);
}
