// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

typedef void _AsyncCallback();

bool _callbacksAreEnqueued = false;
List<_AsyncCallback> _asyncCallbacks = <_AsyncCallback>[];

void _asyncRunCallback() {
  // As long as we are iterating over the registered callbacks we don't
  // unset the [_callbacksAreEnqueued] boolean.
  while (!_asyncCallbacks.isEmpty) {
    List callbacks = _asyncCallbacks;
    // The callbacks we execute can register new callbacks. This means that
    // the for-loop below could grow the list if we don't replace it here.
    _asyncCallbacks = <_AsyncCallback>[];
    for (int i = 0; i < callbacks.length; i++) {
      Function callback = callbacks[i];
      callbacks[i] = null;
      try {
        callback();
      } catch (e) {
        i++;  // Skip current callback.
        List remainingCallbacks = callbacks.sublist(i);
        List newCallbacks = _asyncCallbacks;
        _asyncCallbacks = <_AsyncCallback>[];
        _asyncCallbacks.addAll(remainingCallbacks);
        _asyncCallbacks.addAll(newCallbacks);
        _AsyncRun._enqueueImmediate(_asyncRunCallback);
        throw;
      }
    }
  }
  // Any new callback must register a callback function now.
  _callbacksAreEnqueued = false;
}

/**
 * Runs the given [callback] asynchronously.
 *
 * Callbacks registered through this function are always executed in order and
 * are guaranteed to run before other asynchronous events (like [Timer] events,
 * or DOM events).
 *
 * Warning: it is possible to starve the DOM by registering asynchronous
 * callbacks through this method. For example the following program will
 * run the callbacks without ever giving the Timer callback a chance to execute:
 *
 *     Timer.run(() { print("executed"); });  // Will never be executed;
 *     foo() {
 *       asyncRun(foo);  // Schedules [foo] in front of other events.
 *     }
 *     main() {
 *       foo();
 *     }
 */
void runAsync(void callback()) {
  // Optimizing a group of Timer.run callbacks to be executed in the
  // same Timer callback.
  _asyncCallbacks.add(callback);
  if (!_callbacksAreEnqueued) {
    _AsyncRun._enqueueImmediate(_asyncRunCallback);
    _callbacksAreEnqueued = true;
  }
}

class _AsyncRun {
  /** Enqueues the given callback before any other event in the event-loop. */
  external static void _enqueueImmediate(void callback());
}
