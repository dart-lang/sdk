// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class Trace {
  String trace = "";
  record(x) {
    trace += x.toString();
  }

  toString() => trace;
}

Stream makeMeAStream() {
  return timedCounter(5);
}

Trace t1 = new Trace();

Future consumeOne() async {
  // Equivalent to await for (x in makeMeAStream()) { ... }
  var s = makeMeAStream();
  var it = new StreamIterator(s);
  while (await it.moveNext()) {
    var x = it.current;
    t1.record(x);
  }
  t1.record("X");
}

Trace t2 = new Trace();

Future consumeTwo() async {
  await for (var x in makeMeAStream()) {
    t2.record(x);
  }
  t2.record("Y");
}

Trace t3 = new Trace();

Future consumeNested() async {
  await for (var x in makeMeAStream()) {
    t3.record(x);
    await for (var y in makeMeAStream()) {
      t3.record(y);
    }
    t3.record("|");
  }
  t3.record("Z");
}

Trace t4 = new Trace();

Future consumeSomeOfInfinite() async {
  int i = 0;
  await for (var x in infiniteStream()) {
    i++;
    if (i > 10) break;
    t4.record(x);
  }
  t4.record("U");
}

main() {
  var f1 = consumeOne();
  t1.record("T1:");

  var f2 = consumeTwo();
  t2.record("T2:");

  var f3 = consumeNested();
  t3.record("T3:");

  var f4 = consumeSomeOfInfinite();
  t4.record("T4:");

  asyncStart();
  Future.wait([f1, f2, f3, f4]).then((_) {
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
