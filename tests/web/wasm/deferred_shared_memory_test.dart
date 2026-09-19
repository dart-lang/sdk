// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--enable-deferred-loading --extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

import 'package:expect/expect.dart';

import 'shared_memory_test.dart' deferred as memory;

Future<void> main() async {
  await memory.loadLibrary();
  memory.shared.storeInt32(8, WasmI32.fromInt(123));
  memory.main();
  Expect.equals(123, memory.shared.loadInt32(8).toIntSigned());
}
