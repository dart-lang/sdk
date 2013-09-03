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
  // Test that asynchronous errors are caught.
  catchErrors(() {
    events.add("catch error entry");
    new Future.error("future error");
    new Future.error("future error2");
    new Future.value(499).then((x) => throw x);
    throw "catch error";
  }).listen((x) {
      events.add(x);
    },
    onDone: () {
      Expect.listEquals(
          ["catch error entry",
           "main exit",
           "catch error",
           "future error",
           "future error2",
           499,
          ],
          events);
      asyncEnd();
    });
  events.add("main exit");
}
