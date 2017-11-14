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
  forked = Zone.current.fork(specification: new ZoneSpecification(createTimer:
      (Zone self, ZoneDelegate parent, Zone origin, Duration duration, f()) {
    events.add("forked.createTimer");
    return parent.createTimer(origin, duration, () {
      events.add("wrapped function ${duration.inMilliseconds}");
      f();
    });
  }));

  asyncStart();
  forked.run(() {
    new Timer(Duration.ZERO, () {
      events.add("createTimer");
      Expect.identical(forked, Zone.current);
      done.complete(true);
    });
  });

  Expect.identical(Zone.ROOT, Zone.current);
  events.add("after createTimer");

  done.future.whenComplete(() {
    Expect.listEquals([
      "forked.createTimer",
      "after createTimer",
      "wrapped function 0",
      "createTimer"
    ], events);
    asyncEnd();
  });
}
