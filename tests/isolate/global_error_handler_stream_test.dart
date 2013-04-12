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

void startTest(EventSink finishSink) {
  firstFunction = () { throw new RuntimeError("ignore exception"); };
  finishFunction = () { finishSink.add("done"); finishSink.close(); };
  new Timer(Duration.ZERO, runFunctions);
}

runTest() {
  stream.single.then(startTest);
}

bool globalErrorHandler(IsolateUnhandledException e) {
  return e.source is RuntimeError && e.source.message == "ignore exception";
}

main() {
  var box = new MessageBox();
  var timer;
  EventSink otherIsolate = streamSpawnFunction(runTest, globalErrorHandler);
  otherIsolate.add(box.sink);
  otherIsolate.close();
  box.stream.single.then((msg) {
    box.stream.close();
    timer.cancel();
  });
  timer = new Timer(const Duration(seconds: 2), () { throw "failed"; });
}
