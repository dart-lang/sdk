// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test errors thrown by WasmMemory.

import "package:expect/expect.dart";
import "package:wasm/wasm.dart";
import "dart:typed_data";

void main() {
  // Empty wasm module.
  var data = Uint8List.fromList(
      [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x06, 0x81, 0x00, 0x00]);
  var module = WasmModule(data);

  Expect.throws(() => module.createMemory(1000000000));
  var mem = module.createMemory(100);
  Expect.throws(() => mem.grow(1000000000));
  mem = module.createMemory(100, 200);
  Expect.throws(() => mem.grow(300));
}
