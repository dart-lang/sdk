// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  Completer done = new Completer();
  List events = [];

  Expect.identical(Zone.ROOT, Zone.current);
  Zone forked;
  forked = Zone.current.fork(specification: new ZoneSpecification(
      createPeriodicTimer: (Zone self, ZoneDelegate parent, Zone origin,
          Duration period, f(Timer timer)) {
    events.add("forked.createPeriodicTimer");
    return parent.createPeriodicTimer(origin, period, (Timer timer) {
      events.add("wrapped function ${period.inMilliseconds}");
      f(timer);
    });
  }));

  asyncStart();
  int tickCount = 0;
  forked.run(() {
    new Timer.periodic(const Duration(milliseconds: 5), (Timer timer) {
      events.add("periodic Timer $tickCount");
      Expect.identical(forked, Zone.current);
      tickCount++;
      if (tickCount == 4) {
        timer.cancel();
        // Allow some time in case the cancel didn't work.
        new Timer(const Duration(milliseconds: 20), done.complete);
      }
    });
  });

  Expect.identical(Zone.ROOT, Zone.current);
  events.add("after createPeriodicTimer");

  done.future.whenComplete(() {
    Expect.listEquals([
      "forked.createPeriodicTimer",
      "after createPeriodicTimer",
      "wrapped function 5",
      "periodic Timer 0",
      "wrapped function 5",
      "periodic Timer 1",
      "wrapped function 5",
      "periodic Timer 2",
      "wrapped function 5",
      "periodic Timer 3"
    ], events);
    asyncEnd();
  });
}
