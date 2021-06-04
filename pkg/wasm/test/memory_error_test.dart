// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test errors thrown by WasmMemory.
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wasm/wasm.dart';

import 'test_shared.dart';

void main() {
  test('memory errors', () {
    // Empty wasm module.
    var data = Uint8List.fromList([
      0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00, 0x06, 0x81, 0x00, 0x00, //
    ]);
    var module = WasmModule(data);

    expect(
      () => module.createMemory(1000000000),
      throwsWasmError(startsWith('Failed to create memory.')),
    );
    var mem = module.createMemory(100);
    expect(
      () => mem.grow(1000000000),
      throwsWasmError('Failed to grow memory.'),
    );
    mem = module.createMemory(100, 200);
    expect(
      () => mem.grow(300),
      throwsWasmError('Failed to grow memory.'),
    );
  });
}
