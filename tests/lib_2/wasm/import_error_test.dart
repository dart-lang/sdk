// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test errors thrown by WasmImports.

import "package:expect/expect.dart";
import "dart:wasm";
import "dart:typed_data";

void main() {
  var imp = WasmImports("env");
  Expect.throwsArgumentError(() => imp.addGlobal<int>("a", 1, true));
  Expect.throwsArgumentError(() => imp.addGlobal<double>("b", 2, true));
  Expect.throwsArgumentError(() => imp.addGlobal<dynamic>("c", 3, true));
}
