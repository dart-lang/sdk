// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timer_repeat_test;

import 'dart:async';
import '../../../pkg/unittest/lib/unittest.dart';

const Duration TIMEOUT = const Duration(milliseconds: 500);
const int ITERATIONS = 5;

Timer timer;
int startTime;
int iteration;

void timeoutHandler(Timer timer) {
  int endTime = (new DateTime.now()).millisecondsSinceEpoch;
  iteration++;
  if (iteration < ITERATIONS) {
    startTime = (new DateTime.now()).millisecondsSinceEpoch;
  } else {
    expect(iteration, ITERATIONS);
    timer.cancel();
  }
}

main() {
  test("timer_repeat", () {
    iteration = 0;
    startTime = new DateTime.now().millisecondsSinceEpoch;
    timer = new Timer.periodic(TIMEOUT,
        expectAsync1(timeoutHandler, count: ITERATIONS));
  });
}
