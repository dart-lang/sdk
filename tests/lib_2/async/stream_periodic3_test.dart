// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test merging streams.
library dart.test.stream_from_iterable;

import 'dart:async';

import 'package:unittest/unittest.dart';

// The stopwatch is more precise than the Timer.
// Some browsers (Firefox and IE so far) can trigger too early. So we add more
// margin. We use identical(1, 1.0) as an easy way to know if the test is
// compiled by dart2js.
int get safetyMargin => identical(1, 1.0) ? 5 : 0;

main() {
  test("stream-periodic3", () {
    Stopwatch watch = new Stopwatch()..start();
    Stream stream =
        new Stream.periodic(const Duration(milliseconds: 1), (x) => x);
    stream.take(10).listen((_) {}, onDone: expectAsync(() {
      int millis = watch.elapsedMilliseconds + safetyMargin;
      expect(millis, greaterThanOrEqualTo(10));
    }));
  });
}
