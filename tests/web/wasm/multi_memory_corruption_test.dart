// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

import 'package:expect/expect.dart';

@pragma('wasm:memory-type', MemoryType(limits: Limits(1)))
external Memory get first;

@pragma('wasm:memory-type', MemoryType(limits: Limits(1)))
external Memory get second;

void main() {
  first.storeInt32(0, WasmI32.fromInt(0x01020304));
  second.storeInt32(0, WasmI32.fromInt(0x11223344));

  // Reversing the second store's memory index and offset writes to memory 0
  // at byte offset 1, corrupting the first value to 0x22334404. Keep all
  // immediate offsets zero so the buggy module validates and reaches this
  // assertion instead of being rejected for an out-of-range memory index.
  Expect.equals(0x01020304, first.loadInt32(0).toIntUnsigned());
  Expect.equals(0x11223344, second.loadInt32(0).toIntUnsigned());
}
