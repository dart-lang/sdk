// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Timer implements Timer {
  // Set jitter to wake up timer events that would happen in _TIMER_JITTER ms.
  static const int _TIMER_JITTER = 0;

  // Disables the timer.
  static const int _NO_TIMER = -1;

  static Timer _createTimer(void callback(Timer timer),
                           int milliSeconds,
                           bool repeating) {
    _EventHandler._start();
    if (_timers === null) {
      _timers = new DoubleLinkedQueue<_Timer>();
    }
    Timer timer = new _Timer._internal();
    timer._callback = callback;
    timer._milliSeconds = milliSeconds;
    timer._wakeupTime = (new Date.now()).millisecondsSinceEpoch + milliSeconds;
    timer._repeating = repeating;
    timer._addTimerToList();
    timer._notifyEventHandler();
    return timer;
  }

  factory _Timer(int milliSeconds, void callback(Timer timer)) {
    return _createTimer(callback, milliSeconds, false);
  }

  factory _Timer.repeating(int milliSeconds, void callback(Timer timer)) {
    return _createTimer(callback, milliSeconds, true);
  }

  _Timer._internal() {}

  void _clear() {
    _callback = null;
    _milliSeconds = 0;
    _wakeupTime = 0;
    _repeating = false;
  }


  // Cancels a set timer. The timer is removed from the timer list and if
  // the given timer is the earliest timer the native timer is reset.
  void cancel() {
    _clear();
    DoubleLinkedQueueEntry<_Timer> entry = _timers.firstEntry();
    DoubleLinkedQueueEntry<_Timer> first = _timers.firstEntry();

     while (entry !== null) {
      if (entry.element === this) {
        entry.remove();
        if (first.element == this) {
          entry = _timers.firstEntry();
          _notifyEventHandler();
        }
        return;
      }
      entry = entry.nextEntry();
    }
  }

  void _advanceWakeupTime() {
    _wakeupTime += _milliSeconds;
  }

  // Adds a timer to the timer list and resets the native timer if it is the
  // earliest timer in the list.  Timers with the same wakeup time are enqueued
  // in order and notified in FIFO order.
  void _addTimerToList() {
    if (_callback !== null) {

      DoubleLinkedQueueEntry<_Timer> entry = _timers.firstEntry();
      while (entry !== null) {
        if (_wakeupTime < entry.element._wakeupTime) {
          entry.prepend(this);
          return;
        }
        entry = entry.nextEntry();
      }
      _timers.addLast(this);
    }
  }


  void _notifyEventHandler() {
    if (_handling_callbacks) {
      // While we are already handling callbacks we will not notify the event
      // handler. _handleTimeout will call _notifyEventHandler once all pending
      // timers are processed.
      return;
    }

    if (_timers.firstEntry() === null) {
      // No pending timers: Close the receive port and let the event handler
      // know.
      if (_receivePort !== null) {
        _EventHandler._sendData(null, _receivePort, _NO_TIMER);
        _shutdownTimerHandler();
      }
    } else {
      if (_receivePort === null) {
        // Create a receive port and register a message handler for the timer
        // events.
        _createTimerHandler();
      }
      _EventHandler._sendData(null,
                              _receivePort,
                              _timers.firstEntry().element._wakeupTime);
    }
  }


  // Creates a receive port and registers the timer handler on that
  // receive port.
  void _createTimerHandler() {

    void _handleTimeout() {
      int currentTime =
          (new Date.now()).millisecondsSinceEpoch + _TIMER_JITTER;

      // Collect all pending timers.
      DoubleLinkedQueueEntry<_Timer> entry = _timers.firstEntry();
      var pending_timers = new List();
      while (entry !== null) {
        _Timer timer = entry.element;
        if (timer._wakeupTime <= currentTime) {
          entry.remove();
          pending_timers.addLast(timer);
          entry = _timers.firstEntry();
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
            timer._callback(timer);
            if (timer._repeating) {
              timer._advanceWakeupTime();
              timer._addTimerToList();
            }
          }
        }
      } finally {
        _handling_callbacks = false;
      }
      _notifyEventHandler();
    }

    if(_receivePort === null) {
      _receivePort = new ReceivePort();
      _receivePort.receive((var message, ignored) {
        _handleTimeout();
      });
    }
  }

  void _shutdownTimerHandler() {
    _receivePort.close();
    _receivePort = null;
  }


  // Timers are ordered by wakeup time.
  static DoubleLinkedQueue<_Timer> _timers;

  static ReceivePort _receivePort;
  static bool _handling_callbacks = false;

  var _callback;
  int _milliSeconds;
  int _wakeupTime;
  bool _repeating;
}

// Provide a closure which will allocate a Timer object to be able to hook
// up the Timer interface in dart:isolate with the implementation here.
_getTimerFactoryClosure() {
  return (int milliSeconds, void callback(Timer timer), bool repeating) {
    if (repeating) {
      return new _Timer.repeating(milliSeconds, callback);
    }
    return new _Timer(milliSeconds, callback);
  };
}


