// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=dartFunction|runTest
// tableFilter=NoMatch
// globalFilter=NoMatch
// typeFilter=NoMatch

import 'dart:_wasm';

void main() {
  runTest();
}

@pragma('wasm:never-inline')
void runTest() {
  registerCallback(
    WasmFunction<WasmVoid Function()>.fromFunction(dartFunction),
  );
}

WasmVoid dartFunction() {
  print("Hello");
  return WasmVoid();
}

@pragma('wasm:import', 'outside.registerCallback')
external WasmVoid registerCallback(WasmFunction<WasmVoid Function()> callback);
