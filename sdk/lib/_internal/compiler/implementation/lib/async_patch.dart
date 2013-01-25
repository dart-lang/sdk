// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for the dart:async library.

import 'dart:_isolate_helper' show TimerImpl;

patch class Timer {
  patch factory Timer(int milliseconds, void callback(Timer timer)) {
    return new TimerImpl(milliseconds, callback);
  }

  /**
   * Creates a new repeating timer. The [callback] is invoked every
   * [milliseconds] millisecond until cancelled.
   */
  patch factory Timer.repeating(int milliseconds, void callback(Timer timer)) {
    return new TimerImpl.repeating(milliseconds, callback);
  }
}
