// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple implementation of the [Stopwatch] interface.
 */
class StopwatchImplementation implements Stopwatch {
  // The _start and _stop fields capture the time when [start] and [stop]
  // are called respectively.
  // If _start is null, then the [Stopwatch] has not been started yet.
  // If _stop is null, then the [Stopwatch] has not been stopped yet,
  // or is running.
  int _start;
  int _stop;

  StopwatchImplementation() : _start = null, _stop = null {}

  void start() {
    if (_start === null) {
      // This stopwatch has never been started.
      _start = _now();
    } else {
      if (_stop === null) {
        return;
      }
      // Restarting this stopwatch. Prepend the elapsed time to the current
      // start time.
      _start = _now() - (_stop - _start);
      _stop = null;
    }
  }

  void stop() {
    if (_start === null || _stop !== null) {
      return;
    }
    _stop = _now();
  }

  void reset() {
    if (_start === null) return;
    // If [_start] is not null, then the stopwatch had already been started. It
    // may running right now.
    _start = _now();
    if (_stop !== null) {
      // The watch is not running. So simply set the [_stop] to [_start] thus
      // having an elapsed time of 0.
      _stop = _start;
    }
  }

  int get elapsedTicks {
    if (_start === null) {
      return 0;
    }
    return (_stop === null) ? (_now() - _start) : (_stop - _start);
  }

  int get elapsedMicroseconds {
    return (elapsedTicks * 1000000) ~/ frequency;
  }

  int get elapsedMilliseconds {
    return (elapsedTicks * 1000) ~/ frequency;
  }

  int get frequency => _frequency();

  external static int _frequency();
  external static int _now();
}
