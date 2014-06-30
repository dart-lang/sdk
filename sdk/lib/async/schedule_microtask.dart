// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

typedef void _AsyncCallback();

class _AsyncCallbackEntry {
  final _AsyncCallback callback;
  _AsyncCallbackEntry next;
  _AsyncCallbackEntry(this.callback);
}

_AsyncCallbackEntry _nextCallback;
_AsyncCallbackEntry _lastCallback;

void _asyncRunCallbackLoop() {
  _AsyncCallbackEntry entry = _nextCallback;
  // As long as we are iterating over the registered callbacks we don't
  // set the [_lastCallback] entry.
  while (entry != null) {
    entry.callback();
    entry = _nextCallback = entry.next;
  }
  // Any new callback must register a callback function now.
  _lastCallback = null;
}

void _asyncRunCallback() {
  try {
    _asyncRunCallbackLoop();
  } catch (e, s) {
    _AsyncRun._scheduleImmediate(_asyncRunCallback);
    _nextCallback = _nextCallback.next;
    rethrow;
  }
}

void _scheduleAsyncCallback(callback) {
  // Optimizing a group of Timer.run callbacks to be executed in the
  // same Timer callback.
  if (_lastCallback == null) {
    _nextCallback = _lastCallback = new _AsyncCallbackEntry(callback);
    _AsyncRun._scheduleImmediate(_asyncRunCallback);
  } else {
    _lastCallback = _lastCallback.next = new _AsyncCallbackEntry(callback);
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
 *     main() {
 *       Timer.run(() { print("executed"); });  // Will never be executed.
 *       foo() {
 *         scheduleMicrotask(foo);  // Schedules [foo] in front of other events.
 *       }
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
  if (identical(_ROOT_ZONE, Zone.current)) {
    // No need to bind the callback. We know that the root's scheduleMicrotask
    // will be invoked in the root zone.
    _rootScheduleMicrotask(null, null, _ROOT_ZONE, callback);
    return;
  }
  Zone.current.scheduleMicrotask(
      Zone.current.bindCallback(callback, runGuarded: true));
}

class _AsyncRun {
  /** Schedule the given callback before any other event in the event-loop. */
  external static void _scheduleImmediate(void callback());
}
