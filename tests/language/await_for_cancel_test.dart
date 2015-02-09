// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

bool cancelled;

test1() async {
  cancelled = false;
  try {
    StreamController controller = infiniteStreamController();
    outer: while(true) {
      await for (var x in controller.stream) {
        for (int j = 0; j < 10; j++) {
          if (j == 5) break outer;
        }
      }
    }
  } finally {
    Expect.isTrue(cancelled);
  }
}

test2() async {
  cancelled = false;
  try {
    StreamController controller = infiniteStreamController();
    bool first = true;
    outer: while(true) {
      if (first) {
        first = false;
      } else {
        break;
      }
      await for (var x in controller.stream) {
        for (int j = 0; j < 10; j++) {
          if (j == 5) continue outer;
        }
      }
    }
  } finally {
    Expect.isTrue(cancelled);
  }
}

main() async {
  await test1();
  await test2();

}


// Create a stream that produces numbers [1, 2, ... ]
StreamController infiniteStreamController() {
  StreamController controller;
  Timer timer;
  int counter = 0;

  void tick(_) {
    counter++;
    controller.add(counter); // Ask stream to send counter values as event.
  }

  void startTimer() {
    timer = new Timer.periodic(const Duration(milliseconds: 10), tick);
  }

  void stopTimer() {
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
  }

  controller = new StreamController(
      onListen: startTimer,
      onPause: stopTimer,
      onResume: startTimer,
      onCancel: () {
        cancelled = true;
        stopTimer();
      });

  return controller;
}
