// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An object used to calculate percentile-based analytics.
///
/// See https://en.wikipedia.org/wiki/Percentile.
class PercentileCalculator {
  /// A map from values to the number of times the value has been recorded.
  final Map<int, int> _counts = {};

  /// The number of values in [_counts].
  int _valueCount = 0;

  /// Initialize a newly created percentile calculator.
  PercentileCalculator();

  /// Record that the given [value] has been seen.
  void addValue(int value) {
    _counts[value] = (_counts[value] ?? 0) + 1;
    _valueCount++;
  }

  /// Remove all of the previously seen values.
  void clear() {
    _counts.clear();
    _valueCount = 0;
  }

  /// Calculates the value at the given [percentile], which must be in the range
  /// [0..100].
  int percentile(int percentile) {
    assert(percentile >= 0 && percentile <= 100);
    if (_valueCount == 0) {
      return 0;
    }
    var targetIndex = _valueCount * percentile / 100;
    var values = _counts.keys.toList()..sort();
    // The number of values represented by walking the counts.
    var accumulation = 0;
    for (var i = 0; i < values.length; i++) {
      var value = values[i];
      accumulation += _counts[value]!;
      if (accumulation >= targetIndex) {
        // We've now accounted for [targetIndex] values, which includes the
        // median value.
        return value;
      }
    }
    throw StateError('');
  }

  /// Return a string that is suitable for sending to the analytics service.
  String toAnalyticsString() {
    var buffer = StringBuffer();
    buffer.write('[');
    for (var p = 5; p <= 100; p += 5) {
      if (p > 5) {
        buffer.write(', ');
      }
      buffer.write(percentile(p));
    }
    buffer.write(']');
    return buffer.toString();
  }

  @override
  String toString() => toAnalyticsString();
}
