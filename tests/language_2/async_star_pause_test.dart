// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library async_star_pause_test;

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "dart:async";

main() {
  // await for pauses stream during body.
  asyncTest(() async {
    // Assumes await-for uses streamIterator.
    var log = [];
    var s = () async* {
      for (int i = 0; i < 3; i++) {
        log.add("$i-");
        yield i;
        // Should pause here until next iteration of await-for loop.
        log.add("$i+");
      }
    }();
    await for (var i in s) {
      log.add("$i?");
      await nextMicrotask();
      log.add("$i!");
    }
    Expect.listEquals(log, [
      "0-",
      "0?",
      "0!",
      "0+",
      "1-",
      "1?",
      "1!",
      "1+",
      "2-",
      "2?",
      "2!",
      "2+"
    ]);
  });
}

Future nextMicrotask() => new Future.microtask(() {});
