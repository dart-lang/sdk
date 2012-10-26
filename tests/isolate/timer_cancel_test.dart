// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('timer_cancel_test');

#import("dart:isolate");
#import('../../pkg/unittest/unittest.dart');

main() {
  test("simple timer", () {
    Timer cancelTimer;
    int repeatTimer;

    void unreachable(Timer timer) {
      fail("should not be reached");
    }

    void handler(Timer timer) {
      cancelTimer.cancel();
    }

    void repeatHandler(Timer timer) {
      repeatTimer++;
      timer.cancel();
      expect(repeatTimer, 1);
    }

    cancelTimer = new Timer(1000, expectAsync1(unreachable, count: 0));
    cancelTimer.cancel();
    new Timer(1000, expectAsync1(handler));
    cancelTimer = new Timer(2000, expectAsync1(unreachable, count: 0));
    repeatTimer = 0;
    new Timer.repeating(1500, expectAsync1(repeatHandler));
  });
  
  test("cancel timer with same time", () {
    var t2;
    var t1 = new Timer(0, expectAsync1((t) => t2.cancel()));
    t2 = new Timer(0, expectAsync1((t) => t1.cancel(), count: 0));
  });
}
