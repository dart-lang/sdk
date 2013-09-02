// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

var events = [];

body() {
  events.add("body entry");
  runAsync(() {
    events.add("run async body");
    runAsync(() {
      events.add("run nested body");
    });
  });
  return 499;
}

handler(fun) {
  events.add("handler");
  runAsync(fun);
  events.add("handler done");
}

handler2(fun) {
  events.add("handler2");
  runAsync(fun);
  events.add("handler2 done");
}

main() {
  asyncStart();

  // Test that nested runZonedExperimental go to the next outer zone.
  var result = runZonedExperimental(
      () => runZonedExperimental(body, onRunAsync: handler2),
      onRunAsync: handler);
  events.add("after");
  Timer.run(() {
    Expect.listEquals(
        ["body entry",
         "handler2", "handler", "handler done", "handler2 done",
         "after",
         "run async body",
         "handler2", "handler", "handler done", "handler2 done",
         "run nested body"],
        events);
    asyncEnd();
 });
}
