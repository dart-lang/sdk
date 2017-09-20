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
  forked = Zone.current.fork(specification: new ZoneSpecification(fork:
      (Zone self, ZoneDelegate parent, Zone origin,
          ZoneSpecification zoneSpecification, Map mapValues) {
    // The zone is still the same as when origin.run was invoked, which
    // is the root zone. (The origin zone hasn't been set yet).
    Expect.identical(Zone.ROOT, Zone.current);
    events.add("forked.fork");
    Function descriptionRun = zoneSpecification.run;
    ZoneSpecification modified = new ZoneSpecification.from(zoneSpecification,
        run: <R>(self, parent, origin, R f()) {
      events.add("wrapped run");
      return descriptionRun<R>(self, parent, origin, () {
        events.add("wrapped f");
        return f();
      });
    });
    return parent.fork(origin, modified, mapValues);
  }));

  events.add("start");
  Zone forkedChild = forked.fork(specification: new ZoneSpecification(
      run: <R>(Zone self, ZoneDelegate parent, Zone origin, R f()) {
    events.add("executing child run");
    return parent.run(origin, f);
  }));

  events.add("after child fork");
  Expect.identical(Zone.ROOT, Zone.current);

  forkedChild.run(() {
    events.add("child run");
  });

  events.add("after child run");

  Expect.listEquals([
    "start",
    "forked.fork",
    "after child fork",
    "wrapped run",
    "executing child run",
    "wrapped f",
    "child run",
    "after child run"
  ], events);
}
