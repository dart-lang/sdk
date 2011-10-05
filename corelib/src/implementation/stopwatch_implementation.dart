// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple implementation of the [StopWatch] interface.
 */
class StopWatchImplementation implements StopWatch {
  // The _start and _stop fields capture the time when [start] and [stop]
  // are called respectively.
  // If _start is null, then the [StopWatch] has not been started yet.
  // If _stop is null, then the [StopWatch] has not been stopped yet.
  int _start;
  int _stop;

  StopWatchImplementation() : _start = null, _stop = null {}

  void start() {
    if (_start === null) {
      // This stopwatch has never been started.
      _start = Clock.now();
    } else {
      if (_stop === null) {
        return;
      }
      // Restarting this stopwatch. Prepend the elapsed time to the current
      // start time.
      _start = Clock.now() - (_stop - _start);
    }
  }

  void stop() {
    if (_start === null) {
      return;
    }
    _stop = Clock.now();
  }

  int elapsed() {
    if (_start === null) {
      return 0;
    }
    return (_stop === null) ? (Clock.now() - _start) : (_stop - _start);
  }

  int elapsedInUs() {
    return (elapsed() * 1000000) ~/ frequency();
  }

  int elapsedInMs() {
    return (elapsed() * 1000) ~/ frequency();
  }

  int frequency() {
    return Clock.frequency();
  }

}
