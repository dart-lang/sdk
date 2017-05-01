// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  fun();
  events.add("handler done");
}

main() {
  // Test that scheduleMicrotask interception works.
  var result = runZonedScheduleMicrotask(body, onScheduleMicrotask: handler);
  // No need for a ReceivePort: If the runZonedScheduleMicrotask misbehaved we
  // would have an [events] list that is different from what we expect.
  Expect.listEquals(
      ["body entry", "handler", "run async body", "handler done"], events);
}
