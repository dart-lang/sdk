// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

class SlidingStatistics {
  final Uint32List _values;
  int _index = 0;
  bool _isReady = false;

  SlidingStatistics(int length) : _values = Uint32List(length);

  bool get isReady => _isReady;

  int get max {
    var result = 0;
    for (var value in _values) {
      if (value > result) {
        result = value;
      }
    }
    return result;
  }

  double get mean {
    assert(isReady);
    var sum = 0.0;
    for (var value in _values) {
      sum += value;
    }
    return sum / _values.length;
  }

  int get min {
    var result = 1 << 20;
    for (var value in _values) {
      if (value < result) {
        result = value;
      }
    }
    return result;
  }

  double get standardDeviation {
    assert(isReady);
    var mean = this.mean;
    var sum = 0.0;
    for (var value in _values) {
      var diff = value - mean;
      sum += diff * diff;
    }
    return sqrt(sum / _values.length);
  }

  void add(int value) {
    _values[_index] = value;
    _index++;
    if (_index == _values.length) {
      _isReady = true;
    }
    _index %= _values.length;
  }
}
