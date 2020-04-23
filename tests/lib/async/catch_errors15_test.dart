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

  catchErrors(() {
    events.add("catch error entry");
    catchErrors(() {
      events.add("catch error entry2");
      new Future.error("future error");
      new Future.error("future error2");
      new Future.value(499).then((x) => throw x);
      new Future.delayed(const Duration(milliseconds: 50), () {
        throw "delayed error";
      });
      throw "catch error";
    }).listen((x) {
      events.add("i $x");
      if (x == "delayed error") done.complete(true);
    }, onDone: () {
      Expect.fail("Unexpected callback");
    });
    events.add("after inner");
    throw "inner throw";
  }).listen((x) {
    events.add("o $x");
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });
  done.future.whenComplete(() {
    // Give some time to run the handlers.
    Timer.run(() {
      Expect.listEquals([
        "catch error entry",
        "catch error entry2",
        "after inner",
        "main exit",
        "i catch error",
        // We guarantee the order of one stream but not any
        // global order.
        "o inner throw",
        "i future error",
        "i future error2",
        "i 499",
        "i delayed error",
      ], events);
      asyncEnd();
    });
  });
  events.add("main exit");
}
