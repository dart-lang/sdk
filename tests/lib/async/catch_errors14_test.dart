// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';
import 'catch_errors.dart';

main() {
  asyncStart();
  var events = [];
  // Test that periodic Timers are handled correctly by `catchErrors`.
  catchErrors(() {
    int counter = 0;
    new Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (counter++ == 5) timer.cancel();
      throw "error $counter";
    });
  }).listen((x) {
      events.add(x);
    },
    onDone: () {
      Expect.listEquals([
                         "main exit",
                         "error 1",
                         "error 2",
                         "error 3",
                         "error 4",
                         "error 5",
                         "error 6",
                         ],
                         events);
      asyncEnd();
    });
  events.add("main exit");
}
