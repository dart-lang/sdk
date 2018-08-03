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
  // Test that nested stream (from `catchErrors`) that is delayed by a future
  // is waited for.
  catchErrors(() {
    catchErrors(() {
      new Future.error(499);
      new Future.delayed(const Duration(milliseconds: 20), () {
        events.add(42);
        done.complete(true);
      });
    }).listen(events.add, onDone: () {
      events.add("done");
    });
    throw "foo";
  }).listen((x) {
    events.add("outer: $x");
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });

  done.future.whenComplete(() {
    // Give handlers time to run.
    Timer.run(() {
      Expect.listEquals([
        "outer: foo",
        499,
        42,
      ], events);
      asyncEnd();
    });
  });
}
