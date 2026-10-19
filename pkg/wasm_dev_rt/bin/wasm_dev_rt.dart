// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The Wasm dev runtime app. Modules from the dev compiler import its exports
// as `wasm_dev_rt`.

import 'dart:_js_interop_wasm';
import 'dart:_wasm';
import 'dart:js_interop';

import 'package:wasm_dev_rt/wasm_dev_rt.dart' as rt;

void main() {}

@pragma('wasm:export', 'print')
WasmVoid printMessage(WasmExternRef message) {
  print((message.toJS as JSString).toDart);
  return WasmVoid();
}

@pragma('wasm:export', 'staticId')
WasmI32 staticId(WasmExternRef label) =>
    WasmI32.fromInt(rt.staticId((label.toJS as JSString).toDart));

@pragma('wasm:export', 'declareStatic')
WasmVoid declareStatic(WasmI32 id, WasmFuncRef function) {
  rt.declareStatic(id.toIntSigned(), function);
  return WasmVoid();
}

@pragma('wasm:export', 'lookupStatic')
WasmFuncRef lookupStatic(WasmI32 id) => rt.lookupStatic(id.toIntSigned());
