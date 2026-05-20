// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "dart:_internal" show patch;
import "dart:_wasm";
import "dart:js_interop";

@patch
extension WasmExternRefToJSAny on WasmExternRef {
  @patch
  JSAny get toJS => throw UnsupportedError(
    'WasmExternRefToJSAny.toJS is unsupported on the standalone target.',
  );
}

@patch
WasmExternRef? externRefForJSAny(JSAny object) => throw UnsupportedError(
  'externRefForJSAny is unsupported on the standalone target.',
);
