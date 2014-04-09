// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.utilities.general;

/**
 * Helper for measuring how much time is spent doing some operation.
 */
class TimeCounter {
  static TimeCounter _current = null;
  final Stopwatch _sw = new Stopwatch();

  /**
   * @return the number of milliseconds spent between [start] and [stop].
   */
  int get result => _sw.elapsedMilliseconds;

  /**
   * Starts counting time.
   *
   * @return the [TimeCounterHandle] that should be used to stop counting.
   */
  TimeCounter_TimeCounterHandle start() {
    return new TimeCounter_TimeCounterHandle(this);
  }
}

/**
 * The handle object that should be used to stop and update counter.
 */
class TimeCounter_TimeCounterHandle {
  final TimeCounter _counter;
  TimeCounter _prev;

  TimeCounter_TimeCounterHandle(this._counter) {
    // if there is some counter running, pause it
    _prev = TimeCounter._current;
    if (_prev != null) {
      _prev._sw.stop();
    }
    TimeCounter._current = _counter;
    // start this counter
    _counter._sw.start();
  }

  /**
   * Stops counting time and updates counter.
   */
  void stop() {
    _counter._sw.stop();
    // restore previous counter and resume it
    TimeCounter._current = _prev;
    if (_prev != null) {
      _prev._sw.start();
    }
  }
}