// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

// Checks that an `Error` object that is "thrown" through async functionality
// gets a stack trace set.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

main() async {
  asyncStart();

  for ((String, Object, StackTrace, Object, String, AsyncError?)
      Function() setUp in [
    () {
      // Without error callback. Inject and expect same fresh error.
      var error = StateError("Quo!");
      var stack = StackTrace.fromString("Secret stack");
      return ("", error, stack, error, stack.toString(), null);
    },
    () {
      // With error callback, same error, new stack.
      var error = StateError("Quo");
      var stack = StackTrace.fromString("Secret stack");
      var stack2 = StackTrace.fromString("Other stack");
      var errorCallback = AsyncError(error, stack2);
      return (
        "errorCallback: fresh both",
        error,
        stack,
        error,
        stack2.toString(),
        errorCallback
      );
    },
    () {
      // With error callback, new error, stack.
      var error = StateError("Quo");
      var stack = StackTrace.fromString("Secret stack");
      var error2 = StateError("Quid");
      var stack2 = StackTrace.fromString("Other stack");
      var errorCallback = AsyncError(error2, stack2);
      return (
        "errorCallback: fresh stack",
        error,
        stack,
        error2,
        stack2.toString(),
        errorCallback
      );
    },
  ]) {
    Future<void> test(String name,
        Future<(Object, StackTrace)> Function(Object, StackTrace) body) {
      var (msg, error, stack, expectError, expectStackString, errorCallback) =
          setUp();
      print("Test: $name${msg.isNotEmpty ? ", $msg" : msg}");

      return asyncTest(() => runZoned(() => body(error, stack),
              zoneSpecification: ZoneSpecification(
                  errorCallback: (s, p, z, e, st) => errorCallback)).then((es) {
            var (e, s) = es;
            Expect.identical(expectError, e, name);
            Expect.equals(expectStackString, s.toString(), name);
            Expect.equals(
                expectStackString, (e as Error).stackTrace.toString(), name);
          }));
    }

    // Sanity check: Plain throws.
    () {
      var (name, error, stack, error2, stack2, errorCallback) = setUp();
      try {
        Error.throwWithStackTrace(error, stack);
      } catch (e, s) {
        Expect.identical(error, e, "Error.throw");
        Expect.equals(stack.toString(), s.toString(), "Error.throw");
        Expect.equals(stack.toString(), (e as Error).stackTrace.toString(),
            "Error.throw");
      }
    }();

    // Futures.

    // Immediate error.
    await test("Future.error",
        (error, stack) => futureError(Future.error(error, stack)));

    // Through controller, async.
    await test("Completer().completeError", (error, stack) {
      var completer = Completer<void>();
      completer.completeError(error, stack);
      return futureError(completer.future);
    });

    // Through controller, sync.
    await test("Completer.sync().completeError", (error, stack) {
      var completer = Completer<void>.sync();
      var future = completer.future..ignore();
      completer.completeError(error, stack);
      return futureError(future);
    });

    // Streams.

    // Singleton error.
    await test("Stream.error",
        (error, stack) => streamError(Stream.error(error, stack)));

    // Controller errors.
    for (var broadcast in [false, true]) {
      for (var sync in [false, true]) {
        await test(
            "Stream${broadcast ? ".broadcast" : ""}${sync ? "(sync)" : ""}",
            (error, stack) {
          var controller = broadcast
              ? StreamController<void>.broadcast(sync: sync)
              : StreamController<void>(sync: sync);
          var future = streamError(controller.stream)..ignore();
          controller.addError(error, stack);
          return future;
        });
      }
    }
  }

  asyncEnd();
}

// --------------------------------------------------------------------
// Helper functions

(Object, StackTrace) captureError(Object e, StackTrace s) => (e, s);

(Object, StackTrace) fail(_) {
  Expect.fail("No error from future") as Never;
}

/// Captures error of future.
Future<(Object, StackTrace)> futureError(Future<void> future) =>
    future.then(fail, onError: captureError);

/// Captures first error of stream.
Future<(Object, StackTrace)> streamError(Stream<void> stream) {
  var c = Completer<(Object, StackTrace)>();
  var sub = stream.listen((_) {
    // No values expected.
  }, onError: (Object e, StackTrace s) {
    c.complete((e, s));
  }, onDone: () {
    Expect.fail("No error from stream");
  }, cancelOnError: true);
  return c.future;
}
