// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `await for` and `async*` interact correctly.

// An `await for` must pause its subscription immediately
// if the `await for` body does anything asynchronous
// (any `await`, `await for`, or pausing at a `yield`/`yield*`)
// A pause happening synchronously in an event delivery
// must pause the `sync*` method at the `yield` sending the event.
// A break happening synchronously in an event delivery,
// or while paused at a `yield`, must exit at that `yield`.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

Stream<int> stream(List<String> log) async* {
  log.add("^");
  try {
    log.add("?1");
    yield 1;
    log.add("?2");
    yield 2;
    log.add("?3");
    yield 3;
  } finally {
    log.add(r"$");
  }
}

Stream<int> consume(List<String> log,
    {int breakAt = -1,
    int yieldAt = -1,
    int yieldStarAt = -1,
    int pauseAt = -1}) async* {
  // Create stream.
  var s = stream(log);
  log.add("(");
  // The "consume loop".
  await for (var event in s) {
    // Should be acting synchronously wrt. the delivery of the event.
    // The source stream should be at the yield now.
    log.add("!$event");
    if (event == pauseAt) {
      log.add("p$event[");
      // Async operation causes subscription to pause.
      // Nothing should happen in the source stream
      // until the end of the loop body where the subscription is resumed.
      await Future.delayed(Duration(microseconds: 1));
      log.add("]");
    }
    if (event == yieldAt) {
      log.add("y$event[");
      // Yield may cause subscription to pause or cancel.
      // This loop should stay at the yield until the event has been delieverd.
      // If the receiver pauses or cancels, we delay or break the loop here.
      yield event;
      log.add("]");
    }
    if (event == yieldStarAt) {
      log.add("Y$event[");
      // Yield* will always cause the subscription for this loop to pause.
      // If the listener pauses, this stream is paused. If the listener cancels,
      // this stream is cancelled, and the yield* acts like return, cancelling
      // the loop subscription and waiting for the cancel future.
      yield* Stream<int>.fromIterable([event]);
      log.add("]");
    }
    if (event == breakAt) {
      log.add("b$event");
      // Breaks the loop. This cancels the loop subscription and waits for the
      // cancel future.
      break;
    }
  }
  // Done event from stream or cancel future has completed.
  log.add(")");
}

main() async {
  asyncStart();

  // Just run the loop over the stream. The consume stream emits no events.
  {
    var log = <String>[];
    await for (var _ in consume(log)) {
      throw "unreachable";
    }
    await Future.delayed(Duration(milliseconds: 1));
    var trace = log.join("");
    Expects.equals(r"(^?1!1?2!2?3!3$)", trace, "straight through");
  }

  // Pause at 1, then resume.
  // Consume loop forces a pause when it receives the 1 event.
  // Nothing should happen until that pause is resumed.
  {
    var log = <String>[];
    await for (var _ in consume(log, pauseAt: 1)) {
      throw "unreachable";
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "pause at 1";
    if (trace.contains("p1[?2")) {
      message += " (did not pause in time)";
    }
    Expects.equals(r"(^?1!1p1[]?2!2?3!3$)", trace, message);
  }

  // Break at 1.
  // Consume loop breaks after receiving the 1 event.
  // The consume stream emits no events.
  {
    var log = <String>[];
    await for (var _ in consume(log, breakAt: 1)) {
      throw "unreachable";
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "break at 1";
    if (trace.contains("b1?2")) {
      message += " (did not cancel in time)";
    }
    Expects.equals(r"(^?1!1b1$)", trace, message);
  }

  // Pause then break at 1.
  // Consume loop pauses after receiving the 1 event,
  // then breaks before resuming. It should still be at the yield.
  // The consume stream emits no events.
  {
    var log = <String>[];
    await for (var _ in consume(log, pauseAt: 1, breakAt: 1)) {
      throw "unreachable";
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "pause then break at 1";
    if (trace.contains("p1[?2")) {
      message += " (did not pause in time)";
    }
    if (trace.contains("b1?2")) {
      message += " (did not cancel in time)";
    }
    Expects.equals(r"(^?1!1p1[]b1$)", trace, message);
  }

  // Yield at 1.
  // The consume loop re-emits the 1 event.
  // The test loop should receive that event while the consume loop is still
  // at the yield statement.
  // The consume loop may or may not pause, it should make no difference.
  {
    var log = <String>[];
    await for (var s in consume(log, yieldAt: 1)) {
      log.add("e$s");
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "yield at 1";
    if (trace.contains("y1[?2")) {
      message += " (did not wait for delivery)";
    }
    Expects.equals(r"(^?1!1y1[e1]?2!2?3!3$)", trace, message);
  }

  // Yield at 1, then pause at yield.
  // The consume loop re-emits the 1 event.
  // The test loop should receive that event while the consume loop is still
  // at the yield statement.
  // The test loop then pauses.
  // Nothing should happen in either the original yield
  // or the consume-function yield until the test loop ends.
  {
    var log = <String>[];
    await for (var s in consume(log, yieldAt: 1)) {
      log.add("e$s<");
      // Force pause at yield.
      await Future.delayed(Duration(milliseconds: 1));
      log.add(">");
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "yield at 1, pause at yield";
    if (trace.contains("y1[?2")) {
      message += " (did not wait for delivery)";
    }
    if (trace.contains("e1<?2")) {
      message += " (did not pause in time)";
    }
    Expects.equals(r"(^?1!1y1[e1<>]?2!2?3!3$)", trace, message);
  }

  // Yield at 1, then break at yield.
  // The consume loop re-emits the 1 event.
  // The test loop should receive that event while the consume loop is still
  // at the yield statement.
  // The test loop then breaks. That makes the consume loop yield return,
  // breaking the consume loop, which makes the source yield return.
  {
    var log = <String>[];
    await for (var s in consume(log, yieldAt: 1)) {
      log.add("e${s}B$s");
      break; // Force break at yield*.
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "yield at 1, break at yield";
    if (trace.contains("y1[?2")) {
      message += " (did not wait for delivery)";
    }
    if (trace.contains("B1?2")) {
      message += " (did not break in time)";
    }
    Expects.equals(r"(^?1!1y1[e1B1$)", trace, message);
  }

  // Yield* at 1.
  // The consume loop re-emits a stream containing the 1 event.
  // The test loop should receive that event before the consume loop
  // continues from the `yield*`, which again happens before the source
  // stream continues from its `yield`.
  {
    var log = <String>[];
    await for (var s in consume(log, yieldStarAt: 1)) {
      log.add("e$s");
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "yield* at 1";
    if (trace.contains("Y1[?2")) {
      message += " (did not wait for delivery)";
    }
    Expects.equals(r"(^?1!1Y1[e1]?2!2?3!3$)", trace, message);
  }

  // Yield* at 1, pause at yield.
  // The consume loop re-emits a stream containing the 1 event.
  // The test loop should receive that event before the consume loop
  // continues from the `yield*`. The test loop then force a pause.
  // Nothing further should happen during that pause.
  {
    var log = <String>[];
    await for (var s in consume(log, yieldStarAt: 1)) {
      log.add("e$s<");
      await Future.delayed(Duration(milliseconds: 1)); // force pause.
      log.add(">");
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "yield* then pause at 1";
    if (trace.contains("Y1[?2")) {
      message += " (did not wait for delivery)";
    }
    if (trace.contains("e1<?2")) {
      message += " (did not pause in time)";
    }
    Expects.equals(r"(^?1!1Y1[e1<>]?2!2?3!3$)", trace, message);
  }

  // Yield* at 1, then break at 1.
  // The consume loop re-emits a stream containing the 1 event.
  // The test loop should receive that event before the consume loop
  // continues from the `yield*`.
  // When the consume loop continues, it breaks,
  // forcing the waiting source yield to return.
  {
    var log = <String>[];
    await for (var s in consume(log, yieldStarAt: 1, breakAt: 1)) {
      log.add("e$s");
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "yield* then pause at 1";
    if (trace.contains("Y1[?2")) {
      message += " (did not wait for delivery)";
    }
    Expects.equals(r"(^?1!1Y1[e1]b1$)", trace, message);
  }

  // Yield* at 1, pause at yield, then break at 1.
  // The consume loop re-emits a stream containing the 1 event.
  // The test loop should receive that event before the consume loop
  // continues from the `yield*`. After the `yield*`, the consume loop breaks.
  // This forces the waiting source yield to return.
  {
    var log = <String>[];
    await for (var s in consume(log, yieldStarAt: 1, breakAt: 1)) {
      log.add("e$s<");
      await Future.delayed(Duration(milliseconds: 1)); // force pause.
      log.add(">");
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "yield* then pause at 1";
    Expects.equals(r"(^?1!1Y1[e1<>]b1$)", trace, message);
  }

  // Yield* at 1, break at yield.
  // The consume loop re-emits a stream containing the 1 event.
  // The test loop should receive that event before the consume loop
  // continues from the `yield*`. The test loop then breaks,
  // forcing the two waiting yields to return.
  {
    var log = <String>[];
    await for (var s in consume(log, yieldStarAt: 1)) {
      log.add("e${s}B$s");
      break;
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "yield* then break at 1";
    if (trace.contains("Y1[?2")) {
      message += " (did not deliver event in time)";
    }
    if (trace.contains("e1?2")) {
      message += " (did not cancel in time)";
    }
    Expects.equals(r"(^?1!1Y1[e1B1$)", trace, message);
  }

  // Yield* at 1, pause at yield, then break at yield.
  // The consume loop re-emits a stream containing the 1 event.
  // The test loop should receive that event before the consume loop
  // continues from the `yield*`. The test loop then forces a pause,
  // and then breaks before that pause is resumed.
  // This forces the two waiting yields to return.
  {
    var log = <String>[];
    await for (var s in consume(log, yieldStarAt: 1)) {
      log.add("e$s<");
      await Future.delayed(Duration(milliseconds: 1)); // force pause.
      log.add(">B$s");
      break; // And break.
    }
    await Future.delayed(Duration(milliseconds: 10));
    var trace = log.join("");
    String message = "yield* then pause then break at 1";
    Expects.equals(r"(^?1!1Y1[e1<>B1$)", trace, message);
  }

  Expects.summarize();
  asyncEnd();
}

class Expects {
  static var _errors = [];
  static int _tests = 0;
  static void summarize() {
    if (_errors.isNotEmpty) {
      var buffer = StringBuffer();
      for (var es in _errors) {
        buffer.writeln("FAILURE:");
        buffer.writeln(es[0]); // error
        buffer.writeln(es[1]); // stack trace
      }
      ;
      buffer.writeln("Expectations failed: ${_errors.length}"
          ", succeeded: ${_tests - _errors.length}");
      throw ExpectException(buffer.toString());
    }
  }

  static void equals(o1, o2, String message) {
    _tests++;
    try {
      Expect.equals(o1, o2, message);
    } on ExpectException catch (e) {
      var stack = StackTrace.current;
      _errors.add([e, stack]);
    }
  }
}
