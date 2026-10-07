// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

// Regression test for boxing when storing into a `WasmArray<Object?>`.
//
// Assigning a value whose static type is a primitive (`int`, `double`) through
// `operator []=` must box that value, because the array element type is
// `Object?`.

import 'dart:_wasm';

import 'package:expect/expect.dart';

@pragma('wasm:never-inline')
void storeInt(WasmArray<Object?> array, int value) {
  array[0] = value;
}

@pragma('wasm:never-inline')
void storeDouble(WasmArray<Object?> array, double value) {
  array[1] = value;
}

@pragma('wasm:never-inline')
void storeLiteral(WasmArray<Object?> array) {
  array[2] = 7;
}

/// The same store as [storeInt], written so that it compiles today.
@pragma('wasm:never-inline')
void storeViaObjectVariable(WasmArray<Object?> array, int value) {
  final Object? boxed = value;
  array[3] = boxed;
}

void main() {
  final array = WasmArray<Object?>(4);

  storeInt(array, 42);
  storeDouble(array, 3.5);
  storeLiteral(array);
  storeViaObjectVariable(array, 99);

  Expect.equals(42, array[0]);
  Expect.equals(3.5, array[1]);
  Expect.equals(7, array[2]);
  Expect.equals(99, array[3]);
}
