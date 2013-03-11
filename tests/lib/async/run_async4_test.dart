// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library run_async_test;

import 'dart:async';
import 'dart:isolate';

void startTest(SendPort finishPort, replyPort) {
  int invokedCallbacks = 0;

  for (int i = 0; i < 100; i++) {
    runAsync(() {
      invokedCallbacks++;
      if (invokedCallbacks == 100) finishPort.send("done");
      if (i == 50) throw new RuntimeError("ignore exception");
    });
  }
}

runTest() {
  port.receive(startTest);
}

bool globalErrorHandler(IsolateUnhandledException e) {
  return e.source is RuntimeError && e.source.message == "ignore exception";
}

main() {
  var port = new ReceivePort();
  var timer;
  SendPort otherIsolate = spawnFunction(runTest, globalErrorHandler);
  otherIsolate.send(port.toSendPort());
  port.receive((msg, replyPort) { port.close(); timer.cancel(); });
  timer = new Timer(const Duration(seconds: 2), () { throw "failed"; });
}
