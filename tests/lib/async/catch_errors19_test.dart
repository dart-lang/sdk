// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // hang if the callbacks are not invoked and the test will time out.
  var port = new ReceivePort();
  var events = [];
  Stream stream = new Stream.periodic(const Duration(milliseconds: 20),
                                      (x) => x);
  // Test that asynchronous callbacks in the done-handler of streams (here
  // the `catchErrors`-stream) keep a zone alive.
  catchErrors(() {
    var subscription;
    subscription = stream.take(5).listen((x) {
      events.add(x);
    }, onDone: () {
      new Future.delayed(const Duration(milliseconds: 30), () {
        events.add(499);
      });
    });
  }).listen((x) { events.add("outer: $x"); },
            onDone: () {
              Expect.listEquals([0, 1, 2, 3, 4, 499], events);
              port.close();
            });
}
