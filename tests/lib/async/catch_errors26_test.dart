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
  // Test `StreamController.broadcast` streams. Note that the nested listener
  // doesn't see the error, but the outer one does.
  catchErrors(() {
    catchErrors(() {
      controller = new StreamController.broadcast();
      controller.stream
        .map((x) {
          events.add("map $x");
          return x + 100;
        })
        .transform(new StreamTransformer(
            handleError: (e, sink) => sink.add("error $e")))
        .listen((x) { events.add("stream $x"); });
    }).listen((x) { events.add(x); })
      .asFuture().then((_) { Expect.fail("Unexpected callback"); });
    controller.stream.listen((x) { events.add("stream2 $x"); },
                             onError: (x) { events.add("stream2 error $x"); });
    controller.add(1);
    // Errors are not allowed to traverse boundaries, but in this case the
    // first listener of the broadcast stream is in the same error-zone. So
    // this should work.
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
                          "stream2 1",
                          "stream2 error 2",
                          "outer: 2",
                        ],
                        events);
      asyncEnd();
    });
  });
}
