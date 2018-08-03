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
  });
  return 499;
}

handler(fun) {
  events.add("handler");
  scheduleMicrotask(fun);
  events.add("handler done");
}

main() {
  asyncStart();

  // Test that scheduleMicrotask inside the scheduleMicrotask-handler goes to
  // the parent zone.
  var result = runZonedScheduleMicrotask(body, onScheduleMicrotask: handler);
  events.add("after");
  scheduleMicrotask(() {
    Expect.listEquals(
        ["body entry", "handler", "handler done", "after", "run async body"],
        events);
    asyncEnd();
  });
}
