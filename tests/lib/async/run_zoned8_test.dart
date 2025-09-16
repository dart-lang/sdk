// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

void main() {
  asyncStart();
  Completer done = Completer();

  var events = [];
  // Test runZonedGuarded with periodic Timer. Throw in timer callback.
  runZonedGuarded(
    () {
      int counter = 0;
      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        counter++;
        events.add(counter);
        if (counter == 2) {
          timer.cancel();
          done.complete(true);
        }
        throw counter;
      });
    },
    (e, [StackTrace? s]) {
      events.add("error: $e");
      Expect.isNotNull(s); // Regression test for http://dartbug.com/33589
    },
  );

  done.future.whenComplete(() {
    Expect.listEquals(["main exit", 1, "error: 1", 2, "error: 2"], events);
    asyncEnd();
  });
  events.add("main exit");
}
