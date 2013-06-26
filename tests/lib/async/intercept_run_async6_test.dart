// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';

class A {
  add(x) => print(x);
}
var events = [];

body() {
  events.add("body entry");
  runAsync(() {
    events.add("run async body");
    throw "foo";
  });
  return 499;
}

onAsyncHandler(fun) {
  events.add("async handler");
  runAsync(fun);
  events.add("async handler done");
}

onErrorHandler(e) {
  events.add("error: $e");
}

onDoneHandler() {
  events.add("done");
}

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // hang if the callbacks are not invoked and the test will time out.
  var port = new ReceivePort();

  // Test that runZonedExperimental works when async, error and done are used.
  var result = runZonedExperimental(
      body,
      onRunAsync: onAsyncHandler,
      onError: onErrorHandler,
      onDone: onDoneHandler);
  events.add("after");
  Timer.run(() {
    Expect.listEquals(
        ["body entry",
         "async handler", "async handler done",
         "after",
         "run async body",
         "error: foo",
         "done"],
        events);
    port.close();
 });
}
