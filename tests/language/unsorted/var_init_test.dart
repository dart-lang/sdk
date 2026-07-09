// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing correct initialization of variables in scopes.

import "package:expect/expect.dart";

class VarInitTest {
  static void testMain() {
    for (int i = 0; i < 10; i++) {
      var x;
      Expect.equals(null, x);
      x = 1;
    }
  }
}

main() {
  VarInitTest.testMain();
}
