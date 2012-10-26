// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('multiple_timer_test');

#import("dart:isolate");
#import('../../pkg/unittest/unittest.dart');

const int TIMEOUT1 = 1000;
const int TIMEOUT2 = 2000;
const int TIMEOUT3 = 500;
const int TIMEOUT4 = 1500;

main() {
  test("multiple timer test", () {
    int _startTime1;
    int _startTime2;
    int _startTime3;
    int _startTime4;
    List<int> _order;
    int _message;

    void timeoutHandler1(Timer timer) {
      int endTime = (new Date.now()).millisecondsSinceEpoch;
      expect(endTime - _startTime1, greaterThanOrEqualTo(TIMEOUT1));
      expect(_order[_message], 0);
      _message++;
    }

    void timeoutHandler2(Timer timer) {
      int endTime  = (new Date.now()).millisecondsSinceEpoch;
      expect(endTime - _startTime2, greaterThanOrEqualTo(TIMEOUT2));
      expect(_order[_message], 1);
      _message++;
    }

    void timeoutHandler3(Timer timer) {
      int endTime = (new Date.now()).millisecondsSinceEpoch;
      expect(endTime - _startTime3, greaterThanOrEqualTo(TIMEOUT3));
      expect(_order[_message], 2);
      _message++;
    }

    void timeoutHandler4(Timer timer) {
      int endTime  = (new Date.now()).millisecondsSinceEpoch;
      expect(endTime - _startTime4, greaterThanOrEqualTo(TIMEOUT4));
      expect(_order[_message], 3);
      _message++;
    }

    _order = new List<int>(4);
    _order[0] = 2;
    _order[1] = 0;
    _order[2] = 3;
    _order[3] = 1;
    _message = 0;

    _startTime1 = (new Date.now()).millisecondsSinceEpoch;
    new Timer(TIMEOUT1, expectAsync1(timeoutHandler1));
    _startTime2 = (new Date.now()).millisecondsSinceEpoch;
    new Timer(TIMEOUT2, expectAsync1(timeoutHandler2));
    _startTime3 = (new Date.now()).millisecondsSinceEpoch;
    new Timer(TIMEOUT3, expectAsync1(timeoutHandler3));
    _startTime4 = (new Date.now()).millisecondsSinceEpoch;
    new Timer(TIMEOUT4, expectAsync1(timeoutHandler4));
  });
}
