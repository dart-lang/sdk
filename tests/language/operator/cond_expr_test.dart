// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that conditional expressions can contain assignment expressions.

import "package:expect/expect.dart";

var e1, e2;

f(a) => a < 0 ? e1 = -1 : e2 = 1;

main() {
  e1 = 0;
  e2 = 0;
  var r = f(-100);
  Expect.equals(-1, r);
  Expect.equals(-1, e1);
  Expect.equals(0, e2);

  e1 = 0;
  e2 = 0;
  r = f(100);
  Expect.equals(1, r);
  Expect.equals(0, e1);
  Expect.equals(1, e2);
}
