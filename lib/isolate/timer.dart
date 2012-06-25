// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Timer default _TimerFactory {
  /**
   * Creates a new timer. The [callback] callback is invoked after
   * [milliSeconds] milliseconds.
   */
  Timer(int milliSeconds, void callback(Timer timer));

  /**
   * Creates a new repeating timer. The [callback] is invoked every
   * [milliSeconds] millisecond until cancelled.
   */
  Timer.repeating(int milliSeconds, void callback(Timer timer));

  /**
   * Cancels the timer.
   */
  void cancel();
}
