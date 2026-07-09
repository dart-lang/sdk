// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test correctness of side effects tracking used by load to load forwarding.
// In this cutdown version of the load_to_load_forwarding_vm test, the function
// being compiled ends up in a single basic block, which tests load
// elimination when generating the initial sets.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";
import "dart:typed_data";

testViewAliasing1() {
  final f64 = new Float64List(1);
  final f32 = new Float32List.view(f64.buffer);
  f64[0] = 1.0; // Should not be forwarded.
  f32[1] = 2.0; // upper 32bits for 2.0f and 2.0 are the same
  return f64[0];
}

main() {
  for (var i = 0; i < 20; i++) {
    Expect.equals(2.0, testViewAliasing1());
  }
}
