// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const x = "foo";
const y = "foo";
const g1 = x
  + "bar"  /// 01: compile-time error
;
const g2 = x
  + null   /// 02: compile-time error
;
const g3 = x
  + 499   /// 03: compile-time error
;
const g4 = x
  + 3.3   /// 04: compile-time error
;
const g5 = x
  + true   /// 05: compile-time error
;
const g6 = x
  + false   /// 06: compile-time error
;
const g7 = "foo"
  + x[0]   /// 07: compile-time error
;
const g8 = 1
  + x.length  /// 08: compile-time error
;
const g9 = x == y;

use(x) => x;

main() {
  Expect.equals("foo", g1);
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
