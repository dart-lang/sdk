// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library run_async_test;

import 'dart:async';
import 'package:test/test.dart';

main() {
  test("run async timer after async test", () {
    // Check that Timers don't run before the async callbacks.
    bool timerCallbackExecuted = false;

    scheduleMicrotask(expectAsync(() {
      expect(timerCallbackExecuted, isFalse);
    }));

    Timer.run(expectAsync(() { timerCallbackExecuted = true; }));

    scheduleMicrotask(expectAsync(() {
      expect(timerCallbackExecuted, isFalse);
    }));

    scheduleMicrotask(expectAsync(() {
      // Busy loop.
      var sum = 1;
      var sw = new Stopwatch()..start();
      while (sw.elapsedMilliseconds < 5) {
        sum++;
      }
      if (sum == 0) throw "bad";  // Just to use the result.
      scheduleMicrotask(expectAsync(() {
        expect(timerCallbackExecuted, isFalse);
      }));
    }));

    scheduleMicrotask(expectAsync(() {
      expect(timerCallbackExecuted, isFalse);
    }));
  });
}
