// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart deoptimization of Uint32Array and Int32Array loads.

import 'dart:typed_data';
import "package:expect/expect.dart";

loadI32(a) => a[0] + 1;
loadUi32(a) => a[0] + 1;

main() {
  var i32 = new Int32List(10);
  var ui32 = new Uint32List(10);
  i32[0] = ui32[0] = 8;
  // Optimize loadI32 and LoadUi32 for Smi result of indexed load.
  for (int i = 0; i < 2000; i++) {
    Expect.equals(9, loadI32(i32));
    Expect.equals(9, loadUi32(ui32));
  }
  // On ia32, deoptimize when attempting to load a value that exceeds
  // Smi range.
  i32[0] = ui32[0] = 2147483647;
  Expect.equals(2147483648, loadI32(i32));
  Expect.equals(2147483648, loadUi32(ui32));
  // Reoptimize again, but this time assume mixed Smi/Mint results
  i32[0] = ui32[0] = 10;
  for (int i = 0; i < 2000; i++) {
    Expect.equals(11, loadI32(i32));
    Expect.equals(11, loadUi32(ui32));
  }
}
