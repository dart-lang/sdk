// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Break' to case label is illegal.

class Switch5NegativeTest {
  static testMain() {
    var a = 5;
    var x;
    switch (a) {
      L:
      case 1:
        x = 1;
        break;
      case 6:
        x = 2;
        break L; // illegal
      default:
        break;
    }
    return a;
  }
}

main() {
  Switch5NegativeTest.testMain();
}
