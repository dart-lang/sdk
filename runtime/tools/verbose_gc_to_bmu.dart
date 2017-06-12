// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// NOTE: See also wrapper script sdk/runtime/tools/bmu_benchmark_gallery.sh
//
// Tool to compute bounded mutator utilization (BMU) from a --verbose_gc log.
// Outputs CSV suitable for, e.g., gnuplot:
//
// dart --verbose_gc foo.dart 2> foo.gclog
// dart verbose_gc_to_bmu.dart < foo.gclog > foo.bmu
// gnuplot -p -e "set yr [0:1]; set logscale x; plot 'foo.bmu' with linespoints"

import 'dart:io';
import 'dart:math';

const WINDOW_STEP_FACTOR = 0.9;
const MINIMUM_WINDOW_SIZE_MS = 1;

class Interval<T> {
  T begin;
  T end;
  Interval(this.begin, this.end);
  T get length => max(0, end - begin);
  Interval<T> overlap(Interval<T> other) =>
      new Interval(max(this.begin, other.begin), min(this.end, other.end));
}

class Timeline {
  // Pauses must be added in non-decreasing order of 'begin'.
  void addPause(Interval<int> pause) {
    var last = _pauses.isEmpty ? new Interval<int>(0, 0) : _pauses.last;
    assert(last.begin <= pause.begin);
    // Trim any initial overlap.
    _pauses.add(new Interval(max(pause.begin, last.end), pause.end));
    // TODO(koda): Make VM log actual end time, rather than just last GC end.
    _run.end = max(_run.end, pause.end);
  }

  int get maxWindowSize => _run.length;

  // The windowSize must be no larger than the entire run.
  double minUtilization(int windowSize) {
    assert(windowSize <= _run.length);
    // The minimum utilization can always be found in a window that has one of
    // its endpoints at the beginning or end of a pause or the entire timeline.
    List<int> interesting = [_run.begin, _run.end];
    for (Interval p in _pauses) {
      interesting.add(p.begin);
      interesting.add(p.end);
    }
    double result = 1.0;
    for (int i in interesting) {
      result = min(result, _utilization(new Interval(i, i + windowSize)));
      result = min(result, _utilization(new Interval(i - windowSize, i)));
    }
    return result;
  }

  // Returns the fraction of non-pause time, or 1.0 for an invalid interval.
  double _utilization(Interval<int> iv) {
    if (_run.begin > iv.begin || iv.end > _run.end || iv.length == 0) {
      return 1.0;
    }
    int paused = 0;
    for (Interval<int> p in _pauses) {
      paused += p.overlap(iv).length;
    }
    return 1.0 - (paused / iv.length);
  }

  final Interval<int> _run = new Interval<int>(0, 0);
  final List<Interval<int>> _pauses = [];
}

// Returns a GC pause as an interval in microseconds since program start, or
// the interval [0, 0) on parse error.
Interval<int> parseVerboseGCLine(String line) {
  var fields = line.split(',');
  // Update this (and indices below, if needed) when logging format changes.
  if (fields.length < 10) {
    // Ignore the lines that just specify column names, separated by '|'.
    // We assume these have very few commas in them, so that fields.length
    // is < 10.
    assert(line.contains("|"));
    return new Interval<int>(0, 0);
  }
  var begin = (1e6 * double.parse(fields[2])).floor();
  var duration = (1000 * double.parse(fields[3])).floor();
  var end = begin + duration;
  return new Interval<int>(begin, end);
}

void main() {
  Timeline t = new Timeline();
  for (String line = stdin.readLineSync();
      line != null;
      line = stdin.readLineSync()) {
    t.addPause(parseVerboseGCLine(line));
  }
  print('# window_size_ms, bounded_mutator_utilization');
  var minimumSeen = 1.0;
  for (int w = t._run.length;
      w > 1000 * MINIMUM_WINDOW_SIZE_MS;
      w = (w * WINDOW_STEP_FACTOR).floor()) {
    minimumSeen = min(minimumSeen, t.minUtilization(w));
    print('${w / 1000}, $minimumSeen');
  }
}
