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
  // Test multiple subscribers of an asBroadcastStream inside the same
  // `catchErrors`.
  catchErrors(() {
    var stream = new Stream.fromIterable([1, 2]).asBroadcastStream();
    stream.listen(events.add);
    stream.listen(events.add);
    done.complete(stream.listen(null).asFuture());
  }).listen((x) {
    events.add("outer: $x");
  }, onDone: () {
    Expect.fail("Unexpected callback");
  });

  done.future.whenComplete(() {
    // Give handlers time to run.
    Timer.run(() {
      Expect.listEquals([1, 1, 2, 2], events);
      asyncEnd();
    });
  });
}
