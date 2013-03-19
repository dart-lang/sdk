// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';
import 'dart:isolate';

var firstFunction;
var finishFunction;

void runFunctions() {
  try {
    firstFunction();
  } catch (e) {
    new Timer(Duration.ZERO, finishFunction);
    throw;
  }
}

void startTest(SendPort finishPort, replyPort) {
  firstFunction = () { throw new RuntimeError("ignore exception"); };
  finishFunction = () { finishPort.send("done"); };
  new Timer(Duration.ZERO, runFunctions);
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
