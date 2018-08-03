// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test merging streams.
library dart.test.stream_from_iterable;

import 'dart:async';

import 'package:unittest/unittest.dart';

watchMs(Stopwatch watch) {
  int microsecs = watch.elapsedMicroseconds;
  // Give it some slack. The Stopwatch is more precise than the timers. This
  // means that we sometimes get 3995 microseconds instead of 4+ milliseconds.
  // 200 microseconds should largely account for this discrepancy.
  return (microsecs + 200) ~/ 1000;
}

main() {
  test("stream-periodic4", () {
    Stream stream =
        new Stream.periodic(const Duration(milliseconds: 5), (x) => x);
    Stopwatch watch = new Stopwatch()..start();
    var subscription;
    subscription = stream.take(10).listen((i) {
      int ms = watchMs(watch);
      watch.reset();
      if (i == 2) {
        Stopwatch watch2 = new Stopwatch()..start();
        // Busy wait.
        while (watch2.elapsedMilliseconds < 15) {}
        // Make sure the stream can be paused when it has overdue events.
        // We just busy waited for 15ms, even though the stream is supposed to
        // emit events every 5ms.
        subscription.pause();
        watch.stop();
        new Timer(const Duration(milliseconds: 150), () {
          watch.start();
          subscription.resume();
        });
      }
    }, onDone: expectAsync(() {}));
  });
}
