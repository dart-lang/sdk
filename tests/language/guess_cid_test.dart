// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test cid guessing optimizations.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

main() {
  // Warmup optimizes methods.
  for (int i = 0; i < 100; i++) {
    Expect.equals(i, compareInt(i));
    Expect.equals(i.toDouble(), compareDouble(i.toDouble()));
    Expect.equals(i, binOpInt(i, i));
    Expect.equals(i.toDouble(), binOpDouble(i.toDouble(), i.toDouble()));
  }
  Expect.equals(3, compareInt(3));
  Expect.equals(-2, compareInt(-2));
  Expect.equals(0, compareInt(-1));

  Expect.equals(3, binOpInt(3, 3));
  Expect.equals(0, binOpInt(-2, -2));

  Expect.equals(3.0, binOpDouble(3.0, 3.0));
  Expect.equals(0.0, binOpDouble(-2.0, -2.0));

  Expect.equals(3.0, compareDouble(3.0));
  Expect.equals(-2.0, compareDouble(-2.0));
  Expect.equals(0.0, compareDouble(-1.0));

  testOSR();
}

int compareInt(int i) {
  if (i < 0) {
    // Not visited in before optimization.
    // Guess cid of comparison below.
    if (i == -1) return 0;
  }
  return i;
}

double compareDouble(double i) {
  if (i < 0.0) {
    // Not visited in before optimization.
    // Guess cid of comparison below.
    if (i == -1.0) return 0.0;
  }
  return i;
}

int binOpInt(int i, int x) {
  if (i < 0) {
    // Not visited in before optimization.
    // Guess cid of binary operation below.
    return x + 2;
  }
  return i;
}

double binOpDouble(double i, double x) {
  if (i < 0.0) {
    // Not visited in before optimization.
    // Guess cid of binary operation below.
    return x + 2.0;
  }
  return i;
}

testOSR() {
  // Foul up  IC data in integer's unary minus.
  var y = -0x80000000;
  Expect.equals(1475739525896764129300, testLoop(10, 0x80000000000000000));
  // Second time no deoptimization can occur, since runtime feedback has been collected.
  Expect.equals(1475739525896764129300, testLoop(10, 0x80000000000000000));
}

testLoop(N, x) {
  for (int i = 0; i < N; ++i) {
    // Will trigger OSR. Operation in loop below will use guessed cids.
  }
  int sum = 0;
  for (int i = 0; i < N; ++i) {
    // Guess 'x' is Smi, but is actually Bigint: deoptimize.
    sum += x + 2;
  }
  return sum;
}
