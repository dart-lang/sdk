// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correctness of side effects tracking used by load to load forwarding.
// Should be merged into load_to_load_forwarding once Issue 22151 is fixed.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";
import "dart:typed_data";

testViewAliasing5() {
  final f32 = new Float32List(2);
  final raw = f32.buffer.asByteData();
  f32[0] = 1.5; // Aliased by unaligned write of the same size.
  raw.setInt32(1, 0x00400000, Endian.little);
  return f32[0];
}

main() {
  for (var i = 0; i < 20; i++) {
    Expect.equals(2.0, testViewAliasing5());
  }
}
