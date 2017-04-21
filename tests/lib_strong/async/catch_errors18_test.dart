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
  Stream stream =
      new Stream.periodic(const Duration(milliseconds: 20), (x) => x);
  // Test that errors of periodic streams are caught.
  catchErrors(() {
    var subscription;
    subscription = stream.listen((x) {
      if (x == 5) {
        events.add("cancel");
        subscription.cancel();
        done.complete(true);
        return;
      }
      events.add(x);
    });
  }).listen((x) {
    events.add("outer: $x");
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });

  done.future.whenComplete(() {
    // Give handlers time to run.
    Timer.run(() {
      Expect.listEquals([0, 1, 2, 3, 4, "cancel"], events);
      asyncEnd();
    });
  });
}
