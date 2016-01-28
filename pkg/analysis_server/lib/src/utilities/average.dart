// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.utilities.average;

/// Simple rolling average sample counter.
class Average {
  num _val;
  final int _sampleCount;

  /// Create an average with the given (optional) sample count size.
  Average([this._sampleCount = 20]);

  /// The current average.
  num get value => _val ?? 0;

  /// Add the given [sample].
  void addSample(num sample) {
    if (_val == null) {
      _val = sample;
    } else {
      _val = _val * ((_sampleCount - 1) / _sampleCount) +
          sample * (1 / _sampleCount);
    }
  }

  @override
  String toString() => 'average: $value';
}
