// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we can create a WasmMemory, edit it, and grow it.

import "package:test/test.dart";
import "package:wasm/wasm.dart";
import "dart:typed_data";

void main() {
  test("memory", () {
    // Empty wasm module.
    var data = Uint8List.fromList([
      0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x06, 0x81, 0x00, 0x00,
    ]);
    var module = WasmModule(data);

    var mem = module.createMemory(100);
    expect(mem.lengthInPages, 100);
    expect(mem.lengthInBytes, 100 * WasmMemory.kPageSizeInBytes);

    mem[123] = 45;
    expect(mem[123], 45);

    mem.grow(10);
    expect(mem.lengthInPages, 110);
    expect(mem.lengthInBytes, 110 * WasmMemory.kPageSizeInBytes);
    expect(mem[123], 45);
  });
}
