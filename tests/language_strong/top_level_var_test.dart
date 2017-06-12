// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing top-level variables.

import "package:expect/expect.dart";

var a, b;

class TopLevelVarTest {
  static testMain() {
    Expect.equals(null, a);
    Expect.equals(null, b);
    a = b = 100;
    b++;
    Expect.equals(100, a);
    Expect.equals(101, b);

    Expect.equals(111, x);
    Expect.equals(112, y);
  }
}

// Ensure that initializers work for both const and non-const variables.
const int x = 2 * 55 + 1;
int y = x + 1;

main() {
  TopLevelVarTest.testMain();
}
