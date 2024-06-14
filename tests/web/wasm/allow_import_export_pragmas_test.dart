// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--enable-experimental-wasm-interop

// Test that importing `dart:_wasm` and using import/export pragmas works if the
// compiler is given the `--enable-experimental-wasm-interop` flag.

import 'dart:_wasm';

@pragma('wasm:export', 'f')
void f() {}

@pragma('wasm:import', 'g')
external WasmI32 g(WasmI32 x);

void main() {}
