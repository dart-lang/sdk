// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_isolate_helper' show TimerImpl;

typedef void _TimerCallback0();
typedef void _TimerCallback1(Timer timer);

patch class Timer {
  patch factory Timer(var duration, var callback) {
    // TODO(floitsch): remove these checks when we remove the deprecated
    // millisecond argument and the 1-argument callback. Also remove the
    // int-test below.
    if (callback is! _TimerCallback0 && callback is! _TimerCallback1) {
      throw new ArgumentError(callback);
    }
    int milliseconds = duration is int ? duration : duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    Timer timer;
    _TimerCallback0 zeroArgumentCallback =
        callback is _TimerCallback0 ? callback : () => callback(timer);
    timer = new TimerImpl(milliseconds, zeroArgumentCallback);
    return timer;
  }

  /**
   * Creates a new repeating timer. The [callback] is invoked every
   * [milliseconds] millisecond until cancelled.
   */
  patch factory Timer.repeating(var duration, void callback(Timer timer)) {
    // TODO(floitsch): remove this check when we remove the deprecated
    // millisecond argument.
    int milliseconds = duration is int ? duration : duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return new TimerImpl.repeating(milliseconds, callback);
  }
}
