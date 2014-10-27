// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable_async

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

consumeOne() async {
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

consumeTwo() async {
  await for (var x in makeMeAStream()) {
    t2.record(x);
  }
  t2.record("X");
}

main() {
  var f1 = consumeOne();
  t1.record("T1:");

  var f2 = consumeTwo();
  t2.record("T2:");

  asyncStart();
  Future.wait([f1, f2]).then((_) {
    print("Trace 1: $t1");
    print("Trace 2: $t2");
    Expect.equals("T1:12345X", t1.toString());
    Expect.equals("T2:12345X", t2.toString());
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
      controller.close();    // Ask stream to shut down and tell listeners.
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
