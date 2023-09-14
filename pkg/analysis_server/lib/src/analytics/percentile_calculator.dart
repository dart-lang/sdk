// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

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

  /// The number of values recorded.
  int get valueCount => _valueCount;

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
    var entries = _counts.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));
    // The number of values represented by walking the counts.
    var accumulation = 0;
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i];
      accumulation += entry.value;
      if (accumulation >= targetIndex) {
        // We've now accounted for [targetIndex] values, which includes the
        // median value.
        return entry.key;
      }
    }
    throw StateError('');
  }

  /// Return a string that is suitable for sending to the analytics service.
  String toAnalyticsString() => json.encode(toJson());

  /// Return a map that can be encoded as JSON that represents the state of this
  /// calculator.
  Map<String, Object> toJson() {
    // It's important the the encoded form of the list of percentile values be
    // less than 100 characters long.
    return {
      'count': _valueCount,
      'percentiles': [
        percentile(50),
        percentile(75),
        percentile(90),
        percentile(95),
        percentile(100),
      ],
    };
  }

  @override
  String toString() => toAnalyticsString();
}
