// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Variable initializer must not reference the initialized variable.

class BadInitializer1NegativeTest {
  static testMain() {
    final List elems = const [
      const [1, 2.0, true, false, 0xffffffffff, elems],
      "a",
      "b"
    ];
  }
}

main() {
  BadInitializer1NegativeTest.testMain();
}
