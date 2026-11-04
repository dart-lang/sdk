// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

// Verify that Stopwatch and Timer use the same clock in d8, where the preamble
// sets window.dartUseDateNowForTicks and advances Date.now() when timers fire
// while performance.now() tracks real wall-clock time.
void main() {
  asyncStart();
  final stopwatch = Stopwatch()..start();
  Expect.equals(1000, stopwatch.frequency);
  Timer(const Duration(seconds: 1), () {
    stopwatch.stop();
    Expect.isTrue(
      stopwatch.elapsedMilliseconds >= 1000,
      'Expected >= 1000ms elapsed, got ${stopwatch.elapsedMilliseconds}ms',
    );
    asyncEnd();
  });
}
