// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test check that we catch label errors.


class Label3NegativeTest {
  static testMain() {
    L: while (false) {
      if (true) break L; // Ok
    }
    continue L; // Illegal: L is out of scope.
  }
}


main() {
  Label3NegativeTest.testMain();
}
