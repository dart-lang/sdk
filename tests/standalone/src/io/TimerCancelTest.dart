// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

void testSimpleTimer() {
  Timer cancelTimer;
  int repeatTimer;

  void timeoutHandlerUnreachable(Timer timer) {
    Expect.equals(true, false);
  }

  void timeoutHandler(Timer timer) {
    cancelTimer.cancel();
  }

  void timeoutHandlerRepeat(Timer timer) {
    repeatTimer++;
    timer.cancel();
    Expect.equals(true, repeatTimer == 1);
  }

  cancelTimer = new Timer(timeoutHandlerUnreachable, 1000);
  cancelTimer.cancel();
  new Timer(timeoutHandler, 1000);
  cancelTimer = new Timer(timeoutHandlerUnreachable, 2000);
  repeatTimer = 0;
  new Timer.repeating(timeoutHandlerRepeat, 1500);
}

void testCancelTimerWithSameTime() {
  var t2;
  var t1 = new Timer((t) => t2.cancel(), 0);
  t2 = new Timer((t) => t1.cancel(), 0);
}

main() {
  testSimpleTimer();
  testCancelTimerWithSameTime();
}
