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
  // Test that errors do not cross zone boundaries.
  catchErrors(() {
    catchErrors(() {
      controller = new StreamController();
      controller.stream
        .map((x) {
          events.add("map $x");
          return x + 100;
        })
        .transform(new StreamTransformer.fromHandlers(
            handleError: (e, st, sink) { sink.add("error $e"); }))
        .listen((x) { events.add("stream $x"); });
    }).listen((x) { events.add(x); });
    controller.add(1);
    controller.addError(2);
    new Future.error("outer error");
    controller.close();
  }).listen((x) {
              events.add("outer: $x");
              if (x == "outer error") done.complete(true);
            }, onDone: () { Expect.fail("Unexpected callback"); });

  done.future.whenComplete(() {
    Timer.run(() {
      Expect.listEquals(["map 1",
                         "stream 101",
                         "stream error 2",
                         "outer: outer error",
                        ],
                        events);
      asyncEnd();
    });
  });
}
