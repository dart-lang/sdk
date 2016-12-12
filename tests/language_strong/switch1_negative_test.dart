// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that default clause must be last case.

class Switch1NegativeTest {

  static testMain() {
    var a = 5;
    var x;
    S: switch (a) {
      case 1: x = 1; break;
      case 6: x = 2; break S;
      default:
      case 8:  break;
    }
    return a;
  }
}

main() {
  Switch1NegativeTest.testMain();
}
