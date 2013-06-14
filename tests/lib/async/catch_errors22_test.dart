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
  bool onDoneWasCalled = false;
  var controller = new StreamController();
  // Test that streams that are never closed keep the `catchError` alive.
  catchErrors(() {
    catchErrors(() {
      controller.stream.map((x) { throw x; }).listen((x) {
        // Should not happen.
        events.add("bad: $x");
      });
    }).listen((x) { events.add("caught: $x"); },
              onDone: () { events.add("done"); });
  }).listen((x) { events.add("outer: $x"); },
            onDone: () { onDoneWasCalled = true; });

  [1, 2, 3, 4].forEach(controller.add);

  new Timer(const Duration(milliseconds: 20), () {
    Expect.isFalse(onDoneWasCalled);
    Expect.listEquals(["caught: 1",
                       "caught: 2",
                       "caught: 3",
                       "caught: 4",
                      ],
                      events);
    port.close();
  });
}
