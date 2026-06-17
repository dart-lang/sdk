// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

void main() {
  // l0 value 128 does not fit in signed 8-bit integer [-128, 127]
  const WasmV128.i8x16(128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  //    ^
  // [web] WasmV128 constant lane 'l0' value '128' does not fit in a signed 8-bit integer.

  // l0 value 32768 does not fit in signed 16-bit integer [-32768, 32767]
  const WasmV128.i16x8(32768, 0, 0, 0, 0, 0, 0, 0);
  //    ^
  // [web] WasmV128 constant lane 'l0' value '32768' does not fit in a signed 16-bit integer.

  // l0 value 2147483648 does not fit in signed 32-bit integer [-2147483648, 2147483647]
  const WasmV128.i32x4(2147483648, 0, 0, 0);
  //    ^
  // [web] WasmV128 constant lane 'l0' value '2147483648' does not fit in a signed 32-bit integer.
}
