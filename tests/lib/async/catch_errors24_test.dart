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
  // zone the subscription lives in. In this case the outer listen happens first
  // and the error reaches `handleError`.
  catchErrors(() {
    catchErrors(() {
      controller = new StreamController();
      stream = controller.stream
        .map((x) {
          events.add("map $x");
          return x + 100;
        })
        .transform(new StreamTransformer(
            handleError: (e, sink) => sink.add("error $e")))
        .asBroadcastStream();
      runAsync(() {
        stream.listen((x) {
          events.add("stream $x");
          if (x == "error 2") done.complete(true);
        });
      });
    }).listen((x) { events.add(x); })
      .asFuture().then((_) { Expect.fail("Unexpected callback"); });
    stream.listen((x) { events.add("stream2 $x"); });
    runAsync(() {
      controller.add(1);
      // Errors are not allowed to traverse boundaries, but in this case the
      // first listener of the broadcast stream is in the same error-zone. So
      // this should work.
      controller.addError(2);
      controller.close();
    });
  }).listen((x) { events.add("outer: $x"); },
            onDone: () { Expect.fail("Unexpected callback"); });

  done.future.whenComplete(() {
    // Give handlers time to complete.
    Timer.run(() {
      Expect.listEquals(["map 1",
                          "stream2 101",
                          "stream 101",
                          "stream2 error 2",
                          "stream error 2",
                        ],
                        events);
      asyncEnd();
    });
  });
}
