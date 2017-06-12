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
  // Tests that errors that have been delayed by several milliseconds with
  // Timers are still caught by `catchErrors`.
  catchErrors(() {
    events.add("catch error entry");
    Timer.run(() {
      throw "timer error";
    });
    new Timer(const Duration(milliseconds: 100), () {
      throw "timer2 error";
    });
    new Future.value(499).then((x) {
      new Timer(const Duration(milliseconds: 200), () {
        done.complete(499);
        throw x;
      });
    });
    throw "catch error";
  }).listen((x) {
    events.add(x);
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });
  done.future.whenComplete(() {
    // Give time to execute the callbacks.
    Timer.run(() {
      Expect.listEquals([
        "catch error entry",
        "main exit",
        "catch error",
        "timer error",
        "timer2 error",
        499,
      ], events);
      asyncEnd();
    });
  });
  events.add("main exit");
}
