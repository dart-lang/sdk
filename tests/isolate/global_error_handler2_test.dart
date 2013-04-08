// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'package:expect/expect.dart';
import 'dart:async';
import 'dart:isolate';

runTest() {
  SendPort mainIsolate;
  bool isFirst = true;
  port.receive((msg, replyTo) {
    if (isFirst) {
      mainIsolate = msg;
      isFirst = false;
      throw new RuntimeError("ignore exception");
    }
    Expect.equals("message 2", msg);
    mainIsolate.send("received");
  });
}

bool globalErrorHandler(IsolateUnhandledException e) {
  return e.source is RuntimeError && e.source.message == "ignore exception";
}

main() {
  // Make sure this test doesn't last longer than 2 seconds.
  var timer = new Timer(const Duration(seconds: 2), () { throw "failed"; });

  var port = new ReceivePort();
  SendPort otherIsolate = spawnFunction(runTest, globalErrorHandler);
  otherIsolate.send(port.toSendPort());
  otherIsolate.send("message 2");
  port.receive((msg, replyPort) {
    Expect.equals("received", msg);
    port.close();
    timer.cancel();
  });
}
