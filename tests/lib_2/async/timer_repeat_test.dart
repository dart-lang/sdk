// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timer_repeat_test;

import 'dart:async';
import 'package:test/test.dart';

const Duration TIMEOUT = const Duration(milliseconds: 500);
const int ITERATIONS = 5;

Timer timer;
Stopwatch stopwatch = new Stopwatch();
int iteration;

// Some browsers (Firefox and IE so far) can trigger too early. Add a safety
// margin. We use identical(1, 1.0) as an easy way to know if the test is
// compiled by dart2js.
int get safetyMargin => identical(1, 1.0) ? 100 : 0;

void timeoutHandler(Timer timer) {
  iteration++;
  expect(iteration, lessThanOrEqualTo(ITERATIONS));
  if (iteration == ITERATIONS) {
    // When we are done with all of the iterations, we expect a
    // certain amount of time to have passed.  Checking the time on
    // each iteration doesn't work because the timeoutHandler runs
    // concurrently with the periodic timer.
    expect(stopwatch.elapsedMilliseconds + safetyMargin,
        greaterThanOrEqualTo(ITERATIONS * TIMEOUT.inMilliseconds));
    timer.cancel();
  }
}

main() {
  test("timer_repeat", () {
    iteration = 0;
    stopwatch.start();
    timer = new Timer.periodic(
        TIMEOUT, expectAsync(timeoutHandler, count: ITERATIONS));
  });
}
