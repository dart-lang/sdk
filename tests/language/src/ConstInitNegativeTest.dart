// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that initializer is expected after final variable declaration.

class ConstInitNegativeTest {
  static testMain() {
    final int c0 = 5;
    final int c1;
    Expect.equals(c0, 5);
  }
}

main() {
  ConstInitNegativeTest.testMain();
}
