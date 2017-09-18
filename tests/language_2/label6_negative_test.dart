// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test check that we catch label errors.

class Label6NegativeTest {
  static testMain() {
    L:
    while (false) {
      break; //    ok;
      break L; //  ok
      void innerfunc() {
        if (true) break L; // Illegal: jump target is outside of function
      }

      innerfunc();
    }
  }
}

main() {
  Label6NegativeTest.testMain();
}
