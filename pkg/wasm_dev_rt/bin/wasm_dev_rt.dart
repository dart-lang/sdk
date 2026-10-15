// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The Wasm dev runtime app. Modules from the dev compiler import its exports
// as `wasm_dev_rt`.

import 'dart:_js_interop_wasm';
import 'dart:_wasm';
import 'dart:js_interop';

void main() {}

@pragma('wasm:export', 'print')
WasmVoid printMessage(WasmExternRef message) {
  print((message.toJS as JSString).toDart);
  return WasmVoid();
}
