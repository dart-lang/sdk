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
  // Tests that errors that have been delayed by several milliseconds with
  // Timers are still caught by `catchErrors`.
  catchErrors(() {
    events.add("catch error entry");
    Timer.run(() { throw "timer error"; });
    new Timer(const Duration(milliseconds: 100), () { throw "timer2 error"; });
    new Future.value(499).then((x) {
      new Timer(const Duration(milliseconds: 200), () { throw x; });
    });
    throw "catch error";
  }).listen((x) {
      events.add(x);
    },
    onDone: () {
      Expect.listEquals([
            "catch error entry",
            "main exit",
            "catch error",
            "timer error",
            "timer2 error",
            499,
          ],
          events);
      port.close();
    });
  events.add("main exit");
}
