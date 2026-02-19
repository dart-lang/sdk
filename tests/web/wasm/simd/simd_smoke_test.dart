// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'package:expect/expect.dart';

// ignore: import_internal_library
import 'dart:_wasm';

void main() {
  WasmI64x2 v1 = WasmI64x2.splat(WasmI64.fromInt(10));
  WasmI64x2 v2 = WasmI64x2.splat(WasmI64.fromInt(20));
  Expect.equals(v1.extractLane(0), 10);
  Expect.equals(v1.extractLane(1), 10);
  Expect.equals(v2.extractLane(0), 20);
  Expect.equals(v2.extractLane(1), 20);

  WasmI64x2 v3 = v1 + v2;
  Expect.equals(v3.extractLane(0), 30);
  Expect.equals(v3.extractLane(1), 30);

  WasmI32x4 v4 = v3 as WasmI32x4;
  Expect.equals(v4.extractLane(0).toIntUnsigned(), 30);
  Expect.equals(v4.extractLane(1).toIntUnsigned(), 0);
  Expect.equals(v4.extractLane(2).toIntUnsigned(), 30);
  Expect.equals(v4.extractLane(3).toIntUnsigned(), 0);
}
