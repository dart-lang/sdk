// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// Timer heap implemented as a array-based binary heap[0].
// This allows for O(1) `first`, O(log(n)) `remove`/`removeFirst` and O(log(n))
// `add`.
//
// To ensure the timers are ordered by insertion time, the _Timer class has a
// `_id` field set when added to the heap.
//
// [0] http://en.wikipedia.org/wiki/Binary_heap
class _TimerHeap {
  List<_Timer> _list;
  int _used = 0;

  _TimerHeap([int initSize = 7])
      : _list = new List<_Timer>(initSize);

  bool get isEmpty => _used == 0;
  bool get isNotEmpty => _used > 0;

  _Timer get first => _list[0];

  bool isFirst(_Timer timer) => timer._indexOrNext == 0;

  void add(_Timer timer) {
    if (_used == _list.length) {
      _resize();
    }
    timer._indexOrNext = _used++;
    _list[timer._indexOrNext] = timer;
    _bubbleUp(timer);
  }

  _Timer removeFirst() {
    var f = first;
    remove(f);
    return f;
  }

  void remove(_Timer timer) {
    _used--;
    timer._id = -1;
    if (isEmpty) {
      _list[0] = null;
      timer._indexOrNext = null;
      return;
    }
    var last = _list[_used];
    if (!identical(last, timer)) {
      last._indexOrNext = timer._indexOrNext;
      _list[last._indexOrNext] = last;
      if (last._compareTo(timer) < 0) {
        _bubbleUp(last);
      } else {
        _bubbleDown(last);
      }
    }
    _list[_used] = null;
    timer._indexOrNext = null;
  }

  void _resize() {
    var newList = new List(_list.length * 2 + 1);
    newList.setRange(0, _used, _list);
    _list = newList;
  }

  void _bubbleUp(_Timer timer) {
    while (!isFirst(timer)) {
      Timer parent = _parent(timer);
      if (timer._compareTo(parent) < 0) {
        _swap(timer, parent);
      } else {
        break;
      }
    }
  }

  void _bubbleDown(_Timer timer) {
    while (true) {
      int leftIndex = _leftChildIndex(timer._indexOrNext);
      int rightIndex = _rightChildIndex(timer._indexOrNext);
      _Timer newest = timer;
      if (leftIndex < _used && _list[leftIndex]._compareTo(newest) < 0) {
        newest = _list[leftIndex];
      }
      if (rightIndex < _used && _list[rightIndex]._compareTo(newest) < 0) {
        newest = _list[rightIndex];
      }
      if (identical(newest, timer)) {
        // We are where we should be, break.
        break;
      }
      _swap(newest, timer);
    }
  }

  void _swap(_Timer first, _Timer second) {
    int tmp = first._indexOrNext;
    first._indexOrNext = second._indexOrNext;
    second._indexOrNext = tmp;
    _list[first._indexOrNext] = first;
    _list[second._indexOrNext] = second;
  }

  Timer _parent(_Timer timer) => _list[_parentIndex(timer._indexOrNext)];
  Timer _leftChild(_Timer timer) => _list[_leftChildIndex(timer._indexOrNext)];
  Timer _rightChild(_Timer timer) =>
      _list[_rightChildIndex(timer._indexOrNext)];

  static int _parentIndex(int index) => (index - 1) ~/ 2;
  static int _leftChildIndex(int index) => 2 * index + 1;
  static int _rightChildIndex(int index) => 2 * index + 2;
}

class _Timer implements Timer {
  // Disables the timer.
  static const int _NO_TIMER = -1;

  // Timers are ordered by wakeup time.
  static _TimerHeap _heap = new _TimerHeap();
  static _Timer _firstZeroTimer;
  static _Timer _lastZeroTimer;
  static int _idCount = 0;

  static RawReceivePort _receivePort;
  static SendPort _sendPort;
  static bool _handlingCallbacks = false;

  Function _callback;
  int _milliSeconds;
  int _wakeupTime = 0;
  var _indexOrNext;
  int _id = -1;

  static Timer _createTimer(void callback(Timer timer),
                            int milliSeconds,
                            bool repeating) {
    _Timer timer = new _Timer._internal();
    timer._callback = callback;
    if (milliSeconds > 0) {
      // Add one because DateTime.now() is assumed to round down
      // to nearest millisecond, not up, so that time + duration is before
      // duration milliseconds from now. Using micosecond timers like
      // Stopwatch allows detecting that the timer fires early.
      timer._wakeupTime =
          new DateTime.now().millisecondsSinceEpoch + 1 + milliSeconds;
    }
    timer._milliSeconds = repeating ? milliSeconds : -1;
    if (timer._addTimerToHeap()) {
      // The new timer is the first in queue. Update event handler.
      _notifyEventHandler();
    }
    return timer;
  }

  factory _Timer(int milliSeconds, void callback(Timer timer)) {
    return _createTimer(callback, milliSeconds, false);
  }

  factory _Timer.periodic(int milliSeconds, void callback(Timer timer)) {
    return _createTimer(callback, milliSeconds, true);
  }

  _Timer._internal() {}

  bool get _isInHeap => _id >= 0;

  void _clear() {
    _callback = null;
  }

  int _compareTo(_Timer other) {
    int c = _wakeupTime - other._wakeupTime;
    if (c != 0) return c;
    return _id - other._id;
  }

  bool get _repeating => _milliSeconds >= 0;

  bool get isActive => _callback != null;

  // Cancels a set timer. The timer is removed from the timer list and if
  // the given timer is the earliest timer the native timer is reset.
  void cancel() {
    _clear();
    if (!_isInHeap) return;
    assert(_wakeupTime != 0);
    bool update = (_firstZeroTimer == null) && _heap.isFirst(this);
    _heap.remove(this);
    if (update) {
      _notifyEventHandler();
    }
  }

  void _advanceWakeupTime() {
    assert(_milliSeconds >= 0);
    _wakeupTime += _milliSeconds;
  }

  // Adds a timer to the timer list. Timers with the same wakeup time are
  // enqueued in order and notified in FIFO order.
  bool _addTimerToHeap() {
    if (_wakeupTime == 0) {
      if (_firstZeroTimer == null) {
        _lastZeroTimer = this;
        _firstZeroTimer = this;
        return true;
      } else {
        _lastZeroTimer._indexOrNext = this;
        _lastZeroTimer = this;
        return false;
      }
    } else {
      _id = _idCount++;
      _heap.add(this);
      return _firstZeroTimer == null && _heap.isFirst(this);
    }
  }


  static void _notifyEventHandler() {
    if (_handlingCallbacks) {
      // While we are already handling callbacks we will not notify the event
      // handler. _handleTimeout will call _notifyEventHandler once all pending
      // timers are processed.
      return;
    }

    if (_firstZeroTimer == null && _heap.isEmpty) {
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
      if (_firstZeroTimer != null) {
        _sendPort.send(null);
      } else {
        _EventHandler._sendData(null,
                                _receivePort,
                                _heap.first._wakeupTime);
      }
    }
  }

  static void _handleTimeout(_) {
    int currentTime = new DateTime.now().millisecondsSinceEpoch;
    // Collect all pending timers.
    var timer = _firstZeroTimer;
    var nextTimer = _lastZeroTimer;
    _firstZeroTimer = null;
    _lastZeroTimer = null;
    while (_heap.isNotEmpty && _heap.first._wakeupTime <= currentTime) {
      var next = _heap.removeFirst();
      if (timer == null) {
        nextTimer = next;
        timer = next;
      } else {
        nextTimer._indexOrNext = next;
        nextTimer = next;
      }
    }

    // Trigger all of the pending timers. New timers added as part of the
    // callbacks will be enqueued now and notified in the next spin at the
    // earliest.
    _handlingCallbacks = true;
    try {
      while (timer != null) {
        var next = timer._indexOrNext;
        timer._indexOrNext = null;
        // One of the timers in the pending_timers list can cancel
        // one of the later timers which will set the callback to
        // null.
        if (timer._callback != null) {
          var callback = timer._callback;
          if (!timer._repeating) {
            // Mark timer as inactive.
            timer._callback = null;
          }
          callback(timer);
          // Re-insert repeating timer if not canceled.
          if (timer._repeating && timer._callback != null) {
            timer._advanceWakeupTime();
            timer._addTimerToHeap();
          }
        }
        timer = next;
      }
    } finally {
      _handlingCallbacks = false;
      _notifyEventHandler();
    }
  }

  // Creates a receive port and registers the timer handler on that
  // receive port.
  static void _createTimerHandler() {
    if(_receivePort == null) {
      _receivePort = new RawReceivePort(_handleTimeout);
      _sendPort = _receivePort.sendPort;
    }
  }

  static void _shutdownTimerHandler() {
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


