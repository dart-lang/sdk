// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.utilities.general;

import 'java_core.dart';

/**
 * Helper for measuring how much time is spent doing some operation.
 */
class TimeCounter {
  int result = 0;

  /**
   * Starts counting time.
   *
   * @return the [TimeCounterHandle] that should be used to stop counting.
   */
  TimeCounter_TimeCounterHandle start() => new TimeCounter_TimeCounterHandle(this);
}

/**
 * The handle object that should be used to stop and update counter.
 */
class TimeCounter_TimeCounterHandle {
  final TimeCounter TimeCounter_this;

  int _startTime = JavaSystem.currentTimeMillis();

  TimeCounter_TimeCounterHandle(this.TimeCounter_this);

  /**
   * Stops counting time and updates counter.
   */
  void stop() {
    {
      TimeCounter_this.result += JavaSystem.currentTimeMillis() - _startTime;
    }
  }
}