// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of dart.async;

/**
 *  A basic asynchronous notification.
 */
abstract class Signal {
  factory Signal.delayed(int milliseconds) {
    var completer = new SignalCompleter();
    new Timer(milliseconds, (_) => completer.complete());
    return completer.signal;
  }
  /**
   * The [onComplete] handler is called when the signal completes.
   *
   * If the signal is already complete, the [onComplete] handler is called
   * as soon as possible, but no sooner than the next time an event is fired.
   */
  void then(void onComplete());
}

typedef _SignalCompleteHandler();

/**
 * Simple [Signal] controller that creates a [Signal] and allows completing it.
 */
class SignalCompleter {
  final Signal signal;
  SignalCompleter() : signal = new _SignalImpl();
  void complete() {
    _SignalImpl mySignal = signal;
    mySignal._complete();
  }
}

/**
 * Simple Signal implementation receiving its completion from a
 * [SignalCompleter].
 */
class _SignalImpl implements Signal {
  /** Single-linked list of "done" event handlers to notify. */
  _SignalListener _listeners = null;

  /** Whether the signal is already completed. */
  bool _isComplete = false;

  void then(void onComplete()) {
    _listeners = new _SignalListener(_listeners, onComplete);
    if (_isComplete) {
      // Schedule the done events as soon as the event queue is ready.
      new Timer(0, (Timer timer) { _sendDone(); });
    }
  }

  /**
   * Complete the signal.
   *
   * This immediately notifies all listeners on the signal.
   */
  void _complete() {
    assert(!_isComplete);  // Only complete once.
    _isComplete = true;
    _sendDone();
  }

  /**
   * Notify all listeners.
   */
  void _sendDone() {
    while (_listeners != null) {
      _DoneHandler onDone = _listeners.listener;
      _listeners = _listeners.next;
      try {
        onDone();
      } catch (e, s) {
        new AsyncError(e, s).throwDelayed();
      }
    }
  }
}

/** Single-linked list element of the listeners on a [_SignalImpl]. */
class _SignalListener {
  _SignalListener next;
  _SignalCompleteHandler listener;
  _SignalListener(this.next, this.listener);
}
