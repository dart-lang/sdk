// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 19.5;
final y = 3.3;
final g1 = x + y;
final g2 = x * y;
final g3 = x / y;
final g4 = x ~/ y;
final g5 = -x;
final g6 = x < y;
final g7 = x <= y;
final g8 = x <= x;
final g9 = x > y;
final g10 = x >= y;
final g11 = x >= x;
final g12 = x == y;
final g13 = x == x;
final g14 = x != y;
final g15 = x != x;
final g16 = g1 + g2 + g3 + g4 + g5;
final g17 = x % y;

main() {
  Expect.equals(22.8, g1);
  Expect.equals(64.35, g2);
  Expect.equals(5.909090909090909, g3);
  Expect.equals(5.0, g4);
  Expect.equals(-19.5, g5);
  Expect.equals(false, g6);
  Expect.equals(false, g7);
  Expect.equals(true, g8);
  Expect.equals(true, g9);
  Expect.equals(true, g10);
  Expect.equals(true, g11);
  Expect.equals(false, g12);
  Expect.equals(true, g13);
  Expect.equals(true, g14);
  Expect.equals(false, g15);
  Expect.equals(78.5590909090909, g16);
  Expect.equals(3.000000000000001, g17);
}
