// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that a list literal is expandable and modifiable.

class ListLiteralTest {
  static void testMain() {
    var list = [1, 2, 3];
    Expect.equals(3, list.length);
    list.add(4);
    Expect.equals(4, list.length);
    list.addAll([5, 6]);
    Expect.equals(6, list.length);
    list[0] = 0;
    Expect.equals(0, list[0]);
  }
}

main() {
  ListLiteralTest.testMain();
}
