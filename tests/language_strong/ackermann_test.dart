// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart version of two-argument Ackermann-Peter function.

import "package:expect/expect.dart";

class AckermannTest {
  static ack(m, n) {
    return m == 0
        ? n + 1
        : ((n == 0) ? ack(m - 1, 1) : ack(m - 1, ack(m, n - 1)));
  }

  static testMain() {
    Expect.equals(253, ack(3, 5));
  }
}

main() {
  AckermannTest.testMain();
}
