// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

typedef void _MicrotaskCallback();

/**
 * This class attempts to invoke a callback as soon as the current event stack
 * unwinds, but before the browser repaints.
 */
abstract class _MicrotaskScheduler {
  bool _nextMicrotaskFrameScheduled = false;
  final _MicrotaskCallback _callback;

  _MicrotaskScheduler(this._callback);

  /**
   * Creates the best possible microtask scheduler for the current platform.
   */
  factory _MicrotaskScheduler.best(_MicrotaskCallback callback) {
    if (Window._supportsSetImmediate) {
      return new _SetImmediateScheduler(callback);
    } else if (MutationObserver.supported) {
      return new _MutationObserverScheduler(callback);
    }
    return new _PostMessageScheduler(callback);
  }

  /**
   * Schedules a microtask callback if one has not been scheduled already.
   */
  void maybeSchedule() {
    if (this._nextMicrotaskFrameScheduled) {
      return;
    }
    this._nextMicrotaskFrameScheduled = true;
    this._schedule();
  }

  /**
   * Does the actual scheduling of the callback.
   */
  void _schedule();

  /**
   * Handles the microtask callback and forwards it if necessary.
   */
  void _onCallback() {
    // Ignore spurious messages.
    if (!_nextMicrotaskFrameScheduled) {
      return;
    }
    _nextMicrotaskFrameScheduled = false;
    this._callback();
  }
}

/**
 * Scheduler which uses window.postMessage to schedule events.
 */
class _PostMessageScheduler extends _MicrotaskScheduler {
  const _MICROTASK_MESSAGE = "DART-MICROTASK";

  _PostMessageScheduler(_MicrotaskCallback callback): super(callback) {
      // Messages from other windows do not cause a security risk as
      // all we care about is that _handleMessage is called
      // after the current event loop is unwound and calling the function is
      // a noop when zero requests are pending.
      window.onMessage.listen(this._handleMessage);
  }

  void _schedule() {
    window.postMessage(_MICROTASK_MESSAGE, "*");
  }

  void _handleMessage(e) {
    this._onCallback();
  }
}

/**
 * Scheduler which uses a MutationObserver to schedule events.
 */
class _MutationObserverScheduler extends _MicrotaskScheduler {
  MutationObserver _observer;
  Element _dummy;

  _MutationObserverScheduler(_MicrotaskCallback callback): super(callback) {
    // Mutation events get fired as soon as the current event stack is unwound
    // so we just make a dummy event and listen for that.
    _observer = new MutationObserver(this._handleMutation);
    _dummy = new DivElement();
    _observer.observe(_dummy, attributes: true);
  }

  void _schedule() {
    // Toggle it to trigger the mutation event.
    _dummy.hidden = !_dummy.hidden;
  }

  _handleMutation(List<MutationRecord> mutations, MutationObserver observer) {
    this._onCallback();
  }
}

/**
 * Scheduler which uses window.setImmediate to schedule events.
 */
class _SetImmediateScheduler extends _MicrotaskScheduler {
  _SetImmediateScheduler(_MicrotaskCallback callback): super(callback);

  void _schedule() {
    window._setImmediate(_handleImmediate);
  }

  void _handleImmediate() {
    this._onCallback();
  }
}

List<TimeoutHandler> _pendingMicrotasks;
_MicrotaskScheduler _microtaskScheduler = null;

void _maybeScheduleMicrotaskFrame() {
  if (_microtaskScheduler == null) {
    _microtaskScheduler =
      new _MicrotaskScheduler.best(_completeMicrotasks);
  }
  _microtaskScheduler.maybeSchedule();
}

/**
 * Registers a [callback] which is called after the current execution stack
 * unwinds.
 */
void _addMicrotaskCallback(TimeoutHandler callback) {
  if (_pendingMicrotasks == null) {
    _pendingMicrotasks = <TimeoutHandler>[];
    _maybeScheduleMicrotaskFrame();
  }
  _pendingMicrotasks.add(callback);
}


/**
 * Complete all pending microtasks.
 */
void _completeMicrotasks() {
  var callbacks = _pendingMicrotasks;
  _pendingMicrotasks = null;
  for (var callback in callbacks) {
    callback();
  }
}
