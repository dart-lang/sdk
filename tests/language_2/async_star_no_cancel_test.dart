// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

var events = [];

ticker() async* {
  var sc;
  var sentTickCount = 0;
  sc = new StreamController(onListen: () {
    events.add("listen");
  }, onCancel: () {
    events.add("cancel");
  });

  try {
    var counter = 0;
    await for (var tick in sc.stream) {
      counter++;
    }
  } finally {
    events.add("finally");
  }
}

void main() {
  asyncStart();
  events.add("main");
  final subscription = ticker().listen((val) {});

  bool cancelFinished = false;
  // Cancel the subscription.
  // The async* function is blocked on an `await` (the inner stream) and won't
  // be able to complete.
  Timer.run(() {
    events.add("invoke cancel");
    subscription.cancel().then((_) => cancelFinished = true);
  });

  new Timer(const Duration(milliseconds: 100), () {
    Expect.isFalse(cancelFinished);
    Expect.listEquals(["main", "listen", "invoke cancel"], events);
    asyncEnd();
  });
}
