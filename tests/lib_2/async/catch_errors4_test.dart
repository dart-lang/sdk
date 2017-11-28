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
  // Test that synchronous errors inside a `catchErrors` are caught.
  catchErrors(() {
    events.add("catch error entry");
    throw "catch error";
  }).listen((x) {
    events.add(x);
    done.complete(true);
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });

  done.future.whenComplete(() {
    Expect.listEquals([
      "catch error entry",
      "main exit",
      "catch error",
    ], events);
    asyncEnd();
  });
  events.add("main exit");
}
