// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure optional parameters get renamed properly for sync* transformations.

Iterable<num> range(num startOrStop, [num? stop, num? step]) sync* {
  final start = stop == null ? 0 : startOrStop;
  stop ??= startOrStop;
  step ??= 1;

  if (step == 0) throw ArgumentError('step cannot be 0');
  if (step > 0 && stop < start) {
    throw ArgumentError('if step is positive, stop must be greater than start');
  }
  if (step < 0 && stop > start) {
    throw ArgumentError('if step is negative, stop must be less than start');
  }

  for (
    num value = start;
    step < 0 ? value > stop : value < stop;
    value += step
  ) {
    yield value;
  }
}

void main() {
  print(range(10, 20, 2));
}
