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
  // Test runZoned with periodic Timer. Still works inside a zone.
  runZoned(() {
    int counter = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      counter++;
      events.add(counter);
      if (counter == 6) {
        timer.cancel();
        done.complete(true);
      }
    });
  });

  done.future.whenComplete(() {
    Expect.listEquals(["main exit", 1, 2, 3, 4, 5, 6], events);
    asyncEnd();
  });
  events.add("main exit");
}
