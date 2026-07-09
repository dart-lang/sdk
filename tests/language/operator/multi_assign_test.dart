// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing multiple assignment.

import "package:expect/expect.dart";

class MultiAssignTest {
  static testMain() {
    var i, j, k;
    i = j = k = 11;
    Expect.equals(11, i);
    Expect.equals(11, j);
    Expect.equals(11, k);

    var m;
    var n = m = k = 55;
    Expect.equals(55, m);
    Expect.equals(55, n);
    Expect.equals(55, k);
  }
}

main() {
  MultiAssignTest.testMain();
}
