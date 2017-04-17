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
  // Test `StreamController.broadcast` streams.
  catchErrors(() {
    catchErrors(() {
      controller = new StreamController.broadcast();

      // Listen to the stream from the inner zone.
      controller.stream.map((x) {
        events.add("map $x");
        return x + 100;
      }).transform(
          new StreamTransformer.fromHandlers(handleError: (e, st, sink) {
        sink.add("error $e");
      })).listen((x) {
        events.add("stream $x");
      });
    })
        .listen((x) {
          events.add(x);
        })
        .asFuture()
        .then((_) {
          Expect.fail("Unexpected callback");
        });

    // Listen to the stream from the outer zone.
    controller.stream.listen((x) {
      events.add("stream2 $x");
    }, onError: (x) {
      events.add("stream2 error $x");
    });

    // Feed the controller.
    controller.add(1);
    controller.addError("inner stream");
    new Future.error("outer error");
    controller.close();
  }).listen((x) {
    events.add("outer: $x");
    if (x == "outer error") done.complete(true);
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });

  done.future.whenComplete(() {
    // Give handlers time to run.
    Timer.run(() {
      Expect.listEquals([
        "map 1",
        "stream 101",
        "stream2 1",
        "stream error inner stream",
        "stream2 error inner stream",
        "outer: outer error",
      ], events);
      asyncEnd();
    });
  });
}
