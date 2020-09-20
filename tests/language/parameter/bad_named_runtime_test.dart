// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing bad named parameters.

import "package:expect/expect.dart";

class BadNamedParametersTest {
  int f42(int a, {int b: 20, int c: 30}) {
    return 100 * (100 * a + b) + c;
  }

  int f52(int a, {int b: 20, int? c, int d: 40}) {
    return 100 * (100 * (100 * a + b) + (c == null ? 0 : c)) + d;
  }
}

main() {
  BadNamedParametersTest np = new BadNamedParametersTest();

  // Parameter b passed twice.


  // Parameter x does not exist.


  // Parameter b1 does not exist.


  // Too many parameters.


  // Too few parameters.

}
