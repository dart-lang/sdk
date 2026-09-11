// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--cfg

import 'package:expect/expect.dart';

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int classify(int x) {
  if (x > 0) {
    if (x > 10) {
      return 2;
    } else {
      return 1;
    }
  } else if (x < 0) {
    return -1;
  } else {
    return 0;
  }
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int ternaryPhi(int a, int b) {
  return a > b ? a : b;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int sumWhile(int n) {
  int sum = 0;
  int i = 1;
  while (i <= n) {
    sum += i;
    i++;
  }
  return sum;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int factorialFor(int n) {
  int result = 1;
  for (int i = 2; i <= n; i++) {
    result *= i;
  }
  return result;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int doWhileCount(int n) {
  int count = 0;
  do {
    count++;
    n--;
  } while (n > 0);
  return count;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int gcdEuclid(int a, int b) {
  while (a != b) {
    if (a > b) {
      a -= b;
    } else {
      b -= a;
    }
  }
  return a;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int nestedLoopsWithBreakContinue(int maxI, int maxJ) {
  int total = 0;
  for (int i = 0; i < maxI; i++) {
    if (i == 3) continue;
    for (int j = 0; j < maxJ; j++) {
      if (j == 2) break;
      total += i * 10 + j;
    }
  }
  return total;
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
int intOps(int a, int b) {
  int r = 0;
  r += a + b;
  r += a - b;
  r += a * b;
  r += a & b;
  r += a | b;
  r += a ^ b;
  r += a << 2;
  r += a >> 1;
  r += a >>> 1;
  r += -a;
  r += ~b;
  return r;
}

void main() {
  final int0 = int.parse('0');
  final int1 = int.parse('1');
  final int3 = int.parse('3');
  final int4 = int.parse('4');
  final int5 = int.parse('5');
  final int7 = int.parse('7');
  final int10 = int.parse('10');
  final int15 = int.parse('15');
  final int20 = int.parse('20');
  final negFive = int.parse('-5');

  // Classification (nested ifs)
  Expect.equals(2, classify(int15));
  Expect.equals(1, classify(int5));
  Expect.equals(-1, classify(negFive));
  Expect.equals(0, classify(int0));

  // Ternary / Phi
  Expect.equals(10, ternaryPhi(int10, int5));
  Expect.equals(20, ternaryPhi(int3, int20));

  // While loop
  Expect.equals(55, sumWhile(int10));
  Expect.equals(0, sumWhile(int0));

  // For loop
  Expect.equals(120, factorialFor(int5));
  Expect.equals(1, factorialFor(int1));

  // Do-while loop
  Expect.equals(5, doWhileCount(int5));
  Expect.equals(1, doWhileCount(int0));

  // GCD
  Expect.equals(6, gcdEuclid(int.parse('54'), int.parse('24')));
  Expect.equals(1, gcdEuclid(int7, int5));

  // Nested loops with break & continue
  Expect.equals(144, nestedLoopsWithBreakContinue(int5, int4));

  // Int operations
  Expect.equals(108, intOps(int10, int3));
}
