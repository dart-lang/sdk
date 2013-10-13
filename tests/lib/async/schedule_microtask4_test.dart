// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library run_async_test;

import 'package:async_helper/async_helper.dart';
import 'dart:async';
import 'dart:isolate';

void startTest(SendPort finishPort, replyPort) {
  int invokedCallbacks = 0;

  for (int i = 0; i < 100; i++) {
    scheduleMicrotask(() {
      invokedCallbacks++;
      if (invokedCallbacks == 100) finishPort.send("done");
      if (i == 50) throw new UnsupportedError("ignore exception");
    });
  }
}

runTest() {
  port.receive(startTest);
}

bool globalErrorHandler(IsolateUnhandledException e) {
  return e.source is UnsupportedError && e.source.message == "ignore exception";
}

main() {
  asyncStart();
  var port = new ReceivePort();
  var timer;
  SendPort otherIsolate = spawnFunction(runTest, globalErrorHandler);
  otherIsolate.send(port.toSendPort());
  port.receive((msg, replyPort) {
    port.close();
    timer.cancel();
    asyncEnd();
  });
  timer = new Timer(const Duration(seconds: 2), () { throw "failed"; });
}
