// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple [StopWatch] interface to measure elapsed time.
 */
interface StopWatch factory StopWatchImplementation {

  /**
   * Creates a [StopWatch] in stopped state with a zero elapsed count.
   */
  StopWatch();

  /**
   * Starts the [StopWatch]. The [elapsed] count is increasing monotonically.
   * If the [StopWatch] has been stopped, then calling start again restarts it.
   * If the [StopWatch] is currently running, then calling start does nothing.
   */
  void start();

  /**
   * Stops the [StopWatch]. The [elapsed] count stops increasing.
   * If the [StopWatch] is currently not running, then calling stop does nothing.
   */
  void stop();

  /**
   * Returns the elapsed number of clock ticks since calling [start] while the
   * [StopWatch] is running.
   * Returns the elapsed number of clock ticks between calling [start] and
   * calling [stop].
   * Returns 0 if the [StopWatch] has never been started.
   * The elapsed number of clock ticks increases by [frequency] every second.
   */
  int elapsed();

  /**
   * Returns the [elapsed] counter converted to microseconds.
   */
  int elapsedInUs();

  /**
   * Returns the [elapsed] counter converted to milliseconds.
   */
  int elapsedInMs();

  /**
   * Returns the frequency of the elapsed counter in Hz.
   */
  int frequency();

}
