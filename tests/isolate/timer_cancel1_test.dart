// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('timer_cancel1_test');

#import("dart:isolate");
#import('../../pkg/unittest/unittest.dart');

main() {
  // Test that a timeout handler can cancel another.
  test("timer cancel1 test", () {
    var canceleeTimer;
    var cancelerTimer;

    void unreachable(Timer timer) {
      fail("A canceled timeout handler should be unreachable.");
    }

    void handler(Timer timer) {
      canceleeTimer.cancel();
    }

    cancelerTimer = new Timer(1, expectAsync1(handler));
    canceleeTimer = new Timer(1000, expectAsync1(unreachable, count: 0));
  });
}
