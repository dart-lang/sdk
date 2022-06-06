// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js_util_wasm;

import "dart:_internal";
import "dart:_js_helper";
import "dart:wasm";

@patch
Object allowInterop<F extends Function>(F f) => throw 'unreachable';

@pragma("wasm:import", "dart2wasm.wrapDartCallback")
external WasmAnyRef _wrapDartCallbackRaw(
    WasmAnyRef callback, WasmAnyRef trampolineName);

JSValue? _wrapDartCallback(Object callback, String trampolineName) {
  return JSValue(_wrapDartCallbackRaw(
      callback.toJS().toAnyRef(), trampolineName.toJS().toAnyRef()));
}
