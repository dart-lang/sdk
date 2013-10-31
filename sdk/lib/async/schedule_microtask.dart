// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

typedef void _AsyncCallback();

bool _callbacksAreEnqueued = false;
Queue<_AsyncCallback> _asyncCallbacks = new Queue<_AsyncCallback>();

void _asyncRunCallback() {
  // As long as we are iterating over the registered callbacks we don't
  // unset the [_callbacksAreEnqueued] boolean.
  while (!_asyncCallbacks.isEmpty) {
    Function callback = _asyncCallbacks.removeFirst();
    try {
      callback();
    } catch (e) {
      _AsyncRun._scheduleImmediate(_asyncRunCallback);
      rethrow;
    }
  }
  // Any new callback must register a callback function now.
  _callbacksAreEnqueued = false;
}

void _scheduleAsyncCallback(callback) {
  // Optimizing a group of Timer.run callbacks to be executed in the
  // same Timer callback.
  _asyncCallbacks.add(callback);
  if (!_callbacksAreEnqueued) {
    _AsyncRun._scheduleImmediate(_asyncRunCallback);
    _callbacksAreEnqueued = true;
  }
}

/**
 * Runs a function asynchronously.
 *
 * Callbacks registered through this function are always executed in order and
 * are guaranteed to run before other asynchronous events (like [Timer] events,
 * or DOM events).
 *
 * **Warning:** it is possible to starve the DOM by registering asynchronous
 * callbacks through this method. For example the following program runs
 * the callbacks without ever giving the Timer callback a chance to execute:
 *
 *     Timer.run(() { print("executed"); });  // Will never be executed.
 *     foo() {
 *       scheduleMicrotask(foo);  // Schedules [foo] in front of other events.
 *     }
 *     main() {
 *       foo();
 *     }
 *
 * ## Other resources
 *
 * * [The Event Loop and Dart](https://www.dartlang.org/articles/event-loop/):
 * Learn how Dart handles the event queue and microtask queue, so you can write
 * better asynchronous code with fewer surprises.
 */
void scheduleMicrotask(void callback()) {
  if (Zone.current == Zone.ROOT) {
    // No need to bind the callback. We know that the root's scheduleMicrotask
    // will be invoked in the root zone.
    Zone.current.scheduleMicrotask(callback);
    return;
  }
  Zone.current.scheduleMicrotask(
      Zone.current.bindCallback(callback, runGuarded: true));
}

class _AsyncRun {
  /** Schedule the given callback before any other event in the event-loop. */
  external static void _scheduleImmediate(void callback());
}
