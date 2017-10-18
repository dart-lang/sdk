// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 18869: Check that try-catch is working correctly
// inside switch-case clauses.

import "package:expect/expect.dart";

test_switch() {
  switch (0) {
    _0:
    case 0:
      print("_0");
      continue _5;
    _1:
    case 1:
      try {
        print("bunny");
        continue _6;
      } catch (e) {}
      break;
    _5:
    case 5:
      print("_5");
      continue _6;
    _6:
    case 6:
      print("_6");
      throw 555;
  }
}

main() {
  Expect.throws(() => test_switch(), (e) => e == 555);
}
