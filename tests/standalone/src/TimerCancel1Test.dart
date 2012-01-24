// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

// Test that a timeout handler can cancel another.
class TimerCancel1Test {
  static void testOtherCancel() {
    var canceleeTimer;
    var cancelerTimer;

    void timeoutHandlerUnreachable(Timer timer) {
      Expect.fail("A canceled timeout handler should be unreachable.");
    }

    void cancelHandler(Timer timer) {
      canceleeTimer.cancel();
    }

    cancelerTimer = new Timer(cancelHandler, 1);
    canceleeTimer = new Timer(timeoutHandlerUnreachable, 1000);
  }

  static void testMain() {
    testOtherCancel();
  }
}

main() {
  TimerCancel1Test.testMain();
}
