// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper" show JS, jsStringFromDartString, JSExternWrapperExt;
import 'dart:_string' show JSStringImpl;
import 'dart:_wasm';

String jsonEncode(String object) =>
    // Use checked boxing as `JSON.stringify` can be patched by users.
    JSStringImpl.fromRef(
      JS<WasmExternRef>(
        "s => JSON.stringify(s)",
        jsStringFromDartString(object).wrappedExternRef,
      ),
    );
