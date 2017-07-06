// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core.dart";

/**
 * A simple stopwatch interface to measure elapsed time.
 */
class Stopwatch {
  /**
   * Cached frequency of the system. Must be initialized in [_initTicker];
   */
  static int _frequency;

  // The _start and _stop fields capture the time when [start] and [stop]
  // are called respectively.
  // If _stop is null, the stopwatch is running.
  int _start = 0;
  int _stop = 0;

  /**
   * Creates a [Stopwatch] in stopped state with a zero elapsed count.
   *
   * The following example shows how to start a [Stopwatch]
   * immediately after allocation.
   * ```
   * var stopwatch = new Stopwatch()..start();
   * ```
   */
  Stopwatch() {
    if (_frequency == null) _initTicker();
  }

  /**
   * Frequency of the elapsed counter in Hz.
   */
  int get frequency => _frequency;

  /**
   * Starts the [Stopwatch].
   *
   * The [elapsed] count is increasing monotonically. If the [Stopwatch] has
   * been stopped, then calling start again restarts it without resetting the
   * [elapsed] count.
   *
   * If the [Stopwatch] is currently running, then calling start does nothing.
   */
  void start() {
    if (_stop != null) {
      // (Re)start this stopwatch.
      // Don't count the time while the stopwatch has been stopped.
      _start += _now() - _stop;
      _stop = null;
    }
  }

  /**
   * Stops the [Stopwatch].
   *
   * The [elapsedTicks] count stops increasing after this call. If the
   * [Stopwatch] is currently not running, then calling this method has no
   * effect.
   */
  void stop() {
    _stop ??= _now();
  }

  /**
   * Resets the [elapsed] count to zero.
   *
   * This method does not stop or start the [Stopwatch].
   */
  void reset() {
    _start = _stop ?? _now();
  }

  /**
   * The elapsed number of clock ticks since calling [start] while the
   * [Stopwatch] is running.
   *
   * This is the elapsed number of clock ticks between calling [start] and
   * calling [stop].
   *
   * Is 0 if the [Stopwatch] has never been started.
   *
   * The elapsed number of clock ticks increases by [frequency] every second.
   */
  int get elapsedTicks {
    return (_stop ?? _now()) - _start;
  }

  /**
   * The [elapsedTicks] counter converted to a [Duration].
   */
  Duration get elapsed {
    return new Duration(microseconds: elapsedMicroseconds);
  }

  /**
   * The [elapsedTicks] counter converted to microseconds.
   */
  int get elapsedMicroseconds {
    return (elapsedTicks * 1000000) ~/ frequency;
  }

  /**
   * The [elapsedTicks] counter converted to milliseconds.
   */
  int get elapsedMilliseconds {
    return (elapsedTicks * 1000) ~/ frequency;
  }

  /**
   * Whether the [Stopwatch] is currently running.
   */
  bool get isRunning => _stop == null;

  /**
   * Initializes the time-measuring system. *Must* initialize the [_frequency]
   * variable.
   */
  external static void _initTicker();
  external static int _now();
}
