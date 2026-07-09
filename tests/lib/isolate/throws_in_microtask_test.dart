// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the microtask queue is not broken if a microtask throws.

import 'dart:isolate';
import "dart:async";

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

void main() async {
  asyncStart();
  // Runs code in a new isolate with `errorsAreFatal` set to `fatal`.
  // The isolate code:
  // - schedules two microtasks, each sending an event when they run,
  //   and then they throw.
  // - if `timer` is true, also scheduled a timer which reports
  //   running, but doesn't throw. (To check see that a microtask
  //   doesn't get postponed to after the timer.)
  // - runs the code that schedules the microtasks either
  //   synchronously in the isolate entry point (if `start` is `"sync"`),
  //   as a microtask (if it's `"microtask"`) or as a zero-duration
  //   timer (if it's `"timer"`).

  for (var fatal in [true, false]) {
    for (var timer in [false, true]) {
      for (var start in ["sync", "microtask", "timer"]) {
        // ID to keep cases apart.
        var id = 'ID-${fatal ? 'F' : ''}-${timer ? 'T' : ''}-$start';
        // Expectation.
        var expect = [
          // Always runs once microtask.
          "M:$id#1", "E:$id#1",
          if (!fatal) // If not fatal ...
          ...[
            // Also runs second microtask,
            "M:$id#2", "E:$id#2",
            // and timer if requested, in that order.
            if (timer) "T:$id",
          ],
          "done",
        ];
        Expect.listEquals(
          expect,
          await test(id, fatal: fatal, timer: timer, start: start),
          "(fatal: $fatal, timer: $timer, start: $start)",
        );
      }
    }
  }
  asyncEnd();
}

/// Spawns isolate with given [fatal] running test with the remaining parameters.
///
/// Collects sent messages and uncaught errors, plus a final `"done"` when
/// the isolate closes, and returns the list.
Future<List<String>> test(
  String id, {
  required bool fatal,
  required bool timer,
  required String start,
}) async {
  var log = <String>[];
  var done = Completer<void>();
  var port = RawReceivePort();
  port.handler = (m) {
    switch (m) {
      case null:
        log.add("done");
        done.complete();
        port.close();
      case [var e, _]:
        log.add("E:$e");
      case var o:
        log.add("$o");
    }
  };
  await Isolate.spawn(
    run,
    (id, fatal, timer, start, port.sendPort),
    errorsAreFatal: fatal,
    onError: port.sendPort,
    onExit: port.sendPort,
  );
  await done.future;
  return log;
}

/// Remote isolate entry point.
///
/// Unpacks parameters and runs [runTasks] either synchronously
/// or as a timer event.
void run((String id, bool fatal, bool timer, String start, SendPort) message) {
  var (id, fatal, timer, start, output) = message;
  switch (start) {
    case "sync":
      runTasks(id, timer, output);
    case "microtask":
      Zone.current.scheduleMicrotask(() {
        runTasks(id, timer, output);
      });
    case "timer":
      Zone.current.createTimer(Duration.zero, () {
        runTasks(id, timer, output);
      });
  }
}

void runTasks(String id, bool timer, SendPort output) {
  Zone.current.scheduleMicrotask(() {
    output.send("M:$id#1");
    throw "$id#1";
  });
  Zone.current.scheduleMicrotask(() {
    output.send("M:$id#2");
    throw "$id#2";
  });
  if (timer) {
    Zone.current.createTimer(Duration.zero, () {
      output.send("T:$id");
    });
  }
}
