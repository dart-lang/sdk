// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test deoptimization on an optimistically hoisted smi check.
// VMOptions=--optimization-counter-threshold=10  --no-background-compilation

import 'package:expect/expect.dart';

sum(a, b) {
  var sum = 0;
  for (var j = 1; j < 10; j++) {
    for (var i = a; i < b; i++) {
      sum++;
    }
  }
  return sum;
}

mask(x) {
  for (var i = 0; i < 10; i++) {
    if (i == 1) {
      return x;
    }
    x = x & 0xFF;
  }
}

main() {
  for (var i = 0; i < 20; i++) {
    Expect.equals(9, sum(1, 2));
    Expect.equals(0xAB, mask(0xAB));
  }
  Expect.equals(9, sum(1.0, 2.0)); // Passing double causes deoptimization.
  Expect.equals(0xAB, mask(0x1000000AB));
}
