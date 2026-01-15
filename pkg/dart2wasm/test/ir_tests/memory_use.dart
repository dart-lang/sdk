// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=main
// compilerOption=--no-minify
// compilerOption=--enable-experimental-wasm-interop

import 'dart:_wasm';

@pragma('wasm:import', 'foo.mem')
@pragma('wasm:memory-type', MemoryType(limits: Limits(1)))
external Memory get memory;

@pragma('wasm:never-inline')
void main() {
  memory.size;
  memory.grow(1);
  print(memory.loadFloat32(0, align: 2).toDouble());
  print(memory.loadFloat32(0, align: 2).toDouble());
  print(memory.loadFloat64(0, align: 3).toDouble());

  print(memory.loadFloat32(0, offset: 1, align: 2).toDouble());
  print(memory
      .loadFloat32(
        0,
        align: 2,
        offset: 1,
      )
      .toDouble());

  memory.storeInt32(memory.size, WasmI32.fromInt(32), offset: 10);
}
