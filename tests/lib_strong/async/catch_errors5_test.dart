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
  // Test that synchronous *and* asynchronous errors are caught by
  // `catchErrors`.
  catchErrors(() {
    events.add("catch error entry");
    Future errorFuture = new Future.error("future error");
    errorFuture.whenComplete(() => done.complete(true));
    throw "catch error";
  }).listen((x) {
    events.add(x);
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });

  done.future.whenComplete(() {
    // Give some time for the event listener to execute.
    Timer.run(() {
      Expect.listEquals([
        "catch error entry",
        "main exit",
        "catch error",
        "future error",
      ], events);
      asyncEnd();
    });
  });
  events.add("main exit");
}
