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
  // Test that streams live in the zone they have been listened too.
  // It doesn't matter how many zone-boundaries the stream traverses. What
  // counts is the zone where `listen` was invoked.
  catchErrors(() {
    catchErrors(() {
      controller = new StreamController();

      // Assignment to "global" `stream`.
      stream = controller.stream
        .map((x) {
          events.add("map $x");
          return x + 100;
        })
        .asBroadcastStream();

      // Consume stream in the nested zone.
      stream
        .transform(new StreamTransformer.fromHandlers(
            handleError: (e, st, sink) { sink.add("error $e"); }))
        .listen((x) { events.add("stream $x"); });

      // Feed the controller in the nested zone.
      scheduleMicrotask(() {
        controller.add(1);
        controller.addError(2);
        controller.close();
        new Future.error("done");
      });

    }).listen((x) {
                events.add("listen: $x");
                if (x == "done") done.complete(true);
              })
      .asFuture().then((_) { Expect.fail("Unexpected callback"); });

    // Listen to stream in outer zone.
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
                         "listen: done",
                         "outer: 2",
                        ],
                        events);
      asyncEnd();
    });
  });
}
