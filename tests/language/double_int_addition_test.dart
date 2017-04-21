// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Test that optimized code does not silently convert integers to doubles.

main() {
  // Optimize add-op
  for (int i = 0; i < 20; i++) {
    addOp(1.1, 2.1);
  }

  Expect.isTrue(addOp(1.1, 2.1) is double);
  Expect.isTrue(addOp(1, 2) is int);
}

addOp(a, b) => a + b;
