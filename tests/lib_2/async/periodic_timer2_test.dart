// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  new Timer.periodic(ms * interval, (t) {
    expectGTE(nextTick, t.tick, "tick {1} before expect next tick {0}.");
    nextTick = t.tick + 1; // Always increment tick by at least one.
    int time = sw.elapsedMilliseconds;
    int minTime = interval * t.tick;
    expectGTE(minTime, time, "Actual time {1} before {0} at tick ${t.tick}");
    if (t.tick > 20) {
      t.cancel();
      asyncEnd();
    }
  });
}
