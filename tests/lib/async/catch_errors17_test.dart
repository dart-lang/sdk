// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';
import 'catch_errors.dart';

main() {
  asyncStart();
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
        .transform(new StreamTransformer(
            handleError: (e, sink) => sink.add("error $e")))
        .listen((x) { events.add("stream $x"); });
    }).listen((x) { events.add(x); })
      .asFuture().then((_) { events.add("inner done"); });
    controller.add(1);
    // Errors are not allowed to traverse boundaries. This error should be
    // caught by the outer catchErrors.
    controller.addError(2);
    controller.close();
  }).listen((x) { events.add("outer: $x"); },
            onDone: () {
              Expect.listEquals(["map 1",
                                 "stream 101",
                                 "outer: 2",
                                 "inner done",
                                ],
                                events);
              asyncEnd();
            });
}
