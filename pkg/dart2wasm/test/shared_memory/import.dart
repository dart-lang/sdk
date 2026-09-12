// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_wasm';

import 'package:expect/expect.dart';

@pragma('wasm:import', 'ffi.sharedMemory')
@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 2), shared: true))
external Memory get memory;

@pragma('wasm:import', 'ffi.memory')
@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 2)))
external Memory get unsharedMemory;

@pragma('wasm:import', 'ffi.read')
external WasmI32 read(WasmI32 address);

@pragma('wasm:import', 'ffi.write')
external void write(WasmI32 address, WasmI32 value);

void main() {
  memory.storeInt32(16, WasmI32.fromInt(42));
  Expect.equals(42, read(WasmI32.fromInt(16)).toIntSigned());
  Expect.equals(0, unsharedMemory.loadInt32(16).toIntSigned());
  write(WasmI32.fromInt(20), WasmI32.fromInt(123));
  Expect.equals(123, memory.loadInt32(20).toIntSigned());

  Expect.equals(1, memory.grow(1));
  Expect.equals(1, unsharedMemory.size);
  memory.storeInt32(Memory.pageSize, WasmI32.fromInt(456));
  Expect.equals(456, read(WasmI32.fromInt(Memory.pageSize)).toIntSigned());
}
