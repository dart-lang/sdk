// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing Math.min and Math.max.

// VMOptions=--optimization-counter-threshold=50 --no-background-compilation

import "package:expect/expect.dart";
import "dart:math" as math;

var inf = double.infinity;
var nan = double.nan;

@pragma("vm:never-inline")
int smi_min(int a, int b) => math.min(a, b);

@pragma("vm:never-inline")
int smi_max(int a, int b) => math.max(a, b);

@pragma("vm:never-inline")
int mint_min(int a, int b) => math.min(a, b);

@pragma("vm:never-inline")
int mint_max(int a, int b) => math.max(a, b);

@pragma("vm:never-inline")
double double_min(double a, double b) => math.min(a, b);

@pragma("vm:never-inline")
double double_max(double a, double b) => math.max(a, b);

testSmiMin() {
  Expect.equals(-2, smi_min(-2, -2));
  Expect.equals(-2, smi_min(-1, -2));
  Expect.equals(-2, smi_min(0, -2));
  Expect.equals(-2, smi_min(1, -2));
  Expect.equals(-2, smi_min(2, -2));

  Expect.equals(-2, smi_min(-2, -1));
  Expect.equals(-1, smi_min(-1, -1));
  Expect.equals(-1, smi_min(0, -1));
  Expect.equals(-1, smi_min(1, -1));
  Expect.equals(-1, smi_min(2, -1));

  Expect.equals(-2, smi_min(-2, 0));
  Expect.equals(-1, smi_min(-1, 0));
  Expect.equals(0, smi_min(0, 0));
  Expect.equals(0, smi_min(1, 0));
  Expect.equals(0, smi_min(2, 0));

  Expect.equals(-2, smi_min(-2, 1));
  Expect.equals(-1, smi_min(-1, 1));
  Expect.equals(0, smi_min(0, 1));
  Expect.equals(1, smi_min(1, 1));
  Expect.equals(1, smi_min(2, 1));

  Expect.equals(-2, smi_min(-2, 2));
  Expect.equals(-1, smi_min(-1, 2));
  Expect.equals(0, smi_min(0, 2));
  Expect.equals(1, smi_min(1, 2));
  Expect.equals(2, smi_min(2, 2));
}

testSmiMax() {
  Expect.equals(-2, smi_max(-2, -2));
  Expect.equals(-1, smi_max(-1, -2));
  Expect.equals(0, smi_max(0, -2));
  Expect.equals(1, smi_max(1, -2));
  Expect.equals(2, smi_max(2, -2));

  Expect.equals(-1, smi_max(-2, -1));
  Expect.equals(-1, smi_max(-1, -1));
  Expect.equals(0, smi_max(0, -1));
  Expect.equals(1, smi_max(1, -1));
  Expect.equals(2, smi_max(2, -1));

  Expect.equals(0, smi_max(-2, 0));
  Expect.equals(0, smi_max(-1, 0));
  Expect.equals(0, smi_max(0, 0));
  Expect.equals(1, smi_max(1, 0));
  Expect.equals(2, smi_max(2, 0));

  Expect.equals(1, smi_max(-2, 1));
  Expect.equals(1, smi_max(-1, 1));
  Expect.equals(1, smi_max(0, 1));
  Expect.equals(1, smi_max(1, 1));
  Expect.equals(2, smi_max(2, 1));

  Expect.equals(2, smi_max(-2, 2));
  Expect.equals(2, smi_max(-1, 2));
  Expect.equals(2, smi_max(0, 2));
  Expect.equals(2, smi_max(1, 2));
  Expect.equals(2, smi_max(2, 2));
}

testMintMin() {
  Expect.equals(
    0x8000000000000000,
    mint_min(0x8000000000000000, 0x8000000000000000),
  );
  Expect.equals(0x8000000000000000, mint_min(-1, 0x8000000000000000));
  Expect.equals(0x8000000000000000, mint_min(0, 0x8000000000000000));
  Expect.equals(0x8000000000000000, mint_min(1, 0x8000000000000000));
  Expect.equals(
    0x8000000000000000,
    mint_min(0x7FFFFFFFFFFFFFFF, 0x8000000000000000),
  );

  Expect.equals(0x8000000000000000, mint_min(0x8000000000000000, -1));
  Expect.equals(-1, mint_min(-1, -1));
  Expect.equals(-1, mint_min(0, -1));
  Expect.equals(-1, mint_min(1, -1));
  Expect.equals(-1, mint_min(0x7FFFFFFFFFFFFFFF, -1));

  Expect.equals(0x8000000000000000, mint_min(0x8000000000000000, 0));
  Expect.equals(-1, mint_min(-1, 0));
  Expect.equals(0, mint_min(0, 0));
  Expect.equals(0, mint_min(1, 0));
  Expect.equals(0, mint_min(0x7FFFFFFFFFFFFFFF, 0));

  Expect.equals(0x8000000000000000, mint_min(0x8000000000000000, 1));
  Expect.equals(-1, mint_min(-1, 1));
  Expect.equals(0, mint_min(0, 1));
  Expect.equals(1, mint_min(1, 1));
  Expect.equals(1, mint_min(0x7FFFFFFFFFFFFFFF, 1));

  Expect.equals(
    0x8000000000000000,
    mint_min(0x8000000000000000, 0x7FFFFFFFFFFFFFFF),
  );
  Expect.equals(-1, mint_min(-1, 0x7FFFFFFFFFFFFFFF));
  Expect.equals(0, mint_min(0, 0x7FFFFFFFFFFFFFFF));
  Expect.equals(1, mint_min(1, 0x7FFFFFFFFFFFFFFF));
  Expect.equals(
    0x7FFFFFFFFFFFFFFF,
    mint_min(0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF),
  );
}

testMintMax() {
  Expect.equals(
    0x8000000000000000,
    mint_max(0x8000000000000000, 0x8000000000000000),
  );
  Expect.equals(-1, mint_max(-1, 0x8000000000000000));
  Expect.equals(0, mint_max(0, 0x8000000000000000));
  Expect.equals(1, mint_max(1, 0x8000000000000000));
  Expect.equals(
    0x7FFFFFFFFFFFFFFF,
    mint_max(0x7FFFFFFFFFFFFFFF, 0x8000000000000000),
  );

  Expect.equals(-1, mint_max(0x8000000000000000, -1));
  Expect.equals(-1, mint_max(-1, -1));
  Expect.equals(0, mint_max(0, -1));
  Expect.equals(1, mint_max(1, -1));
  Expect.equals(0x7FFFFFFFFFFFFFFF, mint_max(0x7FFFFFFFFFFFFFFF, -1));

  Expect.equals(0, mint_max(0x8000000000000000, 0));
  Expect.equals(0, mint_max(-1, 0));
  Expect.equals(0, mint_max(0, 0));
  Expect.equals(1, mint_max(1, 0));
  Expect.equals(0x7FFFFFFFFFFFFFFF, mint_max(0x7FFFFFFFFFFFFFFF, 0));

  Expect.equals(1, mint_max(0x8000000000000000, 1));
  Expect.equals(1, mint_max(-1, 1));
  Expect.equals(1, mint_max(0, 1));
  Expect.equals(1, mint_max(1, 1));
  Expect.equals(0x7FFFFFFFFFFFFFFF, mint_max(0x7FFFFFFFFFFFFFFF, 1));

  Expect.equals(
    0x7FFFFFFFFFFFFFFF,
    mint_max(0x8000000000000000, 0x7FFFFFFFFFFFFFFF),
  );
  Expect.equals(0x7FFFFFFFFFFFFFFF, mint_max(-1, 0x7FFFFFFFFFFFFFFF));
  Expect.equals(0x7FFFFFFFFFFFFFFF, mint_max(0, 0x7FFFFFFFFFFFFFFF));
  Expect.equals(0x7FFFFFFFFFFFFFFF, mint_max(1, 0x7FFFFFFFFFFFFFFF));
  Expect.equals(
    0x7FFFFFFFFFFFFFFF,
    mint_max(0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF),
  );
}

testDoubleMin() {
  Expect.equals(-inf, double_min(-inf, -inf));
  Expect.equals(-inf, double_min(-1.0, -inf));
  Expect.equals(-inf, double_min(0.0, -inf));
  Expect.equals(-inf, double_min(1.0, -inf));
  Expect.equals(-inf, double_min(inf, -inf));

  Expect.equals(-inf, double_min(-inf, -1.0));
  Expect.equals(-1.0, double_min(-1.0, -1.0));
  Expect.equals(-1.0, double_min(0.0, -1.0));
  Expect.equals(-1.0, double_min(1.0, -1.0));
  Expect.equals(-1.0, double_min(inf, -1.0));

  Expect.equals(-inf, double_min(-inf, 0.0));
  Expect.equals(-1.0, double_min(-1.0, 0.0));
  Expect.equals(0.0, double_min(0.0, 0.0));
  Expect.equals(0.0, double_min(1.0, 0.0));
  Expect.equals(0.0, double_min(inf, 0.0));

  Expect.equals(-inf, double_min(-inf, 1.0));
  Expect.equals(-1.0, double_min(-1.0, 1.0));
  Expect.equals(0.0, double_min(0.0, 1.0));
  Expect.equals(1.0, double_min(1.0, 1.0));
  Expect.equals(1.0, double_min(inf, 1.0));

  Expect.equals(-inf, double_min(-inf, inf));
  Expect.equals(-1.0, double_min(-1.0, inf));
  Expect.equals(0.0, double_min(0.0, inf));
  Expect.equals(1.0, double_min(1.0, inf));
  Expect.equals(inf, double_min(inf, inf));

  Expect.identical(-0.0, double_min(0.0, -0.0));
  Expect.identical(-0.0, double_min(-0.0, 0.0));

  Expect.isTrue(double_min(nan, nan).isNaN);
  Expect.isTrue(double_min(nan, -inf).isNaN);
  Expect.isTrue(double_min(nan, 1.0).isNaN);
  Expect.isTrue(double_min(nan, inf).isNaN);
  Expect.isTrue(double_min(nan, nan).isNaN);
  Expect.isTrue(double_min(-inf, nan).isNaN);
  Expect.isTrue(double_min(1.0, nan).isNaN);
  Expect.isTrue(double_min(inf, nan).isNaN);
}

testDoubleMax() {
  Expect.equals(-inf, double_max(-inf, -inf));
  Expect.equals(-1.0, double_max(-1.0, -inf));
  Expect.equals(0.0, double_max(0.0, -inf));
  Expect.equals(1.0, double_max(1.0, -inf));
  Expect.equals(inf, double_max(inf, -inf));

  Expect.equals(-1.0, double_max(-inf, -1.0));
  Expect.equals(-1.0, double_max(-1.0, -1.0));
  Expect.equals(0.0, double_max(0.0, -1.0));
  Expect.equals(1.0, double_max(1.0, -1.0));
  Expect.equals(inf, double_max(inf, -1.0));

  Expect.equals(0.0, double_max(-inf, 0.0));
  Expect.equals(0.0, double_max(-1.0, 0.0));
  Expect.equals(0.0, double_max(0.0, 0.0));
  Expect.equals(1.0, double_max(1.0, 0.0));
  Expect.equals(inf, double_max(inf, 0.0));

  Expect.equals(1.0, double_max(-inf, 1.0));
  Expect.equals(1.0, double_max(-1.0, 1.0));
  Expect.equals(1.0, double_max(0.0, 1.0));
  Expect.equals(1.0, double_max(1.0, 1.0));
  Expect.equals(inf, double_max(inf, 1.0));

  Expect.equals(inf, double_max(-inf, inf));
  Expect.equals(inf, double_max(-1.0, inf));
  Expect.equals(inf, double_max(0.0, inf));
  Expect.equals(inf, double_max(1.0, inf));
  Expect.equals(inf, double_max(inf, inf));

  Expect.identical(0.0, double_max(0.0, -0.0));
  Expect.identical(0.0, double_max(-0.0, 0.0));

  Expect.isTrue(double_max(nan, nan).isNaN);
  Expect.isTrue(double_max(nan, -inf).isNaN);
  Expect.isTrue(double_max(nan, 1.0).isNaN);
  Expect.isTrue(double_max(nan, inf).isNaN);
  Expect.isTrue(double_max(-inf, nan).isNaN);
  Expect.isTrue(double_max(1.0, nan).isNaN);
  Expect.isTrue(double_max(inf, nan).isNaN);
}

main() {
  for (int i = 0; i < 100; i++) {
    testSmiMin();
    testSmiMax();
    testMintMin();
    testMintMax();
    testDoubleMin();
    testDoubleMax();
  }
}
