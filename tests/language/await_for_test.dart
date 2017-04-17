// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class Trace {
  String trace;
  Trace(this.trace);
  void record(x) {
    trace += x.toString();
  }

  String toString() => trace;
}

Stream makeMeAStream() {
  return timedCounter(5);
}

consumeOne(trace) async {
  // Equivalent to await for (x in makeMeAStream()) { ... }
  var s = makeMeAStream();
  var it = new StreamIterator(s);
  while (await it.moveNext()) {
    var x = it.current;
    trace.record(x);
  }
  trace.record("X");
}

consumeTwo(trace) async {
  await for (var x in makeMeAStream()) {
    trace.record(x);
  }
  trace.record("Y");
}

consumeNested(trace) async {
  await for (var x in makeMeAStream()) {
    trace.record(x);
    await for (var y in makeMeAStream()) {
      trace.record(y);
    }
    trace.record("|");
  }
  trace.record("Z");
}

consumeSomeOfInfinite(trace) async {
  int i = 0;
  await for (var x in infiniteStream()) {
    i++;
    if (i > 10) break;
    trace.record(x);
  }
  trace.record("U");
}

const String cancelError =
    "ERROR: Error in future returned by .cancel() must be caught";

/// Creates a stream that yields integers forever, but throws when canceled.
///
/// The thrown error should end up in the future returned by `cancel`.
Stream<int> errorOnCancelStream(int n) async* {
  try {
    while (true) yield n++;
  } finally {
    throw cancelError;
  }
}

// Sanity-check that the errorOnCancelStream behaves as expected.
testErrorOnCancel() {
  var stream = errorOnCancelStream(0);
  var subscription = stream.listen(null);
  return subscription.cancel().then((_) {
    Expect.fail("Cancel future did not contain error");
  }, onError: (e) {
    Expect.equals(cancelError, e);
  });
}

testCancelAwaited() async {
  return runZoned(() async {
    var stream = errorOnCancelStream(0);
    try {
      var n = 0;
      await for (var x in stream) {
        Expect.equals(n++, x);
        if (x == 5) break;
      }
      Expect.fail("Didn't await the cancel future.");
    } on String catch (e) {
      Expect.equals(cancelError, e);
    }
  }, onError: (e) {
    // Catch the error if it's uncaught.
    if (cancelError == e) {
      Expect.fail("Error in cancel is considered uncaught");
    }
    throw e;
  });
}

main() {
  Trace t1 = new Trace("T1:");
  var f1 = consumeOne(t1);

  Trace t2 = new Trace("T2:");
  var f2 = consumeTwo(t2);

  Trace t3 = new Trace("T3:");
  var f3 = consumeNested(t3);

  Trace t4 = new Trace("T4:");
  var f4 = consumeSomeOfInfinite(t4);

  var f5 = testErrorOnCancel();

  var f6 = testCancelAwaited();

  asyncStart();
  Future.wait([f1, f2, f3, f4, f5, f6]).then((_) {
    Expect.equals("T1:12345X", t1.toString());
    Expect.equals("T2:12345Y", t2.toString());
    Expect.equals("T3:112345|212345|312345|412345|512345|Z", t3.toString());
    Expect.equals("T4:12345678910U", t4.toString());
    asyncEnd();
  });
}

// Create a stream that produces numbers [1, 2, ... maxCount]
Stream timedCounter(int maxCount) {
  StreamController controller;
  Timer timer;
  int counter = 0;

  void tick(_) {
    counter++;
    controller.add(counter); // Ask stream to send counter values as event.
    if (counter >= maxCount) {
      timer.cancel();
      controller.close(); //    Ask stream to shut down and tell listeners.
    }
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
      onCancel: stopTimer);

  return controller.stream;
}

// Create a stream that produces numbers [1, 2, ... ]
Stream infiniteStream() {
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
      onCancel: stopTimer);

  return controller.stream;
}
