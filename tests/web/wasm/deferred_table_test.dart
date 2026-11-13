// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// dart2wasmOptions=--enable-deferred-loading --extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

import '' deferred as M;

import 'package:expect/expect.dart';

void main() async {
  await M.loadLibrary();

  write();
  Expect.equals(42, M.read(41));
  Expect.equals(
    42,
    M.table
        .callIndirect<WasmI32 Function(WasmI32)>(0)(41.toWasmI32())
        .toIntSigned(),
  );
  Expect.equals(
    42,
    (M.table)
        .callIndirect<WasmI32 Function(WasmI32)>(0)(41.toWasmI32())
        .toIntSigned(),
  );
}

void write() {
  M.table[0] = WasmFunction.fromFunction(addOne);
}

@pragma('wasm:never-inline')
int read(int x) {
  return table
      .callIndirect<WasmI32 Function(WasmI32)>(0)(x.toWasmI32())
      .toIntSigned();
}

@pragma('wasm:table-type', TableType(limits: Limits(1)))
external WasmTable<WasmFuncRef?> get table;

WasmI32 addOne(WasmI32 x) => x + 1.toWasmI32();
