// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timer_cancel2_test;

import 'dart:async';
import 'package:test/test.dart';

main() {
  // Test that a timeout handler can cancel itself.
  test("timer cancel test 2", () {
    var cancelTimer;

    void cancelHandler(Timer timer) {
      cancelTimer.cancel();
    }

    cancelTimer = new Timer.periodic(
        const Duration(milliseconds: 1), expectAsync(cancelHandler));
  });
}
