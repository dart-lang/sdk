// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal';
import 'dart:_js_helper';
import 'dart:_js_types';
import 'dart:_wasm';

@patch
class _BoxedInt {
  @patch
  String toRadixString(int radix) {
    // We could also catch the `_JavaScriptError` here and convert it to
    // `RangeError`, but I'm not sure if that would be faster.
    if (radix < 2 || 36 < radix) {
      throw RangeError.range(radix, 2, 36, "radix");
    }
    return JSStringImpl(JS<WasmExternRef?>(
        '(n, r) => n.toString(r)', toDouble().toExternRef, radix.toDouble()));
  }

  @patch
  String toString() => JSStringImpl(
      JS<WasmExternRef?>('(n) => n.toString()', toDouble().toExternRef));
}
