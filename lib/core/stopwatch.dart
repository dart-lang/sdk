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
  factory Stopwatch() => new StopwatchImplementation();

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
