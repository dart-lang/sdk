// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

import 'catch_errors.dart';

void main() {
  asyncStart();
  Completer done = Completer();

  var events = [];
  // Test that periodic Timers are handled correctly by `catchErrors`.
  catchErrors(() {
    int counter = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (counter == 5) {
        timer.cancel();
        done.complete(true);
      }
      counter++;
      events.add(counter);
    });
  }).listen(
    (x) {
      events.add(x);
    },
    onDone: () {
      Expect.fail("Unexpected callback");
    },
  );

  done.future.whenComplete(() {
    // Give handlers time to run.
    Timer.run(() {
      Expect.listEquals(["main exit", 1, 2, 3, 4, 5, 6], events);
      asyncEnd();
    });
  });

  events.add("main exit");
}
