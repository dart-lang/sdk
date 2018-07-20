// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.cli;

/**
 * Synchronously blocks the calling isolate to wait for asynchronous events to
 * complete.
 *
 * If the [timeout] parameter is supplied, [waitForEvent] will return after
 * the specified timeout even if no events have occurred.
 *
 * This call does the following:
 * - suspends the current execution stack,
 * - runs the microtask queue until it is empty,
 * - waits until the message queue is not empty,
 * - handles messages on the message queue, plus their associated microtasks,
 *   until the message queue is empty,
 * - resumes the original stack.
 *
 * This function breaks the usual promise offered by Dart semantics that
 * message handlers and microtasks run to completion before the next message
 * handler or microtask begins to run. Of particular note is that use of this
 * function in a finally block will allow microtasks and message handlers to
 * run before all finally blocks for an exception have completed, possibly
 * breaking invariants in your program.
 *
 * This function will synchronously throw the first unhandled exception it
 * encounters in running the microtasks and message handlers as though the
 * throwing microtask or message handler was the only Dart invocation on the
 * stack. That is, unhandled exceptions in a microtask or message handler will
 * skip over stacks suspended in a call to [waitForEvent].
 *
 * Calls to this function may be nested. Earlier invocations will not
 * be able to complete until subsequent ones do. Messages that arrive after
 * a subsequent invocation are "consumed" by that invocation, and do not
 * unblock an earlier invocation. Please be aware that nesting calls to
 * [waitForEvent] can lead to deadlock when subsequent calls block to wait for
 * a condition that is only satisfied after an earlier call returns.
 *
 * Please note that this call is only available in the standalone command-line
 * Dart VM. Further, because it suspends the current execution stack until the
 * message queue is empty, even when running in the standalone command-line VM
 * there exists a risk that the current execution stack will be starved.
 */
external void _waitForEvent(int timeoutMillis);

void Function(int) _getWaitForEvent() => _waitForEvent;

// This should be set from C++ code by the embedder to wire up waitFor() to the
// native implementation. In the standalone VM this is set to _waitForEvent()
// above. If it is null, calling waitFor() will throw an UnsupportedError.
void Function(int) _waitForEventClosure;

class _WaitForUtils {
  static void waitForEvent({Duration timeout}) {
    if (_waitForEventClosure == null) {
      throw new UnsupportedError("waitFor is not supported by this embedder");
    }
    _waitForEventClosure(timeout == null ? 0 : max(1, timeout.inMilliseconds));
  }
}

/**
 * Suspends the stack, runs microtasks, and handles incoming events until
 * [future] completes.
 *
 * WARNING: EXPERIMENTAL. USE AT YOUR OWN RISK.
 *
 * This call does the following:
 * - While [future] is not completed:
 *   - suspends the current execution stack,
 *   - runs the microtask queue until it is empty,
 *   - waits until the message queue is not empty,
 *   - handles messages on the message queue, plus their associated microtasks,
 *     until the message queue is empty,
 *   - resumes the original stack.
 *
 * This function breaks the usual promise offered by Dart semantics that
 * message handlers and microtasks run to completion before the next message
 * handler or microtask begins to run. Of particular note is that use of this
 * function in a finally block will allow microtasks and message handlers to
 * run before all finally blocks for an exception have completed, possibly
 * breaking invariants in your program.
 *
 * Use of this function should be considered a last resort when it is not
 * possible to convert a Dart program entirely to an asynchronous style using
 * `async` and `await`.
 *
 * If the [Future] completes normally, its result is returned. If the [Future]
 * completes with an error, the error and stack trace are wrapped in an
 * [AsyncError] and thrown. If a microtask or message handler run during this
 * call results in an unhandled exception, that exception will be propagated
 * as though the microtask or message handler was the only Dart invocation on
 * the stack. That is, unhandled exceptions in a microtask or message handler
 * will skip over stacks suspended in a call to [waitFor].
 *
 * If the optional `timeout` parameter is passed, [waitFor] throws a
 * [TimeoutException] if the [Future] is not completed within the specified
 * period.
 *
 * Calls to [waitFor] may be nested. Earlier invocations will not complete
 * until subsequent ones do, but the completion of a subsequent invocation will
 * cause the previous invocation to wake up and check its [Future] for
 * completion.
 *
 * Please be aware that nesting calls to [waitFor] can lead to deadlock if
 * subsequent calls block waiting for a condition that is only satisfied when
 * an earlier call returns.
 */
@provisional
T waitFor<T>(Future<T> future, {Duration timeout}) {
  T result;
  bool futureCompleted = false;
  Object error;
  StackTrace stacktrace;
  future.then((r) {
    futureCompleted = true;
    result = r;
  }, onError: (e, st) {
    error = e;
    stacktrace = st;
  });

  Stopwatch s;
  if (timeout != null) {
    s = new Stopwatch()..start();
  }
  Timer.run(() {}); // Enusre there is at least one message.
  while (!futureCompleted && (error == null)) {
    Duration remaining;
    if (timeout != null) {
      if (s.elapsed >= timeout) {
        throw new TimeoutException("waitFor() timed out", timeout);
      }
      remaining = timeout - s.elapsed;
    }
    _WaitForUtils.waitForEvent(timeout: remaining);
  }
  if (timeout != null) {
    s.stop();
  }
  Timer.run(() {}); // Ensure that previous calls to waitFor are woken up.

  if (error != null) {
    throw new AsyncError(error, stacktrace);
  }

  return result;
}
