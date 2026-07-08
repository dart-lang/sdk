// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=Export
// typeFilter=NoMatch
// globalFilter=NoMatch
// compilerOption=-O2

import 'dart:_wasm';

void main() {
  print(usedWeakExport);
}

@pragma('wasm:export', 'strongExport')
WasmI32 strongExport() {
  print('strongExport');
  return 1.toWasmI32();
}

@pragma('wasm:export', 'usedWeakExport')
WasmI32 usedWeakExport() {
  print('usedWeakExport');
  return 1.toWasmI32();
}

@pragma('wasm:weak-export', 'unusedWeakExport')
WasmI32 unusedWeakExport() {
  print('unusedWeakExport');
  return 1.toWasmI32();
}
