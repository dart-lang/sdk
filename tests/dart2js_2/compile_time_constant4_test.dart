// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

const x = "foo";
const y = "foo";
const g1 = x + "bar";
const g2 = x
  + null //  //# 01: compile-time error
    ;
const g3 = x
  + 499 //  //# 02: compile-time error
    ;
const g4 = x
  + 3.3 //  //# 03: compile-time error
    ;
const g5 = x
  + true //  //# 04: compile-time error
    ;
const g6 = x
  + false //  //# 05: compile-time error
    ;
const g7 = "foo"
  + x[0] //  //# 06: compile-time error
    ;
const g8 = 1 + x.length;
const g9 = x == y;

use(x) => x;

main() {
  Expect.equals("foobar", g1);
  Expect.isTrue(g9);
  use(g1);
  use(g2);
  use(g3);
  use(g4);
  use(g5);
  use(g6);
  use(g7);
  use(g8);
}
