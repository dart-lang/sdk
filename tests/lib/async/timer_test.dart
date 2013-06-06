// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timer_test;

import 'dart:async';
import '../../../pkg/unittest/lib/unittest.dart';

const int STARTTIMEOUT = 1050;
const int DECREASE = 200;
const int ITERATIONS = 5;

int startTime;
int timeout;
int iteration;

// Some browsers (Firefox and IE so far) can trigger too early. Add a safety
// margin. We use identical(1, 1.0) as an easy way to know if the test is
// compiled by dart2js.
// NOTE: 15 ms seems to be resolution of Stopwatch implementation on Windows.
int get safetyMargin => identical(1, 1.0) ? 100 : 15;

void timeoutHandler() {
  int endTime = (new DateTime.now()).millisecondsSinceEpoch;
  expect(endTime - startTime + safetyMargin, greaterThanOrEqualTo(timeout));
  if (iteration < ITERATIONS) {
    iteration++;
    timeout = timeout - DECREASE;
    Duration duration = new Duration(milliseconds: timeout);
    startTime = (new DateTime.now()).millisecondsSinceEpoch;
    new Timer(duration, expectAsync0(timeoutHandler));
  }
}

main() {
  test("timeout test", () {
    iteration = 0;
    timeout = STARTTIMEOUT;
    Duration duration = new Duration(milliseconds: timeout);
    startTime = (new DateTime.now()).millisecondsSinceEpoch;
    new Timer(duration, expectAsync0(timeoutHandler));
  });
}
