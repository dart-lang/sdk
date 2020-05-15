// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

f() {}
const g = 1;

const identical_ff = identical(f, f);
const identical_fg = identical(f, g);
const identical_gf = identical(g, f);
const identical_gg = identical(g, g);

// Verify proper compile time computation of identical()
const a = const {
  identical_ff: 0, //# 01: compile-time error
  identical_gg: 0, //# 02: compile-time error
  true: 0
};

const b = const {
  identical_fg: 0, //# 03: compile-time error
  identical_gf: 0, //# 04: compile-time error
  false: 0
};

use(x) => x;

main() {
  use(a);
  use(b);

  // Verify proper run time computation of identical()
  Expect.isTrue(identical_ff); //# 05: ok
  Expect.isTrue(identical_gg); //# 06: ok
  Expect.isFalse(identical_fg); //# 07: ok
  Expect.isFalse(identical_gf); //# 08: ok
}
