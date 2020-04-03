// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

const g1 = true;
const g2 = 499;
const g3 = "foo";
const g4 = 3.3;
const g5 = g1 == g2;
const g6 = g1 == g3;
const g7 = g1 == g4;
const g8 = g2 == g3;
const g9 = g2 == g4;
const g10 = g3 == g4;
const g11 = g1 == g1;
const g12 = g2 == g2;
const g13 = g3 == g3;
const g14 = g4 == g4;

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
