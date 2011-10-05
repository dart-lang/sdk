// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing circular initialization errors.

class ConstInit3NegativeTest {
  static final N = O + 1;                // ok
  static final O = N + 1;                // Error: circular reference

  static testMain() {
    Expect.equals(null, N);
  }
}

main() {
  ConstInit3NegativeTest.testMain();
}
