// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test error thrown when the loaded function can't be found.

import "package:expect/expect.dart";
import "dart:wasm";
import "dart:typed_data";

void main() {
  // int64_t square(int64_t n) { return n * n; }
  var data = Uint8List.fromList([
    0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x01, 0x06, 0x01, 0x60,
    0x01, 0x7e, 0x01, 0x7e, 0x03, 0x02, 0x01, 0x00, 0x04, 0x05, 0x01, 0x70,
    0x01, 0x01, 0x01, 0x05, 0x03, 0x01, 0x00, 0x02, 0x06, 0x08, 0x01, 0x7f,
    0x01, 0x41, 0x80, 0x88, 0x04, 0x0b, 0x07, 0x13, 0x02, 0x06, 0x6d, 0x65,
    0x6d, 0x6f, 0x72, 0x79, 0x02, 0x00, 0x06, 0x73, 0x71, 0x75, 0x61, 0x72,
    0x65, 0x00, 0x00, 0x0a, 0x09, 0x01, 0x07, 0x00, 0x20, 0x00, 0x20, 0x00,
    0x7e, 0x0b,
  ]);

  var inst = WasmModule(data).instantiate(WasmImports());
  Expect.isNotNull(inst.lookupFunction<Int64 Function(Int64)>("square"));
  Expect.throwsArgumentError(
      () => inst.lookupFunction<Int64 Function(Int64)>("blah"));
  Expect.throwsArgumentError(
      () => inst.lookupFunction<Int64 Function()>("square"));
  Expect.throwsArgumentError(
      () => inst.lookupFunction<Int64 Function(Int64, Int64)>("square"));
  Expect.throwsArgumentError(
      () => inst.lookupFunction<Void Function(Int64)>("square"));
  Expect.throwsArgumentError(
      () => inst.lookupFunction<Void Function(dynamic)>("square"));
  Expect.throwsArgumentError(
      () => inst.lookupFunction<Int64 Function(Float)>("square"));
  Expect.throwsArgumentError(
      () => inst.lookupFunction<Float Function(Int64)>("square"));
}
