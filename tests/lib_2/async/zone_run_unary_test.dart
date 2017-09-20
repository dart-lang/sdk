// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  Completer done = new Completer();
  List events = [];

  bool shouldForward = true;
  Expect.identical(Zone.ROOT, Zone.current);
  Zone forked = Zone.current.fork(specification: new ZoneSpecification(runUnary:
      <R, T>(Zone self, ZoneDelegate parent, Zone origin, R f(arg), T arg) {
    // The zone is still the same as when origin.run was invoked, which
    // is the root zone. (The origin zone hasn't been set yet).
    Expect.identical(Zone.current, Zone.ROOT);
    events.add("forked.run1");
    if (shouldForward) return parent.runUnary(origin, f, (arg as int) + 1);
    return 42 as R;
  }));

  events.add("zone forked");
  Zone expectedZone = forked;
  var result = forked.runUnary((arg) {
    Expect.identical(expectedZone, Zone.current);
    events.add("run closure");
    return arg + 3;
  }, 495);
  Expect.equals(499, result);
  events.add("executed run");

  shouldForward = false;
  result = forked.runUnary<int, int>((arg) {
    Expect.fail("should not be invoked");
  }, 99);
  Expect.equals(42, result);
  events.add("executed run2");

  asyncStart();
  shouldForward = true;
  result = forked.runUnary((arg) {
    Expect.identical(forked, Zone.current);
    events.add("run closure 2");
    scheduleMicrotask(() {
      events.add("run closure 3");
      Expect.identical(forked, Zone.current);
      done.complete(true);
    });
    return -arg - 8;
  }, 490);
  events.add("after nested scheduleMicrotask");
  Expect.equals(-499, result);

  done.future.whenComplete(() {
    Expect.listEquals([
      "zone forked",
      "forked.run1",
      "run closure",
      "executed run",
      "forked.run1",
      "executed run2",
      "forked.run1",
      "run closure 2",
      "after nested scheduleMicrotask",
      "run closure 3"
    ], events);
    asyncEnd();
  });
}
