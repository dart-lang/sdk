// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// dart2wasmOptions=--enable-deferred-loading --extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

import '' deferred as M;

import 'package:expect/expect.dart';

void main() async {
  await M.loadLibrary();

  write();
  Expect.equals(42, M.read());
}

void write() {
  M.memory.storeInt64(0, WasmI64.fromInt(42));
}

@pragma('wasm:memory-type', MemoryType(limits: Limits(1)))
external Memory get memory;

@pragma('wasm:never-inline')
int read() {
  return memory.loadInt64(0).toInt();
}
