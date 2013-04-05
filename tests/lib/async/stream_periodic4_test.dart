// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test merging streams.
library dart.test.stream_from_iterable;

import "dart:async";
import '../../../pkg/unittest/lib/unittest.dart';

int iteration = 0;

void runTest(period, maxElapsed, pauseDuration) {
  print("Iteration: $iteration");
  var myIteration = iteration;
  iteration++;

  Function done = expectAsync0(() { });

  Stopwatch watch = new Stopwatch()..start();
  Stream stream = new Stream.periodic(period, (x) => x);
  var subscription;
  subscription = stream.take(5).listen((i) {
    if (watch.elapsed > maxElapsed) {
      // Test failed in this configuration. Try with more time (or give up
      // if we reached an unreasonable maxElapsed).
      if (maxElapsed > const Duration(seconds: 2)) {
        // Give up.
        expect(true, false);
      } else {
        subscription.cancel();
        print("Cancelling subscription of iteration: $myIteration");
        // Call 'done' ourself, since it won't be invoked in the onDone handler.
        runTest(period * 2, maxElapsed * 2, pauseDuration * 2);
        print("Invoking done of iteration inside listener: $myIteration");
        done();
        return;
      }
    }
    watch.reset();
    if (i == 2) {
      subscription.pause();
      watch.stop();
      new Timer(pauseDuration, () {
        watch.start();
        subscription.resume();
      });
    }
  }, onDone: () {
    print("Invoking done of iteration: $myIteration");
    done();
  });
}

main() {
  test("stream-periodic4", () {
    runTest(const Duration(milliseconds: 2),
            const Duration(milliseconds: 8),
            const Duration(milliseconds: 10));
  });
}
