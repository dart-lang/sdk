// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Measures event loop responsiveness.
///
/// Schedules new timer events, [tickDuration] in the future, and measures how
/// long it takes for these events to actually arrive.
///
/// Runs [numberOfTicks] times before completing with [EventLoopLatencyStats].
Future<EventLoopLatencyStats> measureEventLoopLatency(
    Duration tickDuration, int numberOfTicks) {
  final completer = Completer<EventLoopLatencyStats>();

  final tickDurationInUs = tickDuration.inMicroseconds;
  final buffer = _TickLatencies(numberOfTicks);
  final sw = Stopwatch()..start();
  int lastTimestamp = 0;

  void trigger() {
    final int currentTimestamp = sw.elapsedMicroseconds;

    // Every tick we missed to schedule we'll add with difference to when we
    // would've scheduled it and when we became responsive again.
    bool done = false;
    while (!done && lastTimestamp < (currentTimestamp - tickDurationInUs)) {
      done = !buffer.add(currentTimestamp - lastTimestamp - tickDurationInUs);
      lastTimestamp += tickDurationInUs;
    }

    if (!done) {
      lastTimestamp = currentTimestamp;
      Timer(tickDuration, trigger);
    } else {
      completer.complete(buffer.makeStats());
    }
  }

  Timer(tickDuration, trigger);

  return completer.future;
}

/// Result of the event loop latency measurement.
class EventLoopLatencyStats {
  /// Minimum latency between scheduling a tick and it's arrival (in ms).
  final double minLatency;

  /// Average latency between scheduling a tick and it's arrival (in ms).
  final double avgLatency;

  /// Maximum latency between scheduling a tick and it's arrival (in ms).
  final double maxLatency;

  /// The 50th percentile (median) (in ms).
  final double percentile50th;

  /// The 90th percentile (in ms).
  final double percentile90th;

  /// The 95th percentile (in ms).
  final double percentile95th;

  /// The 99th percentile (in ms).
  final double percentile99th;

  /// The maximum RSS of the process.
  final int maxRss;

  EventLoopLatencyStats(
      this.minLatency,
      this.avgLatency,
      this.maxLatency,
      this.percentile50th,
      this.percentile90th,
      this.percentile95th,
      this.percentile99th,
      this.maxRss);

  void report(String name) {
    print('$name.Min(RunTimeRaw): $minLatency ms.');
    print('$name.Avg(RunTimeRaw): $avgLatency ms.');
    print('$name.Percentile50(RunTimeRaw): $percentile50th ms.');
    print('$name.Percentile90(RunTimeRaw): $percentile90th ms.');
    print('$name.Percentile95(RunTimeRaw): $percentile95th ms.');
    print('$name.Percentile99(RunTimeRaw): $percentile99th ms.');
    print('$name.Max(RunTimeRaw): $maxLatency ms.');
    print('$name.MaxRss(MemoryUse): $maxRss');
  }
}

/// Accumulates tick latencies and makes statistics for it.
class _TickLatencies {
  final Uint64List _timestamps;
  int _index = 0;

  _TickLatencies(int numberOfTicks) : _timestamps = Uint64List(numberOfTicks);

  /// Returns `true` while the buffer has not been filled yet.
  bool add(int latencyInUs) {
    _timestamps[_index++] = latencyInUs;
    return _index < _timestamps.length;
  }

  EventLoopLatencyStats makeStats() {
    if (_index != _timestamps.length) {
      throw 'Buffer has not been fully filled yet.';
    }

    _timestamps.sort();
    final length = _timestamps.length;
    final double avg = _timestamps.fold(0, (int a, int b) => a + b) / length;
    final int min = _timestamps.fold(0x7fffffffffffffff, math.min);
    final int max = _timestamps.fold(0, math.max);
    final percentile50th = _timestamps[50 * length ~/ 100];
    final percentile90th = _timestamps[90 * length ~/ 100];
    final percentile95th = _timestamps[95 * length ~/ 100];
    final percentile99th = _timestamps[99 * length ~/ 100];

    return EventLoopLatencyStats(
        min / 1000,
        avg / 1000,
        max / 1000,
        percentile50th / 1000,
        percentile90th / 1000,
        percentile95th / 1000,
        percentile99th / 1000,
        ProcessInfo.maxRss);
  }
}
