// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

const x = 19;
const y = 3;
const z = -5;
const g1 = x + y;
const g2 = x * y;
const g3 = x / y;
const g4 = x ~/ y;
const g5 = x << y;
const g6 = x >> y;
const g7 = ~z;
const g8 = -x;
const g9 = x < y;
const g10 = x <= y;
const g11 = x <= x;
const g12 = x > y;
const g13 = x >= y;
const g14 = x >= x;
const g15 = x == y;
const g16 = x == x;
const g17 = x != y;
const g18 = x != x;
const g19 = x | y;
const g20 = x & y;
const g21 = x ^ y;
const g22 = g1 + g2 + g4 + g5 + g6 + g7 + g8;
const g23 = x % y;

main() {
  Expect.equals(22, g1);
  Expect.equals(57, g2);
  Expect.equals(6.333333333333333333333333333, g3);
  Expect.equals(6, g4);
  Expect.equals(152, g5);
  Expect.equals(2, g6);
  Expect.equals(4, g7);
  Expect.equals(-19, g8);
  Expect.equals(false, g9);
  Expect.equals(false, g10);
  Expect.equals(true, g11);
  Expect.equals(true, g12);
  Expect.equals(true, g13);
  Expect.equals(true, g14);
  Expect.equals(false, g15);
  Expect.equals(true, g16);
  Expect.equals(true, g17);
  Expect.equals(false, g18);
  Expect.equals(19, g19);
  Expect.equals(3, g20);
  Expect.equals(16, g21);
  Expect.equals(224, g22);
  Expect.equals(1, g23);
}
