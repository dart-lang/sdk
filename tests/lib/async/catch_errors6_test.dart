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
  var completer = new Completer();
  var errorHandlerOrDoneHasBeenExecuted = false;
  // Test that `catchErrors` doesn't shut down if a future is never completed.
  catchErrors(() {
    completer.future.then((x) { Expect.fail("should not be executed"); });
  }).listen((x) {
      errorHandlerOrDoneHasBeenExecuted = true;
      Expect.fail("should not be executed (listen)");
    },
    onDone: () {
      errorHandlerOrDoneHasBeenExecuted = true;
      Expect.fail("should not be executed (onDone)");
    });
  Timer.run(() {
    Expect.isFalse(errorHandlerOrDoneHasBeenExecuted);
    port.close();
  });
}
