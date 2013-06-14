// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';

main() {
  // We keep a ReceivePort open until all tests are done. This way the VM will
  // time out if the callbacks are not invoked.
  var port = new ReceivePort();
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
    }).listen((x) { events.add(x); })
      .asFuture()
      .then((_) => events.add("inner done"))
      .then((_) { throw "inner done throw"; });
    events.add("after inner");
    throw "inner throw";
  }).listen((x) {
      events.add(x);
    },
    onDone: () {
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
                         "inner done",
                         "inner done throw"
                         ],
                         events);
      port.close();
    });
  events.add("main exit");
}
