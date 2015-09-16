// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test mismatch in argument counts.

class InstanceCallWrongArgumentCountNegativeTest {
  static void testMain() {
    Niederhorn nh = new Niederhorn();
    nh.goodCall(1, 2, 3);
    // Bad call.
    nh.goodCall(1, 2, 3, 4);
  }
}

class Niederhorn {
  Niederhorn() {}
  int goodCall(int a, int b, int c) {
    return a + b;
  }
}

main() {
  InstanceCallWrongArgumentCountNegativeTest.testMain();
}
