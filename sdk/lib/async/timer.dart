// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

abstract class Timer {

  /**
   * Creates a new timer.
   *
   * The [callback] callback is invoked after the given [duration].
   * A negative duration is treated similar to a duration of 0.
   *
   * If the [duration] is statically known to be 0, consider using [run].
   *
   * Frequently the [duration] is either a constant or computed as in the
   * following example (taking advantage of the multiplication operator of
   * the Duration class):
   *
   *     const TIMEOUT = const Duration(seconds: 3);
   *     const ms = const Duration(milliseconds: 1);
   *
   *     startTimeout([int milliseconds]) {
   *       var duration = milliseconds == null ? TIMEOUT : ms * milliseconds;
   *       return new Timer(duration, handleTimeout);
   *     }
   *
   * Note: If Dart code using Timer is compiled to JavaScript, the finest
   * granularity available in the browser is 4 milliseconds.
   */
  external factory Timer(Duration duration, void callback());

  /**
   * Creates a new repeating timer.
   *
   * The [callback] is invoked repeatedly with [duration] intervals until
   * canceled. A negative duration is treated similar to a duration of 0.
   */
  external factory Timer.periodic(Duration duration,
                                  void callback(Timer timer));

  /**
   * Runs the given [callback] asynchronously as soon as possible.
   *
   * This function is equivalent to `new Timer(Duration.ZERO, callback)`.
   */
  static void run(void callback()) {
    new Timer(Duration.ZERO, callback);
  }

  /**
   * Cancels the timer.
   */
  void cancel();
}
