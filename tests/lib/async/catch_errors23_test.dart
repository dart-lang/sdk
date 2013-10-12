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
  // Test that errors are not traversing zone boundaries.
  // Note that the first listener of `asBroadcastStream` determines in which
  // zone the subscription lives.
  catchErrors(() {
    catchErrors(() {
      controller = new StreamController();
      stream = controller.stream
        .map((x) {
          events.add("map $x");
          return x + 100;
        })
        .transform(new StreamTransformer.fromHandlers(
            handleError: (e, st, sink) { sink.add("error $e"); }))
        .asBroadcastStream();
      stream.listen((x) { events.add("stream $x"); });
    }).listen((x) { events.add(x); })
      .asFuture().then((_) { Expect.fail("Unexpected callback"); });
    stream.listen((x) { events.add("stream2 $x"); });
    controller.add(1);
    // Errors are not allowed to traverse boundaries. This error should be
    // caught by the outer catchErrors.
    controller.addError(2);
    controller.close();
  }).listen((x) {
                  events.add("outer: $x");
                  if (x == 2) done.complete(true);
                },
            onDone: () { Expect.fail("Unexpected callback"); });

  done.future.whenComplete(() {
    // Give handlers time to run.
    Timer.run(() {
      Expect.listEquals(["map 1",
                        "stream 101",
                        "stream2 101",
                        "outer: 2",
                        ],
                        events);
      asyncEnd();
    });
  });
}
