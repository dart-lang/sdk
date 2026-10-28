// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timer_test;

import 'dart:async';

import 'package:expect/legacy/async_minitest.dart'; // ignore: deprecated_member_use

const int STARTTIMEOUT = 1050;
const int DECREASE = 200;
const int ITERATIONS = 5;

Stopwatch stopwatch = new Stopwatch();
int timeout = STARTTIMEOUT;
int iteration = 0;

// Some browsers (Firefox and IE so far) can trigger too early. Add a safety
// margin when running on the web.
int get safetyMargin =>
    const bool.fromEnvironment('dart.library.js_interop') ? 100 : 0;

void timeoutHandler() {
  expect(
    stopwatch.elapsedMilliseconds + safetyMargin,
    greaterThanOrEqualTo(timeout),
  );
  if (iteration < ITERATIONS) {
    iteration++;
    timeout = timeout - DECREASE;
    Duration duration = new Duration(milliseconds: timeout);
    stopwatch.reset();
    new Timer(duration, expectAsync(timeoutHandler));
  }
}

main() {
  test("timeout test", () {
    Duration duration = new Duration(milliseconds: timeout);
    stopwatch.start();
    new Timer(duration, expectAsync(timeoutHandler));
  });
}
