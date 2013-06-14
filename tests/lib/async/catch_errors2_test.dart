// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // time out if the callbacks are not invoked.
  var port = new ReceivePort();
  bool futureWasExecuted = false;
  // Make sure that `catchErrors` only closes the error stream when the inner
  // futures are done.
  catchErrors(() {
    new Future(() {
      futureWasExecuted = true;
    });
    return 'allDone';
  }).listen((x) {
      Expect.fail("Unexped callback");
    },
    onDone: () {
      Expect.isTrue(futureWasExecuted);
      port.close();
    });
}
