// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=testGlobals
// globalFilter=foo|bar
// compilerOption=-O0

import 'dart:_wasm';

void main() {
  testGlobals();
}

@pragma('wasm:never-inline')
void testGlobals() {
  bar.value = foo.value + bar.value + const WasmI32(42);
}

@pragma('wasm:import', 'app.foo')
external Global<WasmI32> get foo;

@pragma('wasm:import', 'app.bar')
external MutableGlobal<WasmI32> get bar;
