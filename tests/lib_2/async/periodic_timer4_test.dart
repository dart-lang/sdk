// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timer_test;

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

const ms = const Duration(milliseconds: 1);

expectGTE(min, actual, msg) {
  if (actual >= min) return;
  Expect._fail(msg.replaceAll('{0}', "$min").replaceAll('{1}', "$actual"));
}

main() {
  int interval = 20;
  asyncStart();
  var sw = new Stopwatch()..start();
  int nextTick = 1;
  bool running = true;
  var timer = new Timer.periodic(ms * interval, (t) {
    expectGTE(nextTick, t.tick, "tick {1} before expect next tick {0}.");
    nextTick += 1;
    int time = sw.elapsedMilliseconds;
    int minTime = interval * t.tick;
    expectGTE(minTime, time, "Actual time {1} before {0} at tick ${t.tick}");
    if (t.tick > 20) {
      running = false;
      t.cancel();
      asyncEnd();
    }
  });

  /// Test that ticks still happen when the rest of the system is slow.
  delay() {
    int time = new DateTime.now().millisecondsSinceEpoch;
    int limit = time + 3 * interval;
    while (new DateTime.now().millisecondsSinceEpoch < limit) {
      // Idle.
    }
    nextTick = timer.tick + 2; // At least increment by two, probably more.
    if (running) Timer.run(delay);
  }

  Timer.run(delay);
}
