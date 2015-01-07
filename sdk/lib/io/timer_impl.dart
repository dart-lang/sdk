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
  // Cancels the timer in the event handler.
  static const int _NO_TIMER = -1;

  // Timers are ordered by wakeup time.
  static _TimerHeap _heap = new _TimerHeap();
  static _Timer _firstZeroTimer;
  static _Timer _lastZeroTimer;

  // We use an id to be able to sort timers with the same expiration time.
  // ids are recycled after ID_MASK enqueues or when the timer queue is empty.
  static int _ID_MASK = 0x1fffffff;
  static int _idCount = 0;

  static RawReceivePort _receivePort;
  static SendPort _sendPort;
  static int _scheduledWakeupTime;
  static bool _handlingCallbacks = false;

  Function _callback;  // Closure to call when timer fires. null if canceled.
  int _wakeupTime;  // Expiration time.
  int _milliSeconds;  // Duration specified at creation.
  bool _repeating;  // Indicates periodic timers.
  var _indexOrNext;  // Index if part of the TimerHeap, link otherwise.
  int _id;  // Incrementing id to enable sorting of timers with same expiry.

  // Get the next available id. We accept collisions and reordering when the
  // _idCount overflows and the timers expire at the same millisecond.
  static int _nextId() {
    var result = _idCount;
    _idCount = (_idCount + 1) & _ID_MASK;
    return result;
  }

  _Timer._internal(this._callback,
                   this._wakeupTime,
                   this._milliSeconds,
                   this._repeating) : _id = _nextId();

  static Timer _createTimer(void callback(Timer timer),
                            int milliSeconds,
                            bool repeating) {
    // Negative timeouts are treated as if 0 timeout.
    if (milliSeconds < 0) {
      milliSeconds = 0;
    }
    // Add one because DateTime.now() is assumed to round down
    // to nearest millisecond, not up, so that time + duration is before
    // duration milliseconds from now. Using microsecond timers like
    // Stopwatch allows detecting that the timer fires early.
    int now = new DateTime.now().millisecondsSinceEpoch;
    int wakeupTime = (milliSeconds == 0) ? now : (now + 1 + milliSeconds);

    _Timer timer = new _Timer._internal(callback,
                                        wakeupTime,
                                        milliSeconds,
                                        repeating);

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

  bool get _isInHeap => _indexOrNext is int;

  void _clear() {
    _callback = null;
  }

  int _compareTo(_Timer other) {
    int c = _wakeupTime - other._wakeupTime;
    if (c != 0) return c;
    return _id - other._id;
  }

  bool get isActive => _callback != null;

  // Cancels a set timer. The timer is removed from the timer list and if
  // the given timer is the earliest timer the event handler is notified.
  void cancel() {
    _clear();
    if (!_isInHeap) return;
    // Only heap timers are really removed. Others are just dropped on
    // notification.
    bool update = (_firstZeroTimer == null) && _heap.isFirst(this);
    _heap.remove(this);
    if (update) {
      _notifyEventHandler();
    }
  }

  void _advanceWakeupTime() {
    // Recalculate the next wakeup time. For repeating timers with a 0 timeout
    // the next wakeup time is now.
    _id = _nextId();
    if (_milliSeconds > 0) {
      _wakeupTime += _milliSeconds;
    } else {
      _wakeupTime = new DateTime.now().millisecondsSinceEpoch;
    }
  }

  // Adds a timer to the heap or timer list. Timers with the same wakeup time
  // are enqueued in order and notified in FIFO order.
  bool _addTimerToHeap() {
    if (_milliSeconds == 0) {
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
        _EventHandler._sendData(null, _sendPort, _NO_TIMER);
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
        var wakeupTime = _heap.first._wakeupTime;
        if ((_scheduledWakeupTime == null) ||
            (wakeupTime != _scheduledWakeupTime)) {
          _EventHandler._sendData(null, _sendPort, wakeupTime);
          _scheduledWakeupTime = wakeupTime;
        }
      }
    }
  }

  static void _handleTimeout(pendingImmediateCallback) {
    int currentTime = new DateTime.now().millisecondsSinceEpoch;
    // Collect all pending timers.
    var head = null;
    var tail = null;
    // Keep track of the lowest wakeup times for both the list and heap. If
    // the respective queue is empty move its time beyond the current time.
    var heapTime = _heap.isEmpty ?
        (currentTime + 1) : _heap.first._wakeupTime;
    var listTime = (_firstZeroTimer == null) ?
        (currentTime + 1) : _firstZeroTimer._wakeupTime;

    while ((heapTime <= currentTime) || (listTime <= currentTime)) {
      var timer;
      // Consume the timers in order by removing from heap or list based on
      // their wakeup time and update the queue's time.
      assert((heapTime != listTime) ||
             ((_heap.first != null) && (_firstZeroTimer != null)));
      if ((heapTime < listTime) ||
          ((heapTime == listTime) &&
           (_heap.first._id < _firstZeroTimer._id))) {
        timer = _heap.removeFirst();
        heapTime = _heap.isEmpty ? (currentTime + 1) : _heap.first._wakeupTime;
      } else {
        timer = _firstZeroTimer;
        assert(timer._milliSeconds == 0);
        _firstZeroTimer = timer._indexOrNext;
        if (_firstZeroTimer == null) {
          _lastZeroTimer = null;
          listTime = currentTime + 1;
        } else {
          // We want to drain all entries from the list as they should have
          // been pending for 0 ms. To prevent issues with current time moving
          // we ensure that the listTime does not go beyond current, unless the
          // list is empty.
          listTime = _firstZeroTimer._wakeupTime;
          if (listTime > currentTime) {
            listTime = currentTime;
          }
        }
      }

      // Append this timer to the pending timer list.
      timer._indexOrNext = null;
      if (head == null) {
        assert(tail == null);
        head = timer;
        tail = timer;
      } else {
        tail._indexOrNext = timer;
        tail = timer;
      }
    }

    // No timers queued: Early exit.
    if (head == null) {
      return;
    }

    // If there are no pending timers currently reset the id space before we
    // have a chance to enqueue new timers.
    assert(_firstZeroTimer == null);
    if (_heap.isEmpty) {
      _idCount = 0;
    }

    // Trigger all of the pending timers. New timers added as part of the
    // callbacks will be enqueued now and notified in the next spin at the
    // earliest.
    _handlingCallbacks = true;
    try {
      while (head != null) {
        // Dequeue the first candidate timer.
        var timer = head;
        head = timer._indexOrNext;
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
          if (timer._repeating && (timer._callback != null)) {
            timer._advanceWakeupTime();
            timer._addTimerToHeap();
          }
          // Execute pending micro tasks.
          pendingImmediateCallback();
        }
      }
    } finally {
      _handlingCallbacks = false;
      _notifyEventHandler();
    }
  }

  // Creates a receive port and registers an empty handler on that port. Just
  // the triggering of the event loop will ensure that timers are executed.
  static _ignoreMessage(_) => null;

  static void _createTimerHandler() {
    assert(_receivePort == null);
    _receivePort = new RawReceivePort(_ignoreMessage);
    _sendPort = _receivePort.sendPort;
    _scheduledWakeupTime = null;
  }

  static void _shutdownTimerHandler() {
    _receivePort.close();
    _receivePort = null;
    _sendPort = null;
    _scheduledWakeupTime = null;
  }

  // The Timer factory registered with the dart:async library by the embedder.
  static Timer _factory(int milliSeconds,
                        void callback(Timer timer),
                        bool repeating) {
    if (repeating) {
      return new _Timer.periodic(milliSeconds, callback);
    }
    return new _Timer(milliSeconds, callback);
  }
}

// Provide a closure which will allocate a Timer object to be able to hook
// up the Timer interface in dart:isolate with the implementation here.
_getTimerFactoryClosure() {
  runTimerClosure = _Timer._handleTimeout;
  return _Timer._factory;
}
