// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';
import 'catch_errors.dart';

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // hang if the callbacks are not invoked and the test will time out.
  var port = new ReceivePort();
  bool futureWasExecuted = false;
  // Test that `catchErrors` waits for a future that has been delayed by
  // `Timer.run`.
  catchErrors(() {
    Timer.run(() {
      new Future.value(499).then((x) {
        futureWasExecuted = true;
      });
    });
    return 'allDone';
  }).listen((x) {
      Expect.fail("Unexpected callback");
    },
    onDone: () {
      Expect.isTrue(futureWasExecuted);
      port.close();
    });
}
