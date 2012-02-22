// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final g1 = true;
final g2 = 499;
final g3 = "foo";
final g4 = 3.3;
final g5 = g1 == g2;
final g6 = g1 == g3;
final g7 = g1 == g4;
final g8 = g2 == g3;
final g9 = g2 == g4;
final g10 = g3 == g4;
final g11 = g1 == g1;
final g12 = g2 == g2;
final g13 = g3 == g3;
final g14 = g4 == g4;

main() {
  Expect.isFalse(g5);
  Expect.isFalse(g6);
  Expect.isFalse(g7);
  Expect.isFalse(g8);
  Expect.isFalse(g9);
  Expect.isFalse(g10);
  Expect.isTrue(g11);
  Expect.isTrue(g12);
  Expect.isTrue(g13);
  Expect.isTrue(g14);
}
