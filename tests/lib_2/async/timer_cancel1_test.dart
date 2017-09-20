// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timer_cancel1_test;

import 'dart:async';
import 'package:test/test.dart';

main() {
  // Test that a timeout handler can cancel another.
  test("timer cancel1 test", () {
    var canceleeTimer;
    var cancelerTimer;

    void unreachable() {
      fail("A canceled timeout handler should be unreachable.");
    }

    void handler() {
      canceleeTimer.cancel();
    }

    cancelerTimer =
        new Timer(const Duration(milliseconds: 1), expectAsync(handler));
    canceleeTimer = new Timer(
        const Duration(milliseconds: 1000), expectAsync(unreachable, count: 0));
  });
}
