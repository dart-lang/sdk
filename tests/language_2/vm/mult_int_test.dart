// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

// Tests for long multiplication under
// 64-bit arithmetic wrap-around semantics.

final int maxInt32 = 2147483647;
final int minInt32 = -2147483648;
final int maxInt64 = 0x7fffffffffffffff;
final int minInt64 = 0x8000000000000000;

int mul(int x, int y) {
  return x * y;
}

doConstants() {
  Expect.equals(0, mul(0, 0));
  Expect.equals(0, mul(0, 7));
  Expect.equals(0, mul(7, 0));
  Expect.equals(1, mul(1, 1));
  Expect.equals(7, mul(1, 7));
  Expect.equals(7, mul(7, 1));
  Expect.equals(21, mul(7, 3));
  Expect.equals(21, mul(3, 7));

  Expect.equals(21 << 32, mul(3 << 32, 7));
  Expect.equals(21 << 32, mul(3, 7 << 32));
  Expect.equals(0, mul(3 << 32, 7 << 32));

  Expect.equals(0, mul(0, maxInt32));
  Expect.equals(0, mul(maxInt32, 0));
  Expect.equals(maxInt32, mul(1, maxInt32));
  Expect.equals(maxInt32, mul(maxInt32, 1));
  Expect.equals(maxInt32 + maxInt32, mul(2, maxInt32));

  Expect.equals(0, mul(0, maxInt64));
  Expect.equals(0, mul(maxInt64, 0));
  Expect.equals(maxInt64, mul(1, maxInt64));
  Expect.equals(maxInt64, mul(maxInt64, 1));
  Expect.equals(-2, mul(2, maxInt64));

  Expect.equals(0, mul(0, minInt32));
  Expect.equals(0, mul(minInt32, 0));
  Expect.equals(minInt32, mul(1, minInt32));
  Expect.equals(minInt32, mul(minInt32, 1));
  Expect.equals(minInt32 + minInt32, mul(2, minInt32));

  Expect.equals(0, mul(0, minInt64));
  Expect.equals(0, mul(minInt64, 0));
  Expect.equals(minInt64, mul(1, minInt64));
  Expect.equals(minInt64, mul(minInt64, 1));
  Expect.equals(0, mul(2, minInt64));

  Expect.equals(4611686014132420609, mul(maxInt32, maxInt32));
  Expect.equals(-4611686016279904256, mul(maxInt32, minInt32));
  Expect.equals(9223372034707292161, mul(maxInt32, maxInt64));
  Expect.equals(minInt64, mul(maxInt32, minInt64));

  Expect.equals(-4611686016279904256, mul(minInt32, maxInt32));
  Expect.equals(4611686018427387904, mul(minInt32, minInt32));
  Expect.equals(2147483648, mul(minInt32, maxInt64));
  Expect.equals(0, mul(minInt32, minInt64));

  Expect.equals(9223372034707292161, mul(maxInt64, maxInt32));
  Expect.equals(2147483648, mul(maxInt64, minInt32));
  Expect.equals(1, mul(maxInt64, maxInt64));
  Expect.equals(minInt64, mul(maxInt64, minInt64));

  Expect.equals(minInt64, mul(minInt64, maxInt32));
  Expect.equals(0, mul(minInt64, minInt32));
  Expect.equals(minInt64, mul(minInt64, maxInt64));
  Expect.equals(0, mul(minInt64, minInt64));
}

doVars(int v) {
  int e = v;
  for (int i = 1; i < 256; i++) {
    Expect.equals(e, mul(i, v));
    Expect.equals(e, mul(v, i));
    e += v;
  }
}

main() {
  // Repeat tests to enter JIT (when applicable).
  for (int i = 0; i < 20; i++) {
    doConstants();
    doVars(1);
    doVars(maxInt32);
    doVars(minInt32);
    doVars(7 << 32);
    doVars(-(7 << 32));
    doVars(maxInt64);
    doVars(minInt64);
  }
}
