// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test errors thrown by function imports.

import "package:expect/expect.dart";
import "dart:wasm";
import "dart:typed_data";

void main() {
  // This module expects a function import like:
  // int64_t someFn(int32_t a, int64_t b, float c, double d);
  var data = Uint8List.fromList([
    0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x0c, 0x02, 0x60,
    0x04, 0x7f, 0x7e, 0x7d, 0x7c, 0x01, 0x7e, 0x60, 0x00, 0x00, 0x02, 0x0e,
    0x01, 0x03, 0x65, 0x6e, 0x76, 0x06, 0x73, 0x6f, 0x6d, 0x65, 0x46, 0x6e,
    0x00, 0x00, 0x03, 0x02, 0x01, 0x01, 0x04, 0x05, 0x01, 0x70, 0x01, 0x01,
    0x01, 0x05, 0x03, 0x01, 0x00, 0x02, 0x06, 0x08, 0x01, 0x7f, 0x01, 0x41,
    0x80, 0x88, 0x04, 0x0b, 0x07, 0x11, 0x02, 0x06, 0x6d, 0x65, 0x6d, 0x6f,
    0x72, 0x79, 0x02, 0x00, 0x04, 0x62, 0x6c, 0x61, 0x68, 0x00, 0x01, 0x0a,
    0x1d, 0x01, 0x1b, 0x00, 0x41, 0x01, 0x42, 0x02, 0x43, 0x00, 0x00, 0x40,
    0x40, 0x44, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x40, 0x10, 0x80,
    0x80, 0x80, 0x80, 0x00, 0x1a, 0x0b,
  ]);

  var mod = WasmModule(data);
  var imp = WasmImports()
    ..addFunction<Int64 Function(Int32, Int64, Float, Double)>(
        "env", "someFn", (num a, num b, num c, num d) => 123);
  mod.instantiate(imp);

  imp = WasmImports();
  Expect.throwsArgumentError(() => mod.instantiate(imp));

  imp = WasmImports()
    ..addFunction<Int64 Function(Int32)>("env", "someFn", (num a) => 123);
  Expect.throwsArgumentError(() => mod.instantiate(imp));

  imp = WasmImports()
    ..addFunction<Double Function(Int32, Int64, Float, Double)>(
        "env", "someFn", (num a, num b, num c, num d) => 123);
  Expect.throwsArgumentError(() => mod.instantiate(imp));

  imp = WasmImports()
    ..addFunction<Int64 Function(Int32, Int64, Float, Float)>(
        "env", "someFn", (num a, num b, num c, num d) => 123);
  Expect.throwsArgumentError(() => mod.instantiate(imp));

  Expect.throwsArgumentError(() => WasmImports()
    ..addFunction<dynamic Function(Int32, Int64, Float, Double)>(
        "env", "someFn", (num a, num b, num c, num d) => 123));

  Expect.throwsArgumentError(() => WasmImports()
    ..addFunction<Int64 Function(Int32, Int64, dynamic, Double)>(
        "env", "someFn", (num a, num b, num c, num d) => 123));

  imp = WasmImports()..addGlobal<Int64>("env", "someFn", 123, false);
  Expect.throwsArgumentError(() => mod.instantiate(imp));
}
