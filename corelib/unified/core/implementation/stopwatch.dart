// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple implementation of the [Stopwatch] interface.
 */
class StopwatchImplementation implements Stopwatch {
  // The _start and _stop fields capture the time when [start] and [stop]
  // are called respectively.
  // If _start is null, then the [Stopwatch] has not been started yet.
  // If _stop is null, then the [Stopwatch] has not been stopped yet,
  // or is running.
  int _start;
  int _stop;

  StopwatchImplementation() : _start = null, _stop = null {}
  StopwatchImplementation.start() : _start = null, _stop = null {
    start();
  }

  void start() {
    if (_start === null) {
      // This stopwatch has never been started.
      _start = _Clock.now();
    } else {
      if (_stop === null) {
        return;
      }
      // Restarting this stopwatch. Prepend the elapsed time to the current
      // start time.
      _start = _Clock.now() - (_stop - _start);
      _stop = null;
    }
  }

  void stop() {
    if (_start === null || _stop !== null) {
      return;
    }
    _stop = _Clock.now();
  }

  void reset() {
    if (_start === null) return;
    // If [_start] is not null, then the stopwatch had already been started. It
    // may running right now.
    _start = _Clock.now();
    if (_stop !== null) {
      // The watch is not running. So simply set the [_stop] to [_start] thus
      // having an elapsed time of 0.
      _stop = _start;
    }
  }

  int elapsed() {
    if (_start === null) {
      return 0;
    }
    return (_stop === null) ? (_Clock.now() - _start) : (_stop - _start);
  }

  int elapsedInUs() {
    return (elapsed() * 1000000) ~/ frequency();
  }

  int elapsedInMs() {
    return (elapsed() * 1000) ~/ frequency();
  }

  int frequency() {
    return _Clock.frequency();
  }
}

/**
 * The class [_Clock] provides access to a monotonically incrementing clock
 * device.
 */
class _Clock {

  /**
   * Returns the current clock tick.
   */
  external static int now();

  /**
   * Returns the frequency of clock ticks in Hz.
   */
  external static int frequency();
}
