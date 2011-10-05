// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Timer factory _Timer{

  /*
   * Creates a new timer. The [callback] callback is invoked after
   * [milliSeconds] milliseconds. If [repeating] is set, the timer
   * is repeated every [milliSeconds] milliseconds until cancelled.
   */
  Timer(void callback(Timer timer), int milliSeconds, bool repeating);

  /*
   * Cancels the timer.
   */
  void cancel();
}

