// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // hang if the callbacks are not invoked and the test will time out.
  var port = new ReceivePort();
  var events = [];
  // Test that nested stream (from `catchErrors`) that is delayed by a future
  // is waited for.
  catchErrors(() {
    catchErrors(() {
      new Future.error(499);
      new Future.delayed(const Duration(milliseconds: 20), () {
        events.add(42);
      });
    }).listen(events.add,
              onDone: () { events.add("done"); });
    throw "foo";
  }).listen((x) { events.add("outer: $x"); },
            onDone: () {
              Expect.listEquals(["outer: foo",
                                 499,
                                 42,
                                 "done",
                                ],
                                events);
              port.close();
            });
}
