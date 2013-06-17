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
  StreamController controller;
  Stream stream;
  // Test that the first listen on a `asBroadcastStream` determines the
  // zone the subscription lives in. The inner listen happens first, and
  // the outer listener must not see the error since it would cross a
  // zone boundary. It is therefore given to the inner `catchErrors`.
  catchErrors(() {
    catchErrors(() {
      controller = new StreamController();
      stream = controller.stream
        .map((x) {
          events.add("map $x");
          return x + 100;
        })
        .asBroadcastStream();
      stream
        .transform(new StreamTransformer(
            handleError: (e, sink) => sink.add("error $e")))
        .listen((x) { events.add("stream $x"); });
      runAsync(() {
        controller.add(1);
        // Errors are not allowed to traverse boundaries, but in this case the
        // first listener of the broadcast stream is in the same error-zone. So
        // this should work.
        controller.addError(2);
        controller.close();
      });
    }).listen((x) { events.add(x); })
      .asFuture().then((_) { events.add("inner done"); });
    stream.listen((x) { events.add("stream2 $x"); });
  }).listen((x) { events.add("outer: $x"); },
            onDone: () {
              Expect.listEquals(["map 1",
                                 "stream 101",
                                 "stream2 101",
                                 "stream error 2",
                                 2, // Caught by the inner `catchErrors`.
                                 "inner done",
                                ],
                                events);
              port.close();
            });
}
