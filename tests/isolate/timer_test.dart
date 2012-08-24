// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('timer_test');

#import("dart:isolate");

class TimerTest {

  static const int _STARTTIMEOUT = 1050;
  static const int _DECREASE = 200;
  static const int _ITERATIONS = 5;

  static void testSimpleTimer() {

    void timeoutHandler(Timer timer) {
      int endTime = (new Date.now()).millisecondsSinceEpoch;
      Expect.equals(true, (endTime - _startTime) >= _timeout);
      if (_iteration < _ITERATIONS) {
        _iteration++;
        _timeout = _timeout - _DECREASE;
        _startTime = (new Date.now()).millisecondsSinceEpoch;
        new Timer(_timeout, timeoutHandler);
      }
    }

    _iteration = 0;
    _timeout = _STARTTIMEOUT;
    _startTime = (new Date.now()).millisecondsSinceEpoch;
    new Timer(_timeout, timeoutHandler);
  }

  static void testMain() {
    testSimpleTimer();
  }

  static int _startTime;
  static int _timeout;
  static int _iteration;
}

main() {
  TimerTest.testMain();
}
