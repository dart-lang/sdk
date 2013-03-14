// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test merging streams.
library dart.test.stream_from_iterable;

import "dart:async";
import '../../../pkg/unittest/lib/unittest.dart';

main() {
  test("stream-periodic3", () {
    Stopwatch watch = new Stopwatch()..start();
    Stream stream = new Stream.periodic(const Duration(milliseconds: 1),
                                        (x) => x);
    stream.take(10).listen((_) { }, onDone: expectAsync0(() {
      int microsecs = watch.elapsedMicroseconds;
      // Give it some slack. The Stopwatch is more precise than the timers.
      int millis = (microsecs + 200) ~/ 1000;
      expect(millis, greaterThan(10));
    }));
  });
}
