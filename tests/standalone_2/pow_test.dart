// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing math's pow.

library pow_test;

import "package:expect/expect.dart";
import 'dart:math';

var expectedResults = [
  1,
  2,
  4,
  8,
  16,
  32,
  64,
  128,
  256,
  512,
  1024,
  2048,
  4096,
  8192,
  16384,
  32768,
  65536,
  131072,
  262144,
  524288,
  1048576,
  2097152,
  4194304,
  8388608,
  16777216,
  33554432,
  67108864,
  134217728,
  268435456,
  536870912,
  1073741824,
  2147483648,
  4294967296,
  8589934592,
  17179869184,
  34359738368,
  68719476736,
  137438953472,
  274877906944,
  549755813888,
  1099511627776,
  2199023255552,
  4398046511104,
  8796093022208,
  17592186044416,
  35184372088832,
  70368744177664,
  140737488355328,
  281474976710656,
  562949953421312,
  1125899906842624,
  2251799813685248,
  4503599627370496,
  9007199254740992,
  18014398509481984,
  36028797018963968,
  72057594037927936,
  144115188075855872,
  288230376151711744,
  576460752303423488,
  1152921504606846976,
  2305843009213693952,
  4611686018427387904,
  9223372036854775808,
  18446744073709551616,
  36893488147419103232,
  73786976294838206464,
  147573952589676412928
];

void main() {
  int exp = 0;
  for (int val in expectedResults) {
    Expect.equals(val, pow(2, exp));
    Expect.equals(val.toDouble(), pow(2, exp.toDouble()));
    exp++;
  }

  // Optimize it.
  for (int i = 0; i < 8888; i++) {
    pow(2, 3);
    pow(2.0, 3.0);
  }
  exp = 0;
  for (int val in expectedResults) {
    Expect.equals(val, pow(2, exp));
    Expect.equals(val.toDouble(), pow(2, exp.toDouble()));
    exp++;
  }
  // Test Bigints.
  Expect.equals(5559917313492231481, pow(11, 18));
  Expect.equals(672749994932560009201, pow(11, 20));
}
