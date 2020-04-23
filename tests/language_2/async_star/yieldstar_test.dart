// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

Stream<int> subStream(p) async* {
  yield p;
  yield p + 1;
}

Stream foo(Completer<bool> finalized) async* {
  int i = 0;
  try {
    while (true) {
      yield "outer";
      yield* subStream(i);
      i++;
    }
  } finally {
    // See that we did not run too many iterations.
    Expect.isTrue(i < 10);
    // Canceling the stream-subscription should run the finalizer.
    finalized.complete(true);
  }
}

foo2(Stream subStream) async* {
  yield* subStream;
}

test() async {
  Expect.listEquals([0, 1], await (subStream(0).toList()));
  Completer<bool> finalized = new Completer<bool>();
  Expect.listEquals(["outer", 0, 1, "outer", 1, 2, "outer", 2],
      await (foo(finalized).take(8).toList()));
  Expect.isTrue(await (finalized.future));

  finalized = new Completer<bool>();
  // Canceling the stream while it is yield*-ing from the sub-stream.
  Expect.listEquals(["outer", 0, 1, "outer", 1, 2, "outer"],
      await (foo(finalized).take(7).toList()));
  Expect.isTrue(await (finalized.future));
  finalized = new Completer<bool>();

  Completer<bool> pausedCompleter = new Completer<bool>();
  Completer<bool> resumedCompleter = new Completer<bool>();
  Completer<bool> canceledCompleter = new Completer<bool>();

  StreamController controller;
  int i = 0;
  addNext() {
    if (i >= 10) return;
    controller.add(i);
    i++;
    if (!controller.isPaused) {
      scheduleMicrotask(addNext);
    }
  }

  controller = new StreamController(onListen: () {
    scheduleMicrotask(addNext);
  }, onPause: () {
    pausedCompleter.complete(true);
  }, onResume: () {
    resumedCompleter.complete(true);
    scheduleMicrotask(addNext);
  }, onCancel: () {
    canceledCompleter.complete(true);
  });

  StreamSubscription subscription;
  // Test that the yield*'ed stream is paused and resumed.
  subscription = foo2(controller.stream).listen((event) {
    if (event == 2) {
      subscription.pause();
      scheduleMicrotask(() {
        subscription.resume();
      });
    }
    if (event == 5) {
      subscription.cancel();
    }
  });
  // Test that the yield*'ed streamSubscription is paused, resumed and canceled
  // by the async* stream.
  Expect.isTrue(await pausedCompleter.future);
  Expect.isTrue(await resumedCompleter.future);
  Expect.isTrue(await canceledCompleter.future);
}

main() {
  asyncStart();
  test().then((_) {
    asyncEnd();
  });
}
