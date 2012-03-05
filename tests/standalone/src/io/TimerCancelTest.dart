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

  cancelTimer = new Timer(1000, timeoutHandlerUnreachable);
  cancelTimer.cancel();
  new Timer(1000, timeoutHandler);
  cancelTimer = new Timer(2000, timeoutHandlerUnreachable);
  repeatTimer = 0;
  new Timer.repeating(1500, timeoutHandlerRepeat);
}

void testCancelTimerWithSameTime() {
  var t2;
  var t1 = new Timer(0, (t) => t2.cancel());
  t2 = new Timer(0, (t) => t1.cancel());
}

main() {
  testSimpleTimer();
  testCancelTimerWithSameTime();
}
