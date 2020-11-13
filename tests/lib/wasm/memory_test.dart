// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we can create a WasmMemory, edit it, and grow it.

import "package:expect/expect.dart";
import "package:wasm/wasm.dart";
import "dart:typed_data";

void main() {
  // Empty wasm module.
  var data = Uint8List.fromList(
      [0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x06, 0x81, 0x00, 0x00]);
  var module = WasmModule(data);

  var mem = module.createMemory(100);
  Expect.equals(100, mem.lengthInPages);
  Expect.equals(100 * WasmMemory.kPageSizeInBytes, mem.lengthInBytes);

  mem[123] = 45;
  Expect.equals(45, mem[123]);

  mem.grow(10);
  Expect.equals(110, mem.lengthInPages);
  Expect.equals(110 * WasmMemory.kPageSizeInBytes, mem.lengthInBytes);
  Expect.equals(45, mem[123]);
}
