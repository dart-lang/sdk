// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Timer implements Timer {

  /*
   * Set jitter to wake up timer events that would happen in _TIMER_JITTER ms.
   */
  static final int _TIMER_JITTER = 0;

  /*
   * Disables the timer.
   */
  static final int _NO_TIMER = -1;

  factory _Timer(void callback(Timer timer),
                 int milliSeconds,
                 bool repeating) {
    EventHandler._start();
    if (_timers === null) {
      _timers = new DoubleLinkedQueue<_Timer>();
    }
    Timer timer = new _Timer._internal();
    timer._callback = callback;
    timer._milliSeconds = milliSeconds;
    timer._wakeupTime = (new Date.now()).value + milliSeconds;
    timer._repeating = repeating;
    timer._addTimerToList();
    timer._notifyEventHandler();
    return timer;
  }

  _Timer._internal() {}

  void _clear() {
    _callback = null;
    _milliSeconds = 0;
    _wakeupTime = 0;
    _repeating = false;
  }

  /*
   * Cancels a set timer. The timer is removed from the timer list and if
   * the given timer is the earliest timer the native timer is reset.
   */
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

  /*
   * Adds a timer to the timer list and resets the native timer if it is the
   * earliest timer in the list.  Timers with the same wakeup time are enqueued
   * in order and notified in FIFO order.
   */
  void _addTimerToList() {
    if (_callback !== null) {

      DoubleLinkedQueueEntry<_Timer> entry = _timers.firstEntry();
      if (entry === null) {
        _createTimerHandler();
      }

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
    if (_timers.firstEntry() === null) {
      if (_receivePort != null) {
        EventHandler._sendData(-1, _receivePort, _NO_TIMER);
        _shutdownTimerHandler();
      }
    } else {
      EventHandler._sendData(-1,
                             _receivePort,
                             _timers.firstEntry().element._wakeupTime);
    }
  }


  /*
   * Creates a receive port and registers the timer handler on that receive
   * port.
   */
  void _createTimerHandler() {

    void _handleTimeout() {
      int currentTime = (new Date.now()).value + _TIMER_JITTER;

      DoubleLinkedQueueEntry<_Timer> entry = _timers.firstEntry();
      while (entry !== null) {
        _Timer timer = entry.element;
        if (timer._wakeupTime <= currentTime) {
          entry.remove();
          timer._callback(timer);
          // Always process the event with the earliest wakeupTime first.
          entry = _timers.firstEntry();
          if (timer._repeating) {
            timer._advanceWakeupTime();
            timer._addTimerToList();
            _notifyEventHandler();
          }
        } else {
          break;
        }
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


  /*
   * Timers are ordered by wakeup time.
   */
  static DoubleLinkedQueue<_Timer> _timers;

  static ReceivePort _receivePort;

  var _callback;
  int _milliSeconds;
  int _wakeupTime;
  bool _repeating;
}

