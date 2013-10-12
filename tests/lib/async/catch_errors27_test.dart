// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';
import 'catch_errors.dart';

main() {
  asyncStart();
  Completer done = new Completer();

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
        .transform(new StreamTransformer.fromHandlers(
            handleError: (e, st, sink) { sink.add("error $e"); }))
        .listen((x) { events.add("stream $x"); });
      scheduleMicrotask(() {
        controller.add(1);
        // Errors are not allowed to traverse boundaries, but in this case the
        // first listener of the broadcast stream is in the same error-zone. So
        // this should work.
        controller.addError(2);
        controller.close();
      });
    }).listen((x) {
                events.add(x);
                if (x == 2) done.complete(true);
              })
      .asFuture().then((_) { Expect.fail("Unexpected callback"); });
    stream.listen((x) { events.add("stream2 $x"); });
  }).listen((x) { events.add("outer: $x"); },
            onDone: () { Expect.fail("Unexpected callback"); });

  done.future.whenComplete(() {
    // Give handlers time to run.
    Timer.run(() {
      Expect.listEquals(["map 1",
                          "stream 101",
                          "stream2 101",
                          "stream error 2",
                          2, // Caught by the inner `catchErrors`.
                        ],
                        events);
      asyncEnd();
    });
  });
}
