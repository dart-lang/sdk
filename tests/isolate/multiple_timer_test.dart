// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('multiple_timer_test');

#import("dart:isolate");

class MultipleTimerTest {

  static final int TIMEOUT1 = 1000;
  static final int TIMEOUT2 = 2000;
  static final int TIMEOUT3 = 500;
  static final int TIMEOUT4 = 1500;

  static void testMultipleTimer() {

    void timeoutHandler1(Timer timer) {
      int endTime = (new Date.now()).millisecondsSinceEpoch;
      Expect.equals(true, (endTime - _startTime1) >= TIMEOUT1);
      Expect.equals(true, _order[_message] == 0);
      _message++;
    }

    void timeoutHandler2(Timer timer) {
      int endTime  = (new Date.now()).millisecondsSinceEpoch;
      Expect.equals(true, (endTime - _startTime2) >= TIMEOUT2);
      Expect.equals(true, _order[_message] == 1);
      _message++;
    }

    void timeoutHandler3(Timer timer) {
      int endTime = (new Date.now()).millisecondsSinceEpoch;
      Expect.equals(true, (endTime - _startTime3) >= TIMEOUT3);
      Expect.equals(true, _order[_message] == 2);
      _message++;
    }

    void timeoutHandler4(Timer timer) {
      int endTime  = (new Date.now()).millisecondsSinceEpoch;
      Expect.equals(true, (endTime - _startTime4) >= TIMEOUT4);
      Expect.equals(true, _order[_message] == 3);
      _message++;
    }

    _order = new List<int>(4);
    _order[0] = 2;
    _order[1] = 0;
    _order[2] = 3;
    _order[3] = 1;
    _message = 0;

    _startTime1 = (new Date.now()).millisecondsSinceEpoch;
    new Timer(TIMEOUT1, timeoutHandler1);
    _startTime2 = (new Date.now()).millisecondsSinceEpoch;
    new Timer(TIMEOUT2, timeoutHandler2);
    _startTime3 = (new Date.now()).millisecondsSinceEpoch;
    new Timer(TIMEOUT3, timeoutHandler3);
    _startTime4 = (new Date.now()).millisecondsSinceEpoch;
    new Timer(TIMEOUT4, timeoutHandler4);
  }

  static void testMain() {
    testMultipleTimer();
  }

  static int _startTime1;
  static int _startTime2;
  static int _startTime3;
  static int _startTime4;
  static List<int> _order;
  static int _message;
}

main() {
  MultipleTimerTest.testMain();
}
