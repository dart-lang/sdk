// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  Completer done = new Completer();
  List events = [];

  // runGuarded calls run, captures the synchronous error (if any) and
  // gives that one to handleUncaughtError.

  var result;

  Expect.identical(Zone.ROOT, Zone.current);
  Zone forked;
  forked = Zone.current.fork(
      specification: new ZoneSpecification(
          run: <R>(Zone self, ZoneDelegate parent, Zone origin, R f()) {
    // The zone is still the same as when origin.run was invoked, which
    // is the root zone. (The origin zone hasn't been set yet).
    Expect.identical(Zone.ROOT, Zone.current);
    events.add("forked.run");
    return parent.run(origin, f);
  }, handleUncaughtError:
              (Zone self, ZoneDelegate parent, Zone origin, error, stackTrace) {
    Expect.identical(Zone.ROOT, Zone.current);
    Expect.identical(forked, origin);
    events.add("forked.handleUncaught $error");
    result = 499;
  }));

  forked.runGuarded(() {
    events.add("runGuarded 1");
    Expect.identical(forked, Zone.current);
    result = 42;
  });
  Expect.identical(Zone.ROOT, Zone.current);
  Expect.equals(42, result);
  events.add("after runGuarded 1");

  result = null;
  forked.runGuarded(() {
    events.add("runGuarded 2");
    Expect.identical(forked, Zone.current);
    throw 42;
  });
  Expect.equals(499, result);

  Expect.listEquals([
    "forked.run",
    "runGuarded 1",
    "after runGuarded 1",
    "forked.run",
    "runGuarded 2",
    "forked.handleUncaught 42"
  ], events);

  result = null;
  events.clear();
  asyncStart();
  forked.runGuarded(() {
    Expect.identical(forked, Zone.current);
    events.add("run closure");
    forked.scheduleMicrotask(() {
      events.add("run closure 2");
      Expect.identical(forked, Zone.current);
      done.complete(true);
      throw 88;
    });
    throw 1234;
  });
  events.add("after nested scheduleMicrotask");
  Expect.equals(499, result);

  done.future.whenComplete(() {
    Expect.listEquals([
      "forked.run",
      "run closure",
      "forked.handleUncaught 1234",
      "after nested scheduleMicrotask",
      "forked.run",
      "run closure 2",
      "forked.handleUncaught 88"
    ], events);
    asyncEnd();
  });
}
