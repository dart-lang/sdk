// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_wasm';

import '' deferred as D0;

void main() async {
  print('main');
  await D0.loadLibrary();
  print('main - after D0 loaded');
  D0.d0_export();
  D0.d0_weakExport();
  D0.d0_noExport();
}

@pragma('wasm:export', 'd0_export')
WasmVoid d0_export() {
  print('Strong export');
  return WasmVoid();
}

@pragma('wasm:weak-export', 'd0_weakExport')
WasmVoid d0_weakExport() {
  print('Weak export');
  return WasmVoid();
}

void d0_noExport() {
  print('No export');
}
