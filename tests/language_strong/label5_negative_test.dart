// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test check that we catch label errors.

class Label5NegativeTest {
  static testMain() {
    var L = 33;
    while (false) {
      if (true) break L; // Illegal: L is not a label.
    }
  }
}

main() {
  Label5NegativeTest.testMain();
}
