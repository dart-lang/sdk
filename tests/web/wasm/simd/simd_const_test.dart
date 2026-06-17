// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

// ignore: import_internal_library
import 'dart:_wasm';

import 'package:expect/expect.dart';

// I8x16
const _i8x16 = WasmI8x16(
  WasmV128.i8x16(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16),
);

// I16x8
const _i16x8 = WasmI16x8(WasmV128.i16x8(10, 20, 30, 40, 50, 60, 70, 80));

// I32x4
const _i32x4 = WasmI32x4(WasmV128.i32x4(100, 200, 300, 400));

// I64x2
const _i64x2 = WasmI64x2(WasmV128.i64x2(1000, 2000));

// F32x4
const _f32x4 = WasmF32x4(WasmV128.f32x4(1.5, 2.5, 3.5, 4.5));

// F64x2
const _f64x2 = WasmF64x2(WasmV128.f64x2(1.1, 2.2));

void main() {
  print("Starting tests...");
  testI8x16();
  testI16x8();
  testI32x4();
  testI64x2();
  testF32x4();
  testF64x2();
  testF64x2Literal();
  print("All tests passed!");
}

void testF64x2Literal() {
  print("Running testF64x2Literal...");
  // Constant
  const v_const = WasmF64x2(WasmV128.f64x2(3.3, 4.4));
  Expect.equals(3.3, v_const.extractLane(0).toDouble());
  Expect.equals(4.4, v_const.extractLane(1).toDouble());

  // Using runtime call to verify intrinsic generation for non-const arguments.
  final a = 3.3;
  final b = 4.4;
  final v = WasmF64x2.fromDoubles(a, b);
  Expect.equals(3.3, v.extractLane(0).toDouble());
  Expect.equals(4.4, v.extractLane(1).toDouble());
}

void testI8x16() {
  print("Running testI8x16...");
  final v = _i8x16;
  Expect.equals(1, v.extractLaneSigned(0).toIntSigned());
  Expect.equals(2, v.extractLaneSigned(1).toIntSigned());
  Expect.equals(8, v.extractLaneSigned(7).toIntSigned());
  Expect.equals(16, v.extractLaneSigned(15).toIntSigned());
}

void testI16x8() {
  print("Running testI16x8...");
  final v = _i16x8;
  Expect.equals(10, v.extractLaneSigned(0).toIntSigned());
  Expect.equals(20, v.extractLaneSigned(1).toIntSigned());
  Expect.equals(80, v.extractLaneSigned(7).toIntSigned());
}

void testI32x4() {
  print("Running testI32x4...");
  final v = _i32x4;
  Expect.equals(100, v.extractLane(0).toIntSigned());
  Expect.equals(200, v.extractLane(1).toIntSigned());
  Expect.equals(400, v.extractLane(3).toIntSigned());
}

void testI64x2() {
  print("Running testI64x2...");
  final v = _i64x2;
  Expect.equals(1000, v.extractLane(0).toInt());
  Expect.equals(2000, v.extractLane(1).toInt());
}

void testF32x4() {
  print("Running testF32x4...");
  final v = _f32x4;
  Expect.equals(1.5, v.extractLane(0).toDouble());
  Expect.equals(2.5, v.extractLane(1).toDouble());
  Expect.equals(4.5, v.extractLane(3).toDouble());
}

void testF64x2() {
  print("Running testF64x2...");
  final v = _f64x2;
  Expect.equals(1.1, v.extractLane(0).toDouble());
  Expect.equals(2.2, v.extractLane(1).toDouble());
}
