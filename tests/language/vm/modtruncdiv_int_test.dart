// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

// Tests for long trunc div and mod under
// 64-bit arithmetic wrap-around semantics.

final int maxInt32 = 2147483647;
final int minInt32 = -2147483648;
final int maxInt64 = 0x7fffffffffffffff;
final int minInt64 = 0x8000000000000000;

int mod(int x, int y) {
  return x % y;
}

int truncdiv(int x, int y) {
  return x ~/ y;
}

doModConstants() {
  Expect.equals(0, mod(0, 1));
  Expect.equals(0, mod(0, -1));
  Expect.equals(1, mod(1, 2));
  Expect.equals(1, mod(-1, 2));
  Expect.equals(1, mod(1, -2));
  Expect.equals(1, mod(-1, -2));
  Expect.equals(2, mod(8, 3));
  Expect.equals(1, mod(-8, 3));
  Expect.equals(2, mod(8, -3));
  Expect.equals(1, mod(-8, -3));
  Expect.equals(0, mod(6, 3));
  Expect.equals(1, mod(7, 3));
  Expect.equals(2, mod(8, 3));
  Expect.equals(0, mod(9, 3));

  Expect.equals(1, mod(1, maxInt32));
  Expect.equals(1, mod(1, maxInt64));
  Expect.equals(1, mod(1, minInt32));
  Expect.equals(1, mod(1, minInt64));

  Expect.equals(maxInt32 - 1, mod(-1, maxInt32));
  Expect.equals(maxInt64 - 1, mod(-1, maxInt64));
  Expect.equals(maxInt32, mod(-1, minInt32));
  Expect.equals(maxInt64, mod(-1, minInt64));

  Expect.equals(0, mod(minInt32, -1));
  Expect.equals(0, mod(maxInt32, -1));
  Expect.equals(0, mod(minInt64, -1));
  Expect.equals(0, mod(maxInt64, -1));

  Expect.equals(0, mod(maxInt32, maxInt32));
  Expect.equals(maxInt32, mod(maxInt32, minInt32));
  Expect.equals(maxInt32, mod(maxInt32, maxInt64));
  Expect.equals(maxInt32, mod(maxInt32, minInt64));

  Expect.equals(maxInt32 - 1, mod(minInt32, maxInt32));
  Expect.equals(0, mod(minInt32, minInt32));
  Expect.equals(9223372034707292159, mod(minInt32, maxInt64));
  Expect.equals(9223372034707292160, mod(minInt32, minInt64));

  Expect.equals(1, mod(maxInt64, maxInt32));
  Expect.equals(0, mod(maxInt64 - 1, maxInt32));
  Expect.equals(maxInt32 - 1, mod(maxInt64 - 2, maxInt32));
  Expect.equals(maxInt32, mod(maxInt64, minInt32));
  Expect.equals(0, mod(maxInt64, maxInt64));
  Expect.equals(maxInt64, mod(maxInt64, minInt64));

  Expect.equals(maxInt32 - 2, mod(minInt64, maxInt32));
  Expect.equals(0, mod(minInt64, minInt32));
  Expect.equals(maxInt64 - 1, mod(minInt64, maxInt64));
  Expect.equals(0, mod(minInt64, minInt64));

  Expect.equals(maxInt32 - 1, mod(maxInt32 - 1, maxInt32));
  Expect.equals(1, mod(maxInt32 + 1, maxInt32));
  Expect.equals(maxInt32 - 2, mod(minInt32 - 1, maxInt32));
  Expect.equals(0, mod(minInt32 + 1, maxInt32));

  Expect.equals(15, mod(-1, 16));
  Expect.equals(15, mod(-17, 16));
  Expect.equals(15, mod(-1, -16));
  Expect.equals(15, mod(-17, -16));
  Expect.equals(100, mod(100, 1 << 32));
  Expect.equals(100, mod(100, -(1 << 32)));
  Expect.equals((1 << 32) - 1, mod((1 << 35) - 1, 1 << 32));
  Expect.equals((1 << 32) - 1, mod((1 << 35) - 1, -(1 << 32)));
  Expect.equals(maxInt64, mod(-1, 1 << 63));
  Expect.equals(0, mod(minInt64, 1 << 63));
}

doModVarConstant() {
  for (int i = -10; i < 10; i++) {
    Expect.equals(i & maxInt64, mod(i, minInt64));
  }
}

doTruncDivConstants() {
  Expect.equals(0, truncdiv(0, 1));
  Expect.equals(0, truncdiv(0, -1));
  Expect.equals(0, truncdiv(1, 2));
  Expect.equals(0, truncdiv(-1, 2));
  Expect.equals(0, truncdiv(1, -2));
  Expect.equals(0, truncdiv(-1, -2));
  Expect.equals(2, truncdiv(8, 3));
  Expect.equals(-2, truncdiv(-8, 3));
  Expect.equals(-2, truncdiv(8, -3));
  Expect.equals(2, truncdiv(-8, -3));
  Expect.equals(2, truncdiv(6, 3));
  Expect.equals(2, truncdiv(7, 3));
  Expect.equals(2, truncdiv(8, 3));
  Expect.equals(3, truncdiv(9, 3));

  Expect.equals(0, truncdiv(1, maxInt32));
  Expect.equals(0, truncdiv(1, maxInt64));
  Expect.equals(0, truncdiv(1, minInt32));
  Expect.equals(0, truncdiv(1, minInt64));

  Expect.equals(0, truncdiv(-1, maxInt32));
  Expect.equals(0, truncdiv(-1, maxInt64));
  Expect.equals(0, truncdiv(-1, minInt32));
  Expect.equals(0, truncdiv(-1, minInt64));

  Expect.equals(-minInt32, truncdiv(minInt32, -1));
  Expect.equals(-maxInt32, truncdiv(maxInt32, -1));
  Expect.equals(minInt64, truncdiv(minInt64, -1));
  Expect.equals(-maxInt64, truncdiv(maxInt64, -1));

  Expect.equals(1, truncdiv(maxInt32, maxInt32));
  Expect.equals(0, truncdiv(maxInt32, minInt32));
  Expect.equals(0, truncdiv(maxInt32, maxInt64));
  Expect.equals(0, truncdiv(maxInt32, minInt64));

  Expect.equals(-1, truncdiv(minInt32, maxInt32));
  Expect.equals(1, truncdiv(minInt32, minInt32));
  Expect.equals(0, truncdiv(minInt32, maxInt64));
  Expect.equals(0, truncdiv(minInt32, minInt64));

  Expect.equals(4294967298, truncdiv(maxInt64, maxInt32));
  Expect.equals(4294967298, truncdiv(maxInt64 - 1, maxInt32));
  Expect.equals(4294967297, truncdiv(maxInt64 - 2, maxInt32));
  Expect.equals(-4294967295, truncdiv(maxInt64, minInt32));
  Expect.equals(1, truncdiv(maxInt64, maxInt64));
  Expect.equals(0, truncdiv(maxInt64, minInt64));

  Expect.equals(-4294967298, truncdiv(minInt64, maxInt32));
  Expect.equals(4294967296, truncdiv(minInt64, minInt32));
  Expect.equals(-1, truncdiv(minInt64, maxInt64));
  Expect.equals(1, truncdiv(minInt64, minInt64));

  Expect.equals(0, truncdiv(maxInt32 - 1, maxInt32));
  Expect.equals(1, truncdiv(maxInt32 + 1, maxInt32));
  Expect.equals(-1, truncdiv(minInt32 - 1, maxInt32));
  Expect.equals(-1, truncdiv(minInt32 + 1, maxInt32));
}

int acc = -1;

doModVars(int xlo, int xhi, int ylo, int yhi) {
  for (int x = xlo; x <= xhi; x++) {
    for (int y = ylo; y <= yhi; y++) {
      acc += mod(x, y);
    }
  }
}

doTruncDivVars(int xlo, int xhi, int ylo, int yhi) {
  for (int x = xlo; x <= xhi; x++) {
    for (int y = ylo; y <= yhi; y++) {
      acc += truncdiv(x, y);
    }
  }
}

main() {
  // Repeat to enter JIT (when applicable).
  for (int i = 0; i < 20; i++) {
    // Constants.

    doModConstants();
    doModVarConstant();
    doTruncDivConstants();

    // Variable ranges.

    acc = 0;
    doModVars(3, 5, 2, 6);
    Expect.equals(28, acc);

    acc = 0;
    doModVars((3 << 32) - 1, (3 << 32) + 1, (3 << 32) - 1, (3 << 32) + 1);
    Expect.equals(38654705666, acc);

    acc = 0;
    doModVars(minInt32 - 4, minInt32 + 4, -11, -1);
    Expect.equals(239, acc);

    acc = 0;
    doModVars(minInt32 - 4, minInt32 + 4, 2, 7);
    Expect.equals(85, acc);

    acc = 0;
    doModVars(minInt32 - 4, minInt32 + 4, minInt32 - 4, minInt32 + 4);
    Expect.equals(77309411268, acc);

    acc = 0;
    doModVars(minInt32 - 4, minInt32 + 4, maxInt32 - 4, maxInt32 + 4);
    Expect.equals(96636763974, acc);

    acc = 0;
    doModVars(maxInt32 - 4, maxInt32 + 4, 2, 7);
    Expect.equals(104, acc);

    acc = 0;
    doModVars(maxInt32 - 4, maxInt32 + 4, minInt32 - 4, minInt32 + 4);
    Expect.equals(96636764139, acc);

    acc = 0;
    doModVars(maxInt32 - 4, maxInt32 + 4, maxInt32 - 4, maxInt32 + 4);
    Expect.equals(77309411352, acc);

    acc = 0;
    doTruncDivVars(3, 5, 2, 6);
    Expect.equals(11, acc);

    acc = 0;
    doTruncDivVars(-5, -3, 2, 6);
    Expect.equals(-11, acc);

    acc = 0;
    doTruncDivVars(3, 5, -6, -2);
    Expect.equals(-11, acc);

    acc = 0;
    doTruncDivVars(-5, -3, -6, -2);
    Expect.equals(11, acc);

    acc = 0;
    doTruncDivVars((3 << 32) - 1, (3 << 32) + 1, 3, 6);
    Expect.equals(36721970376, acc);

    acc = 0;
    doTruncDivVars(minInt64, minInt64, -1, -1);
    Expect.equals(minInt64, acc);

    acc = 0;
    doTruncDivVars(minInt32 - 4, minInt32 + 4, -11, -1);
    Expect.equals(58366234918, acc);

    acc = 0;
    doTruncDivVars(minInt32 - 4, minInt32 + 4, 2, 7);
    Expect.equals(-30785711991, acc);

    acc = 0;
    doTruncDivVars(minInt32 - 4, minInt32 + 4, minInt32 - 4, minInt32 + 4);
    Expect.equals(45, acc);

    acc = 0;
    doTruncDivVars(minInt32 - 4, minInt32 + 4, maxInt32 - 4, maxInt32 + 4);
    Expect.equals(-53, acc);

    acc = 0;
    doTruncDivVars(maxInt32 - 4, maxInt32 + 4, 2, 7);
    Expect.equals(30785711975, acc);

    acc = 0;
    doTruncDivVars(maxInt32 - 4, maxInt32 + 4, minInt32 - 4, minInt32 + 4);
    Expect.equals(-36, acc);

    acc = 0;
    doTruncDivVars(maxInt32 - 4, maxInt32 + 4, maxInt32 - 4, maxInt32 + 4);
    Expect.equals(45, acc);

    acc = 0;
    doTruncDivVars(maxInt32 - 4, maxInt32 + 4, 1, 7);
    Expect.equals(50113064798, acc);

    // Exceptions at the right time.

    acc = 0;
    try {
      doModVars(9, 9, -9, 0);
      acc = 0; // don't reach!
    } on IntegerDivisionByZeroException catch (e, s) {}
    Expect.equals(12, acc);

    acc = 0;
    try {
      doTruncDivVars(9, 9, -9, 0);
      acc = 0; // don't reach!
    } on IntegerDivisionByZeroException catch (e, s) {}
    Expect.equals(-23, acc);
  }
}
