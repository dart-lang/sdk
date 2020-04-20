// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';
import 'catch_errors.dart';

main() {
  asyncStart();
  Completer done = new Completer();

  var events = [];
  // Test runZoned with periodic Timers.
  runZoned(() {
    int counter = 0;
    new Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (counter == 1) {
        timer.cancel();
        done.complete(true);
      }
      counter++;
      events.add(counter);
      throw counter;
    });
  }, onError: (e, [s]) {
    events.add("error: $e");
    Expect.isNotNull(s); // Regression test for http://dartbug.com/33589
  });

  done.future.whenComplete(() {
    Expect.listEquals([
      "main exit",
      1,
      "error: 1",
      2,
      "error: 2",
    ], events);
    asyncEnd();
  });
  events.add("main exit");
}
