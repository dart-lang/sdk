// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple [Stopwatch] interface to measure elapsed time.
 */
abstract class Stopwatch {
  /**
   * Creates a [Stopwatch] in stopped state with a zero elapsed count.
   *
   * The following example shows how to start a [Stopwatch]
   * right after allocation.
   *
   *     Stopwatch stopwatch = new Stopwatch()..start();
   */
  factory Stopwatch() => new _StopwatchImpl();

  /**
   * Starts the [Stopwatch]. The [elapsed] count is increasing monotonically.
   * If the [Stopwatch] has been stopped, then calling start again restarts it
   * without resetting the [elapsed] count.
   * If the [Stopwatch] is currently running, then calling start does nothing.
   */
  void start();

  /**
   * Stops the [Stopwatch]. The [elapsed] count stops increasing.
   * If the [Stopwatch] is currently not running, then calling stop does
   * nothing.
   */
  void stop();

  /**
   * Resets the [elapsed] count to zero. This method does not stop or start
   * the [Stopwatch].
   */
  void reset();

  /**
   * Returns the elapsed number of clock ticks since calling [start] while the
   * [Stopwatch] is running.
   * Returns the elapsed number of clock ticks between calling [start] and
   * calling [stop].
   * Returns 0 if the [Stopwatch] has never been started.
   * The elapsed number of clock ticks increases by [frequency] every second.
   */
  int get elapsedTicks;

  /**
   * Returns the [elapsedTicks] counter converted to microseconds.
   */
  int get elapsedMicroseconds;

  /**
   * Returns the [elapsedTicks] counter converted to milliseconds.
   */
  int get elapsedMilliseconds;

  /**
   * Returns the frequency of the elapsed counter in Hz.
   */
  int get frequency;
}

class _StopwatchImpl implements Stopwatch {
  // The _start and _stop fields capture the time when [start] and [stop]
  // are called respectively.
  // If _start is null, then the [Stopwatch] has not been started yet.
  // If _stop is null, then the [Stopwatch] has not been stopped yet,
  // or is running.
  int _start;
  int _stop;

  _StopwatchImpl() : _start = null, _stop = null {}

  void start() {
    if (_start === null) {
      // This stopwatch has never been started.
      _start = _now();
    } else {
      if (_stop === null) {
        return;
      }
      // Restarting this stopwatch. Prepend the elapsed time to the current
      // start time.
      _start = _now() - (_stop - _start);
      _stop = null;
    }
  }

  void stop() {
    if (_start === null || _stop !== null) {
      return;
    }
    _stop = _now();
  }

  void reset() {
    if (_start === null) return;
    // If [_start] is not null, then the stopwatch had already been started. It
    // may running right now.
    _start = _now();
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
    return (_stop === null) ? (_now() - _start) : (_stop - _start);
  }

  int elapsedInUs() {
    return (elapsed() * 1000000) ~/ frequency();
  }

  int elapsedInMs() {
    return (elapsed() * 1000) ~/ frequency();
  }

  int frequency() => _frequency();

  external static int _frequency();
  external static int _now();
}
