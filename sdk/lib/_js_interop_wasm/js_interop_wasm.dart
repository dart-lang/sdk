// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities to transform between `dart:js_interop` types and `WasmExternRef`
/// from `dart:_wasm`.
library;

import 'dart:_wasm';
import 'dart:js_interop';

extension WasmExternRefToJSAny on WasmExternRef {
  external JSAny get toJS;
}

// Note: We would make this an extension method on JSAny, but external methods
// on JS interop types are assumed to be JS interop functions, not methods that
// are patched in patch files. So instead we just use a plain function here.
external WasmExternRef? externRefForJSAny(JSAny object);
