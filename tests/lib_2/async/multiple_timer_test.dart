// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library multiple_timer_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

const Duration TIMEOUT1 = const Duration(seconds: 1);
const Duration TIMEOUT2 = const Duration(seconds: 2);
const Duration TIMEOUT3 = const Duration(milliseconds: 500);
const Duration TIMEOUT4 = const Duration(milliseconds: 1500);

// The stopwatch is more precise than the Timer.
// Some browsers (Firefox and IE so far) can trigger too early. So we add more
// margin. We use identical(1, 1.0) as an easy way to know if the test is
// running on the web.
int get safetyMargin => identical(1, 1.0) ? 100 : 0;

main() {
  Stopwatch _stopwatch1 = new Stopwatch();
  Stopwatch _stopwatch2 = new Stopwatch();
  Stopwatch _stopwatch3 = new Stopwatch();
  Stopwatch _stopwatch4 = new Stopwatch();
  List<int> _order;
  int _message;

  void timeoutHandler1() {
    Expect.isTrue((_stopwatch1.elapsedMilliseconds + safetyMargin) >=
        TIMEOUT1.inMilliseconds);
    Expect.equals(_order[_message], 0);
    _message++;
    asyncEnd();
  }

  void timeoutHandler2() {
    Expect.isTrue((_stopwatch2.elapsedMilliseconds + safetyMargin) >=
        TIMEOUT2.inMilliseconds);
    Expect.equals(_order[_message], 1);
    _message++;
    asyncEnd();
  }

  void timeoutHandler3() {
    Expect.isTrue((_stopwatch3.elapsedMilliseconds + safetyMargin) >=
        TIMEOUT3.inMilliseconds);
    Expect.equals(_order[_message], 2);
    _message++;
    asyncEnd();
  }

  void timeoutHandler4() {
    Expect.isTrue((_stopwatch4.elapsedMilliseconds + safetyMargin) >=
        TIMEOUT4.inMilliseconds);
    Expect.equals(_order[_message], 3);
    _message++;
    asyncEnd();
  }

  _order = new List<int>(4);
  _order[0] = 2;
  _order[1] = 0;
  _order[2] = 3;
  _order[3] = 1;
  _message = 0;

  asyncStart();
  _stopwatch1.start();
  new Timer(TIMEOUT1, timeoutHandler1);
  asyncStart();
  _stopwatch2.start();
  new Timer(TIMEOUT2, timeoutHandler2);
  asyncStart();
  _stopwatch3.start();
  new Timer(TIMEOUT3, timeoutHandler3);
  asyncStart();
  _stopwatch4.start();
  new Timer(TIMEOUT4, timeoutHandler4);
}
