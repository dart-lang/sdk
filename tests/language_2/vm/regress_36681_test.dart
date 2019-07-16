// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Enforce proper S-overlapping register for temp (dartbug.com/36681).
//
// VMOptions=--deterministic --optimization_counter_threshold=5

import "package:expect/expect.dart";

double v = 0;

@pragma('vm:never-inline')
int foo(int a, int p, int q) {
  double p1 = 0;
  double p2 = 0;
  double p3 = 0;
  double p4 = 0;
  double p5 = 0;
  double p6 = 0;
  double p7 = 0;
  double p8 = 0;
  for (int z = 0; z < 8; z++) {
    a += (p ~/ q);
    a += (p % q);
    p += 3;
    q += 2;
    p1 += 1;
    p2 += 2;
    p3 += 3;
    p4 += 4;
    p5 += 1;
    p6 += 2;
    p7 += 3;
    p8 += 4;
  }
  v = p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8;
  return a;
}

main() {
  for (int j = 0; j < 10; j++) {
    int i = foo(1, 1, 1);
    Expect.equals(37, i);
    Expect.equals(160, v);
  }
}
