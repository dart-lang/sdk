// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test may crash dart2js.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

main() {
  var res = [];
  fisk() async* {
    res.add("+fisk");
    try {
      for (int i = 0; i < 2; i++) {
        yield await new Future.microtask(() => i);
      }
    } finally {
      res.add("-fisk");
    }
  }

  fugl(int count) async {
    res.add("fisk $count");
    try {
      await for (int i in fisk().take(count)) res.add(i);
    } finally {
      res.add("done");
    }
  }

  asyncStart();
  fugl(3)
      .whenComplete(() => fugl(2))
      .whenComplete(() => fugl(1))
      .whenComplete(() {
    Expect.listEquals([
      "fisk 3",
      "+fisk",
      0,
      1,
      "-fisk",
      "done",
      "fisk 2",
      "+fisk",
      0,
      1,
      "-fisk",
      "done",
      "fisk 1",
      "+fisk",
      0,
      "-fisk",
      "done"
    ], res);
    asyncEnd();
  });
}
