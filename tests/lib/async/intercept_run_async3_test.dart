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
  });
  return 499;
}

handler(fun) {
  events.add("handler");
  runAsync(fun);
  events.add("handler done");
}

main() {
  asyncStart();

  // Test that runAsync inside the runAsync-handler goes to the parent zone.
  var result = runZonedExperimental(body, onRunAsync: handler);
  events.add("after");
  runAsync(() {
    Expect.listEquals(
        ["body entry", "handler", "handler done", "after", "run async body"],
        events);
    asyncEnd();
  });
}
