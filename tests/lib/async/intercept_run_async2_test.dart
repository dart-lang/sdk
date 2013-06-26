// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  fun();
  events.add("handler done");
}

main() {
  // Test that runAsync interception works.
  var result = runZonedExperimental(body, onRunAsync: handler);
  // No need for a ReceivePort: If the runZonedExperimental disbehaved we
  // would have an [events] list that is different from what we expect.
  Expect.listEquals(["body entry", "handler", "run async body", "handler done"],
                    events);
}
