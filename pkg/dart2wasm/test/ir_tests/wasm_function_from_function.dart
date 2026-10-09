// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=dartFunction|runTest|JS_Trampoline
// tableFilter=NoMatch
// globalFilter=NoMatch
// typeFilter=NoMatch

import 'dart:_wasm';
import 'dart:js_interop';

void main() {
  runTest();
}

@pragma('wasm:never-inline')
void runTest() {
  registerCallback(
    WasmFunction<WasmVoid Function()>.fromFunction(dartFunction),
  );
  print(makeJsCallback(jsCallback1));
  print(makeJsCallback(jsCallback2));
}

@pragma('wasm:never-inline')
JSFunction makeJsCallback<T extends JSAny?>(void Function(T) callback) {
  return callback.toJS;
}

void jsCallback1(JSString s) => print(s);
void jsCallback2(JSNumber n) => print(n);

WasmVoid dartFunction() {
  print("Hello");
  return WasmVoid();
}

@pragma('wasm:import', 'outside.registerCallback')
external WasmVoid registerCallback(
  WasmFuncRef /* WasmFunction<WasmVoid Function()> */ callback,
);
