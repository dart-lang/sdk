// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

bool canceled;

test1() async {
  canceled = false;
  try {
    StreamController controller = infiniteStreamController();
    outer:
    while (true) {
      await for (var x in controller.stream) {
        for (int j = 0; j < 10; j++) {
          if (j == 5) break outer;
        }
      }
    }
  } finally {
    Expect.isTrue(canceled);
  }
}

test2() async {
  canceled = false;
  try {
    StreamController controller = infiniteStreamController();
    bool first = true;
    outer:
    while (true) {
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
    Expect.isTrue(canceled);
  }
}

test() async {
  await test1();
  await test2();
}

main() {
  asyncStart();
  test().then((_) {
    asyncEnd();
  });
}

// Create a stream that produces numbers [1, 2, ... ]
StreamController infiniteStreamController() {
  StreamController controller;
  Timer timer;
  int counter = 0;

  void tick() {
    if (controller.isPaused) {
      return;
    }
    if (canceled) {
      return;
    }
    counter++;
    controller.add(counter); // Ask stream to send counter values as event.
    Timer.run(tick);
  }

  void startTimer() {
    Timer.run(tick);
  }

  controller = new StreamController(
      onListen: startTimer,
      onResume: startTimer,
      onCancel: () {
        canceled = true;
      });

  return controller;
}
