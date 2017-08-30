// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library run_async_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";

main() {
  // Check that Timers don't run before the async callbacks.
  bool timerCallbackExecuted = false;

  scheduleMicrotask(() {
    Expect.isFalse(timerCallbackExecuted);
  });

  asyncStart();
  Timer.run(() {
    timerCallbackExecuted = true;
    asyncEnd();
  });

  scheduleMicrotask(() {
    Expect.isFalse(timerCallbackExecuted);
  });

  scheduleMicrotask(() {
    // Busy loop.
    var sum = 1;
    var sw = new Stopwatch()..start();
    while (sw.elapsedMilliseconds < 5) {
      sum++;
    }
    if (sum == 0) throw "bad"; // Just to use the result.
    scheduleMicrotask(() {
      Expect.isFalse(timerCallbackExecuted);
    });
  });

  scheduleMicrotask(() {
    Expect.isFalse(timerCallbackExecuted);
  });
}
