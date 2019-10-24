// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test errors thrown by WasmMemory.

import "package:expect/expect.dart";
import "dart:wasm";
import "dart:typed_data";

void main() {
  Expect.throwsArgumentError(() => WasmMemory(1000000000));
  var mem = WasmMemory(1000);
  Expect.throwsArgumentError(() => mem.grow(1000000000));
}
