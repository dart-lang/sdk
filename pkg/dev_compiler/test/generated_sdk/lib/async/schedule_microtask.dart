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

/** Head of single linked list of pending callbacks. */
_AsyncCallbackEntry _nextCallback;
/** Tail of single linked list of pending callbacks. */
_AsyncCallbackEntry _lastCallback;
/**
 * Tail of priority callbacks added by the currently executing callback.
 *
 * Priority callbacks are put at the beginning of the
 * callback queue, so that if one callback schedules more than one
 * priority callback, they are still enqueued in scheduling order.
 */
_AsyncCallbackEntry _lastPriorityCallback;
/**
 * Whether we are currently inside the callback loop.
 *
 * If we are inside the loop, we never need to schedule the loop,
 * even if adding a first element.
 */
bool _isInCallbackLoop = false;

void _asyncRunCallbackLoop() {
  while (_nextCallback != null) {
    _lastPriorityCallback = null;
    _AsyncCallbackEntry entry = _nextCallback;
    _nextCallback = entry.next;
    if (_nextCallback == null) _lastCallback = null;
    entry.callback();
  }
}

void _asyncRunCallback() {
  _isInCallbackLoop = true;
  try {
    _asyncRunCallbackLoop();
  } finally {
    _lastPriorityCallback = null;
    _isInCallbackLoop = false;
    if (_nextCallback != null) _AsyncRun._scheduleImmediate(_asyncRunCallback);
  }
}

/**
 * Schedules a callback to be called as a microtask.
 *
 * The microtask is called after all other currently scheduled
 * microtasks, but as part of the current system event.
 */
void _scheduleAsyncCallback(callback) {
  // Optimizing a group of Timer.run callbacks to be executed in the
  // same Timer callback.
  if (_nextCallback == null) {
    _nextCallback = _lastCallback = new _AsyncCallbackEntry(callback);
    if (!_isInCallbackLoop) {
      _AsyncRun._scheduleImmediate(_asyncRunCallback);
    }
  } else {
    _AsyncCallbackEntry newEntry = new _AsyncCallbackEntry(callback);
    _lastCallback.next = newEntry;
    _lastCallback = newEntry;
  }
}

/**
 * Schedules a callback to be called before all other currently scheduled ones.
 *
 * This callback takes priority over existing scheduled callbacks.
 * It is only used internally to give higher priority to error reporting.
 */
void _schedulePriorityAsyncCallback(callback) {
  _AsyncCallbackEntry entry = new _AsyncCallbackEntry(callback);
  if (_nextCallback == null) {
    _scheduleAsyncCallback(callback);
    _lastPriorityCallback = _lastCallback;
  } else if (_lastPriorityCallback == null) {
    entry.next = _nextCallback;
    _nextCallback = _lastPriorityCallback = entry;
  } else {
    entry.next = _lastPriorityCallback.next;
    _lastPriorityCallback.next = entry;
    _lastPriorityCallback = entry;
    if (entry.next == null) {
      _lastCallback = entry;
    }
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
  static void _scheduleImmediate(void callback()) {
    scheduleImmediateClosure(callback);
  }

  static final Function scheduleImmediateClosure =
      _initializeScheduleImmediate();

  static Function _initializeScheduleImmediate() {
    requiresPreamble();
    if (JS('', 'self.scheduleImmediate') != null) {
      return _scheduleImmediateJsOverride;
    }
    if (JS('', 'self.MutationObserver') != null &&
        JS('', 'self.document') != null) {
      // Use mutationObservers.
      var div = JS('', 'self.document.createElement("div")');
      var span = JS('', 'self.document.createElement("span")');
      var storedCallback;

      internalCallback(_) {
        leaveJsAsync();
        var f = storedCallback;
        storedCallback = null;
        f();
      };

      var observer = JS('', 'new self.MutationObserver(#)',
          convertDartClosureToJS(internalCallback, 1));
      JS('', '#.observe(#, { childList: true })',
          observer, div);

      return (void callback()) {
        assert(storedCallback == null);
        enterJsAsync();
        storedCallback = callback;
        // Because of a broken shadow-dom polyfill we have to change the
        // children instead a cheap property.
        // See https://github.com/Polymer/ShadowDOM/issues/468
        JS('', '#.firstChild ? #.removeChild(#): #.appendChild(#)',
            div, div, span, div, span);
      };
    } else if (JS('', 'self.setImmediate') != null) {
      return _scheduleImmediateWithSetImmediate;
    }
    // TODO(20055): We should use DOM promises when available.
    return _scheduleImmediateWithTimer;
  }

  static void _scheduleImmediateJsOverride(void callback()) {
    internalCallback() {
      leaveJsAsync();
      callback();
    };
    enterJsAsync();
    JS('void', 'self.scheduleImmediate(#)',
       convertDartClosureToJS(internalCallback, 0));
  }

  static void _scheduleImmediateWithSetImmediate(void callback()) {
    internalCallback() {
      leaveJsAsync();
      callback();
    };
    enterJsAsync();
    JS('void', 'self.setImmediate(#)',
       convertDartClosureToJS(internalCallback, 0));
  }

  static void _scheduleImmediateWithTimer(void callback()) {
    Timer._createTimer(Duration.ZERO, callback);
  }
}
