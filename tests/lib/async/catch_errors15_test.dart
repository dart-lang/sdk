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
  // Test that the outer `catchErrors` waits for the nested `catchErrors` stream
  // to be done.
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
    }).listen((x) { events.add("i $x"); },
              onDone: () => events.add("inner done"));
    events.add("after inner");
    throw "inner throw";
  }).listen((x) {
      events.add("o $x");
    },
    onDone: () {
      Expect.listEquals(["catch error entry",
                         "catch error entry2",
                         "after inner",
                         "main exit",
                         "i catch error",
                         "o inner throw",
                         "i future error",
                         "i future error2",
                         "i 499",
                         "i delayed error",
                         "inner done",
                         ],
                         events);
      asyncEnd();
    });
  events.add("main exit");
}
