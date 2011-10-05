// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to check that the catching exception class is defined.

class TryCatch9NegativeTest {
  static void testMain() {
    try {
      throw "Hello";
    } catch (MammaMia e) {
      // Exception undefined, error at compile time expected. Instead we are
      // catching all.
    }
  }
}
main() {
  TryCatch9NegativeTest.testMain();
}
