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
  var controller = new StreamController();
  // Test that stream errors, as a result of bad user-code (`map`) are correctly
  // caught by `catchErrors`. Note that the values are added outside both
  // `catchErrors`, but since the `listen` happens in the most nested
  // `catchErrors` it is caught there.
  catchErrors(() {
    catchErrors(() {
      controller.stream.map((x) {
        throw x;
      }).listen((x) {
        // Should not happen.
        events.add("bad: $x");
      });
    }).listen((x) {
      events.add("caught: $x");
      if (x == 4) done.complete(true);
    }, onDone: () {
      Expect.fail("Unexpected callback");
    });
  }).listen((x) {
    events.add("outer: $x");
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });

  done.future.whenComplete(() {
    // Give handlers time to run.
    Timer.run(() {
      Expect.listEquals([
        "caught: 1",
        "caught: 2",
        "caught: 3",
        "caught: 4",
      ], events);
      asyncEnd();
    });
  });

  [1, 2, 3, 4].forEach(controller.add);
  controller.close();
}
