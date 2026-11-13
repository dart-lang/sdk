// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=main
// functionFilter=tbl
// compilerOption=--no-minify
// compilerOption=--enable-experimental-wasm-interop

import 'dart:_wasm';

@pragma('wasm:never-inline')
void main() {
  print(table.size);
  print(table.grow(1, WasmFunction.fromFunction(f)));
  table.fill(0, WasmFunction.fromFunction(f), 2);
  table[0] = WasmFunction.fromFunction(f);
  print(
    table
        .callIndirect<WasmI32 Function(WasmI32)>(0)(42.toWasmI32())
        .toIntSigned(),
  );

  // Ensure we don't import table as a procedure when TFA replaces this with an
  // unconditional throw.
  table[0] = alwaysOne == 1 ? throw 'a' : WasmFunction.fromFunction(f);
}

@pragma('wasm:import', 'foo.tbl')
@pragma('wasm:table-type', TableType(limits: Limits(1, 10)))
external WasmTable<WasmFuncRef?> get table;

WasmI32 f(WasmI32 x) => x;

int get alwaysOne => 1;
