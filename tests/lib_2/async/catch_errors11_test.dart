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
  // Test that `catchErrors` catches errors that are delayed by `Timer.run`.
  catchErrors(() {
    events.add("catch error entry");
    new Future.error("future error");
    Timer.run(() {
      done.complete(true);
      throw "timer error";
    });
  }).listen((x) {
    events.add(x);
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });

  done.future.whenComplete(() {
    // Give the handler time to execute.
    Timer.run(() {
      Expect.listEquals([
        "catch error entry",
        "main exit",
        "future error",
        "timer error",
      ], events);
      asyncEnd();
    });
  });
  events.add("main exit");
}
