// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Stress test isolate generation.
// DartOptions=-- tests/standalone/src/EchoServerTest.dart tests/standalone/src/ManyEchoServerTest.dart -- ManyEchoServerTest.testMain

class ManyEchoServerTest {
  static testMain() {
    for (int i = 0; i < 5000; i++) {
      EchoServerTest.testMain();
    }
  }
}

main() {
  ManyEchoServerTest.testMain();
}
