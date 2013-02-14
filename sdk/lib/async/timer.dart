// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

abstract class Timer {
  /**
   * Creates a new timer.
   *
   * The [callback] callback is invoked after the given [duration]
   * (a [Duration]) has passed. A negative duration is treated similar to
   * a duration of 0.
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
   * *Deprecation warning*: this constructor used to take an [int] (the time
   * in milliseconds) and a callback with one argument (the timer). This has
   * changed to a [Duration] and a callback without arguments.
   */
  // TODO(floitsch): add types.
  external factory Timer(var duration, Function callback);

  /**
   * Creates a new repeating timer.
   *
   * The [callback] is invoked repeatedly with [duration] intervals until
   * canceled. A negative duration is treated similar to a duration of 0.
   *
   * *Deprecation warning*: this constructor used to take an [int] (the time
   * in milliseconds). This has changed to a [Duration].
   */
  external factory Timer.repeating(var duration,
                                   void callback(Timer timer));

  /**
   * Runs the given [callback] asynchronously as soon as possible.
   *
   * Returns a [Timer] that can be cancelled if the callback is not necessary
   * anymore.
   */
  static Timer run(void callback()) {
    return new Timer(const Duration(), callback);
  }

  /**
   * Cancels the timer.
   */
  void cancel();
}
