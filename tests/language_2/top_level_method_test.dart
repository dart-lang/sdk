// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

untypedTopLevel() {
  return 1;
}

class TopLevelMethodTest {
  static void testMain() {
    Expect.equals(1, untypedTopLevel());
  }
}

main() {
  TopLevelMethodTest.testMain();
}
