// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that no wakeups are being dropped if we cancel timers.
// WARNING: For this test to work it cannot rely on any other async features
// and will just timeout if it is failing.

library timer_regress22626_test;

import 'dart:async';
import 'dart:math';
import 'package:expect/expect.dart';

int countdown = 5;
var rng = new Random(1234);

void test(int delay, int delta) {
  var t0 = new Timer(new Duration(milliseconds: delay + delta),
      () => Expect.fail("should have been cancelled by now"));
  new Timer(Duration.zero, () => t0.cancel());
  new Timer(
      Duration.zero,
      () => new Timer(new Duration(milliseconds: delay), () {
            if (--countdown == 0) {
              print("done");
            } else {
              test(delay, max(0, delta + rng.nextInt(2) - 1));
            }
          }));
}

void main() {
  test(200, 2);
}
