// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we can create a WasmMemory, edit it, and grow it.

import "package:expect/expect.dart";
import "dart:wasm";
import "dart:typed_data";

void main() {
  var mem = WasmMemory(1000);
  Expect.equals(1000, mem.lengthInPages);
  Expect.equals(1000 * WasmMemory.kPageSizeInBytes, mem.lengthInBytes);

  mem[123] = 45;
  Expect.equals(45, mem[123]);

  mem.grow(100);
  Expect.equals(1100, mem.lengthInPages);
  Expect.equals(1100 * WasmMemory.kPageSizeInBytes, mem.lengthInBytes);
  Expect.equals(45, mem[123]);

  Expect.throwsArgumentError(() => WasmMemory(1000000000));
  Expect.throwsArgumentError(() => mem.grow(1000000000));
}
