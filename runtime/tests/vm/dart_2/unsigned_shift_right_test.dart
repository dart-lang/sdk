// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=50
// VMOptions=--no-intrinsify

// Test int.operator>>> in case of Smi range overflow and deoptimization.

import "package:expect/expect.dart";

@pragma('vm:never-inline')
void test1(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test2(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test3(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test4(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test5(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test6(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test7(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test8(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test9(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test10(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test11(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test12(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test13(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

@pragma('vm:never-inline')
void test14(int a, int b, int expected) {
  Expect.equals(expected, a >>> b);
}

void testCornerCases() {
  // Make sure test methods are optimized.
  for (int i = 0; i < 100; ++i) {
    test1(1, 1, 0);
    test2(1, 1, 0);
    test3(1, 1, 0);
    test4(1, 1, 0);
    test5(1, 1, 0);
    test6(1, 1, 0);
    test7(1, 1, 0);
    test8(1, 1, 0);
    test9(1, 1, 0);
    test10(1, 1, 0);
    test11(1, 1, 0);
    test12(1, 1, 0);
    test13(1, 1, 0);
    test14(1, 1, 0);
  }
  // Run tests, may trigger deoptimization.
  for (int i = 0; i < 100; ++i) {
    test1(0xffffffffffffffff, 1, 0x7fffffffffffffff);
    test2(0xffffffffffffabcd, 1, 0x7fffffffffffd5e6);
    test3(0xffffffffffffffff, 31, 0x1ffffffff);
    test4(0xffffffffffffffff, 32, 0xffffffff);
    test5(0xfedcba9876543210, 32, 0xfedcba98);
    test6(0xffffffffffffffff, 34, 0x3fffffff);
    test7(0xffffffffffffffff, 56, 0xff);
    test8(0xfeffffffffffabcd, 56, 0xfe);
    test9(0xffffffffffffffff, 63, 0x1);
    test10(0xffffffffffffffff, 64, 0);
    test11(0xffffffffffffffff, 70, 0);
    test12(0x8000000000000000, 1, 0x4000000000000000);
    test13(0x7fedcba987654321, 1, 0x3ff6e5d4c3b2a190);
    test14(0x7fedcba987654321, 40, 0x7fedcb);
  }
}

void testSingleOneBit() {
  for (int i = 0; i <= 63; ++i) {
    final int x = 1 << i;
    for (int j = 0; j <= 127; ++j) {
      Expect.equals((j > i) ? 0 : 1 << (i - j), x >>> j);
    }
  }
}

void testSingleZeroBit() {
  for (int i = 0; i <= 63; ++i) {
    final int x = ~(1 << i);
    for (int j = 0; j <= 127; ++j) {
      if (j >= 64) {
        Expect.equals(0, x >>> j);
      } else {
        final int mask = (1 << (64 - j)) - 1;
        if (j > i) {
          Expect.equals(mask, x >>> j);
        } else {
          Expect.equals(mask & ~(1 << (i - j)), x >>> j);
        }
      }
    }
  }
}

main() {
  testCornerCases();

  for (int i = 0; i < 100; ++i) {
    testSingleOneBit();
    testSingleZeroBit();
  }
}
