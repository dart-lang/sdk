// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=runTest|addInt|addWasmI32|pass.*ToJS
// typeFilter=NoMatch
// globalFilter=NoMatch
// compilerOption=--enable-experimental-wasm-interop
// compilerOption=-O0
// compilerOption=--inlining

import 'dart:_wasm';
import 'dart:_js_helper';

void main() {
  runTest();
}

@pragma('wasm:never-inline')
void runTest() {
  consumeInt(addInt(1, 2));
  consumeInt(addInt(3, 4));
  consumeInt(addWasmI32(1.toWasmI32(), 2.toWasmI32()).toIntSigned());
  consumeInt(addWasmI32(3.toWasmI32(), 4.toWasmI32()).toIntSigned());
  consumeAny(passIntToJS(1));
  consumeAny(passIntToJS(2));
  consumeAny(passWasmI32ToJS(1.toWasmI32()));
  consumeAny(passWasmI32ToJS(2.toWasmI32()));
}

@pragma('wasm:never-inline')
void consumeInt(int arg) {
  print(arg);
}

@pragma('wasm:never-inline')
void consumeAny(dynamic arg) {
  print(arg);
}

// This should be inlined as arguments are directly passed to wasm import and
// return value is directly returned.
WasmI32 addWasmI32(WasmI32 a, WasmI32 b) =>
    JS<WasmI32>('(a, b) => a + b', a, b);

// This should not be inlined as there's extra work on the arguments and result
// value.
int addInt(int a, int b) =>
    JS<WasmI32>('(a, b) => a + b', a.toWasmI32(), b.toWasmI32()).toIntSigned();

dynamic passIntToJS(int a) => JS<void>('(a) => {}', a.toWasmI32());
dynamic passWasmI32ToJS(WasmI32 a) => JS<void>('(a) => {}', a);
