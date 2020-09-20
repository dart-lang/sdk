// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

// Tests for long negations under
// 64-bit arithmetic wrap-around semantics.

final int maxInt32 = 2147483647;
final int minInt32 = -2147483648;
final int maxInt64 = 0x7fffffffffffffff;
final int minInt64 = 0x8000000000000000;

int negate(int x) {
  return -x;
}

doConstant() {
  Expect.equals(1, negate(-1));
  Expect.equals(0, negate(0));
  Expect.equals(-1, negate(1));

  Expect.equals(-maxInt32, negate(maxInt32));
  Expect.equals(-minInt32, negate(minInt32));
  Expect.equals(-maxInt64, negate(maxInt64));
  Expect.equals(minInt64, negate(minInt64)); // sic!
}

doVar() {
  int d = 0;
  for (int i = -88; i < 10; i++) {
    d += negate(i);
  }
  Expect.equals(3871, d);
}

main() {
  // Repeat tests to enter JIT (when applicable).
  for (int i = 0; i < 20; i++) {
    doConstant();
    doVar();
  }
}
