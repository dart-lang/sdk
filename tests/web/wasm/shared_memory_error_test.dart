// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

@pragma('wasm:memory-type', MemoryType(limits: Limits(1), shared: true))
external Memory get missingMaximum;
//                  ^
// [web] Shared WebAssembly memories must specify a maximum size.

@pragma('wasm:import', 'host.memory')
@pragma('wasm:memory-type', MemoryType(limits: Limits(1), shared: true))
external Memory get importedMissingMaximum;
//                  ^
// [web] Shared WebAssembly memories must specify a maximum size.

void main() {}
