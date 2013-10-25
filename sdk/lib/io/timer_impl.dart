// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

class _Timer extends LinkedListEntry<_Timer> implements Timer {
  // Disables the timer.
  static const int _NO_TIMER = -1;

  // Timers are ordered by wakeup time.
  static LinkedList<_Timer> _timers = new LinkedList<_Timer>();

  static RawReceivePort _receivePort;
  static bool _handling_callbacks = false;

  Function _callback;
  int _milliSeconds;
  int _wakeupTime;

  static Timer _createTimer(void callback(Timer timer),
                            int milliSeconds,
                            bool repeating) {
    _Timer timer = new _Timer._internal();
    timer._callback = callback;
    timer._wakeupTime =
        new DateTime.now().millisecondsSinceEpoch + milliSeconds;
    timer._milliSeconds = repeating ? milliSeconds : -1;
    timer._addTimerToList();
    timer._notifyEventHandler();
    return timer;
  }

  factory _Timer(int milliSeconds, void callback(Timer timer)) {
    return _createTimer(callback, milliSeconds, false);
  }

  factory _Timer.periodic(int milliSeconds, void callback(Timer timer)) {
    return _createTimer(callback, milliSeconds, true);
  }

  _Timer._internal() {}

  void _clear() {
    _callback = null;
    _milliSeconds = 0;
    _wakeupTime = 0;
  }

  bool get _repeating => _milliSeconds >= 0;

  bool get isActive => _callback != null;

  // Cancels a set timer. The timer is removed from the timer list and if
  // the given timer is the earliest timer the native timer is reset.
  void cancel() {
    _clear();
    // Return if already canceled.
    if (list == null) return;
    assert(!_timers.isEmpty);
    _Timer first = _timers.first;
    unlink();
    if (identical(first, this)) {
      _notifyEventHandler();
    }
  }

  void _advanceWakeupTime() {
    assert(_milliSeconds >= 0);
    _wakeupTime += _milliSeconds;
  }

  // Adds a timer to the timer list and resets the native timer if it is the
  // earliest timer in the list. Timers with the same wakeup time are enqueued
  // in order and notified in FIFO order.
  void _addTimerToList() {
    _Timer entry = _timers.isEmpty ? null : _timers.first;
    while (entry != null) {
      if (_wakeupTime < entry._wakeupTime) {
        entry.insertBefore(this);
        return;
      }
      entry = entry.next;
    }
    _timers.add(this);
  }


  void _notifyEventHandler() {
    if (_handling_callbacks) {
      // While we are already handling callbacks we will not notify the event
      // handler. _handleTimeout will call _notifyEventHandler once all pending
      // timers are processed.
      return;
    }

    if (_timers.isEmpty) {
      // No pending timers: Close the receive port and let the event handler
      // know.
      if (_receivePort != null) {
        _EventHandler._sendData(null, _receivePort, _NO_TIMER);
        _shutdownTimerHandler();
      }
    } else {
      if (_receivePort == null) {
        // Create a receive port and register a message handler for the timer
        // events.
        _createTimerHandler();
      }
      _EventHandler._sendData(null,
                              _receivePort,
                              _timers.first._wakeupTime);
    }
  }


  // Creates a receive port and registers the timer handler on that
  // receive port.
  void _createTimerHandler() {

    void _handleTimeout() {
      int currentTime = new DateTime.now().millisecondsSinceEpoch;

      // Collect all pending timers.
      var pending_timers = new List();
      while (!_timers.isEmpty) {
        _Timer entry = _timers.first;
        if (entry._wakeupTime <= currentTime) {
          entry.unlink();
          pending_timers.add(entry);
        } else {
          break;
        }
      }

      // Trigger all of the pending timers. New timers added as part of the
      // callbacks will be enqueued now and notified in the next spin at the
      // earliest.
      _handling_callbacks = true;
      try {
        for (var timer in pending_timers) {
          // One of the timers in the pending_timers list can cancel
          // one of the later timers which will set the callback to
          // null.
          if (timer._callback != null) {
            var callback = timer._callback;
            if (!timer._repeating) {
              //Mark timer as inactive.
              timer._callback = null;
            }
            callback(timer);
            // Re-insert repeating timer if not canceled.
            if (timer._repeating && timer._callback != null) {
              timer._advanceWakeupTime();
              timer._addTimerToList();
            }
          }
        }
      } finally {
        _handling_callbacks = false;
        _notifyEventHandler();
      }
    }

    if(_receivePort == null) {
      _receivePort = new RawReceivePort((_) { _handleTimeout(); });
    }
  }

  void _shutdownTimerHandler() {
    _receivePort.close();
    _receivePort = null;
  }
}

// Provide a closure which will allocate a Timer object to be able to hook
// up the Timer interface in dart:isolate with the implementation here.
_getTimerFactoryClosure() {
  return (int milliSeconds, void callback(Timer timer), bool repeating) {
    if (repeating) {
      return new _Timer.periodic(milliSeconds, callback);
    }
    return new _Timer(milliSeconds, callback);
  };
}


