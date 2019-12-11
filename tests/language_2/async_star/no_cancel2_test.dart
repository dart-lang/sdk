// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

var events = [];

var timer;
ticker(period) async* {
  var sc;
  sc = new StreamController(onListen: () {
    events.add("listen");
    timer = new Timer.periodic(period, (_) {
      sc.add(null);
    });
  }, onCancel: () {
    events.add("cancel");
    timer.cancel();
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
  final subscription =
      ticker(const Duration(milliseconds: 20)).listen((val) {});

  bool cancelFinished = false;
  new Timer(const Duration(milliseconds: 100), () async {
    // Despite the cancel call below, the stream doesn't stop.
    // The async* function is not blocked at any await (since the inner timer
    // continuously ticks), but since there/ is no yield-point in the function
    // it won't cancel.
    new Timer(const Duration(milliseconds: 30), () {
      Expect.isFalse(cancelFinished);
      Expect.listEquals(["main", "listen", "invoke cancel"], events);
      timer.cancel();
      asyncEnd();
    });

    events.add("invoke cancel");
    await subscription.cancel();
    // This line should never be reached, since the cancel-future doesn't
    // complete.
    cancelFinished = true;
  });
}
