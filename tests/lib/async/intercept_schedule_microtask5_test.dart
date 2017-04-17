// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';
import 'catch_errors.dart';

var events = [];

body() {
  events.add("body entry");
  scheduleMicrotask(() {
    events.add("run async body");
    scheduleMicrotask(() {
      events.add("run nested body");
    });
  });
  return 499;
}

handler(fun) {
  events.add("handler");
  scheduleMicrotask(fun);
  events.add("handler done");
}

handler2(fun) {
  events.add("handler2");
  scheduleMicrotask(fun);
  events.add("handler2 done");
}

main() {
  asyncStart();

  // Test that nested runZonedScheduleMicrotask go to the next outer zone.
  var result = runZonedScheduleMicrotask(
      () => runZonedScheduleMicrotask(body, onScheduleMicrotask: handler2),
      onScheduleMicrotask: handler);
  events.add("after");
  Timer.run(() {
    Expect.listEquals([
      "body entry",
      "handler2",
      "handler",
      "handler done",
      "handler2 done",
      "after",
      "run async body",
      "handler2",
      "handler",
      "handler done",
      "handler2 done",
      "run nested body"
    ], events);
    asyncEnd();
  });
}
