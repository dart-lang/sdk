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
  // Test nested `catchErrors`.
  // The nested `catchErrors` throws all kinds of different errors (synchronous
  // and asynchronous). The body of the outer `catchErrors` furthermore has a
  // synchronous `throw`.
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
      events.add(x);
      if (x == "delayed error") {
        throw "inner done throw";
      }
    });
    events.add("after inner");
    throw "inner throw";
  }).listen((x) {
    events.add(x);
    if (x == "inner done throw") {
      done.complete(true);
    }
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });

  done.future.whenComplete(() {
    Expect.listEquals([
      "catch error entry",
      "catch error entry2",
      "after inner",
      "main exit",
      "catch error",
      "inner throw",
      "future error",
      "future error2",
      499,
      "delayed error",
      "inner done throw"
    ], events);
    asyncEnd();
  });
  events.add("main exit");
}
