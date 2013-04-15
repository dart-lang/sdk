// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'package:expect/expect.dart';
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
  return source is RuntimeError && source.message == "ignore exception";
}

main() {
  var keepRunningBox = new MessageBox();
  // Make sure this test doesn't last longer than 2 seconds.
  var timer = new Timer(const Duration(seconds: 2), () { throw "failed"; });

  var box = new MessageBox();
  IsolateSink otherIsolate = streamSpawnFunction(runTest, globalErrorHandler);
  otherIsolate.add(box.sink);
  // The previous event should have been handled entirely, but the current
  // implementations don't guarantee that and might mix the done event with
  // the handling of the previous event. We therefore delay the closing.
  // Note: if the done is sent too early it won't lead to failing tests, but
  // just won't make sure that the globalErrorHandler works.
  new Timer(const Duration(milliseconds: 10), otherIsolate.close);
  box.stream.single.then((msg) {
    Expect.equals("received done", msg);
    timer.cancel();
    keepRunningBox.stream.close();
  });
}
