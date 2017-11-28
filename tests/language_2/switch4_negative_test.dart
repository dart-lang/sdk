// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Discover unresolved case labels.

class Switch4NegativeTest {
  static testMain() {
    var a = 5;
    var x;
    switch (a) {
      case 1:
        x = 1;
        continue L; // unresolved forward reference
      case 6:
        x = 2;
        break;
      case 8:
        break;
    }
    return a;
  }
}

main() {
  Switch4NegativeTest.testMain();
}
