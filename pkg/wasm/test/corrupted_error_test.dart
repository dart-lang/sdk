// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test error thrown when the wasm module is corrupted.
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wasm/wasm.dart';

import 'test_shared.dart';

void main() {
  test('corrupted module', () {
    var data = Uint8List.fromList([
      0x01, 0x00, 0x00, 0x00, 0x01, 0x06, 0x01, 0x60, 0x01, 0x7e, 0x01, 0x7e, //
      0x07, 0x13, 0x02, 0x06, 0x6d, 0x65, 0x6d, 0x6f, 0x72, 0x79, 0x02, 0x00,
      0x06, 0x73, 0x71, 0x75, 0x61, 0x72, 0x65, 0x00, 0x00, 0x00, 0x20, 0x00,
      0x7e, 0x0b,
    ]);

    expect(
      () => WasmModule(data),
      throwsWasmError(
        allOf(
          contains('Wasm module compile failed.'),
          contains('Validation error: Bad magic number (at offset 0)'),
        ),
      ),
    );
  });
}
