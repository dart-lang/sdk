// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library exit_at_spawn;

import "dart:isolate";
import "dart:async";
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

// Isolate exiting immediately.
isomain(args) {}

// Isolate exiting after running microtasks.
isomain2(args) {
  scheduleMicrotask(() {});
}

// Isolate exiting after running timers.
isomain3(args) {
  new Timer(Duration.zero, () {});
}

main() {
  asyncStart();

  test(isomain);
  test(isomain2);
  test(isomain3);

  asyncEnd();
}

void test(mainFunction) {
  asyncStart();

  RawReceivePort exitPort = new RawReceivePort();
  exitPort.handler = (message) {
    Expect.equals(null, message);
    exitPort.close();
    asyncEnd();
  };

  // Ignore returned Future.
  Isolate.spawn(mainFunction, null,
      // Setup handler as part of spawn.
      errorsAreFatal: false,
      onExit: exitPort.sendPort);
}
