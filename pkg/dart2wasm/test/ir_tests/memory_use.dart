// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=main
// functionFilter=mem
// compilerOption=--no-minify
// compilerOption=--enable-experimental-wasm-interop

import 'dart:_wasm';

@pragma('wasm:import', 'foo.mem')
@pragma('wasm:memory-type', MemoryType(limits: Limits(1)))
external Memory get memory;

@pragma('wasm:import', 'foo.second_mem')
@pragma('wasm:memory-type', MemoryType(limits: Limits(1)))
external Memory get secondMemory;

@pragma('wasm:never-inline')
void main() {
  memory.size;
  memory.grow(1);
  print(memory.loadFloat32(0, align: 2).toDouble());
  print(memory.loadFloat32(0, align: 2).toDouble());
  print(memory.loadFloat64(0, align: 3).toDouble());

  print(memory.loadFloat32(0, offset: 1, align: 2).toDouble());
  print(memory.loadFloat32(0, align: 2, offset: 1).toDouble());

  memory.storeInt32(memory.size, WasmI32.fromInt(32), offset: 10);

  // Ensure the memory index and offset are correctly ordered; 
  // if not, wasm-opt must reject before the IR snapshot is produced.
  // See https://dart-review.googlesource.com/c/sdk/+/547420
  secondMemory.storeFloat64(
    secondMemory.size,
    WasmF64.fromDouble(42.5),
    offset: 258,
    align: 3,
  );
  print(
    secondMemory
        .loadFloat64(secondMemory.size, offset: 258, align: 3)
        .toDouble(),
  );

  // Ensure we don't import memory as a procedure when TFA replaces this with an
  // unconditional throw (https://dart-review.googlesource.com/c/sdk/+/546240).
  memory.storeInt64(0, alwaysOne == 1 ? throw 'a' : WasmI64.fromInt(42));
}

int get alwaysOne => 1;
