// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';
import 'catch_errors.dart';

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // hang if the callbacks are not invoked and the test will time out.
  var port = new ReceivePort();
  var events = [];
  // Test that asynchronous errors are caught.
  catchErrors(() {
    events.add("catch error entry");
    new Future.error("future error");
    new Future.error("future error2");
    new Future.value(499).then((x) => throw x);
    throw "catch error";
  }).listen((x) {
      events.add(x);
    },
    onDone: () {
      Expect.listEquals(
          ["catch error entry",
           "main exit",
           "catch error",
           "future error",
           "future error2",
           499,
          ],
          events);
      port.close();
    });
  events.add("main exit");
}
