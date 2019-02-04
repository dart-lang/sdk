// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that stream cancellation is checked immediately after delivering the
// event, and before continuing after the yield.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

main() async {
  asyncStart();
  var log = [];
  Stream<int> f() async* {
    try {
      log.add("-1");
      yield 1;
      log.add("-2");
      yield 2;
    } finally {
      log.add("x");
    }
  }

  var completer = Completer();
  var s;
  s = f().listen((e) {
    log.add("+$e");
    // The `cancel` operation makes all `yield` operations act as returns.
    // It should make the `finally` block in `f` log an "x",
    // and nothing else.
    completer.complete(s.cancel());
  }, onError: (e) {
    // Should never be reached, but if it does, we'll make the await
    // below terminate.
    completer.complete(new Future.sync(() {
      Expect.fail("$e");
    }));
  }, onDone: () {
    completer.complete(null);
  });
  await completer.future;
  Expect.listEquals(["-1", "+1", "x"], log, "cancel");
  asyncEnd();
}
