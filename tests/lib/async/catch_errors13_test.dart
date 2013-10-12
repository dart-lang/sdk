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
  // Work around bug that makes scheduleMicrotask use Timers. By invoking
  // `scheduleMicrotask` here we make sure that asynchronous non-timer events
  // are executed before any Timer events.
  scheduleMicrotask(() { });

  // Test that errors are caught by nested `catchErrors`. Also uses
  // `scheduleMicrotask` in the body of a Timer.
  catchErrors(() {
    events.add("catch error entry");
    catchErrors(() {
      events.add("catch error entry2");
      Timer.run(() { throw "timer error"; });
      new Timer(const Duration(milliseconds: 50),
                () {
                     scheduleMicrotask(() { throw "scheduleMicrotask"; });
                     throw "delayed error";
                   });
    }).listen((x) {
      events.add(x);
      if (x == "scheduleMicrotask") {
        throw "inner done throw";
      }
    });
    events.add("after inner");
    Timer.run(() { throw "timer outer"; });
    throw "inner throw";
  }).listen((x) {
      events.add(x);
      if (x == "inner done throw") done.complete(true);
    },
    onDone: () { Expect.fail("Unexpected callback"); });

  done.future.whenComplete(() {
    // Give callbacks time to run.
    Timer.run(() {
      Expect.listEquals([
                         "catch error entry",
                         "catch error entry2",
                         "after inner",
                         "main exit",
                         "inner throw",
                         "timer error",
                         "timer outer",
                         "delayed error",
                         "scheduleMicrotask",
                         "inner done throw"
                         ],
                         events);
      asyncEnd();
    });
  });
  events.add("main exit");
}
