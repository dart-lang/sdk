// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// A throttling algorithm. This models the throttling after a bucket with
/// water dripping into it at the rate of 1 drop per replenish duration. If the
/// bucket has water when an operation is requested, 1 drop of water is removed
/// and the operation is performed. If not the operation is skipped. This
/// algorithm lets operations be performed in bursts without throttling, but
/// holds the overall average rate of operations to 1 per replenish duration.
class ThrottlingBucket {
  final int bucketSize;
  final Duration replenishDuration;

  int _drops;
  int _lastReplenish;

  ThrottlingBucket(this.bucketSize, this.replenishDuration) {
    _drops = bucketSize;
    _lastReplenish = new DateTime.now().millisecondsSinceEpoch;
  }

  bool removeDrop() {
    _checkReplenish();

    if (_drops <= 0) {
      return false;
    } else {
      _drops--;
      return true;
    }
  }

  void _checkReplenish() {
    int now = new DateTime.now().millisecondsSinceEpoch;

    int replenishMillis = replenishDuration.inMilliseconds;

    if (_lastReplenish + replenishMillis >= now) {
      int inc = (now - _lastReplenish) ~/ replenishMillis;
      _drops = math.min(_drops + inc, bucketSize);
      _lastReplenish += (replenishMillis * inc);
    }
  }
}
