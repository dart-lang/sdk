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
  // Test that periodic Timers are handled correctly by `catchErrors`.
  catchErrors(() {
    int counter = 0;
    new Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (counter == 5) timer.cancel();
      counter++;
      events.add(counter);
    });
  }).listen((x) {
      events.add(x);
    },
    onDone: () {
      Expect.listEquals([
                         "main exit",
                         1, 2, 3, 4, 5, 6,
                         ],
                         events);
      port.close();
    });
  events.add("main exit");
}
