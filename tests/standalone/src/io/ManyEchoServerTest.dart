// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Stress test isolate generation.

#import("EchoServerTest.dart", prefix: "single");

class ManyEchoServerTest {
  static testMain() {
    for (int i = 0; i < 5000; i++) {
      single.EchoServerTest.testMain();
    }
  }
}

main() {
  ManyEchoServerTest.testMain();
}
