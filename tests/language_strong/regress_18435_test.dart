// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 18435.

import "package:expect/expect.dart";

main() {
  const MISSING_VALUE = "MISSING_VALUE";

  void foo([var p1 = MISSING_VALUE, var p2 = MISSING_VALUE]) {
    Expect.equals("P1", p1);
    Expect.equals("P2", p2);
  }

  void bar([var p1 = "MISSING_VALUE", var p2 = "MISSING_VALUE"]) {
    Expect.equals("P1", p1);
    Expect.equals("P2", p2);
  }

  foo("P1", "P2");
  bar("P1", "P2");
}
