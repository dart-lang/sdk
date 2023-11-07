// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

const ms = const Duration(milliseconds: 1);

expectGTE(min, actual, msg) {
  if (actual >= min) return;
  Expect.fail(msg.replaceAll('{0}', "$min").replaceAll('{1}', "$actual"));
}

main() {
  int interval = 100;
  // Most browsers can trigger timers too early. Test data shows instances where
  // timers fire even 15ms early. We add a safety margin to prevent flakiness
  // when running this test on affected platforms.
  int safetyMargin = const bool.fromEnvironment('dart.library.js') ? 40 : 0;

  asyncStart();
  var sw = new Stopwatch()..start();
  int nextTick = 1;
  new Timer.periodic(ms * interval, (t) {
    expectGTE(nextTick, t.tick, "tick {1} before expect next tick {0}.");
    nextTick = t.tick + 1; // Always increment tick by at least one.
    int time = sw.elapsedMilliseconds;
    int minTime = interval * t.tick - safetyMargin;
    expectGTE(minTime, time, "Actual time {1} before {0} at tick ${t.tick}");
    if (t.tick > 20) {
      t.cancel();
      asyncEnd();
    }
  });
}
