// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';
import 'dart:isolate';

runTest() {
  IsolateSink mainIsolate;
  stream.listen((msg) {
    mainIsolate = msg;
    throw new RuntimeError("ignore exception");
  }, onDone: () {
    mainIsolate.add("received done");
    mainIsolate.close();
  });
}

bool globalErrorHandler(IsolateUnhandledException e) {
  var source = e.source;
  if (source is AsyncError) {
    source = source.error;
  }
  return source is RuntimeError && source.message == "ignore exception";
}

main() {
  // Make sure this test doesn't last longer than 2 seconds.
  var timer = new Timer(const Duration(seconds: 2), () { throw "failed"; });

  var box = new MessageBox();
  IsolateSink otherIsolate = streamSpawnFunction(runTest, globalErrorHandler);
  otherIsolate.add(box.sink);
  otherIsolate.close();
  box.stream.single.then((msg) {
    Expect.equals("received done", msg);
    timer.cancel();
  });
}
