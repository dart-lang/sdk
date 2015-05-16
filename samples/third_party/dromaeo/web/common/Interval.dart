// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of common;

// A utility object for measuring time intervals.

class Interval {
  int _start, _stop;

  Interval() {
  }

  void start() {
    _start = BenchUtil.now;
  }

  void stop() {
    _stop = BenchUtil.now;
  }

  // Microseconds from between start() and stop().
  int get elapsedMicrosec {
    return (_stop - _start) * 1000;
  }

  // Milliseconds from between start() and stop().
  int get elapsedMillisec {
    return (_stop - _start);
  }
}
