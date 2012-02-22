// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 19;
final y = 3;
final g1 = x + y;
final g2 = x * y;
final g3 = x / y;
final g4 = x ~/ y;
final g5 = x << y;
final g6 = x >> y;
final g7 = ~x;
final g8 = -x;
final g9 = x < y;
final g10 = x <= y;
final g11 = x <= x;
final g12 = x > y;
final g13 = x >= y;
final g14 = x >= x;
final g15 = x == y;
final g16 = x == x;
final g17 = x != y;
final g18 = x != x;
final g19 = x | y;
final g20 = x & y;
final g21 = x ^ y;
final g22 = g1 + g2 + g4 + g5 + g6 + g7 + g8;
final g23 = x % y;

main() {
  Expect.equals(22, g1);
  Expect.equals(57, g2);
  Expect.equals(6.333333333333333333333333333, g3);
  Expect.equals(6, g4);
  Expect.equals(152, g5);
  Expect.equals(2, g6);
  Expect.equals(-20, g7);
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
  Expect.equals(200, g22);
  Expect.equals(1, g23);
}
