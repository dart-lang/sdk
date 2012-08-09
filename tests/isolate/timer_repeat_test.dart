// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('timer_repeat_test');

#import("dart:isolate");

class TimerRepeatTest {

  static final int _TIMEOUT = 500;
  static final int _ITERATIONS = 5;

  static void testRepeatTimer() {

    void timeoutHandler(Timer timer) {
      int endTime = (new Date.now()).millisecondsSinceEpoch;
      _iteration++;
      if (_iteration < _ITERATIONS) {
        _startTime = (new Date.now()).millisecondsSinceEpoch;
      } else {
        Expect.equals(_iteration, _ITERATIONS);
        timer.cancel();
      }
    }

    _iteration = 0;
    _startTime = (new Date.now()).millisecondsSinceEpoch;
    timer = new Timer.repeating(_TIMEOUT, timeoutHandler);
  }

  static void testMain() {
    testRepeatTimer();
  }

  static Timer timer;
  static int _startTime;
  static int _iteration;
}

main() {
  TimerRepeatTest.testMain();
}
