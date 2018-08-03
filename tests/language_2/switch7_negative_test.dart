// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Illegal to reference a labeled case stmt with break

class Switch7NegativeTest {
  static testMain() {
    var x = 1;
    L:
    while (true) {
      switch (x) {
        L:
        case 1: // Shadowing another label is OK.
          break L; // illegal, can't reference labeled case stmt from break
      }
    }
  }
}

main() {
  Switch7NegativeTest.testMain();
}
