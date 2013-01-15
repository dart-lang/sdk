// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

abstract class Timer {
  /**
   * Creates a new timer. The [callback] callback is invoked after
   * [milliseconds] milliseconds.
   */
  external factory Timer(int milliseconds, void callback(Timer timer));

  /**
   * Creates a new repeating timer. The [callback] is invoked every
   * [milliseconds] millisecond until cancelled.
   */
  external factory Timer.repeating(int milliseconds,
                                   void callback(Timer timer));

  /**
   * Cancels the timer.
   */
  void cancel();
}
